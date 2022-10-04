/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets.button;
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

bool incDropdownButtonIcon(string idStr, string icon, ImVec2 size = ImVec2(-1, -1), bool open=false) {
    
    // Early escape to incDropdownButton if no icon is set
    if (icon.length == 0) return incDropdownButton(idStr, size, open);

    // Otherwise we begin our special code path
    auto ctx = igGetCurrentContext();
    auto window = igGetCurrentWindow();
    auto style = igGetStyle();

    if (window.SkipItems)
        return false;
    
    // Should always appear on same line
    igSameLine(0, 0);
    ImVec2 isize = incMeasureString(icon);

    const(float) default_size = igGetFrameHeight();
    if (size.x <= 0) size.x = isize.x+28;
    if (size.y <= 0) size.y = default_size;

    auto id = igGetID(idStr.ptr, idStr.ptr+idStr.length);
    const(ImRect) bb = {
        window.DC.CursorPos,
        ImVec2(window.DC.CursorPos.x + size.x, window.DC.CursorPos.y + size.y)
    };

    igItemSize(size, (size.y >= default_size) ? ctx.Style.FramePadding.y : -1.0f);
    if (!igItemAdd(bb, id))
        return false;

    bool hovered, held;
    bool pressed = igButtonBehavior(bb, id, &hovered, &held, ImGuiButtonFlags.None);

    // Render
    const ImU32 bgCol = igGetColorU32(
        ((held && hovered) || open) ? style.Colors[ImGuiCol.ButtonActive] : hovered ? 
            style.Colors[ImGuiCol.ButtonHovered] : 
            style.Colors[ImGuiCol.Button]);
    igRenderNavHighlight(bb, id);
    igRenderFrame(bb.Min, bb.Max, bgCol, true, ctx.Style.FrameRounding);
    string s = "";
    ImVec2 ssize = incMeasureString(s);
    
    igRenderText(ImVec2(
        bb.Min.x + max(0.0f, 4), 
        bb.Min.y + max(0.0f, (size.y - isize.y) * 0.5f)
    ), icon.ptr, icon.ptr+icon.length, true);
    
    igRenderText(ImVec2(
        bb.Min.x + max(0.0f, (size.x - (ssize.x+2))), 
        bb.Min.y + max(0.0f, (size.y - ssize.y) * 0.5f)
    ), s.ptr, s.ptr+s.length, true);
    return pressed;
}

bool incDropdownButton(string idStr, ImVec2 size = ImVec2(-1, -1), bool open=false) {
    auto ctx = igGetCurrentContext();
    auto window = igGetCurrentWindow();
    auto style = igGetStyle();

    if (window.SkipItems)
        return false;
    
    // Should always appear on same line
    igSameLine(0, 0);

    const(float) default_size = igGetFrameHeight();
    if (size.x <= 0) size.x = 16;
    if (size.y <= 0) size.y = default_size;

    auto id = igGetID(idStr.ptr, idStr.ptr+idStr.length);
    const(ImRect) bb = {
        window.DC.CursorPos,
        ImVec2(window.DC.CursorPos.x + size.x, window.DC.CursorPos.y + size.y)
    };

    igItemSize(size, (size.y >= default_size) ? ctx.Style.FramePadding.y : -1.0f);
    if (!igItemAdd(bb, id))
        return false;

    bool hovered, held;
    bool pressed = igButtonBehavior(bb, id, &hovered, &held, ImGuiButtonFlags.None);

    // Render
    const ImU32 bgCol = igGetColorU32(
        ((held && hovered) || open) ? style.Colors[ImGuiCol.ButtonActive] : hovered ? 
            style.Colors[ImGuiCol.ButtonHovered] : 
            style.Colors[ImGuiCol.Button]);
    igRenderNavHighlight(bb, id);
    igRenderFrame(bb.Min, bb.Max, bgCol, true, ctx.Style.FrameRounding);
    const(string) s = "";
    ImVec2 ssize = incMeasureString(s);

    igRenderText(ImVec2(
        bb.Min.x + max(0.0f, (size.x - ssize.x) * 0.5f), 
        bb.Min.y + max(0.0f, (size.y - ssize.y) * 0.5f)
    ), s.ptr, s.ptr+s.length, true);
    return pressed;
}

private {
    struct DropDownMenuData {
        bool wasOpen;
        ImVec2 winSize;
    }
}

bool incBeginDropdownMenu(string idStr, string icon="") {
    auto storage = igGetStateStorage();
    auto window = igGetCurrentWindow();
    auto id = igGetID(idStr.ptr, idStr.ptr+idStr.length);

    igPushID(id);
    DropDownMenuData* menuData = cast(DropDownMenuData*)ImGuiStorage_GetVoidPtr(storage, igGetID("WAS_OPEN"));
    if (!menuData) {
        menuData = cast(DropDownMenuData*)igMemAlloc(DropDownMenuData.sizeof);
        ImGuiStorage_SetVoidPtr(storage, igGetID("WAS_OPEN"), menuData);
    }

    // Dropdown button itself
    auto pressed = incDropdownButtonIcon("DROPDOWN_BTN", icon, ImVec2(-1, -1), menuData.wasOpen);
    if (igIsPopupOpen("DROPDOWN_CONTENT") && pressed) igClosePopupsOverWindow(window, true);
    else if (pressed) igOpenPopup("DROPDOWN_CONTENT", ImGuiPopupFlags.MouseButtonLeft | ImGuiPopupFlags.NoOpenOverItems);

    ImVec2 pos;
    igGetCursorScreenPos(&pos);

    // Clamp to outer window
    if (window) pos.x = clamp(pos.x, window.OuterRectClipped.Max.x, window.OuterRectClipped.Min.x-192);

    // Dropdown menu
    igSetNextWindowSizeConstraints(ImVec2(192, 0), ImVec2(192, float.max));
    igSetNextWindowPos(ImVec2(pos.x, pos.y+4), ImGuiCond.Always, ImVec2(0, 0));
    menuData.wasOpen = igBeginPopup("DROPDOWN_CONTENT");
    if (!menuData.wasOpen) igPopID();
    else {
        menuData.winSize = igGetCurrentWindow().Size;
    }
    return menuData.wasOpen;
}

void incEndDropdownMenu() {
    igEndPopup();
    igPopID();
}