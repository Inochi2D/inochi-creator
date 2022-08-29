/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.io;
public import creator.io.psd;
public import creator.io.inpexport;

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

string incShowSaveDialog(TFD_Filter[] filters, string fname) {
    c_str filename = tinyfd_saveFileDialog(__("Save..."), fname.toStringz, filters);
    if (filename !is null) {
        string file = cast(string)filename.fromStringz;
        return file;
    }
    return null;
}