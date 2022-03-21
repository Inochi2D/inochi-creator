/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets.colorbutton;
import creator.widgets;
import creator.core;
import inochi2d;
import std.math : isFinite;
import std.string;

bool incButtonColored(const(char)* text, const ImVec2 size, const ImVec4 textColor = ImVec4(float.nan, float.nan, float.nan, float.nan)) {
    if (!isFinite(textColor.x) || !isFinite(textColor.y) || !isFinite(textColor.z) || !isFinite(textColor.w)) {
        return igButton(text, size);
    }

    igPushStyleColor(ImGuiCol.Text, textColor);
    scope(exit) igPopStyleColor();

    return igButton(text, size);
}