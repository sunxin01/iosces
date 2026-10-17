#!/usr/bin/env bash
# 本地 macOS 一键打包(仅在有 Xcode 的 Mac 上可用)
set -e

if [ "$(uname)" != "Darwin" ]; then
  echo "本脚本只能在 macOS 上运行(需要 Xcode 工具链)。"
  echo "Windows/Linux 请走 GitHub Actions(见 .github/workflows/build-ipa.yml)。"
  exit 1
fi

SCHEME="ShiGuang"
CONF="Release"
WORK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARCHIVE_PATH="$WORK_DIR/build/${SCHEME}.xcarchive"
IPA_OUT="$WORK_DIR/build/${SCHEME}-unsigned.ipa"

mkdir -p "$WORK_DIR/build"

echo "==> xcodebuild archive"
xcodebuild archive \
  -project "$WORK_DIR/${SCHEME}.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONF" \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_ENTITLEMENTS="" \
  ENABLE_BITCODE=NO

APP_PATH="$ARCHIVE_PATH/Products/Applications/${SCHEME}.app"
[ -d "$APP_PATH" ] || { echo "ERROR: $APP_PATH not found"; exit 1; }

echo "==> package IPA"
STAGE="$WORK_DIR/build/stage"
rm -rf "$STAGE"
mkdir -p "$STAGE/Payload"
cp -R "$APP_PATH" "$STAGE/Payload/"
rm -rf "$STAGE/Payload/${SCHEME}.app/_CodeSignature"
rm -f  "$STAGE/Payload/${SCHEME}.app/embedded.mobileprovision"
( cd "$STAGE" && zip -qry "$IPA_OUT" Payload )

shasum -a 256 "$IPA_OUT"
echo "Done: $IPA_OUT"
