/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets.dummy;
import creator.widgets;
import std.math : abs;

/**
    More advanced dummy widget
*/
void incDummy(ImVec2 size) {
    ImVec2 avail = incAvailableSpace();
    if (size.x <= 0) size.x = avail.x - abs(size.x);
    if (size.y <= 0) size.y = avail.y - abs(size.y);
    igDummy(size);
}

/**
    A same-line spacer
*/
void incSpacer(ImVec2 size) {
    igSameLine(0, 0);
    incDummy(size);
}

/**
    Gets available space
*/
ImVec2 incAvailableSpace() {
    ImVec2 avail;
    igGetContentRegionAvail(&avail);
    return avail;
}

/**
    Measures a string in pixels
*/
ImVec2 incMeasureString(string text) {
    ImVec2 strLen;
    igCalcTextSize(&strLen, text.ptr, text.ptr+text.length);
    return strLen;
}