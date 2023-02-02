/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.utils.link;
import std.process;

/**
    Opens a link with the user's preferred webbrowser
*/
void incOpenLink(string link) {
    version(Windows) {
        spawnShell("start " ~ escapeShellCommand("", link));
    } else version(OSX) {
        spawnShell("open " ~ escapeShellCommand(link));
    } else version(Posix) {
        spawnShell("xdg-open " ~ escapeShellCommand(link));
    }
}