#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
HIGHRES="$ROOT/Resources/brand-source.png"
VECTOR="$ROOT/Resources/brand-fallback.svg"
TARGET="$ROOT/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
mkdir -p "$(dirname "$TARGET")"

if [ -s "$HIGHRES" ]; then
    dimensions="$(sips -g pixelWidth -g pixelHeight "$HIGHRES")"
    width="$(printf '%s\n' "$dimensions" | awk '/pixelWidth:/ {print $2}')"
    height="$(printf '%s\n' "$dimensions" | awk '/pixelHeight:/ {print $2}')"
    if [ "$width" -lt 1024 ] || [ "$height" -lt 1024 ]; then
        echo "::error::Original logo must be at least 1024x1024; refusing to upscale" >&2
        exit 1
    fi
    sips -s format png -z 1024 1024 "$HIGHRES" --out "$TARGET" >/dev/null
elif [ -s "$VECTOR" ]; then
    echo "Original high-res PNG not committed; generating crisp vector fallback."
    command -v rsvg-convert >/dev/null 2>&1 || {
       echo "::error::rsvg-convert missing. Install librsvg in CI." >&2
       exit 1
    }
    rsvg-convert --width 1024 --height 1024 "$VECTOR" --output "$TARGET"
else
    echo "::error::No high-res PNG or vector fallback. Old 5.7KB JPG intentionally rejected." >&2
    exit 1
fi

/usr/bin/python3 - "$TARGET" <<'PY'
import struct
import sys
with open(sys.argv[1], "rb") as image:
    head = image.read(24)
assert head[:8] == bytes([137,80,78,71,13,10,26,10]), "Icon must be PNG"
assert struct.unpack(">II", head[16:24]) == (1024, 1024), "Icon must be 1024x1024"
PY
echo "ViePN AI Keyboard high-res icon ready"
