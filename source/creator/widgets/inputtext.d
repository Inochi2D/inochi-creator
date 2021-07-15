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
    struct Str {
        string str;
    }
}

/**
    D compatible text input
*/
bool incInputText(const(char)* label, ref string buffer, ImGuiInputTextFlags flags = ImGuiInputTextFlags.None) {
    auto id = igGetID(label);
    auto storage = igGetStateStorage();

    // We put a new string container on the heap and make sure the GC doesn't yeet it.
    if (ImGuiStorage_GetVoidPtr(storage, id) is null) {
        Str* cursedString = new Str(buffer~"\0");
        GC.addRoot(cursedString);
        ImGuiStorage_SetVoidPtr(storage, id, cursedString);
    }

    // We get it
    Str* str = cast(Str*)ImGuiStorage_GetVoidPtr(storage, id);

    if (igInputText(
        label, 
        cast(char*)str.str.ptr, 
        str.str.length,
        flags | 
            ImGuiInputTextFlags.CallbackResize |
            ImGuiInputTextFlags.EnterReturnsTrue,
        cast(ImGuiInputTextCallback)(ImGuiInputTextCallbackData* data) {

            // Allow resizing strings on GC heap
            if (data.EventFlag == ImGuiInputTextFlags.CallbackResize) {
                Str* str = (cast(Str*)data.UserData);
                str.str ~= "\0";
                str.str.length = data.BufTextLen;
            }
            return 1;
        },
        str
    )) {

        // Apply string, without null terminator
        buffer = str.str;
        GC.removeRoot(ImGuiStorage_GetVoidPtr(storage, id));
        ImGuiStorage_SetVoidPtr(storage, id, null);
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

// /**
//     D compatible text input
// */
// bool incInputTextEx(const(char)* label, ref string buffer, ImGuiInputTextFlags flags, uint limit) {
//     limit = clamp(limit, 1, uint.max);
//     return igInputText(
//         label, 
//         cast(char*)(buffer).ptr, 
//         clamp(buffer.length, 0, limit),
//         flags | 
//             ImGuiInputTextFlags.CallbackResize |
//             ImGuiInputTextFlags.EnterReturnsTrue,
//         cast(ImGuiInputTextCallback)(ImGuiInputTextCallbackData* data) {
//             if (data.EventFlag == ImGuiInputTextFlags.CallbackCompletion) {

//             }
//             if (data.EventFlag == ImGuiInputTextFlags.CallbackResize) {
//                 string* str = (cast(string*)data.UserData);
//                 str.length = data.BufTextLen;
//                 (*str) ~= "\0";
//             }
//             return 1;
//         },
//         &buffer
//     );
// }