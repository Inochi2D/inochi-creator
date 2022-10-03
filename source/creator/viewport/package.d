/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.viewport;
import inochi2d;
import creator;
import creator.core;
import creator.core.input;
import bindbc.imgui;
import creator.viewport.model;
import creator.viewport.vertex;
import creator.viewport.anim;
import creator.viewport.test;

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
            case EditMode.VertexEdit:
                incViewportVertexDraw(camera);
                break;
            case EditMode.AnimEdit:
                incViewportAnimDraw(camera);
                break;
            case EditMode.ModelTest:
                incViewportTestDraw(camera);
                break;
            default: assert(0);
        }
    inEndScene();

    if (incShouldPostProcess) {
        inPostProcessScene();
    }
}

/**
    Draws the viewport overlay (if any)
*/
void incViewportDrawTools() {
    switch(incEditMode) {
        case EditMode.VertexEdit:
            incViewportVertexTools();
            break;
        case EditMode.ModelEdit: 
            incViewportModelTools(); 
            break;
        case EditMode.AnimEdit:
        case EditMode.ModelTest:
            break;
        default: assert(0);
    }
}

void incViewportDrawOptions() {
    switch(incEditMode) {
        case EditMode.ModelEdit:
            incViewportModelOptions();
            break;
        case EditMode.VertexEdit:
            incViewportVertexOptions();
            break;
        case EditMode.AnimEdit:
            incViewportAnimOverlay();
            break;
        case EditMode.ModelTest:
            incViewportTestOverlay();
            break;
        default: assert(0);
    }
}

void incViewportDrawConfirmBar() {
    switch(incEditMode) {
        case EditMode.VertexEdit:
            incViewportVertexConfirmBar();
            break;
        case EditMode.ModelEdit:
            incViewportModelConfirmBar();
            break;
        case EditMode.AnimEdit:
        case EditMode.ModelTest:
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
void incViewportUpdate(bool localOnly = false) {
    ImGuiIO* io = igGetIO();
    auto camera = inGetCamera();

    // First update viewport movement
    if (!localOnly) incViewportMovement(io, camera);

    // Then update sub-stuff
    switch(incEditMode) {
        case EditMode.ModelEdit:
            incViewportModelUpdate(io, camera);
            break;
        case EditMode.VertexEdit:
            incViewportVertexUpdate(io, camera);
            break;
        case EditMode.AnimEdit:
            incViewportAnimUpdate(io, camera);
            break;
        case EditMode.ModelTest:
            incViewportTestUpdate(io, camera);
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
        case EditMode.VertexEdit:
            incViewportVertexToolbar();
            break;
        case EditMode.AnimEdit:
            incViewportAnimToolbar();
            break;
        case EditMode.ModelTest:
            incViewportTestToolbar();
            break;
        default: assert(0);
    }
}

/**
    Called on editing mode present
*/
void incViewportPresentMode(EditMode mode) {
    switch(editMode_) {
        case EditMode.ModelEdit:
            incViewportModelPresent();
            break;
        case EditMode.VertexEdit:
            incViewportVertexPresent();
            break;
        case EditMode.AnimEdit:
            incViewportAnimPresent();
            break;
        case EditMode.ModelTest:
            incViewportTestPresent();
            break;
        default: assert(0);
    }
}

/**
    Called on editing mode withdraw
*/
void incViewportWithdrawMode(EditMode mode) {
    switch(editMode_) {
        case EditMode.ModelEdit:
            incViewportModelWithdraw();
            break;
        case EditMode.VertexEdit:
            incViewportVertexWithdraw();
            break;
        case EditMode.AnimEdit:
            incViewportAnimWithdraw();
            break;
        case EditMode.ModelTest:
            incViewportTestWithdraw();
            break;
        default: assert(0);
    }
}

void incViewportMenu() {
    switch(incEditMode) {
        case EditMode.ModelEdit:
            incViewportModelMenu();
            break;
        default: return;
    }
}

void incViewportMenuOpening() {
    switch(incEditMode) {
        case EditMode.ModelEdit:
            incViewportModelMenuOpening();
            break;
        default: return;
    }
}

bool incViewportHasMenu() {
    switch(incEditMode) {
        case EditMode.ModelEdit: return true;
        default: return false;
    }
}

/**
    Updates the viewport tool settings
*/
void incViewportToolSettings() {
    switch(incEditMode) {
        case EditMode.ModelEdit:
            incViewportModelToolSettings();
            break;
        case EditMode.VertexEdit:
            incViewportVertexToolSettings();
            break;
        default: 
            incViewportToolSettingsNoTool();
            break;
    }
}

bool incViewportAlwaysUpdate() {
    switch(incEditMode) {
        case EditMode.ModelTest:
            return true;
        default: return false;
    }
}

/// For when there's no tools for that view
void incViewportToolSettingsNoTool() {
    import i18n : _;
    import creator.widgets.label;
    incText(_("No tool selected..."));
}

bool incStartedDrag(int btn) {
    return isDragging[btn];
}

void incBeginDrag(int btn) {
    isDragging[btn] = true;
}

void incEndDrag(int btn) {
    isDragging[btn] = false;
}

bool incDragStartedInViewport(int btn) {
    return isDraggingInViewport[btn];
}

void incBeginDragInViewport(int btn) {
    isDraggingInViewport[btn] = true;
}

void incEndDragInViewport(int btn) {
    isDraggingInViewport[btn] = false;
}

//
//          VIEWPORT CAMERA HANDLING
//

enum incVIEWPORT_ZOOM_MIN = 0.05;
enum incVIEWPORT_ZOOM_MAX = 12.0;

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
    bool[ImGuiMouseButton.COUNT] isDraggingInViewport;
    bool[ImGuiMouseButton.COUNT] isDragging;
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
