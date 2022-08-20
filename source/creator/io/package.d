/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.io;
public import creator.io.psd;

import tinyfiledialogs;
public import tinyfiledialogs : TFD_Filter;
import std.string;
import i18n;

string incShowImportDialog(TFD_Filter[] filters) {
    c_str filename = tinyfd_openFileDialog(__("Import..."), "", filters, false);
    if (filename !is null) {
        string file = cast(string)filename.fromStringz;
        return file;
    }
    return null;
}

string incShowOpenDialog() {
    TFD_Filter[] filters = [
        {["*.inx"], "Inochi Creator Project"}
    ];

    c_str filename = tinyfd_openFileDialog(__("Open..."), "", filters, false);
    if (filename !is null) {
        string file = cast(string)filename.fromStringz;
        return file;
    }
    return null;
}