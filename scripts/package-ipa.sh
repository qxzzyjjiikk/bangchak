#!/usr/bin/env bash
# Builds Bangchak into an unsigned .ipa. Run on macOS with Xcode installed.
#
#   ./scripts/package-ipa.sh [bundle-id]
#
# Passing a bundle id rewrites project.yml before generating, so a device-signable
# identifier can be used without editing files by hand:
#   ./scripts/package-ipa.sh xyz.rlzx.bangchak

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BUNDLE_ID="${1:-}"
if [[ -n "$BUNDLE_ID" ]]; then
  echo "==> bundle id override: $BUNDLE_ID"
  sed -i '' "s|PRODUCT_BUNDLE_IDENTIFIER: .*|PRODUCT_BUNDLE_IDENTIFIER: $BUNDLE_ID|" project.yml
fi

echo "==> cleaning previous output"
rm -rf build
mkdir -p build

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen missing. install with: brew install xcodegen" >&2
  exit 1
fi

echo "==> generating project"
xcodegen generate

echo "==> compiling (Release, unsigned)"
xcodebuild \
  -project Bangchak.xcodeproj \
  -scheme Bangchak \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP="build/Build/Products/Release-iphoneos/Bangchak.app"
if [[ ! -d "$APP" ]]; then
  echo "build produced no app bundle at $APP" >&2
  exit 1
fi

echo "==> packaging Payload"
mkdir -p build/ipa/Payload
cp -R "$APP" build/ipa/Payload/
( cd build/ipa && zip -qry ../Bangchak.ipa Payload )

echo
echo "OK  build/Bangchak.ipa  ($(du -h build/Bangchak.ipa | cut -f1))"
echo "Sign it with Sideloadly or AltStore using your Apple ID."
