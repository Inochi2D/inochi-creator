mkdir build
cd build

mkdir inochi-creator.AppDir
cd inochi-creator.AppDir
mkdir usr
mkdir usr/bin
cp ../../out/inochi-creator usr/bin/inochi-creator
cp ../../res/logo_256.png logo_256.png
cp ../../res/inochi-creator.desktop inochi-creator.desktop
cp ../../res/AppRun AppRun
cp ../../res/NotoSansCJK-Regular-LICENSE usr/bin/NotoSansCJK-Regular-LICENSE
cp ../../res/MaterialIcons-LICENSE usr/bin/MaterialIcons-LICENSE
cp ../../res/OpenDyslexic-LICENSE usr/bin/AppRun
cp ../../LICENSE usr/bin/LICENSE

cd ..

ARCH=x86_64 appimagetool.AppImage inochi-creator.AppDir