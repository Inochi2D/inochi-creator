/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.viewport;
import inochi2d;
import creator;
import creator.core.input;
import bindbc.imgui;
import creator.viewport.model;
import creator.viewport.deform;
import creator.viewport.vertex;

/**
    Draws the viewport contents
*/
void incViewportDraw() {
    auto camera = inGetCamera();
    inBeginScene();
    
        switch(incEditMode) {
            case EditMode.ModelEdit:
                incViewportModelDraw(camera);
                break;
            case EditMode.DeformEdit:
                incViewportDeformDraw(camera);
                break;
            case EditMode.VertexEdit:
                incViewportVertexDraw(camera);
                break;
            default: assert(0);
        }
    inEndScene();
}

/**
    Draws the viewport overlay (if any)
*/
void incViewportDrawOverlay() {
    switch(incEditMode) {
        case EditMode.ModelEdit:
            incViewportModelOverlay();
            break;
        case EditMode.DeformEdit:
            incViewportDeformOverlay();
            break;
        case EditMode.VertexEdit:
            incViewportVertexOverlay();
            break;
        default: assert(0);
    }
}

/**
    Begins polling for viewport interactivity
*/
void incViewportPoll() {
    incInputPoll();
    ImVec2 pos;
    ImVec2 mpos;
    igGetItemRectMin(&pos);
    igGetMousePos(&mpos);
    incInputSetViewportMouse(pos.x-mpos.x, pos.y-mpos.y);
}

/**
    Updates the viewport
*/
void incViewportUpdate() {
    ImGuiIO* io = igGetIO();
    auto camera = inGetCamera();

    // First update viewport movement
    incViewportMovement(io, camera);

    // Then update sub-stuff
    switch(incEditMode) {
        case EditMode.ModelEdit:
            incViewportModelUpdate(io, camera);
            break;
        case EditMode.DeformEdit:
            incViewportDeformUpdate(io, camera);
            break;
        case EditMode.VertexEdit:
            incViewportVertexUpdate(io, camera);
            break;
        default: assert(0);
    }
}

/**
    Updates the viewport toolbars
*/
void incViewportToolbar() {
    switch(incEditMode) {
        case EditMode.ModelEdit:
            incViewportModelToolbar();
            break;
        case EditMode.DeformEdit:
            incViewportDeformToolbar();
            break;
        case EditMode.VertexEdit:
            incViewportVertexToolbar();
            break;
        default: assert(0);
    }
}




//
//          VIEWPORT CAMERA HANDLING
//

enum incVIEWPORT_ZOOM_MIN = 0.05;
enum incVIEWPORT_ZOOM_MAX = 8.0;

/**
    Target camera position in scene
*/
vec2 incViewportTargetPosition = vec2(0);

/**
    Target camera zoom in scene
*/
float incViewportTargetZoom = 1;

/**
    The actual zoom of the viewport
*/
float incViewportZoom = 1;

/**
    Resets the viewport
*/
void incViewportReset() {
    incViewportTargetPosition = vec2(0);
    incViewportTargetZoom = 1;
}



//
//          Internal Viewport Stuff(TM)
//
private {
    bool isMovingViewport;
    float sx, sy;
    float csx, csy;
    bool isMovingPart;

    void incViewportMovement(ImGuiIO* io, Camera camera) {
        
        // HANDLE MOVE VIEWPORT
        if (!isMovingViewport && io.MouseDown[1] && incInputIsDragRequested()) {
            isMovingViewport = true;
            sx = io.MousePos.x;
            sy = io.MousePos.y;
            csx = camera.position.x;
            csy = camera.position.y;
        }

        if (isMovingViewport && !io.MouseDown[1]) {
            isMovingViewport = false;
        }

        if (isMovingViewport) {

            camera.position = vec2(
                csx+((io.MousePos.x-sx)/incViewportZoom),
                csy+((io.MousePos.y-sy)/incViewportZoom)
            );

            incViewportTargetPosition = camera.position;
        }

        // HANDLE ZOOM
        if (io.MouseWheel != 0) {
            incViewportZoom += (io.MouseWheel/50)*incViewportZoom;
            incViewportZoom = clamp(incViewportZoom, incVIEWPORT_ZOOM_MIN, incVIEWPORT_ZOOM_MAX);
            camera.scale = vec2(incViewportZoom);
            incViewportTargetZoom = incViewportZoom;
        }
    }
}
