#!/usr/bin/env bash
set -euo pipefail

APP="out/Inochi Creator.app"
CONTENTS="$APP/Contents"
EXECUTABLE="$CONTENTS/MacOS/inochi-creator"

if [[ ! -f "$EXECUTABLE" ]]; then
    echo "Could not find $EXECUTABLE" >&2
    exit 1
fi

echo "Creating directory structure..."
rm -rf "$CONTENTS/Frameworks" "$CONTENTS/SharedSupport" "$CONTENTS/Resources"
rm -f "$CONTENTS/Info.plist"
mkdir -p "$CONTENTS/Frameworks" "$CONTENTS/SharedSupport" "$CONTENTS/Resources/i18n"

# DUB copies the dynamic dependencies beside the executable. Move them into
# the standard bundle location before signing the finished application.
if [[ -f "$CONTENTS/MacOS/libSDL2-2.0.dylib" ]]; then
    mv "$CONTENTS/MacOS/libSDL2-2.0.dylib" "$CONTENTS/Frameworks/libSDL2.dylib"
fi
find "$CONTENTS/MacOS" -maxdepth 1 -name '*.dylib' -exec mv -n {} "$CONTENTS/Frameworks/" \;

cp build-aux/osx/Info.plist "$CONTENTS/Info.plist"

version=""
if [[ -s version.txt ]]; then
    version="$(tr -d '\r\n' < version.txt)"
fi
if [[ -z "$version" ]]; then
    version="$(sed -nE 's/.*INC_VERSION = "([^"]+)".*/\1/p' source/creator/ver.d | head -n 1)"
fi

version="${version#v}"
short_version="${version%%+*}"
short_version="${short_version%%-*}"
if [[ ! "$short_version" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]]; then
    echo "Invalid macOS bundle version: $short_version" >&2
    exit 1
fi

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $short_version" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $short_version" "$CONTENTS/Info.plist"

shopt -s nullglob
translations=(out/*.mo out/i18n/*.mo)
if (( ${#translations[@]} )); then
    cp "${translations[@]}" "$CONTENTS/Resources/i18n/"
fi
shopt -u nullglob

cp res/*-LICENSE "$CONTENTS/SharedSupport/"
cp LICENSE "$CONTENTS/SharedSupport/LICENSE"

if [[ ! -f out/InochiCreator.icns ]]; then
    iconutil -c icns -o out/InochiCreator.icns build-aux/osx/Inochi-Creator.iconset
fi
cp out/InochiCreator.icns "$CONTENTS/Resources/InochiCreator.icns"

find "$CONTENTS/MacOS" -type f ! -name 'inochi-creator' -delete
chmod 755 "$EXECUTABLE"

# LDC linker-signs the executable, but adding bundle resources invalidates that
# partial signature. Apply a valid ad-hoc signature until release notarization
# is configured with the project's Developer ID credentials.
xattr -cr "$APP"
xattr -d com.apple.FinderInfo "$APP" 2>/dev/null || true
codesign --force --deep --sign - "$APP"

echo "Created $APP ($short_version)"
