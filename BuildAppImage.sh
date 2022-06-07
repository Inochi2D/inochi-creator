mkdir build
cd build

mkdir inochi-creator.AppDir
cd inochi-creator.AppDir
mkdir usr
mkdir usr/bin
cp ../../out/inochi-creator usr/bin/inochi-creator
cp ../../res/logo_256.png logo_256.png
cp ../../res/inochi-creator.desktop inochi-creator.desktop
cd ..

appimagetool.AppImage inochi-creator.AppDir