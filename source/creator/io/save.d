/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/

module creator.io.save;
import creator.windows;
import creator.core;
import creator;

import tinyfiledialogs;
import i18n;

void incFileOpen() {
    const TFD_Filter[] filters = [
        { ["*.inx"], "Inochi Creator Project (*.inx)" }
    ];

    string file = incShowOpenDialog(filters, _("Open..."));
    if (file) incOpenProject(file);
}

bool incFileSave() {
    incPopWelcomeWindow();

    // If a projeect path is set then the user has opened or saved
    // an existing file, we should just override that
    if (incProjectPath.length > 0) {
        // TODO: do backups on every save?

        incSaveProject(incProjectPath);
        return true;
    } else {
        const TFD_Filter[] filters = [
            { ["*.inx"], "Inochi Creator Project (*.inx)" }
        ];

        string file = incShowSaveDialog(filters, "", _("Save..."));
        if (file) {
            incSaveProject(file);
            return true;
        }
    }
    return false;
}

void incFileSaveAs() {
    incPopWelcomeWindow();
    const TFD_Filter[] filters = [
        { ["*.inx"], "Inochi Creator Project (*.inx)" }
    ];

    string fname = incProjectPath().length > 0 ? incProjectPath : "";
    string file = incShowSaveDialog(filters, fname, _("Save As..."));
    if (file) incSaveProject(file);
}

string incGetSaveProjectOnClose() {
    auto config = incSettingsGet!string("SaveProjectOnClose", "Ask");

    // validate config
    import std.algorithm : canFind;
    auto keys = incGetSaveProjectOption().keys();
    if (keys.canFind(config) == false) {
        config = "Ask";
        incSetSaveProjectOnClose(config);
    }
    return config;
}

string[string] incGetSaveProjectOption() {
    string[string] options = [
        "Ask": _("Always ask"),
        "dontSave": _("Don't save"),
        // maybe should not have "Save" option prevent users stuck when exit
        // "Save": _("Save")
    ];
    return options;
}


void incSetSaveProjectOnClose(string select) {
    incSettingsSet("SaveProjectOnClose", select);
}

/**
    Handle New Project with save ask
    NOTE: it is only called by UI, not by code
*/
void incNewProjectAsk() {
    auto handler = new NewProjectAskHandler();
    incCloseProjectAsk(handler);
}

class NewProjectAskHandler : CloseAskHandler {
    override
    void onProjectClose() {
        incNewProject();
    }
}
