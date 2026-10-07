#!/usr/bin/env bash
# Headless logic tests. Exit code is non-zero on failure.
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
if [ ! -d .godot ]; then
  timeout 300 "$GODOT" --headless --import >/dev/null 2>&1 || true
fi
out="$(timeout 90 "$GODOT" --headless --audio-driver Dummy --path . res://tests/test_main.tscn -- --no-save 2>&1)"
code=$?
echo "$out" | grep -E "FAIL|checks|SCRIPT ERROR|Parse Error|at: " || true
exit $code
