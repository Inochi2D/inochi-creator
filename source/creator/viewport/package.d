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

bool incDragStartedOnHandle(int btn, string name) {
    return (name in isDraggingOnHandle) !is null && isDraggingOnHandle[name].dragged[btn];
}

void incBeginDragInViewport(int btn) {
    isDraggingInViewport[btn] = true;
}

void incBeginDragOnHandle(int btn, string name) {
    if (name !in isDraggingOnHandle)
        isDraggingOnHandle[name] = DraggingOnHandle(true);
    isDraggingOnHandle[name].dragged[btn] = true;
}

void incEndDragInViewport(int btn) {
    isDraggingInViewport[btn] = false;
}

void incEndDragOnHandle(int btn, string name) {
    isDraggingOnHandle[name].dragged[btn] = false;
}

void incViewportTransformHandle() {
    Camera camera = inGetCamera();
    Parameter param = incArmedParameter();
    if (incSelectedNodes.length > 0) {
        foreach(selectedNode; incSelectedNodes) {
            if (cast(Part)selectedNode is null) continue; 

            import std.stdio;
            import creator.viewport;
            import creator.widgets.viewport;
            ImVec2 currSize;
            ImVec2 pos;

            vec2 WorldToViewport(float x, float y) {
                vec2 camPos = camera.position;
                vec2 camScale = camera.scale;
                vec2 camCenter = camera.getCenterOffset();
                float uiScale = incGetUIScale();

                return (
                    mat3.scaling(uiScale, uiScale,1).inverse()
                    * mat3.scaling(camScale.x, camScale.y, 1) 
                    * mat3.translation(camPos.x+camCenter.x, camPos.y+camCenter.y, 0) 
                    * vec3(x, y, 1)
                ).xy;
            }

            auto obounds=(cast(Part)selectedNode).bounds;
            auto bounds = vec4(WorldToViewport(obounds.x, obounds.y), WorldToViewport(obounds.z, obounds.w));
            string name = selectedNode.name ~ "move";
            ImGuiMouseButton btn = ImGuiMouseButton.Left;
            if (incDragStartedOnHandle(btn, name)) {
                if (igIsMouseDown(btn)) {
                    writefln("drag move");
                } else {
                    writeln("release move");
                    incEndDragOnHandle(btn, name);
                    incEndDrag(btn);
                }
            }
            incBeginViewportToolArea(name, ImVec2(bounds.x - 32, bounds.y - 32));
            igButton("", ImVec2(32, 32));
            if (igIsItemHovered() && igIsMouseDown(btn)) {
                if (!incDragStartedOnHandle(btn, name)) {
                    writeln("start move");
                    incBeginDrag(btn);
                    incBeginDragOnHandle(btn, name);
                }
            }
            name = selectedNode.name ~ "scale";
            if (incDragStartedOnHandle(btn, name)) {
                if (igIsMouseDown(btn)) {
                    writefln("drag scale");
                } else {
                    writeln("release scale");
                    incEndDrag(btn);
                    incEndDragOnHandle(btn, name);
                }
            }
            incEndViewportToolArea();
            incBeginViewportToolArea(name, ImVec2(bounds.x - 32, bounds.w));
            igButton("", ImVec2(32, 32));
            if (igIsItemHovered() && igIsMouseDown(btn)) {
                if (!incDragStartedOnHandle(btn, name)) {
                    writeln("start scale");
                    incBeginDrag(btn);
                    incBeginDragOnHandle(btn, name);
                }
            }
            name = selectedNode.name ~ "rotate";
            if (incDragStartedOnHandle(btn, name)) {
                if (igIsMouseDown(btn)) {
                    writefln("drag rotate");
                } else {
                    writeln("release rotate");
                    incEndDrag(btn);
                    incEndDragOnHandle(btn, name);
                }
            }
            incEndViewportToolArea();
            incBeginViewportToolArea(name, ImVec2(bounds.z, bounds.y - 32));
            igButton("", ImVec2(32, 32));
            if (igIsItemHovered() && igIsMouseDown(btn)) {
                if (!incDragStartedOnHandle(btn, name)) {
                    writeln("start rotate");
                    incBeginDrag(btn);
                    incBeginDragOnHandle(btn, name);
                }
            }
            name = selectedNode.name ~ "sort";
            if (incDragStartedOnHandle(btn, name)) {
                if (igIsMouseDown(btn)) {
                    writefln("drag sort");
                } else {
                    writeln("release sort");
                    incEndDrag(btn);
                    incEndDragOnHandle(btn, name);
                }
            }
            incEndViewportToolArea();
            incBeginViewportToolArea(name, ImVec2(bounds.z, bounds.w));
            igButton("", ImVec2(32, 32));
            if (igIsItemHovered() && igIsMouseDown(btn)) {
                if (!incDragStartedOnHandle(btn, name)) {
                    writeln("start sort");
                    incBeginDrag(btn);
                    incBeginDragOnHandle(btn, name);
                }
            }
            incEndViewportToolArea();
        }
    }
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
    struct DraggingOnHandle {
        bool [ImGuiMouseButton.COUNT] dragged;
    }
    bool[ImGuiMouseButton.COUNT] isDraggingInViewport;
    DraggingOnHandle[string] isDraggingOnHandle;
    bool[ImGuiMouseButton.COUNT] isDragging;
    bool isMovingViewport;
    float sx, sy;
    float csx, csy;
    bool isMovingPart;

    void incViewportMovement(ImGuiIO* io, Camera camera) {
        float uiScale = incGetUIScale();
        
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
                csx+((io.MousePos.x-sx)/incViewportZoom)*uiScale,
                csy+((io.MousePos.y-sy)/incViewportZoom)*uiScale
            );

            incViewportTargetPosition = camera.position;
        }

        // HANDLE ZOOM
        if (io.MouseWheel != 0) {
            incViewportZoom += (io.MouseWheel/50)*incViewportZoom*uiScale;
            incViewportZoom = clamp(incViewportZoom, incVIEWPORT_ZOOM_MIN, incVIEWPORT_ZOOM_MAX);
            camera.scale = vec2(incViewportZoom);
            incViewportTargetZoom = incViewportZoom;
        }
    }
}
