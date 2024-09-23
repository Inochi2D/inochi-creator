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

void incFileNew() {
    incNewProject();
}

void incFileOpen() {
    const TFD_Filter[] filters = [
        { ["*.inx"], "Inochi Creator Project (*.inx)" }
    ];

    string file = incShowOpenDialog(filters, _("Open..."));
    if (file) incOpenProject(file);
}

void incFileSave() {
    incPopWelcomeWindow();

    // If a projeect path is set then the user has opened or saved
    // an existing file, we should just override that
    if (incProjectPath.length > 0) {
        // TODO: do backups on every save?

        incSaveProject(incProjectPath);
    } else {
        const TFD_Filter[] filters = [
            { ["*.inx"], "Inochi Creator Project (*.inx)" }
        ];

        string file = incShowSaveDialog(filters, "", _("Save..."));
        if (file) incSaveProject(file);
    }
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