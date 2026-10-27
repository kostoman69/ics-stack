#!/usr/bin/env python3
"""Executes the build retention run that the Operations Service requested (Docs/Operations/working/artifact-retention.md).

Runs on the release server as root from cron, next to host-disk-report.sh:

  */10 * * * * python3 /home/administrator/ics-stack/composer/service-level/ics-operations/artifact-retention-apply.py

Operations (the web-facing container) only reads the build folders; it writes the folders it wants deleted to
/data/ics/retention/request.json. This script takes that request and checks every folder again before deleting it:
a known release root, a build folder name ({buildId} or {buildId}.partial), a real folder inside that root, not the
latest.json build, not the compatibility bridge that build's manifest names, not pinned. Then it rebuilds versions.json
of each root it changed (ics-versions-index.sh beside this file) and writes result.json, which ITO shows.

Python 3 standard library only. Nothing to do when there is no request.
"""
from __future__ import annotations

import fcntl
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

ROOTS = ("11-backend", "11-desk", "11-tooling")
FOLDER = re.compile(r"^\d+(\.partial)?$")
HERE = Path(__file__).resolve().parent


def now() -> str:
    return datetime.now().astimezone().isoformat(timespec="seconds")


def read_json(path: Path) -> dict:
    try:
        # utf-8-sig: VERSION.json and manifests may carry a BOM (Windows PowerShell 5.1).
        value = json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, ValueError):
        return {}
    return value if isinstance(value, dict) else {}


def write_json(path: Path, payload: dict) -> None:
    tmp = path.with_name(f".{path.name}.tmp.{os.getpid()}")
    tmp.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    os.chmod(tmp, 0o644)
    tmp.replace(path)


def as_int(value: object) -> int | None:
    if isinstance(value, int) and not isinstance(value, bool):
        return value
    if isinstance(value, str) and value.strip().isdigit():
        return int(value)
    return None


def protected(data_root: Path, root: str, state: Path) -> dict[int, str]:
    """Build ids of one root that must never be deleted, read now (not from the request)."""
    out: dict[int, str] = {}
    latest = as_int(read_json(data_root / root / "latest.json").get("build_id"))
    if latest is not None:
        out[latest] = "latest.json"
        bridge = as_int(read_json(data_root / root / str(latest) / "manifest.json").get("minimum_supported_build_id"))
        if bridge is not None:
            out[bridge] = "compatibility bridge"
    pins = read_json(state / "pins.json").get(root)
    for row in pins if isinstance(pins, list) else []:
        build_id = as_int(row.get("build_id")) if isinstance(row, dict) else None
        if build_id is not None:
            out.setdefault(build_id, "pinned")
    return out


def size_of(path: Path) -> int:
    total = 0
    for base, _, files in os.walk(path):
        for name in files:
            try:
                total += (Path(base) / name).lstat().st_size
            except OSError:
                continue
    return total


def check(data_root: Path, state: Path, root: str, folder: str) -> tuple[Path | None, str | None]:
    if root not in ROOTS:
        return None, "unknown release root"
    if not FOLDER.match(folder):
        return None, "not a build folder name"
    root_dir = (data_root / root).resolve()
    path = data_root / root / folder
    if path.is_symlink() or not path.is_dir():
        return None, "not a folder"
    if path.resolve().parent != root_dir:
        return None, "outside its release root"
    reason = protected(data_root, root, state).get(int(folder.split(".")[0]))
    if reason:
        return None, reason
    return path, None


def apply(data_root: Path, state: Path, index_script: Path) -> dict | None:
    request_path, running_path = state / "request.json", state / "running.json"
    if not request_path.is_file():
        return None
    # Taken over before any deletion: a new request written meanwhile waits for the next run.
    request_path.replace(running_path)
    request = read_json(running_path)
    result: dict = {"requested_by": request.get("requested_by"), "requested_at": request.get("requested_at"),
                    "started_at": now(), "deleted": [], "refused": [], "index_rebuilt": [], "errors": []}
    changed: set[str] = set()
    deletions = request.get("deletions") if isinstance(request.get("deletions"), list) else []
    checked: list[tuple[str, str, Path]] = []
    for item in deletions:
        root = str(item.get("root", "")) if isinstance(item, dict) else ""
        folder = str(item.get("folder", "")) if isinstance(item, dict) else ""
        path, reason = check(data_root, state, root, folder)
        if path is None:
            result["refused"].append({"root": root, "folder": folder, "reason": reason})
        else:
            checked.append((root, folder, path))

    # Independent safety net: never delete more than half of a root's build folders in one run, whatever was asked
    # (a reading error once made Operations plan to delete every Backend build).
    for root in ROOTS:
        builds = [f for r, f, _ in checked if r == root and f.isdigit()]
        try:
            present = sum(1 for p in (data_root / root).iterdir() if p.name.isdigit() and p.is_dir() and not p.is_symlink())
        except OSError:
            present = 0
        if builds and len(builds) * 2 > present:
            result["errors"].append(f"{root}: {len(builds)} of {present} build folders requested · more than half, refused")
            checked = [c for c in checked if c[0] != root]

    for root, folder, path in checked:
        size = size_of(path)
        # Renamed first: a half-deleted build never stays visible under its build id.
        trash = path.with_name(f".deleting-{folder}")
        try:
            path.rename(trash)
            shutil.rmtree(trash)
        except OSError as exc:
            result["errors"].append(f"{root}/{folder}: {exc}")
            continue
        result["deleted"].append({"root": root, "folder": folder, "bytes": size})
        changed.add(root)

    for root in sorted(changed):
        run = subprocess.run(["sh", str(index_script), str(data_root / root)], capture_output=True, text=True)
        if run.returncode == 0:
            result["index_rebuilt"].append(root)
        else:
            result["errors"].append(f"{root}/versions.json: {run.stderr.strip() or run.returncode}")
        for line in run.stderr.splitlines():
            if line.startswith("WARNING"):
                result["errors"].append(f"{root}: {line}")

    result["freed_bytes"] = sum(d["bytes"] for d in result["deleted"])
    result["finished_at"] = now()
    write_json(state / "result.json", result)
    running_path.unlink(missing_ok=True)
    return result


def main() -> int:
    data_root = Path(os.getenv("ICS_RELEASE_ROOT", "/data/ics"))
    state = Path(os.getenv("ICS_RETENTION_DIR", str(data_root / "retention")))
    index_script = Path(os.getenv("ICS_VERSIONS_INDEX_SCRIPT", str(HERE / "ics-versions-index.sh")))
    if not state.is_dir():
        return 0
    with open(state / ".apply.lock", "w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return 0
        result = apply(data_root, state, index_script)
    if result is not None:
        print(f"retention: deleted {len(result['deleted'])}, refused {len(result['refused'])}, "
              f"freed {result['freed_bytes']} bytes, errors {len(result['errors'])}")
    return 1 if result and result["errors"] else 0


if __name__ == "__main__":
    sys.exit(main())
