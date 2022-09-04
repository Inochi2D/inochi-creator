DMGTITLE="Install Inochi Creator"
DMGFILENAME="$DMGTITLE.dmg"

if [ -d "out/Inochi Creator.app" ]; then
    if [ -f "out/$DMGFILENAME" ]; then
        echo "Removing prior install dmg..."
        rm "out/$DMGFILENAME"
    fi

    PREVPWD=$PWD
    cd out/
    echo "Building $DMGFILENAME..."

    # Create Install Volume directory

    if [ -d "InstallVolume" ]; then
        echo "Cleaning up old install volume..."
        rm -r InstallVolume
    fi

    mkdir -p InstallVolume
    cp ../LICENSE LICENSE
    cp -r "Inochi Creator.app" "InstallVolume/Inochi Creator.app"
    
    create-dmg \
        --volname "$DMGTITLE" \
        --volicon "icons.iconset/InochiCreator.icns" \
        --window-size 800 600 \
        --icon "Inochi Creator.app" 200 250 \
        --hide-extension "Inochi Creator.app" \
        --eula "LICENSE" \
        --app-drop-link 600 250 \
        "$DMGFILENAME" InstallVolume/

    echo "Done! Cleaning up temporaries..."
    rm LICENSE

    echo "DMG generated as $PWD/$DMGFILENAME"
    cd $PREVPWD
else
    echo "Could not find Inochi Creator for packaging..."
fi