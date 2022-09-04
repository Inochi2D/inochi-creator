echo "Creating directory structure..."
LASTPWD=$PWD

# Handle copying all the dylibs to their respective directories
# As well handle creating our directory structure
cd out/Inochi\ Creator.app/Contents

# Remove old files
rm -r Frameworks SharedSupport Resources
rm Info.plist

# Create new directories and move dylibs
mkdir -p Frameworks SharedSupport Resources
mv -n MacOS/*.dylib Frameworks

# Fix SDL2
mv -n Frameworks/libSDL2*.dylib Frameworks/libSDL2.dylib

# Move back to where we were
cd $LASTPWD

echo "Setting up file structure..."

# Copy info plist and icon
cp res/Info.plist out/Inochi\ Creator.app/Contents/

# Copy license info to SharedSupport
cp res/*-LICENSE out/Inochi\ Creator.app/Contents/SharedSupport/
cp LICENSE out/Inochi\ Creator.app/Contents/SharedSupport/LICENSE


# Create icons dir
# TODO: check if dir exists, skip this step if it does
ICONDIR="out/icons.iconset"
if [ ! -d "$ICONDIR" ]; then
    echo "Creating Icons..."
    mkdir -p $ICONDIR

    # Create normal icons
    for SIZE in 16 32 63 128 256 512; do
        sips -z $SIZE $SIZE res/icon.png --out $ICONDIR/icon_${SIZE}x${SIZE}.png;
    done

    # Create retina icons
    for SIZE in 16 32 63 128 256 512; do
        sips -z $SIZE $SIZE res/icon.png --out $ICONDIR/icon_$(expr $SIZE / 2)x$(expr $SIZE / 2)x2.png;
    done

    iconutil -c icns -o $ICONDIR/InochiCreator.icns $ICONDIR
else
    echo "Icons already exist, skipping..."
fi

echo "Applying Icon..."
cp $ICONDIR/InochiCreator.icns out/Inochi\ Creator.app/Contents/Resources/InochiCreator.icns 

echo "Cleaning up..."
find out/Inochi\ Creator.app/Contents/MacOS -type f ! -name "inochi-creator" -delete

echo "Done!"