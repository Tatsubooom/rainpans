#!/usr/bin/env bash
# Runs the game under a virtual display and saves a screenshot.
#   tools/shot.sh out.png [extra game args...]   e.g. --demo --frames=120
set -euo pipefail
cd "$(dirname "$0")/.."
out="${1:-shots/shot.png}"
shift || true
mkdir -p "$(dirname "$out")"
GODOT="${GODOT:-godot}"
if [ ! -d .godot ]; then
  timeout 300 "$GODOT" --headless --import >/dev/null 2>&1 || true
fi
abs="$(cd "$(dirname "$out")" && pwd)/$(basename "$out")"
timeout 180 xvfb-run -a -s "-screen 0 1280x720x24" \
  "$GODOT" --rendering-driver opengl3 --audio-driver Dummy --path . \
  --resolution 320x180 -- --no-save --shot="$abs" "$@" 2>&1 \
  | grep -vE "ALSA|audio driver|dummy driver|audio_server|init_output_device|^\s*at: " || true
test -f "$abs"
