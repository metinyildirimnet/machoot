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
MIN_MACOS="15.2"

# Build each architecture separately, then merge with lipo.
# (Multi --arch builds go through xcbuild, which is flaky across Xcode versions.)
SLICES=()
for a in $ARCHS; do
  triple="$a-apple-macosx$MIN_MACOS"
  swift build -c release --triple "$triple" --scratch-path ".build/$a"
  SLICES+=("$(swift build -c release --triple "$triple" --scratch-path ".build/$a" --show-bin-path)/Machoot")
done
mkdir -p build
lipo -create "${SLICES[@]}" -output build/Machoot-bin

APP="build/Machoot.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
mv build/Machoot-bin "$APP/Contents/MacOS/Machoot"
cp Resources/Info.plist "$APP/Contents/Info.plist"
if [ -n "${VERSION:-}" ]; then   # e.g. VERSION=0.2.0 (set by CI from the git tag)
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
fi
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$APP/Contents/Resources/" \
  && /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP/Contents/Info.plist"

codesign --force --options runtime --timestamp=none --sign "$SIGN_IDENTITY" "$APP"

(cd build && rm -f Machoot.zip && ditto -c -k --keepParent Machoot.app Machoot.zip)
echo "✅ Built $APP and build/Machoot.zip"
