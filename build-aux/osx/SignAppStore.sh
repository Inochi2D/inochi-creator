# Copy provision profile over
cp build-aux/osx/embedded.provisionprofile out/Inochi\ Creator.app/Contents/embedded.provisionprofile

# Sign with hardened runtime
for lib in out/Inochi\ Creator.app/Contents/Frameworks/*
do
    xcrun codesign -s "Apple Distribution: " -f --timestamp --options=runtime --verbose "${lib}"
done
xcrun codesign -s "Apple Distribution: " -f --entitlements build-aux/osx/InochiCreator.entitlements --timestamp --options=runtime --verbose "out/Inochi Creator.app"

# Build pkg
xcrun productbuild --product build-aux/osx/product_definition.plist --timestamp --component out/Inochi\ Creator.app /Applications --sign "3rd Party Mac Developer Installer: " out/Inochi\ Creator.pkg