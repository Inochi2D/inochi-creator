/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
import std.stdio;
import creator.app;
import gtk.Main;
import crashdump;

int main(string[] args)
{
    try {
        Main.init(args);
        (new InochiCreator).showAll();
        Main.run();
    } catch(Throwable throwable) {
        crashdump.crashdump(throwable, args);
        return -1;
    }
    return 0;
}
