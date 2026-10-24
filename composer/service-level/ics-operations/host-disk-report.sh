#!/bin/sh
# Host disk report for the Operations dashboard («Where the rest of the disk goes»).
#
# Runs on the release server as root from cron (every 30 minutes) and writes a small JSON file that the
# icsops container reads through a read-only mount. icsops itself sees only its own folders; this keeps the
# web-facing container without access to the rest of the host. Read-only: it measures, it never deletes.
#
#   */30 * * * * /home/administrator/ics-stack/composer/service-level/ics-operations/host-disk-report.sh
#
# Output: ${ICS_HOST_REPORT_DIR:-/data/ics/host-report}/disk-report.json, written atomically.
set -eu

out_dir=${ICS_HOST_REPORT_DIR:-/data/ics/host-report}
out="$out_dir/disk-report.json"
tmp="$out.tmp.$$"
mkdir -p "$out_dir"

json_escape() { sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

{
  printf '{\n  "generated_at": "%s",\n' "$(date +%Y-%m-%dT%H:%M:%S%z | sed 's/\(..\)$/:\1/')"
  printf '  "host": "%s",\n' "$(hostname | json_escape)"

  # The root filesystem as the host sees it (bytes).
  df -B1 --output=size,used,avail / | tail -n 1 | awk '{ printf "  \"filesystem\": {\"path\": \"/\", \"total_bytes\": %s, \"used_bytes\": %s, \"free_bytes\": %s},\n", $1, $2, $3 }'

  # Folders two levels below / on the root filesystem only (-x skips /proc, /sys, other disks), largest first.
  printf '  "folders": [\n'
  du -x -B1 --max-depth=2 / 2>/dev/null | sort -rn | awk -v q='"' '
    $2 != "/" {
      path = substr($0, index($0, $2)); gsub(/\\/, "\\\\", path); gsub(/"/, "\\\"", path)
      depth = gsub(/\//, "/", path)
      printf "%s    {\"path\": %s%s%s, \"bytes\": %s, \"depth\": %d}", (n++ ? ",\n" : ""), q, path, q, $1, depth
      if (n >= 60) exit
    }
    END { printf "\n" }'
  printf '  ],\n'

  # Docker storage with what can be reclaimed (images, containers, local volumes, build cache).
  printf '  "docker": ['
  if command -v docker >/dev/null 2>&1; then
    docker system df --format '{{json .}}' 2>/dev/null | awk '{ printf "%s\n    %s", (n++ ? "," : ""), $0 } END { if (n) printf "\n  " }'
  fi
  printf ']\n}\n'
} > "$tmp"

chmod 644 "$tmp"
mv -f "$tmp" "$out"
