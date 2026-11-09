#!/bin/sh
# Prepare ViePN AI Keyboard iOS 1024px App Icon from the user-supplied logo.
set -eu
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SOURCE="$ROOT/Resources/brand-source.jpg"
TARGET="$ROOT/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
if [ ! -s "$SOURCE" ]; then
  echo "Missing supplied ViePN keyboard logo" >&2
  exit 1
fi
mkdir -p "$(dirname "$TARGET")"
sips -s format png -z 1024 1024 "$SOURCE" --out "$TARGET" >/dev/null
/usr/bin/python3 - "$TARGET" <<'PY'
import struct
import sys
with open(sys.argv[1], "rb") as stream:
    header = stream.read(24)
assert header[:8] == b"\x89PNG\r\n\x1a\n", "App Icon is not PNG"
assert struct.unpack(">II", header[16:24]) == (1024, 1024), "App Icon must be 1024 x 1024"
PY
echo "Prepared ViePN AI Keyboard App Icon: $TARGET"
