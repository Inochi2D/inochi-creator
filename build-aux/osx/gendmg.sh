#!/usr/bin/env bash
set -euo pipefail

DMG_TITLE="Install Inochi Creator"
DMG_FILENAME="Install_Inochi_Creator.dmg"
APP="out/Inochi Creator.app"
EXECUTABLE="$APP/Contents/MacOS/inochi-creator"

if [[ ! -d "$APP" ]]; then
    echo "Could not find Inochi Creator for packaging" >&2
    exit 1
fi

# actions/upload-artifact intentionally normalizes file permissions. Restore
# the executable bit and signature after the bundle is downloaded by this job.
chmod 755 "$EXECUTABLE"
if ! codesign --verify --deep "$APP" 2>/dev/null; then
    xattr -cr "$APP"
    xattr -d com.apple.FinderInfo "$APP" 2>/dev/null || true
    codesign --force --deep --sign - "$APP"
fi
./build-aux/osx/validate-bundle.sh "$APP"

rm -f "out/$DMG_FILENAME"
rm -rf out/InstallVolume
mkdir -p out/InstallVolume
cp LICENSE out/LICENSE
cp -R "$APP" "out/InstallVolume/Inochi Creator.app"
./build-aux/osx/validate-bundle.sh "out/InstallVolume/Inochi Creator.app"

cd out
create-dmg \
    --volname "$DMG_TITLE" \
    --volicon InochiCreator.icns \
    --background ../build-aux/osx/dmgbg.png \
    --window-size 800 600 \
    --icon "Inochi Creator.app" 200 250 \
    --hide-extension "Inochi Creator.app" \
    --eula LICENSE \
    --app-drop-link 600 250 \
    "$DMG_FILENAME" InstallVolume/

rm LICENSE
echo "DMG generated as $PWD/$DMG_FILENAME"
