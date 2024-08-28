/*
    Copyright © 2020-2024, nijigenerate Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Lin, Yong Xiang (r888800009)
*/

module creator.io.touchpad;
import creator.core;
import std.math.algebraic: abs;
import inochi2d;

// This const works well for macbook touchpad
// but i don't know it for other OS or touchpad
const float INC_MACBOOK_TOUCHPAD_SENSITIVITY = 0.040f;
const float INC_MACBOOK_TOUCHPAD_PINCH_MULTIPLIER = 70.0f;
const float INC_MACBOOK_TOUCHPAD_XY_MULTIPLIER = 2500.0f;
const float INC_MACBOOK_TOUCHPAD_XY_SENSITIVITY = 4.0f;

struct Touchpad {
    vec2 xy, deltaXY;
    vec2 startXY;
    float startDist;
    float dDist;
    bool isZooming;
    TouchpadState state = TouchpadState.Up;
};

enum TouchpadState
{
    Up,
    DownInit,
    Down,
    Started,
}

private {
    Touchpad incTouchpad;
    bool incTouchpadUpdated;

    float incTouchpadSensitivity = INC_MACBOOK_TOUCHPAD_SENSITIVITY;
    float incTouchpadPinchMultiplier = INC_MACBOOK_TOUCHPAD_PINCH_MULTIPLIER;
    float incTouchpadXYMultiplier = INC_MACBOOK_TOUCHPAD_XY_MULTIPLIER;
    float incTouchpadXYSensitivity = INC_MACBOOK_TOUCHPAD_XY_SENSITIVITY;
}

void incUpdateTouchpad(float x, float y, float dDist) {
    incTouchpadUpdated = true;

    // state machine
    if (incTouchpad.state == TouchpadState.DownInit) {
        incTouchpad.deltaXY = vec2(0.0f, 0.0f);
        incTouchpad.startXY = vec2(x, y);
        incTouchpad.startDist = dDist;
        incTouchpad.state = TouchpadState.Down;
    } else if (incTouchpad.state == TouchpadState.Down) {
        // just trigger when more then Sensitivity
        if (abs(incTouchpad.startDist) > incTouchpadSensitivity) {
            incTouchpad.state = TouchpadState.Started;
            incTouchpad.isZooming = true;
        } else if ((incTouchpad.startXY - vec2(x, y)).length() * incTouchpadPinchMultiplier > incTouchpadXYSensitivity) {
            incTouchpad.state = TouchpadState.Started;
            incTouchpad.isZooming = false;
        } else {
            incTouchpad.startDist += dDist;
            incTouchpad.deltaXY = vec2(x - incTouchpad.xy.x, y - incTouchpad.xy.y);
        }
    } else if (incTouchpad.state == TouchpadState.Started) {
        incTouchpad.deltaXY = vec2(x - incTouchpad.xy.x, y - incTouchpad.xy.y);
    }

    incTouchpad.dDist = dDist;
    incTouchpad.xy = vec2(x, y);
}

vec2 incGetTouchpadDeltaXY() {
    if (!incTouchpadUpdated || incTouchpad.state != TouchpadState.Started || incTouchpad.isZooming)
        return vec2(0.0f, 0.0f);
    return incTouchpad.deltaXY * incTouchpadXYMultiplier;
}

void incClearTouchpad() {
    incTouchpad.deltaXY = vec2(0.0f, 0.0f);
    incTouchpadUpdated = false;
}

float incGetPinchDistance() {
    if (!incTouchpadUpdated || incTouchpad.state != TouchpadState.Started || !incTouchpad.isZooming)
        return 0.0f;
    return incTouchpad.dDist * incTouchpadPinchMultiplier;
}

bool incIsTouchpadUpdated() {
    return incTouchpadUpdated && incIsTouchpadEnabled();
}

void incUpdateTouchpadUp() {
    incClearTouchpad();
    incTouchpad.state = TouchpadState.Up;
}

bool incIsTouchpadDown() {
    return incTouchpad.state != TouchpadState.Up && incIsTouchpadEnabled();
}

void incUpdateTouchpadDown() {
    incTouchpad.state = TouchpadState.DownInit;
}

bool incIsTouchpadEnabled() {
    if (incSettingsCanGet("TouchpadEnabled"))
        return incSettingsGet!bool("TouchpadEnabled");
    else
        // default is disabled, also see incSettingsLoad()
        return false;
}
