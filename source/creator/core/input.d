module creator.core.input;
import creator.core;
import inochi2d.core;
import inochi2d.math;
import bindbc.imgui;

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