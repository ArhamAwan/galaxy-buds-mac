#!/bin/bash
set -euo pipefail

# Builds the app, names it "Budsy.app", and produces a distributable
# drag-to-Applications .dmg in dist/.

APP_NAME="Budsy"
VERSION="${1:-1.0.0}"
DIST="dist"
STAGE="$DIST/stage"
DMG="$DIST/Budsy-$VERSION.dmg"

echo "==> Building…"
bash build.sh

echo "==> Staging $APP_NAME.app…"
rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "Budsy.app" "$STAGE/$APP_NAME.app"
ln -s /Applications "$STAGE/Applications"

echo "==> Creating .dmg…"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGE" \
  -ov -format UDZO \
  "$DMG"

rm -rf "$STAGE"
echo "==> Done: $DMG"
echo "    SHA256: $(shasum -a 256 "$DMG" | awk '{print $1}')"
