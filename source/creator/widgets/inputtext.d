/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets.inputtext;
import creator.widgets;
import creator.core;
import inochi2d;
import bindbc.sdl;
import std.stdio;
import std.string;
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
    /*
    if (buffer.ptr[buffer.length] != '\0') {
        // If buffer.ptr does not end with '\0', recreate string to force '\0' at the end.
        buffer = buffer.ptr[0..buffer.length]~'\0';
    }
    */
    buffer = buffer.toStringz.fromStringz;

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

                // Make sure the buffer doesn't become negatively sized.
                if (data.BufTextLen < 0) data.BufTextLen = 0;

                // Resize and pass buffer ptr in
                (*udata.str).length = data.BufTextLen+1;

                // slice out the null terminator
                data.Buf = cast(char*)(*udata.str).ptr;
                data.Buf[data.BufTextLen] = '\0';
                (*udata.str) = (*udata.str)[0..$-1];
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

                // Make sure the buffer doesn't become negatively sized.
                if (data.BufTextLen < 0) data.BufTextLen = 0;
            
                // Resize and pass buffer ptr in
                (*udata.str).length = data.BufTextLen+1;

                // slice out the null terminator
                data.Buf = cast(char*)(*udata.str).ptr;
                data.Buf[data.BufTextLen] = '\0';
                (*udata.str) = (*udata.str)[0..$-1];
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
bool incInputTextMultiline(string wId, ref string buffer, ImVec2 size, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None) {

    // NOTE: null strings would result in segfault, make sure it's at least just empty.
    if (buffer.ptr is null) {
        buffer = "";
    }
/*
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
*/
    // Create callback data
    TextCallbackUserData cb;
    cb.str = &buffer;

    // Call ImGui's input handling
    if (igInputTextMultiline(
        "###INPUT",
        cast(char*)buffer.ptr, 
        buffer.length+1,
        size,
        flags | ImGuiInputTextFlags.CallbackResize,
        cast(ImGuiInputTextCallback)(ImGuiInputTextCallbackData* data) {
            TextCallbackUserData* udata = cast(TextCallbackUserData*)data.UserData;

            // Allow resizing strings on GC heap
            if (data.EventFlag == ImGuiInputTextFlags.CallbackResize) {

                // Make sure the buffer doesn't become negatively sized.
                if (data.BufTextLen < 0) data.BufTextLen = 0;
            
                // Resize and pass buffer ptr in
                (*udata.str).length = data.BufTextLen+1;

                // slice out the null terminator
                data.Buf = cast(char*)(*udata.str).ptr;
                data.Buf[data.BufTextLen] = '\0';
                (*udata.str) = (*udata.str)[0..$-1];
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