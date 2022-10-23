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
import creator.actions;
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
    return (name in isDraggingOnHandle[btn].dragged) !is null && isDraggingOnHandle[btn].dragged[name];
}

void incBeginDragInViewport(int btn) {
    isDraggingInViewport[btn] = true;
}

void incBeginDragOnHandle(int btn, string name, vec2 prevValue = vec2(0,0)) {
    isDraggingOnHandle[btn].dragged[name] = true;
    auto mpos = incInputGetMousePosition();
    isDraggingOnHandle[btn].dragOrigin[name] = mpos;
    isDraggingOnHandle[btn].prevValue[name] = prevValue;
}

bool incGetDragOriginOnHandle(int btn, string name, out vec2 mpos) {
    bool result = incDragStartedOnHandle(btn, name);
    mpos = isDraggingOnHandle[btn].dragOrigin[name];
    return result;
}

bool incGetDragPrevValueOnHandle(int btn, string name, out vec2 value) {
    bool result = incDragStartedOnHandle(btn, name);
    value = isDraggingOnHandle[btn].prevValue[name];
    return result;
}

void incEndDragInViewport(int btn) {
    isDraggingInViewport[btn] = false;
}

void incEndDragOnHandle(int btn, string name) {
    isDraggingOnHandle[btn].dragged.remove(name);
    isDraggingOnHandle[btn].dragOrigin.remove(name);
    isDraggingOnHandle[btn].prevValue.remove(name);
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

            Parameter armedParam = incArmedParameter();

            // Move
            string name = selectedNode.name ~ "move";
            ImGuiMouseButton btn = ImGuiMouseButton.Left;
            vec2u index = armedParam? armedParam.findClosestKeypoint() : vec2u(0, 0);
            if (incDragStartedOnHandle(btn, name)) {
                if (igIsMouseDown(btn)) {
                    vec2 mpos, origPos;
                    incGetDragOriginOnHandle(btn, name, origPos);
                    mpos = incInputGetMousePosition();

                    if (armedParam) {
                        // Convert back to radians for data managment
                        // Set binding
                        GroupAction groupAction = null;
                        vec2 relPos = -(mpos - origPos);
                        GroupAction changeParameter(Node node, GroupAction action, Parameter param, string paramName, vec2u index, float prevValue, float newValue) {
                            if (newValue == 0) {
                                return action;
                            }
                            if (!action)
                                action = new GroupAction();
                            ValueParameterBinding b = cast(ValueParameterBinding)param.getBinding(node, paramName);
                            if (b is null) {
                                b = cast(ValueParameterBinding)param.createBinding(node, paramName);
                                param.addBinding(b);
                                auto addAction = new ParameterBindingAddAction(param, b);
                                action.addAction(addAction);
                            }
                            // Push action
                            auto addAction = new ParameterBindingValueChangeAction!(float)(b.getName(), b, index.x, index.y);
                            action.addAction(addAction);
                            b.setValue(index, prevValue + newValue);
                            addAction.updateNewState();
                            return action;
                        }
                        vec2 prevValue;
                        incGetDragPrevValueOnHandle(btn, name, prevValue);
                        if (relPos.x != 0) {
                            groupAction = changeParameter(selectedNode, groupAction, armedParam, "transform.t.x", index, prevValue.x, prevValue.x + relPos.x);
                        }
                        if (relPos.y != 0) {
                            groupAction = changeParameter(selectedNode, groupAction, armedParam, "transform.t.y", index, prevValue.y, prevValue.y + relPos.y);
                        }
                        if (groupAction)
                            incActionPush(groupAction);                            
                    } else {
                        auto action = new GroupAction();
                        Node node = selectedNode;
                        vec2 prevValue;
                        incGetDragPrevValueOnHandle(btn, name, prevValue);
                        auto relPos = -(mpos - origPos);

                        node.localTransform.translation.vector[0] = prevValue.x + relPos.x;
                        node.localTransform.translation.vector[1] = prevValue.y + relPos.y;
                        if (relPos.x != 0) {
                            action.addAction(
                                new NodeValueChangeAction!(Node, float)(
                                    "X",
                                    node, 
                                    prevValue.x,
                                    node.localTransform.translation.vector[0],
                                    &node.localTransform.translation.vector[0]
                                )
                            );
                        }
                        if (relPos.y != 0) {
                            action.addAction(
                                new NodeValueChangeAction!(Node, float)(
                                    "Y",
                                    node, 
                                    prevValue.y,
                                    node.localTransform.translation.vector[1],
                                    &node.localTransform.translation.vector[1]
                                )
                            );

                        }
                        incActionPush(action);

                    }
                } else {
                    incEndDragOnHandle(btn, name);
                    incEndDrag(btn);
                }
            }
            incBeginViewportToolArea(name, ImVec2(bounds.x - 32, bounds.y - 32));
            igButton("", ImVec2(32, 32));
            if (igIsItemHovered() && igIsMouseDown(btn)) {
                if (!incDragStartedOnHandle(btn, name)) {
                    incBeginDrag(btn);
                    if (armedParam) {
                        ValueParameterBinding b;
                        b = cast(ValueParameterBinding)param.getBinding(selectedNode, "transform.t.x");
                        auto origX = (b !is null)? b.getValue(index) : 0;
                        b = cast(ValueParameterBinding)param.getBinding(selectedNode, "transform.t.y");
                        auto origY = (b !is null)? b.getValue(index) : 0;
                        incBeginDragOnHandle(btn, name, vec2(origX, origY));
                    } else
                        incBeginDragOnHandle(btn, name, vec2(selectedNode.localTransform.translation.vector[0], selectedNode.localTransform.translation.vector[1]));
                }
            }

            // Scaling
            name = selectedNode.name ~ "scale";
            if (incDragStartedOnHandle(btn, name)) {
                if (igIsMouseDown(btn)) {
                    vec2 mpos, origPos;
                    incGetDragOriginOnHandle(btn, name, origPos);
                    mpos = incInputGetMousePosition();
                    vec2 origin = selectedNode.localTransform.translation.xy;
                    mpos -= origin;
                    origPos -= origin;
                    if (armedParam) {
                        GroupAction groupAction = null;
                        GroupAction changeParameter(Node node, GroupAction action, Parameter param, string paramName, vec2u index, float prevValue, float newValue) {
                            if (newValue == 0) {
                                return action;
                            }
                            if (!action)
                                action = new GroupAction();
                            ValueParameterBinding b = cast(ValueParameterBinding)param.getBinding(node, paramName);
                            if (b is null) {
                                b = cast(ValueParameterBinding)param.createBinding(node, paramName);
                                param.addBinding(b);
                                auto addAction = new ParameterBindingAddAction(param, b);
                                action.addAction(addAction);
                            }
                            // Push action
                            auto addAction = new ParameterBindingValueChangeAction!(float)(b.getName(), b, index.x, index.y);
                            action.addAction(addAction);
                            b.setValue(index, prevValue + newValue);
                            addAction.updateNewState();
                            return action;
                        }
                        float ratioX = origPos.x == 0? 0: mpos.x / origPos.x;
                        float ratioY = origPos.y == 0? 0: mpos.y / origPos.y;
                        vec2 prevValue;
                        incGetDragPrevValueOnHandle(btn, name, prevValue);
                        if (ratioX != 1) {
                            groupAction = changeParameter(selectedNode, groupAction, armedParam, "transform.s.x", index, prevValue.x, prevValue.x * ratioX);
                        }
                        if (ratioY != 1) {
                            groupAction = changeParameter(selectedNode, groupAction, armedParam, "transform.s.y", index, prevValue.y, prevValue.y * ratioY);
                        }
                        if (groupAction)
                            incActionPush(groupAction);                            
                    } else {
                        auto action = new GroupAction();
                        Node node = selectedNode;
                        vec2 prevValue;

                        incGetDragPrevValueOnHandle(btn, name, prevValue);

                        float ratioX = origPos.x == 0? 0: mpos.x / origPos.x;
                        float ratioY = origPos.y == 0? 0: mpos.y / origPos.y;
                        node.localTransform.scale.vector[0] = prevValue.x * ratioX;
                        node.localTransform.scale.vector[1] = prevValue.y * ratioY;
                        if (ratioX != 1) {
                            action.addAction(
                                new NodeValueChangeAction!(Node, float)(
                                    "X",
                                    node, 
                                    prevValue.x,
                                    node.localTransform.scale.vector[0],
                                    &node.localTransform.scale.vector[0]
                                )
                            );
                        }
                        if (ratioY != 1) {
                            action.addAction(
                                new NodeValueChangeAction!(Node, float)(
                                    "Y",
                                    node, 
                                    prevValue.y,
                                    node.localTransform.scale.vector[1],
                                    &node.localTransform.scale.vector[1]
                                )
                            );
                        }
                        incActionPush(action);
                    }
                } else {
                    incEndDrag(btn);
                    incEndDragOnHandle(btn, name);
                }
            }
            incEndViewportToolArea();
            incBeginViewportToolArea(name, ImVec2(bounds.x - 32, bounds.w));
            igButton("", ImVec2(32, 32));
            if (igIsItemHovered() && igIsMouseDown(btn)) {
                if (!incDragStartedOnHandle(btn, name)) {
                    incBeginDrag(btn);
                    if (armedParam) {
                        ValueParameterBinding b;
                        b = cast(ValueParameterBinding)param.getBinding(selectedNode, "transform.s.x");
                        auto origX = (b !is null)? b.getValue(index) : 1;
                        b = cast(ValueParameterBinding)param.getBinding(selectedNode, "transform.s.y");
                        auto origY = (b !is null)? b.getValue(index) : 1;
                        incBeginDragOnHandle(btn, name, vec2(origX, origY));
                    } else
                        incBeginDragOnHandle(btn, name, vec2(selectedNode.localTransform.scale.vector[0], selectedNode.localTransform.scale.vector[1]));
                }
            }

            // Rotation
            name = selectedNode.name ~ "rotate";
            if (incDragStartedOnHandle(btn, name)) {
                if (igIsMouseDown(btn)) {
                    if (armedParam) {

                    } else {
                    }
                } else {
                    incEndDrag(btn);
                    incEndDragOnHandle(btn, name);
                }
            }
            incEndViewportToolArea();
            incBeginViewportToolArea(name, ImVec2(bounds.z, bounds.y - 32));
            igButton("", ImVec2(32, 32));
            if (igIsItemHovered() && igIsMouseDown(btn)) {
                if (!incDragStartedOnHandle(btn, name)) {
                    incBeginDrag(btn);
                    incBeginDragOnHandle(btn, name);
                }
            }
            name = selectedNode.name ~ "sort";
            if (incDragStartedOnHandle(btn, name)) {
                if (igIsMouseDown(btn)) {
                    if (armedParam) {

                    } else {
                    }
                } else {
                    incEndDrag(btn);
                    incEndDragOnHandle(btn, name);
                }
            }
            incEndViewportToolArea();
            incBeginViewportToolArea(name, ImVec2(bounds.z, bounds.w));
            igButton("", ImVec2(32, 32));
            if (igIsItemHovered() && igIsMouseDown(btn)) {
                if (!incDragStartedOnHandle(btn, name)) {
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
        bool[string] dragged;
        vec2[string] dragOrigin;
        vec2[string] prevValue;
    }
    bool[ImGuiMouseButton.COUNT] isDraggingInViewport;
    DraggingOnHandle[ImGuiMouseButton.COUNT] isDraggingOnHandle;
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
