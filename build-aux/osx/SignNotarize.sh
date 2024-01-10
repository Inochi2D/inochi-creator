# Copy provision profile over
cp build-aux/osx/embedded.provisionprofile out/Inochi\ Creator.app/Contents/embedded.provisionprofile

# Sign with hardened runtime
for lib in out/Inochi\ Creator.app/Contents/Frameworks/*
do
    xcrun codesign -s "Developer ID Application: " -f --timestamp --options=runtime --verbose "${lib}"
done
xcrun codesign -s "Developer ID Application: " -f --entitlements build-aux/osx/InochiCreator.entitlements --timestamp --options=runtime --verbose "out/Inochi Creator.app"

# Zip up
zip -vr out/Inochi\ Creator.zip out/ -x "*.DS_Store" -x "InochiCreator.icns"

# Notarize
xcrun notarytool submit out/Inochi\ Creator.zip --keychain-profile "${SIGN_PROFILE}" --wait

# Staple the app file
xcrun stapler staple out/Inochi\ Creator.app