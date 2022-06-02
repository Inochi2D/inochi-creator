module creator.core.input;
import creator.core;
import inochi2d.core;
import inochi2d.math;
import bindbc.imgui;
import bindbc.sdl;
import std.algorithm;

private {
    vec2 mpos;
    ImGuiIO* io;
}

/**
    Begins a UI input pass
*/
void incInputPoll() {
    io = igGetIO();
}

/**
    Sets the mouse within the viewport
*/
void incInputSetViewportMouse(float x, float y) {
    vec2 camPos = inGetCamera().position;
    vec2 camScale = inGetCamera().scale;
    vec2 camCenter = inGetCamera().getCenterOffset();

    mpos = (
        mat4.translation(
            camPos.x+camCenter.x, 
            camPos.y+camCenter.y, 
            0
        ) * 
        mat4.scaling(
            camScale.x, 
            camScale.y, 
            1
        ).inverse() *
        mat4.translation(
            x, 
            y, 
            0
        ) *
        vec4(0, 0, 0, 1)
    ).xy;
}

/**
    Gets the position of the mouse in the viewport
*/
vec2 incInputGetMousePosition() {
    return mpos;
}

/**
    Gets whether a mouse button is down
*/
bool incInputIsMouseDown(int idx) {
    return io.MouseDown[idx];
}

/**
    Gets whether a mouse button is down
*/
bool incInputIsMouseClicked(ImGuiMouseButton idx) {
    return igIsMouseClicked(idx, false);
}

/**
    Gets whether a mouse button is down
*/
bool incInputIsMouseReleased(ImGuiMouseButton idx) {
    return igIsMouseReleased(idx);
}

/**
    Gets whether a right click popup menu is requested by the user
*/
bool incInputIsPopupRequested() {
    return 
        !incInputIsDragRequested() &&  // User can drag camera, make sure they aren't doing that 
        incInputIsMouseReleased(ImGuiMouseButton.Right); // Check mouse button released
}

/**
    Gets whether the user has requested to drag something
*/
bool incInputIsDragRequested(ImGuiMouseButton btn = ImGuiMouseButton.Right) {
    ImVec2 dragDelta;
    igGetMouseDragDelta(&dragDelta, btn);
    return abs(dragDelta.x) > 0.1f && abs(dragDelta.y) > 0.1f;
}

/**
    Gets whether a key is held down
*/
bool incInputIsKeyDown(ImGuiKey key) {
    return igIsKeyDown(igGetKeyIndex(key));
}

/**
    Gets whether a key is held down
*/
bool incInputIsKeyUp(ImGuiKey key) {
    return !incInputIsKeyDown(key);
}

/**
    Gets whether a key is held down
*/
bool incInputIsKeyPressed(ImGuiKey key) {
    return igIsKeyPressed(igGetKeyIndex(key));
}

uint incKeyScancode(string c) {
    switch (c) {
        case "A": return SDL_SCANCODE_A;
        case "B": return SDL_SCANCODE_B;
        case "C": return SDL_SCANCODE_C;
        case "D": return SDL_SCANCODE_D;
        case "E": return SDL_SCANCODE_E;
        case "F": return SDL_SCANCODE_F;
        case "G": return SDL_SCANCODE_G;
        case "H": return SDL_SCANCODE_H;
        case "I": return SDL_SCANCODE_I;
        case "J": return SDL_SCANCODE_J;
        case "K": return SDL_SCANCODE_K;
        case "L": return SDL_SCANCODE_L;
        case "M": return SDL_SCANCODE_M;
        case "N": return SDL_SCANCODE_N;
        case "O": return SDL_SCANCODE_O;
        case "P": return SDL_SCANCODE_P;
        case "Q": return SDL_SCANCODE_Q;
        case "R": return SDL_SCANCODE_R;
        case "S": return SDL_SCANCODE_S;
        case "T": return SDL_SCANCODE_T;
        case "U": return SDL_SCANCODE_U;
        case "V": return SDL_SCANCODE_V;
        case "W": return SDL_SCANCODE_W;
        case "X": return SDL_SCANCODE_X;
        case "Y": return SDL_SCANCODE_Y;
        case "Z": return SDL_SCANCODE_Z;
        case "0": return SDL_SCANCODE_0;
        case "1": return SDL_SCANCODE_1;
        case "2": return SDL_SCANCODE_2;
        case "3": return SDL_SCANCODE_3;
        case "4": return SDL_SCANCODE_4;
        case "5": return SDL_SCANCODE_5;
        case "6": return SDL_SCANCODE_6;
        case "7": return SDL_SCANCODE_7;
        case "8": return SDL_SCANCODE_8;
        case "9": return SDL_SCANCODE_9;
        case "F1": return SDL_SCANCODE_F1;
        case "F2": return SDL_SCANCODE_F2;
        case "F3": return SDL_SCANCODE_F3;
        case "F4": return SDL_SCANCODE_F4;
        case "F5": return SDL_SCANCODE_F5;
        case "F6": return SDL_SCANCODE_F6;
        case "F7": return SDL_SCANCODE_F7;
        case "F8": return SDL_SCANCODE_F8;
        case "F9": return SDL_SCANCODE_F9;
        case "F10": return SDL_SCANCODE_F10;
        case "F11": return SDL_SCANCODE_F11;
        case "F12": return SDL_SCANCODE_F12;
        case "Left": return SDL_SCANCODE_LEFT;
        case "Right": return SDL_SCANCODE_RIGHT;
        case "Up": return SDL_SCANCODE_UP;
        case "Down": return SDL_SCANCODE_DOWN;
        default: return SDL_SCANCODE_UNKNOWN;
    }
}

bool incShortcut(string s, bool repeat=false) {
    auto io = igGetIO();

    if (startsWith(s, "Ctrl+")) {
        if (!io.KeyCtrl) return false;
        s = s[5..$];
    }
    if (startsWith(s, "Alt+")) {
        if (!io.KeyAlt) return false;
        s = s[4..$];
    }
    if (startsWith(s, "Shift+")) {
        if (!io.KeyShift) return false;
        s = s[6..$];
    }

    uint scancode = incKeyScancode(s);
    if (scancode == SDL_SCANCODE_UNKNOWN) return false;

    return igIsKeyPressed(scancode, repeat);
}
