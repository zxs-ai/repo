#!/bin/bash

# Stop deb repack watcher

set -euo pipefail

pids=$(pgrep -f "auto-watch-repack.sh" || true)
if [ -z "$pids" ]; then
  echo "No watcher process found."
  exit 0
fi

echo "Stopping watcher PIDs: $pids"
kill $pids
