#!/usr/bin/env bash
set -euo pipefail

APP="${1:-out/Inochi Creator.app}"
CONTENTS="$APP/Contents"
EXECUTABLE="$CONTENTS/MacOS/inochi-creator"

[[ -x "$EXECUTABLE" ]] || { echo "$EXECUTABLE is not executable" >&2; exit 1; }
plutil -lint "$CONTENTS/Info.plist"

short_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$CONTENTS/Info.plist")"
bundle_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$CONTENTS/Info.plist")"
[[ "$short_version" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]] || { echo "Invalid short version: $short_version" >&2; exit 1; }
[[ "$bundle_version" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]] || { echo "Invalid bundle version: $bundle_version" >&2; exit 1; }

minimum_macos="$(otool -l "$EXECUTABLE" | awk '/LC_BUILD_VERSION/{found=1} found && $1 == "minos" {print $2; exit}')"
[[ "$minimum_macos" == '12.0' ]] || { echo "Unexpected minimum macOS version: $minimum_macos" >&2; exit 1; }

while IFS= read -r macho_file; do
    lipo "$macho_file" -verify_arch arm64 x86_64
    if otool -L "$macho_file" | grep -E '/(opt/homebrew|usr/local|opt/local)/' >/dev/null; then
        echo "Host package-manager dependency found in $macho_file" >&2
        exit 1
    fi
done < <(find "$CONTENTS/MacOS" "$CONTENTS/Frameworks" -type f -print | while IFS= read -r candidate; do
    if file "$candidate" | grep -q 'Mach-O'; then
        printf '%s\n' "$candidate"
    fi
done)

codesign --verify --deep --verbose=2 "$APP"
echo "Validated universal macOS bundle: $APP"
