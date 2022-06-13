/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
import std.stdio;
import std.string;
import creator.core;
import creator.core.settings;
import creator.utils.crashdump;
import creator.panels;
import creator.windows;
import creator.widgets;
import creator.core.actionstack;
import creator.core.i18n;
import creator.ext;
import inochi2d;
import creator;
import i18n;

version(D_X32) {
    static assert(0, "😎👉👉 no");
}

version(Windows) {
    debug {

    } else {
        version(InLite) {   
            // Sorry to the programming gods for this crime
            // phobos will crash in lite mode if this isn't here.
        } else {
            version (LDC) {
                pragma(linkerDirective, "/SUBSYSTEM:WINDOWS");
                static if (__VERSION__ >= 2091)
                    pragma(linkerDirective, "/ENTRY:wmainCRTStartup");
                else
                    pragma(linkerDirective, "/ENTRY:mainCRTStartup");
            }
        }
    }
}

int main(string[] args)
{
    try {
        incSettingsLoad();
        incLocaleInit();
        if (incSettingsCanGet("lang")) {
            string lang = incSettingsGet!string("lang");
            auto entry = incLocaleGetEntryFor(lang);
            if (entry !is null) {
                i18nLoadLanguage(entry.file);
            }
        }

        inSetUpdateBounds(true);

        // Initialize Window and Inochi2D
        incInitPanels();
        incActionInit();
        incOpenWindow();

        // Initialize node overrides
        incInitExtNodes();

        // Open or create project
        if (args.length > 1) incOpenProject(args[1]);
        else incNewProject();

        // TODO: Replace with first-time welcome screen
        if (incSettingsGet!bool("ShowWarning", true)) {
            incPushWindow(new NoticeWindow());
        }

        // Update loop
        while(!incIsCloseRequested()) {
            incUpdate();
        }
        incSettingsSave();
        incFinalize();
    } catch(Throwable ex) {
        debug {
            throw ex;
        } else {
            crashdump(ex);
        }
    }
    return 0;
}

/**
    Update
*/
void incUpdate() {

    // Update Inochi2D
    inUpdate();

    // Begin IMGUI loop
    incBeginLoop();
        if (incShouldProcess()) {
            incStatusbar();

            incHandleShortcuts();
            incMainMenu();
            incToolbar();

            incUpdatePanels();
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
    
    // Begin IMGUI loop
    incBeginLoopNoEv();
        if (incShouldProcess()) {
            incStatusbar();

            incHandleShortcuts();
            incMainMenu();
            incToolbar();

            incUpdatePanels();
            incUpdateWindows();
        }
    incEndLoop();
}