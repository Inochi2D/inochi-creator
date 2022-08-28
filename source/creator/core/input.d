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
    float uiScale = incGetUIScale();

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
            x*uiScale, 
            y*uiScale, 
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
    return igIsKeyDown(key);
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
    return igIsKeyPressed(key);
}

ImGuiKey incKeyScancode(string c) {
    switch (c) {
        case "A": return ImGuiKey.A;
        case "B": return ImGuiKey.B;
        case "C": return ImGuiKey.C;
        case "D": return ImGuiKey.D;
        case "E": return ImGuiKey.E;
        case "F": return ImGuiKey.F;
        case "G": return ImGuiKey.G;
        case "H": return ImGuiKey.H;
        case "I": return ImGuiKey.I;
        case "J": return ImGuiKey.J;
        case "K": return ImGuiKey.K;
        case "L": return ImGuiKey.L;
        case "M": return ImGuiKey.M;
        case "N": return ImGuiKey.N;
        case "O": return ImGuiKey.O;
        case "P": return ImGuiKey.P;
        case "Q": return ImGuiKey.Q;
        case "R": return ImGuiKey.R;
        case "S": return ImGuiKey.S;
        case "T": return ImGuiKey.T;
        case "U": return ImGuiKey.U;
        case "V": return ImGuiKey.V;
        case "W": return ImGuiKey.W;
        case "X": return ImGuiKey.X;
        case "Y": return ImGuiKey.Y;
        case "Z": return ImGuiKey.Z;
        case "0": return ImGuiKey.n0;
        case "1": return ImGuiKey.n1;
        case "2": return ImGuiKey.n2;
        case "3": return ImGuiKey.n3;
        case "4": return ImGuiKey.n4;
        case "5": return ImGuiKey.n5;
        case "6": return ImGuiKey.n6;
        case "7": return ImGuiKey.n7;
        case "8": return ImGuiKey.n8;
        case "9": return ImGuiKey.n9;
        case "F1": return ImGuiKey.F1;
        case "F2": return ImGuiKey.F2;
        case "F3": return ImGuiKey.F3;
        case "F4": return ImGuiKey.F4;
        case "F5": return ImGuiKey.F5;
        case "F6": return ImGuiKey.F6;
        case "F7": return ImGuiKey.F7;
        case "F8": return ImGuiKey.F8;
        case "F9": return ImGuiKey.F9;
        case "F10": return ImGuiKey.F10;
        case "F11": return ImGuiKey.F11;
        case "F12": return ImGuiKey.F12;
        case "Left": return ImGuiKey.LeftArrow;
        case "Right": return ImGuiKey.RightArrow;
        case "Up": return ImGuiKey.UpArrow;
        case "Down": return ImGuiKey.DownArrow;
        default: return ImGuiKey.None;
    }
}

bool incShortcut(string s, bool repeat=false) {
    auto io = igGetIO();

    if(io.KeyCtrl && io.KeyAlt) return false;

    if (startsWith(s, "Ctrl+Shift+")) {
        if (!(io.KeyCtrl && !io.KeyAlt && io.KeyShift)) return false;
        s = s[11..$];
    }
    if (startsWith(s, "Ctrl+")) {
        if (!(io.KeyCtrl && !io.KeyAlt && !io.KeyShift)) return false;
        s = s[5..$];
    }
    if (startsWith(s, "Alt+")) {
        if (!(!io.KeyCtrl && io.KeyAlt && !io.KeyShift)) return false;
        s = s[4..$];
    }
    if (startsWith(s, "Shift+")) {
        if (!(!io.KeyCtrl && !io.KeyAlt && io.KeyShift)) return false;
        s = s[6..$];
    }

    ImGuiKey scancode = incKeyScancode(s);
    if (scancode == ImGuiKey.None) return false;

    return igIsKeyPressed(scancode, repeat);
}
