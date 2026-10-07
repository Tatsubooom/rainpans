#!/usr/bin/env bash
# Re-imports the project and fails on any GDScript parse/compile error.
cd "$(dirname "$0")/.."
out="$(timeout 300 "${GODOT:-godot}" --headless --import 2>&1)"
errs="$(echo "$out" | grep -A1 -E "SCRIPT ERROR|Parse Error" | grep -E "ERROR|at: " | paste - - | sort -u)"
if [ -n "$errs" ]; then echo "$errs"; exit 1; fi
echo "scripts ok"
