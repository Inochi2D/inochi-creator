/*
    Copyright © 2020-2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors:
        Luna Nielsen
        Lin, Yong Xiang <r888800009@gmail.com>
*/

module creator.io.save;
import creator.windows;
import creator.widgets.dialog;
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

/**
    Handle exit with save ask
    NOTE: it is only called by UI, not by code
*/
void incExitSaveAsk() {
    ExitAskHandler handler = new ExitAskHandler();
    incCloseProjectAsk(handler);
}

class ExitAskHandler : CloseAskHandler {
    override
    void onProjectClose() {
        incExit();
    }
}

void incCloseProjectAsk(CloseAskHandler handler) {
    if (!incIsProjectModified()) {
        handler.onClickNo();
        return;
    }

    switch (incGetSaveProjectOnClose()) {
        case "dontSave":
            handler.onClickNo();
            return;
        case "Save":
            // maybe should not have "Save" option prevent users stuck when exit
            handler.onClickYes();
            return;
        case "Ask":
            handler.register();
            handler.show();
            return;
        default:
            throw new Exception("Invalid save project on close setting");
            return;
    }
}

class CloseAskHandler : DialogHandler {
    const(char)* INC_EXIT_ASK_DIALOG_NAME = "CloseAskDialog";

    this () {
        super(INC_EXIT_ASK_DIALOG_NAME);
    }

    override
    bool onClickYes() {
        if (incFileSave()) this.onProjectClose();
        return true;
    }

    override
    bool onClickNo() {
        this.onProjectClose();
        return true;
    }

    void onProjectClose() {
        // override
    }

    void show() {
        incDialog(
            INC_EXIT_ASK_DIALOG_NAME,
            __("Save changes before close?"),
            _("Would you like to save your changes before closing?\n\nYou can change the default behaviour in the settings."),
            DialogLevel.Info,
            DialogButtons.Yes | DialogButtons.No | DialogButtons.Cancel
        );
    }
}
