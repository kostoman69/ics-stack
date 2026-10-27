#!/bin/sh
# Rebuilds versions.json of one release root (11-backend, 11-desk or 11-tooling) from each build's own VERSION.json.
#
# One script for every writer of the index: the publish pipeline (azp-publish-artifacts.yml uploads this file next to
# each root's latest.json and calls it after every publish) and artifact-retention-apply.py (after it deleted builds).
#
#   sh ics-versions-index.sh /data/ics/11-backend [updated_at]
#
# Storage is flat and BuildId-keyed, so folder names carry no version meaning: each build's VERSION.json is the only
# source of truth. Folders that are not plain numbers (www-lib, {buildId}.partial uploads) are ignored. A build with
# artifact files but no usable VERSION.json is skipped with a warning on stderr.
# The new index is written next to the old one and renamed over it, so readers never see a half-written file.
set -eu

root=${1:?usage: ics-versions-index.sh ROOT_DIR [updated_at]}
root=${root%/}
updated_at=${2:-$(date +%Y-%m-%dT%H:%M:%S%z | sed 's/\(..\)$/:\1/')}
name=$(basename "$root")

case "$name" in
  11-backend) prefix='' ;;
  11-desk) prefix='desk' ;;
  11-tooling) prefix='tooling' ;;
  *) echo "ERROR: unknown release root $root" >&2; exit 2 ;;
esac

# VERSION.json key: major, deskMajor, toolingMajor, ...
key() {
  if [ -z "$prefix" ]; then
    printf '%s' "$1"
  else
    printf '%s%s%s' "$prefix" "$(printf '%s' "$1" | cut -c1 | tr '[:lower:]' '[:upper:]')" "$(printf '%s' "$1" | cut -c2-)"
  fi
}

extract_json_num() {
  # $1 = file, $2 = json key (numeric value, unquoted in JSON)
  sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p" "$1" | head -n1
}

extract_json_str() {
  # $1 = file, $2 = json key (string value). Portable BRE only; an escaped quote inside the value is not expected.
  sed -n "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$1" | head -n1
}

tmp="$root/.versions.json.tmp.$$"
trap 'rm -f "$tmp"' EXIT

printf '{\n  "root": "%s",\n  "updated_at": "%s",\n  "entries": [\n' "$name" "$updated_at" > "$tmp"
first=1
for dir in "$root"/*/; do
  [ -d "$dir" ] || continue
  buildDirName=$(basename "$dir")
  case "$buildDirName" in
    ''|*[!0-9]*) continue ;;
  esac

  vfile="${dir}VERSION.json"
  if [ ! -f "$vfile" ]; then
    # Old pre-migration container folders have neither VERSION.json nor artifacts: skip quietly.
    for artifactName in manifest.json api.zip app.zip cnx.zip; do
      if [ -f "${dir}${artifactName}" ]; then
        echo "WARNING: skipping $dir -- has artifact files but no VERSION.json (incomplete/broken build?)" >&2
        break
      fi
    done
    continue
  fi

  major=$(extract_json_num "$vfile" "$(key major)")
  minor=$(extract_json_num "$vfile" "$(key minor)")
  patch=$(extract_json_num "$vfile" "$(key patch)")
  build_id=$(extract_json_num "$vfile" "$(key buildId)")
  ops_label=$(extract_json_str "$vfile" opsLabel)

  if [ -z "$major" ] || [ -z "$minor" ] || [ -z "$patch" ] || [ -z "$build_id" ]; then
    echo "WARNING: skipping $vfile -- could not extract $(key major)/$(key minor)/$(key patch)/$(key buildId)" >&2
    continue
  fi
  if [ "$build_id" != "$buildDirName" ]; then
    echo "WARNING: skipping $vfile -- $(key buildId) ($build_id) does not match its own folder name ($buildDirName)" >&2
    continue
  fi

  version="11.${major}.${minor}"
  if [ "$patch" -ne 0 ]; then
    version="${version}.${patch}"
  fi

  if [ "$first" -eq 0 ]; then
    printf ',\n' >> "$tmp"
  fi
  printf '    {"major": %s, "minor": %s, "patch": %s, "build_id": %s, "version": "%s", "path": "%s/%s", "ops_label": "%s"}' \
    "$major" "$minor" "$patch" "$build_id" "$version" "$root" "$buildDirName" "$ops_label" >> "$tmp"
  first=0
done
printf '\n  ]\n}\n' >> "$tmp"

# Run as root (retention), keep the file owned like its folder so the pipeline's SSH user can replace it next time.
if [ "$(id -u)" -eq 0 ]; then
  chown "$(stat -c '%u:%g' "$root")" "$tmp"
fi
chmod 644 "$tmp"
mv -f "$tmp" "$root/versions.json"
trap - EXIT
