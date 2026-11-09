#!/bin/sh
# ViePN AI Keyboard app icon
# Never upscale a tiny JPEG: it produces visibly pixelated iPhone icons.
set -eu
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
HIGHRES="$ROOT/Resources/brand-source.png"
OLD="$ROOT/Resources/brand-source.jpg"
TARGET="$ROOT/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

mkdir -p "$(dirname "$TARGET")"
if [ -s "$HIGHRES" ]; then
  SOURCE="$HIGHRES"
elif [ -s "$TARGET" ]; then
  SOURCE="$TARGET"
else
  echo "::error::Sharp ViePN AI Keyboard icon is missing. Do not upscale $OLD (old 5.7 KB placeholder)." >&2
  echo "Upload a source PNG at Resources/brand-source.png (at least 1024 x 1024), or place AppIcon.png in AppIcon.appiconset." >&2
  exit 1
fi

dimensions="$(sips -g pixelWidth -g pixelHeight "$SOURCE")"
width="$(printf '%s\n' "$dimensions" | awk '/pixelWidth:/ {print $2}')"
height="$(printf '%s\n' "$dimensions" | awk '/pixelHeight:/ {print $2}')"
if [ "$width" -lt 1024 ] || [ "$height" -lt 1024 ]; then
  echo "::error::Refusing blurry icon: source is ${width}x${height}, minimum is 1024x1024" >&2
  exit 1
fi
if [ "$SOURCE" != "$TARGET" ]; then
  sips -s format png -z 1024 1024 "$SOURCE" --out "$TARGET" >/dev/null
fi
echo "High-resolution ViePN AI Keyboard icon ready at $TARGET"
