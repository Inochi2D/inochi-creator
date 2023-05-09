# First build ARM64 version...
echo "Building arm64 binary..."
dub build --build=release --config=osx-full --arch=arm64-apple-macos
mv "out/Inochi Creator.app/Contents/MacOS/inochi-creator" "out/Inochi Creator.app/Contents/MacOS/inochi-creator-arm64"

# Then the X86_64 version...
echo "Building x86_64 binary..."
dub build --build=release --config=osx-full --arch=x86_64-apple-macos
mv "out/Inochi Creator.app/Contents/MacOS/inochi-creator" "out/Inochi Creator.app/Contents/MacOS/inochi-creator-x86_64"

# Glue them together with lipo
echo "Gluing them together..."
lipo "out/Inochi Creator.app/Contents/MacOS/inochi-creator-x86_64" "out/Inochi Creator.app/Contents/MacOS/inochi-creator-arm64" -output "out/Inochi Creator.app/Contents/MacOS/inochi-creator" -create

# Print some nice info
echo "Done!"
lipo -info "out/Inochi Creator.app/Contents/MacOS/inochi-creator"

# Cleanup and bundle
echo "Cleaning up..."
rm "out/Inochi Creator.app/Contents/MacOS/inochi-creator-x86_64" "out/Inochi Creator.app/Contents/MacOS/inochi-creator-arm64"
./build-aux/osx/osxbundle.sh