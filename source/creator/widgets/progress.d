/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets.progress;
import creator.widgets;
import inochi2d.math;

//
//  BORROWED AND MODIFIED FROM
//  https://github.com/ocornut/imgui/issues/1901
//

bool incBufferBar(string label, float value, ImVec2 size, ImU32 bgColor, ImU32 fgColor) {
    ImGuiWindow* window = igGetCurrentWindow();
    if (window.SkipItems) return false;

    ImVec2 avail;
    igGetContentRegionAvail(&avail);
    if (size.x <= 0) size.x = avail.x-size.x;
    if (size.y == 0) size.y = 64;

    value = clamp(value, 0, 1);
    

    ImGuiContext* ctx = igGetCurrentContext();
    ImGuiStyle style = ctx.Style;
    ImGuiID id = ImGuiWindow_GetID_Str(window, label.ptr, label.ptr+label.length);

    ImVec2 pos = window.DC.CursorPos;
    size.x -= style.FramePadding.x*2;

    ImRect bb = ImRect(ImVec2(pos.x, pos.y+((size.y/2)-2)), ImVec2(pos.x+size.x, pos.y+((size.y/2)+2)));
    ImRect obb = ImRect(pos, ImVec2(pos.x+size.x, pos.y+size.y));
    igItemSize_Rect(obb, style.FramePadding.y);
    if (!igItemAdd(obb, id, null))
        return false;
    
    float circleStart = size.x; // * 0.7f;
    float circleEnd = size.x;
    float circleWidth = circleEnd-circleStart;

    ImDrawList_AddRectFilled(igGetWindowDrawList(), bb.Min, ImVec2(pos.x + circleStart, bb.Max.y), bgColor, 8, ImDrawFlags.RoundCornersAll);
    ImDrawList_AddRectFilled(igGetWindowDrawList(), bb.Min, ImVec2(pos.x + circleStart*value, bb.Max.y), fgColor, 8, ImDrawFlags.RoundCornersAll);
    
    
    igNewLine();
    return false;
}

/**
    Creates a spinner
*/
bool incSpinner(string label, float radius, int thickness, ImU32 color) {
    ImGuiWindow* window = igGetCurrentWindow();
    if (window.SkipItems) return false;

    // If radius less or equal to 0 is passed do normal imgui behaviour
    ImVec2 avail;
    igGetContentRegionAvail(&avail);
    if (radius <= 0) radius = (min(avail.x, avail.y)/2) - radius;


    ImGuiContext* ctx = igGetCurrentContext();
    ImGuiStyle style = ctx.Style;
    ImGuiID id = ImGuiWindow_GetID_Str(window, label.ptr, label.ptr+label.length);

    ImVec2 pos = ImVec2(window.DC.CursorPos.x, window.DC.CursorPos.y);
    ImVec2 size = ImVec2((radius*2), ((radius+style.FramePadding.y)*2));
    ImRect bb = ImRect(pos, ImVec2(pos.x+size.x, pos.y+size.y));
    igItemSize_Rect(bb, style.FramePadding.y);
    if (!igItemAdd(bb, id))
        return false;

    // Render
    ImDrawList_PathClear(igGetWindowDrawList());

    enum SEGMENTS = 45;
    float start = abs(sin(ctx.Time*1.4f)*(SEGMENTS-5));

    const float aMin = PI*2 * (cast(float)start / cast(float)SEGMENTS);
    const float aMax = PI*2 * ((cast(float)SEGMENTS-3) / cast(float)SEGMENTS);

    ImVec2 center = ImVec2(pos.x+radius, pos.y+radius+style.FramePadding.y);

    for (int i = 0; i < SEGMENTS; i++) {
        const float a = aMin + (cast(float)i / cast(float)SEGMENTS) * (aMax-aMin);
        ImDrawList_PathLineTo(igGetWindowDrawList(), ImVec2(
            center.x + cos(a+ctx.Time*8) * (radius-thickness),
            center.y + sin(a+ctx.Time*8) * (radius-thickness)
        ));
    }

    ImDrawList_PathStroke(igGetWindowDrawList(), color, ImDrawFlags.None, thickness);
    igNewLine();
    return false;
}