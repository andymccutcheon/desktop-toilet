#!/usr/bin/env bash
# Build a signed-ad-hoc "Desktop Toilet.app" in dist/.
# Requires macOS 13+ on Apple Silicon and Swift command-line tools.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: Desktop Toilet.app can only be assembled on macOS (this host is $(uname -s))." >&2
  echo "You can still run the portable logic tests here: make test" >&2
  exit 1
fi

if [[ "$(uname -m)" != "arm64" ]]; then
  echo "warning: this project targets Apple Silicon (arm64); this Mac is $(uname -m)." >&2
fi

if ! command -v swift >/dev/null; then
  echo "error: swift not found. Install Xcode Command Line Tools: xcode-select --install" >&2
  exit 1
fi

if ! command -v codesign >/dev/null; then
  echo "error: codesign not found." >&2
  exit 1
fi

APP_NAME="Desktop Toilet"
BINARY_NAME="DesktopToilet"
DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

rm -rf "$APP"
mkdir -p "$MACOS" "$RESOURCES"

echo "→ swift build -c release --arch arm64 --product $BINARY_NAME"
swift build -c release --arch arm64 --product "$BINARY_NAME"

BIN=""
for candidate in \
  "$ROOT/.build/arm64-apple-macosx/release/$BINARY_NAME" \
  "$ROOT/.build/release/$BINARY_NAME"
do
  if [[ -x "$candidate" ]]; then
    BIN="$candidate"
    break
  fi
done

if [[ -z "$BIN" ]]; then
  BIN="$(find "$ROOT/.build" -type f -name "$BINARY_NAME" -perm -111 | head -n 1 || true)"
fi

if [[ -z "$BIN" || ! -x "$BIN" ]]; then
  echo "error: built binary not found under .build/" >&2
  exit 1
fi

cp "$BIN" "$MACOS/$BINARY_NAME"
chmod +x "$MACOS/$BINARY_NAME"
cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"
printf 'APPL????' > "$CONTENTS/PkgInfo"
cp "$ROOT/Resources/Sounds/plop.wav" "$RESOURCES/plop.wav"
cp "$ROOT/Resources/Sounds/flush.wav" "$RESOURCES/flush.wav"

echo "→ codesign --sign - (ad hoc)"
codesign --force --deep --sign - "$APP"

echo
echo "Built: $APP"
echo "Launch: open \"$APP\""
echo "The app is an LSUIElement (no Dock icon). Look for the drop icon in the menu bar."
