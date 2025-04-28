/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Author: Luna Nielsen
*/
module creator.viewport.common.utils;
import i2d.imgui;

/**
    Returns the given color with the alpha channel modified.
*/
ImVec4 setAlpha(inout(ImVec4)* in_, float alpha) {
    ImVec4 out_ = *in_;
    out_.w = alpha;
    return out_;
}