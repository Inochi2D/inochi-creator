/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
import std.stdio;
import std.string;
import creator.core;
import creator.frames;
import creator.windows;
import creator.core.actionstack;
import inochi2d;
import creator;

int main(string[] args)
{
    incSettingsLoad();
    incInitFrames();
    incActionInit();

    incOpenWindow();
    incNewProject();

    while(!incIsCloseRequested()) {

        // Update Inochi2D
        inUpdate();
        incUpdateActiveProject();

        // Begin IMGUI loop
        incBeginLoop();
            incRenderMenu();

            incUpdateFrames();
            incUpdateWindows();
        incEndLoop();
    }
    incSettingsSave();
    incFinalize();
    return 0;
}
