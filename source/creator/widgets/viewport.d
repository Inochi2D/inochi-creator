/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets.viewport;
import creator.widgets;
import inochi2d.math;

private {
    struct ViewportToolAreaData {
        ImVec2 contentSize;
    }
}

/**
    Starts a generalized tool area that resizes to fit its contents
*/
void incBeginViewportToolArea(string id_str, ImVec2 pos, bool pad = true) {
    incBeginViewportToolArea(id_str, ImGuiDir.Right, ImGuiDir.Up, pad, &pos);
}

void incBeginViewportToolArea(string id_str, ImGuiDir hdir, ImGuiDir vdir = ImGuiDir.Up, bool pad = true, ImVec2* pos = null) {
    igSetItemAllowOverlap();
    igPushID(id_str.ptr, id_str.ptr+id_str.length);
    auto storage = igGetStateStorage();
    auto win = igGetCurrentWindow();
    auto style = igGetStyle();
    auto id = igGetID("CONTENT_SIZE");

    // NOTE: Since this data is needed *before* we enter the child window
    // we need to access it now, when we're writing to the values later
    // we'll want to end the child FIRST before accessing it.
    ViewportToolAreaData* data = cast(ViewportToolAreaData*)ImGuiStorage_GetVoidPtr(storage, id);
    if (!data) {
        data = cast(ViewportToolAreaData*)igMemAlloc(ViewportToolAreaData.sizeof);
        data.contentSize = ImVec2(1, 1);
        ImGuiStorage_SetVoidPtr(storage, id, data);
    }

    float paddingX = pad ? style.FramePadding.x : 0;
    float paddingY = pad ? style.FramePadding.y : 0; 

    // Depending on whether we're on the right or the left we want the tool area to display slightly offset
    // on the top left or top right, this ensures that.
    igSetCursorScreenPos(
        pos? ImVec2(pos.x + win.InnerRect.Max.x, pos.y + win.InnerRect.Max.y):
        ImVec2(
            hdir == ImGuiDir.Right ? win.InnerRect.Min.x - (paddingX+data.contentSize.x) : win.InnerRect.Max.x + paddingX,
            vdir == ImGuiDir.Down ? win.InnerRect.Min.y - (paddingY+data.contentSize.y) : win.InnerRect.Max.y + paddingY,   
        )
    );

    igPushStyleVar(ImGuiStyleVar.FrameRounding, 0);

    enum FLAGS = ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoScrollWithMouse;
    igBeginChild("CONTENT_CHILD", ImVec2(data.contentSize.x, data.contentSize.y), false, FLAGS);
}

void incEndViewportToolArea() {
    auto win = igGetCurrentWindow();
    
    // End the child
    igEndChild();

    // Pop style vars
    igPopStyleVar();

    // NOTE: now that we're outside the child we can actually set the ViewportToolAreaData.
    // Since we set the state storage outside of the child in the beginning
    auto storage = igGetStateStorage();
    auto id = igGetID("CONTENT_SIZE");
    ViewportToolAreaData* data = cast(ViewportToolAreaData*)ImGuiStorage_GetVoidPtr(storage, id);
    if (data) data.contentSize = ImVec2(clamp(win.ContentSize.x, 1, float.max), clamp(win.ContentSize.y, 1, float.max));
    
    // Finally pop the user specified ID which the state storage is stored inside
    igPopID();
}