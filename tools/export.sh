#!/usr/bin/env bash
# Exports the Web and Windows builds into build/ (needs export templates:
# tools/export.sh --templates downloads the web + windows ones first).
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
VER="4.3-stable"
TPL="$HOME/.local/share/godot/export_templates/${VER/-/.}"
if [ "${1:-}" = "--templates" ] || [ ! -f "$TPL/web_nothreads_release.zip" ]; then
  mkdir -p "$TPL"
  tmp="$(mktemp -d)"
  curl -sSL --retry 4 -o "$tmp/t.tpz" "https://github.com/godotengine/godot/releases/download/$VER/Godot_v${VER}_export_templates.tpz"
  unzip -oqj "$tmp/t.tpz" templates/version.txt templates/web_nothreads_release.zip \
    templates/web_nothreads_debug.zip templates/windows_release_x86_64.exe -d "$TPL"
  rm -rf "$tmp"
fi
timeout 300 "$GODOT" --headless --import >/dev/null 2>&1 || true
mkdir -p build/web build/windows
"$GODOT" --headless --export-release "Web" build/web/index.html
"$GODOT" --headless --export-release "Windows" build/windows/Rainpans.exe
ls -la build/web build/windows
