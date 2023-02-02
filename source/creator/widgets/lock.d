/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets.lock;
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
        igPushItemWidth(16);
            incText(((*val ? "\uE897" : "\uE898")));
            
            if ((clicked = igIsItemClicked(ImGuiMouseButton.Left)) == true) {
                *val = !*val;
            }
            
        igPopItemWidth();
    igPopID();
    return clicked;
}