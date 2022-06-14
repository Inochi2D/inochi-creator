/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.psdmerge;
import creator.windows;
import creator.core;
import std.string;
import creator.utils.link;
import inochi2d;
import i18n;
import psd;

class PSDMergeWindow : Window {
private:
    PSD document;

protected:

    override
    void onUpdate() {

    }

public:
    ~this() {
        destroy(document);
    }

    this(string path) {
        document = parseDocument(path);
        super(_("PSD Merging"));
    }
}

