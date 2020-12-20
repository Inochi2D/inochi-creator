/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
import std.stdio;
import creator.appwindow;
import gtk.Main;
import crashdump;

int main(string[] args)
{
    try {
        Main.init(args);
        (new InochiWindow).showAll();
        Main.run();
    } catch(Throwable throwable) {
        crashdump.crashdump(throwable);
        return -1;
    }
    return 0;
}
