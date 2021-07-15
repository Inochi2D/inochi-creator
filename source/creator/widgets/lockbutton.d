/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets.lockbutton;
import creator.widgets;
import creator.core;
import std.string;

/**
    A lock button
*/
bool incLockButton(bool* val, string origin) {
    bool clicked = false;

    igSameLine(0, 0);
    igPushID(origin.ptr);
        igPushFont(incIconFont());
            igPushItemWidth(16);
                igText(((*val ? "\uE897" : "\uE898")).toStringz);
                
                if ((clicked = igIsItemClicked(ImGuiMouseButton.Left)) == true) {
                    *val = !*val;
                }
                
            igPopItemWidth();
        igPopFont();
    igPopID();
    return clicked;
}