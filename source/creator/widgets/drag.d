/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets.drag;
import creator.widgets;
import core.stdc.stdlib : malloc, free;

private {
    struct DragState {
        float initialState;
        bool isActive;
        bool wasJustCreated;
    }
}

/**
    A drag float that only returns true once you're done changing its value
*/
bool incDragFloat(string id, float* value, float adjustSpeed, float minValue, float maxValue, string fmt, ImGuiSliderFlags flags = ImGuiSliderFlags.None) {
    auto storage = igGetStateStorage();
    auto igID = igGetID(id.ptr, id.ptr+id.length);

    // Store initial state if needed
    float inState = *value;

    DragState* dragState = cast(DragState*)ImGuiStorage_GetVoidPtr(storage, igID);

    // initialize if need be
    if (dragState is null) {
        dragState = cast(DragState*)malloc(DragState.sizeof);

        dragState.initialState = inState;
        dragState.isActive = true;
        dragState.wasJustCreated = true;

        ImGuiStorage_SetVoidPtr(storage, igID, dragState);
    }

    if (igDragFloat("", value, adjustSpeed, minValue, maxValue, fmt.ptr, flags)) {
        if (!dragState.isActive) {
            dragState.initialState = inState;
            dragState.isActive = true;
            dragState.wasJustCreated = false;
        }

    } else {
        if (dragState !is null && dragState.isActive) {
            dragState.isActive = false;
            return !dragState.wasJustCreated;
        }
    }
    return false;
}

/**
    Gets whether specified DragFloat has state stored for it
*/
bool incGetHasDragState(string id) {
    auto storage = igGetStateStorage();
    auto igID = igGetID(id.ptr, id.ptr+id.length);
    return ImGuiStorage_GetVoidPtr(storage, igID) !is null;
}

/**
    Gets the initial value of the specified drag float

    Returns NaN if there's no drag state
*/
float incGetDragFloatInitialValue(string id) {
    auto storage = igGetStateStorage();
    auto igID = igGetID(id.ptr, id.ptr+id.length);

    DragState* dragState = cast(DragState*)ImGuiStorage_GetVoidPtr(storage, igID);
    if (dragState !is null) return dragState.initialState;
    return float.nan;
}