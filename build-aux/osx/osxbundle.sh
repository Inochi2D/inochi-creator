echo "Creating directory structure..."
LASTPWD=$PWD

# Handle copying all the dylibs to their respective directories
# As well handle creating our directory structure
cd out/Inochi\ Creator.app/Contents

# Remove old files
if [ -d "Frameworks" ]; then
    echo "Removing files from prior bundle..."
    rm -r Frameworks SharedSupport Resources
    rm Info.plist
fi

# Create new directories and move dylibs
mkdir -p Frameworks SharedSupport Resources Resources/i18n
mv MacOS/libSDL2-2.0.dylib Frameworks/libSDL2.dylib
mv -n MacOS/*.dylib Frameworks

# Move back to where we were
cd $LASTPWD

echo "Setting up file structure..."

# Copy info plist and icon
cp build-aux/osx/Info.plist out/Inochi\ Creator.app/Contents/

# Move any translation files in if any.
mv -n out/*.mo out/Inochi\ Creator.app/Contents/Resources/i18n/

# Copy license info to SharedSupport
cp res/*-LICENSE out/Inochi\ Creator.app/Contents/SharedSupport/
cp LICENSE out/Inochi\ Creator.app/Contents/SharedSupport/LICENSE

# CI step for i18n
if [ -d "out/i18n/" ]; then
    echo "(CI Step) Applying translations..."
    mv -n out/i18n/*.mo out/Inochi\ Creator.app/Contents/Resources/i18n/
fi


# Create icons dir
# TODO: check if dir exists, skip this step if it does
if [ ! -d "out/InochiCreator.icns" ]; then
    iconutil -c icns -o out/InochiCreator.icns build-aux/osx/Inochi-Creator.iconset
else
    echo "Icons already exist, skipping..."
fi

echo "Applying Icon..."
cp out/InochiCreator.icns out/Inochi\ Creator.app/Contents/Resources/InochiCreator.icns 

echo "Cleaning up..."
find out/Inochi\ Creator.app/Contents/MacOS -type f ! -name "inochi-creator" -delete

echo "Done!"