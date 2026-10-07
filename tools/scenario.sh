#!/usr/bin/env bash
# Runs a scripted input scenario under a virtual display: tools/scenario.sh drag
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
out="$(timeout 120 xvfb-run -a -s "-screen 0 1280x720x24" "$GODOT" --rendering-driver opengl3 \
  --audio-driver Dummy --path . --resolution 640x360 -- --no-save --scenario="$1" 2>&1)"
echo "$out" | grep -E "SCENARIO|SCRIPT ERROR|Parse Error|at: .*res://" || true
echo "$out" | grep -q "SCENARIO OK"
