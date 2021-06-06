/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
import std.stdio;
import std.string;
import creator.core;
import creator.core.settings;
import creator.frames;
import creator.windows;
import creator.core.actionstack;
import inochi2d;
import creator;

int main(string[] args)
{
    try {
        incSettingsLoad();
        incInitFrames();
        incActionInit();

        incOpenWindow();
        incNewProject();

        if (incSettingsGet!bool("ShowWarning", true)) {
            incPushWindow(new NoticeWindow());
        }

        while(!incIsCloseRequested()) {

            // Update Inochi2D
            inUpdate();
            incUpdateActiveProject();
            

            // Begin IMGUI loop
            incBeginLoop();
                if (incShouldProcess()) {
                    incHandleShortcuts();
                    incRenderMenu();

                    incUpdateFrames();
                    incUpdateWindows();
                }
            incEndLoop();
        }
        incSettingsSave();
        incFinalize();
        return 0;
    } catch(Exception ex) {
        import std.file : write;
        write("crash.log", ex.msg);
        debug throw ex;
        return -1;
    }
}
