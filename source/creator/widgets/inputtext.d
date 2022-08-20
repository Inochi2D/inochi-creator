/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets.inputtext;
import creator.widgets;
import creator.core;
import inochi2d;
import bindbc.sdl;
import std.stdio;
import core.memory : GC;

private {

    struct TextCallbackUserData {
        string* str;
    }
}

/**
    D compatible text input
*/
bool incInputText(string wId, ref string buffer, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None) {
    auto available = incAvailableSpace();
    return incInputText(wId, available.x, buffer, flags);
}

/**
    D compatible text input
*/
bool incInputText(string wId, float width, ref string buffer, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None) {

    // NOTE: null strings would result in segfault, make sure it's at least just empty.
    if (buffer.ptr is null) {
        buffer = "";
    }

    // Push ID
    auto id = igGetID(wId.ptr, wId.ptr+wId.length);
    igPushID(id);
    scope(exit) igPopID();

    // Set desired width
    igPushItemWidth(width);
    scope(success) igPopItemWidth();

    // Create callback data
    TextCallbackUserData cb;
    cb.str = &buffer;

    // Call ImGui's input handling
    if (igInputText(
        "###INPUT",
        cast(char*)buffer.ptr, 
        buffer.length+1,
        flags | ImGuiInputTextFlags.CallbackResize,
        cast(ImGuiInputTextCallback)(ImGuiInputTextCallbackData* data) {
            TextCallbackUserData* udata = cast(TextCallbackUserData*)data.UserData;

            // Allow resizing strings on GC heap
            if (data.EventFlag == ImGuiInputTextFlags.CallbackResize) {
            
                // Resize and pass buffer ptr in
                (*udata.str).length = data.BufTextLen;
                data.Buf = cast(char*)(*udata.str).ptr;
            }
            return 0;
        },
        &cb
    )) {
        return true;
    }

    ImVec2 min, max;
    igGetItemRectMin(&min);
    igGetItemRectMax(&max);

    auto rect = SDL_Rect(
        cast(int)min.x+32, 
        cast(int)min.y, 
        cast(int)max.x, 
        32
    );

    SDL_SetTextInputRect(&rect);
    return false;
}
/**
    D compatible text input
*/
bool incInputText(string wId, string label, ref string buffer, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None) {
    auto available = incAvailableSpace();
    return incInputText(wId, label, available.x, buffer, flags);
}

/**
    D compatible text input
*/
bool incInputText(string wId, string label, float width, ref string buffer, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None) {

    // NOTE: null strings would result in segfault, make sure it's at least just empty.
    if (buffer.ptr is null) {
        buffer = "";
    }

    // Push ID
    auto id = igGetID(wId.ptr, wId.ptr+wId.length);
    igPushID(id);
    scope(exit) igPopID();

    // Set desired width
    igPushItemWidth(width);
    scope(success) igPopItemWidth();

    // Render label
    scope(success) {
        igSameLine(0, igGetStyle().ItemSpacing.x);
        igTextEx(label.ptr, label.ptr+label.length);
    }

    // Create callback data
    TextCallbackUserData cb;
    cb.str = &buffer;

    // Call ImGui's input handling
    if (igInputText(
        "###INPUT",
        cast(char*)buffer.ptr, 
        buffer.length+1,
        flags | ImGuiInputTextFlags.CallbackResize,
        cast(ImGuiInputTextCallback)(ImGuiInputTextCallbackData* data) {
            TextCallbackUserData* udata = cast(TextCallbackUserData*)data.UserData;

            // Allow resizing strings on GC heap
            if (data.EventFlag == ImGuiInputTextFlags.CallbackResize) {
            
                // Resize and pass buffer ptr in
                (*udata.str).length = data.BufTextLen;
                data.Buf = cast(char*)(*udata.str).ptr;
            }
            return 0;
        },
        &cb
    )) {
        return true;
    }

    ImVec2 min, max;
    igGetItemRectMin(&min);
    igGetItemRectMax(&max);

    auto rect = SDL_Rect(
        cast(int)min.x+32, 
        cast(int)min.y, 
        cast(int)max.x, 
        32
    );

    SDL_SetTextInputRect(&rect);
    return false;
}