#!/usr/bin/env bash
# Builds Machoot.app into ./build
#   ./scripts/build-app.sh            # release, universal (arm64 + x86_64)
#   ARCHS=arm64 ./scripts/build-app.sh
#   VERSION=0.2.0 ./scripts/build-app.sh
#   SIGN_IDENTITY="Developer ID Application: ..." ./scripts/build-app.sh
set -euo pipefail
cd "$(dirname "$0")/.."

ARCHS="${ARCHS:-arm64 x86_64}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"   # "-" = ad-hoc signature
ARCH_FLAGS=()
for a in $ARCHS; do ARCH_FLAGS+=(--arch "$a"); done

swift build -c release "${ARCH_FLAGS[@]}"
BIN_DIR="$(swift build -c release "${ARCH_FLAGS[@]}" --show-bin-path)"

APP="build/Machoot.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/Machoot" "$APP/Contents/MacOS/Machoot"
cp Resources/Info.plist "$APP/Contents/Info.plist"
if [ -n "${VERSION:-}" ]; then   # e.g. VERSION=0.2.0 (set by CI from the git tag)
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
fi
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$APP/Contents/Resources/" \
  && /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP/Contents/Info.plist"

codesign --force --options runtime --timestamp=none --sign "$SIGN_IDENTITY" "$APP"

(cd build && rm -f Machoot.zip && ditto -c -k --keepParent Machoot.app Machoot.zip)
echo "✅ Built $APP and build/Machoot.zip"
