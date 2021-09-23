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
import creator.widgets;
import creator.core.actionstack;
import inochi2d;
import creator;

version(D_X32) {
    static assert(0, "😎👉👉 no");
}

int main(string[] args)
{
    incSettingsLoad();
    incInitFrames();
    incActionInit();

    incOpenWindow();
    incNewProject();

    if (incSettingsGet!bool("ShowWarning", true)) {
        incPushWindow(new NoticeWindow());
    }

    while(!incIsCloseRequested()) {
        incUpdate();
    }
    incSettingsSave();
    incFinalize();
    return 0;
}

/**
    Update
*/
void incUpdate() {

    // Update Inochi2D
    inUpdate();
    incUpdateActiveProject();
    

    // Begin IMGUI loop
    incBeginLoop();
        if (incShouldProcess()) {
            if (!incGetUseNativeTitlebar()) {
                incTitlebar();
            }
            incStatusbar();

            incHandleShortcuts();
            incMainMenu();
            incToolbar();

            incUpdateFrames();
            incUpdateWindows();
        }
    incEndLoop();
}

/**
    Update without any event polling
*/
void incUpdateNoEv() {

    // Update Inochi2D
    inUpdate();
    incUpdateActiveProject();
    

    // Begin IMGUI loop
    incBeginLoopNoEv();
        if (incShouldProcess()) {
            if (!incGetUseNativeTitlebar()) {
                incTitlebar();
            }
            incStatusbar();

            incHandleShortcuts();
            incMainMenu();
            incToolbar();

            incUpdateFrames();
            incUpdateWindows();
        }
    incEndLoop();
}