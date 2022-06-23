mkdir -p build/inochi-creator.AppDir/usr/bin
cd build/inochi-creator.AppDir/usr/bin
cp ../../out/inochi-creator usr/bin/inochi-creator
cp ../../out/*.mo ./
cp ../../res/logo_256.png logo_256.png
cp ../../res/inochi-creator.desktop inochi-creator.desktop
cp ../../res/AppRun AppRun
cp ../../res/NotoSansCJK-Regular-LICENSE usr/bin/NotoSansCJK-Regular-LICENSE
cp ../../res/MaterialIcons-LICENSE usr/bin/MaterialIcons-LICENSE
cp ../../res/OpenDyslexic-LICENSE usr/bin/OpenDyslexic-LICENSE
cp ../../LICENSE usr/bin/LICENSE


# Make sure to chmod stuff
chmod a+x AppRun usr/bin/inochi-creator

cd ..

ARCH=x86_64 appimagetool.AppImage inochi-creator.AppDir
