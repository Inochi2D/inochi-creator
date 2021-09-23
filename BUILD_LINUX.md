# Inochi Creator - Linux Build Instructions

**NOTE:** These instructions are preliminary and for an in-development version of Inochi Creator.

## Prerequisites

 * cmake
 * dub
 * ldc or dmd
 * make
 * g++ and gcc (for the cimgui library)

## Building

For the sake of this documentation, assume we are working in a directory called `inochi` as our root.

First, clone all the needed repositories:
```
$ git clone --recursive https://github.com/Inochi2D/bindbc-imgui
...
$ git clone https://github.com/Inochi2D/inochi2d
...
$ git clone https://github.com/Inochi2D/psd-d
...
$ git clone https://github.com/Inochi2D/inochi-creator
...
```

Now that we have all the repositories cloned, we need to build the `bindbc-imgui` deps.

First change directory into `bindbc-imgui/deps` and create a new build directory:
```
$ cd ./bindbc-imgui/deps
$ mkdir build
$ cd build
```

Now, configure and run the build:
```
$ cmake ..
$ make
```

Once that is done, we can now setup the dub packages. To do so, cd back to the root and run `dub add-local . "1.0.0"` in the `bindbc-imgui`, `inochi2d`, and `psd-d` directories, like so:
```
$ cd bindbc-imgui
$ dub add-local . "1.0.0"
$ cd ../inochi2d
$ dub add-local . "1.0.0"
$ cd ../psd-d
$ dub add-local . "1.0.0"
```

Now, in the `inochi-creator` directory, create an `out` directory and copy the `cimgui.so` and the `libSDL2-2.0.so.1` libraries into it:
```
$ cd inochi-creator
$ mkdir out
$ cp ../bindbc-imgui/deps/build/cimgui/cimgui.so ./out/cimgui.so
$ cp ../bindbc-imgui/lib/libSDL2-2.0.so.1 ./out/libSDL2-2.0.so.1 
```

You should now be able to run `dub` and have `inochi-creator` build and run.
