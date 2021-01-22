# Inochi Creator
An in-progress rigging application for Inochi2D.
Written in D using GTK, imgui and Inochi2D.

# Why can't I theme this app?
There's some checks in place to ensure that the app does not use any other themes than Adwaita  
This is to prevent breakage due to unsupported theme usage.  
On top of this, widgets in this app are made specifically for Adwaita and can not be styled  
with css.

# Building on Linux
Just run `dub build`

# Building on Windows
To build on Windows you will need to have Visual Studio 2017 installed, we're using `rc.exe` from it to include the icons.

If you do not wish to install Visual Studio 2017 you can build the project with the `winapp-noicon` configuration.