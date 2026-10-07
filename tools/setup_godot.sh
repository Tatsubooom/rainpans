#!/usr/bin/env bash
# Installs a headless-capable Godot binary for cloud sessions (idempotent).
set -euo pipefail
GODOT_VERSION="${GODOT_VERSION:-4.3-stable}"
DEST="${GODOT_HOME:-$HOME/.local/share/godot}"
BIN="$DEST/Godot_v${GODOT_VERSION}_linux.x86_64"
if [ ! -x "$BIN" ]; then
  mkdir -p "$DEST"
  url="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
  curl -sSL --retry 4 -o "$DEST/godot.zip" "$url"
  unzip -oq "$DEST/godot.zip" -d "$DEST"
  rm -f "$DEST/godot.zip"
  chmod +x "$BIN"
fi
mkdir -p "$HOME/.local/bin"
ln -sf "$BIN" "$HOME/.local/bin/godot"
echo "godot: $("$BIN" --headless --version 2>/dev/null | tail -1)"
