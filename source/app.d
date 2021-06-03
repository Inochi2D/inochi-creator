/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
import std.stdio;
import std.string;
import creator.core;

int main(string[] args)
{

    incOpenWindow();
    while(!incIsCloseRequested()) {
        incBeginLoop();

        incEndLoop();
    }
    incFinalize();
    return 0;
}
