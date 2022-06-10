# Inochi Creator
![image](https://user-images.githubusercontent.com/7032834/170948484-2f3a8175-9c45-4cf6-ae7e-0a6ee86bdc53.png)
_Ada model by [ku-ini](https://twitter.com/duckmastah)_

&nbsp;
&nbsp;

[![Support me on Patreon](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fshieldsio-patreon.vercel.app%2Fapi%3Fusername%3Dclipsey%26type%3Dpatrons&style=for-the-badge)](https://patreon.com/clipsey)
[![Join the Discord](https://img.shields.io/discord/855173611409506334?label=Community&logo=discord&logoColor=FFFFFF&style=for-the-badge)](https://discord.com/invite/abnxwN6r9v)

Inochi Creator is tool to create and edit [Inochi2D puppets](https://github.com/Inochi2D/inochi2d).

## For package maintainers
We do not officially support packages that we don't officially build ourselves, we ask that you build using the barebones configurations, as the branding assets are copyright the Inochi2D Project.  
You may request permission to use our branding assets in your package by submitting an issue.

Barebones builds are more or less equivalent to official builds with the exception that branding is removed,  
and that we don't accept support tickets unless a problem can be replicated on an official build.

## What package formats are/will be officially supported?
Anything we upload to the Releases page is officially supported, as well as anything that is linked to on our official website (TBA).  
We currently plan to distribute Inochi Creator in the following formats:
 - Windows MSI Installer
 - Linux AppImage
 - macOS DMG

## Under Construction
Inochi Creator is currently under construction and is not recommended for production use.

## Intel Integrated Graphics
Inochi Creator currently crashes on Intel Integrated Graphics. I unfortunately do not have the means to debug and fix this issue right now, sorry.

## Building
It's occasionally the case that our dependencies are out of sync with dub, so it's somewhat recommended if you're building from source to clone the tip of `main` and `dub add-local . "<version matching inochi-creator dep>"` any of our forked dependencies (i18n-d, psd-d, bindbc-imgui, facetrack-d, inmath, inochi2d). This will generally keep you up to date with what we're doing, and it's how the primary contributors work. Ideally we'd have a script to help set this up, but currently we do it manually, PRs welcome :)

Because our project has dependencies on C++ through bindbc-imgui, and because there's no common way to get imgui binaries across platforms, we require a C++ toolchain as well as a few extra dependencies installed. These will be listed in their respective platform sections below.  
Currently you **have** to _recursively_ clone bindbc-imgui from git and set its version to `0.7.0`, otherwise the build will fail.

Once the below dependencies are met, building and running inochi-creator should be as simple as calling `dub` within this repo.

### Windows
#### Dependencies
- Visual Studio 2022 (With "Desktop development with C++" workflow installed)
  - In theory, "Build Tools for Visual Studio 2022" should also work, but is untested.
- CMake (Currently 3.16 or higher is needed.)
- Dlang, either dmd or ldc

### Linux
#### Dependencies
- The equivalent of build-essential on Ubuntu, on centos 7, this was `sudo yum groupinstall 'Development Tools'`, this should get you a working C++ toolchain.
- Dlang, either dmd or ldc
- CMake (Currently 3.16 or higher is needed.)
- SDL2 (developer package)
- Freetype (developer package)
- appimagetool (for building an AppImage)

## Building an AppImage (Experimental)
The AppImages we're currently experimenatlly distributing are generated on CentOS 7, and have only been tested (for creation) there. Eventually we'll containerize this environment somehow and set up GitHub Actions to generate releases

In the meantime, if you've got the project built on your Linux environment, simply run `./BuildAppImage.sh` to build it, it should generate a `build` directory, and a `inochi-creator-x86_64.AppImage` file within it. 

Currently we're not set up for Arm builds (or 32 bit builds), but down the line we plan to improve the tooling for easily building an creating images for all of our targets. 

Obviously the existing caveats with AppImages still exist when generating them on newer environments, or ones without for example Freetype and SDL install. We're looking at improving our story in this regard as well, but these are just some of the reasons why it's still Experimental.

### CentOS 7 Env Setup:
This is roughly what we did to set up our CentOS 7 env for building/creating an AppImage. Thanks go to @grillo-delmal for helping us with this!

```bash
# Install our deps
yum -y groupinstall 'Development Tools'
yum -y install epel-release
yum -y install SDL2-devel.x86_64
yum -y install freetype-devel.x86_64
yum -y install cmake3
ln -s /usr/bin/cmake3 /usr/bin/cmake

# Install llvm
yum -y install centos-release-scl
yum -y install llvm-toolset-7.0
yum -y install llvm-toolset-7.0-llvm-devel
yum -y install llvm-toolset-7.0-llvm-static

# Install an older LDC that we can't use for inochi-creator, since LDC needs a D compiler to build.
mkdir -p ~/dlang && curl -L https://dlang.org/install.sh -o ~/dlang/install.sh
bash ~/dlang/install.sh ldc-1.24.0
source ~/dlang/ldc-1.24.0/activate

# Finally, clone and build a recent LDC
curl -L https://github.com/ldc-developers/ldc/releases/download/v1.29.0/ldc-1.29.0-src.tar.gz -o ldc-1.29.0-src.tar.gz
tar -xzf ldc-1.29.0-src.tar.gz
pushd ldc-1.29.0-src

mkdir build
pushd build

scl enable llvm-toolset-7.0 'cmake -S ..'
# Maybe should do `make -j8` or whatever here. Maybe we should depend on ninja...
scl enable llvm-toolset-7.0 'make'
scl enable llvm-toolset-7.0 'make install'

popd
popd
deactivate

# Navigate to inochi-creator dir and build
scl enable llvm-toolset-7.0 dub
```
