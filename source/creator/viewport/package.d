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
import creator.viewport;
import creator.viewport.model;
import creator.viewport.vertex;
import creator.viewport.anim;
import creator.viewport.test;
import creator.widgets.viewport;
import bindbc.imgui;
import std.algorithm.sorting;
import std.stdio;

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
    return (name in isDraggingOnHandle[btn]) !is null && isDraggingOnHandle[btn][name].dragged;
}

void incBeginDragInViewport(int btn) {
    isDraggingInViewport[btn] = true;
}

void incBeginDragOnHandle(int btn, string name, vec2 prevValue = vec2(0,0)) {
    auto mpos = incInputGetMousePosition();
    isDraggingOnHandle[btn][name] = new DraggingOnHandle(mpos, prevValue);
}

bool incGetDragOriginOnHandle(int btn, string name, out vec2 mpos) {
    bool result = incDragStartedOnHandle(btn, name);
    mpos = isDraggingOnHandle[btn][name].dragOrigin;
    return result;
}

bool incGetDragPrevValueOnHandle(int btn, string name, out vec2 value) {
    bool result = incDragStartedOnHandle(btn, name);
    value = isDraggingOnHandle[btn][name].prevValue;
    return result;
}

void incEndDragInViewport(int btn) {
    isDraggingInViewport[btn] = false;
}

void incEndDragOnHandle(int btn, string name) {
    isDraggingOnHandle[btn].remove(name);
}

DraggingOnHandle incGetDragOnHandleStatus(int btn, string name) {
    return name in isDraggingOnHandle[btn]? isDraggingOnHandle[btn][name] : null;
}

void incViewportTransformHandle() {
    Camera camera = inGetCamera();
    auto io = igGetIO();
    Parameter param = incArmedParameter();
    if (incSelectedNodes.length > 0) {
        foreach(selectedNode; incSelectedNodes) {
            if (cast(Part)selectedNode is null) continue; 

            auto obounds=(cast(Part)selectedNode).bounds;
            auto bounds = vec4(WorldToViewport(obounds.x, obounds.y), WorldToViewport(obounds.z, obounds.w));

            Parameter armedParam = incArmedParameter();

            string name;
            ImGuiMouseButton btn = ImGuiMouseButton.Left;

            void changeParameter(Node node, Parameter param, string paramName, vec2u index, float newValue) {
                if (newValue == 0)
                    return;
                ValueParameterBinding b = cast(ValueParameterBinding)param.getBinding(node, paramName);
                DraggingOnHandle status = incGetDragOnHandleStatus(btn, name);
                if (b is null) {
                    b = cast(ValueParameterBinding)param.createBinding(node, paramName);
                    param.addBinding(b);
                    status.actions["Add"]= new ParameterBindingAddAction(param, b);
                }
                // Push action
                if (paramName !in status.actions)
                    status.actions[paramName] = new ParameterBindingValueChangeAction!(float)(b.getName(), b, index.x, index.y);
                b.setValue(index, newValue);
            }

            // Move
            name = selectedNode.name ~ "move";
            vec2u index = armedParam? armedParam.findClosestKeypoint() : vec2u(0, 0);
            if (incDragStartedOnHandle(btn, name)) {
                vec2 prevValue;
                incGetDragPrevValueOnHandle(btn, name, prevValue);
                DraggingOnHandle status = incGetDragOnHandleStatus(btn, name);

                if (igIsMouseDown(btn)) {
                    vec2 mpos, origPos;
                    incGetDragOriginOnHandle(btn, name, origPos);
                    mpos = incInputGetMousePosition();
                    auto relPos = -(mpos - origPos);
                    float newValueX = prevValue.x + relPos.x;
                    float newValueY = prevValue.y + relPos.y;
                    if (io.KeyCtrl) {
                        newValueX = round(newValueX / 5) * 5;
                        newValueY = round(newValueY / 5) * 5;
                    }
                    if (io.KeyShift) {
                        if (abs(relPos.x) > abs(relPos.y))
                            status.lockOrientation(LockedOrientation.Vertical);
                        else
                            status.lockOrientation(LockedOrientation.Horizontal);
                    } else {
                        status.lockOrientation(LockedOrientation.None);
                    }
                    if (status.locked == LockedOrientation.Vertical)
                        newValueY = prevValue.y;
                    if (status.locked == LockedOrientation.Horizontal)
                        newValueX = prevValue.x;

                    if (armedParam) {
                        changeParameter(selectedNode, armedParam, "transform.t.x", index, newValueX);
                        changeParameter(selectedNode, armedParam, "transform.t.y", index, newValueY);
                    } else {
                        selectedNode.localTransform.translation.vector[0] = newValueX;
                        selectedNode.localTransform.translation.vector[1] = newValueY;
                    }
                } else {
                    if (!armedParam) {
                        if (selectedNode.localTransform.translation.vector[0] != prevValue.x) {
                            status.actions["X"] =
                                new NodeValueChangeAction!(Node, float)("X", selectedNode, prevValue.x,
                                    selectedNode.localTransform.translation.vector[0], &selectedNode.localTransform.translation.vector[0]
                                );
                        }
                        if (selectedNode.localTransform.translation.vector[1] != prevValue.y) {
                            status.actions["Y"] =
                                new NodeValueChangeAction!(Node, float)("Y", selectedNode, prevValue.y,
                                    selectedNode.localTransform.translation.vector[1], &selectedNode.localTransform.translation.vector[1]);
                        }
                    }
                    status.commitActions();

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
            incEndViewportToolArea();

            // Scaling
            name = selectedNode.name ~ "scale";
            if (incDragStartedOnHandle(btn, name)) {
                vec2 prevValue;
                incGetDragPrevValueOnHandle(btn, name, prevValue);
                DraggingOnHandle status = incGetDragOnHandleStatus(btn, name);

                if (igIsMouseDown(btn)) {
                    vec2 mpos, origPos;
                    incGetDragOriginOnHandle(btn, name, origPos);
                    mpos = incInputGetMousePosition();
                    auto origin = -(obounds.xy + obounds.zw) / 2;
                    mpos -= origin;
                    origPos -= origin;
                    origPos = (mat3.identity.rotateZ(selectedNode.localTransform.rotation.vector[2]) * vec3(origPos.x, origPos.y, 1)).xy;
                    mpos = (mat3.identity.rotateZ(selectedNode.localTransform.rotation.vector[2]) * vec3(mpos.x, mpos.y, 1)).xy;
                    float ratioX = origPos.x == 0 ? 0 : mpos.x / origPos.x;
                    float ratioY = origPos.y == 0 ? 0 : mpos.y / origPos.y;
                    float newValueX = prevValue.x * ratioX;
                    float newValueY = prevValue.y * ratioY;
                    if (io.KeyShift) {
                        if (io.KeyAlt) {

                            // Keep Ratio
                            float nScale = sqrt((mpos.x^^2) + (mpos.y^^2)) / sqrt((origPos.x^^2) + (origPos.y^^2));
                            newValueX = prevValue.x * nScale;
                            newValueY = prevValue.y * nScale;

                        } else {

                            // Lock to axis
                            if (abs(ratioX) > abs(ratioY)) {
                                status.lockOrientation(LockedOrientation.Vertical);
                            } else {
                                status.lockOrientation(LockedOrientation.Horizontal);
                            }
                            if (status.locked == LockedOrientation.Vertical) {
                                newValueY = prevValue.y;
                            } else if (status.locked == LockedOrientation.Horizontal) {
                                newValueX = prevValue.x;
                            }
                        }
                    } else {
                        status.lockOrientation(LockedOrientation.None);
                    }

                    // Snap
                    if (io.KeyCtrl) {
                        newValueX = floor(newValueX * 10) / 10;
                        newValueY = floor(newValueY * 10) / 10;
                    }
                    
                    if (armedParam) {
                        changeParameter(selectedNode, armedParam, "transform.s.x", index, newValueX);
                        changeParameter(selectedNode, armedParam, "transform.s.y", index, newValueY);
                    } else {
                        selectedNode.localTransform.scale.vector[0] = newValueX;
                        selectedNode.localTransform.scale.vector[1] = newValueY;
                    }
                } else {
                    if (!armedParam) {
                        if (selectedNode.localTransform.scale.vector[0] != prevValue.x) {
                            status.actions["X"] =
                                new NodeValueChangeAction!(Node, float)("X", selectedNode, prevValue.x,
                                    selectedNode.localTransform.scale.vector[0], &selectedNode.localTransform.scale.vector[0]);
                        }
                        if (selectedNode.localTransform.scale.vector[1] != prevValue.y) {
                            status.actions["Y"] = 
                                new NodeValueChangeAction!(Node, float)("Y", selectedNode, prevValue.y,
                                    selectedNode.localTransform.scale.vector[1], &selectedNode.localTransform.scale.vector[1]);
                        }
                    } 
                    status.commitActions();

                    incEndDrag(btn);
                    incEndDragOnHandle(btn, name);
                }
            }
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
            incEndViewportToolArea();

            // Rotation
            name = selectedNode.name ~ "rotate";
            if (incDragStartedOnHandle(btn, name)) {
                vec2 prevValue;
                incGetDragPrevValueOnHandle(btn, name, prevValue);
                DraggingOnHandle status = incGetDragOnHandleStatus(btn, name);

                if (igIsMouseDown(btn)) {
                    vec2 mpos, origPos;
                    incGetDragOriginOnHandle(btn, name, origPos);
                    mpos = incInputGetMousePosition();
                    auto origin = -(obounds.xy + obounds.zw) / 2;
                    mpos -= origin;
                    origPos -= origin;

                    float getArg(vec2 p) {
                        float arg = acos(p.length == 0 ? 0: p.x / p.length);
                        if (p.y < 0)
                            arg *= -1;
                        return arg;
                    }
                    float origArg = getArg(origPos);
                    float newArg  = getArg(mpos);
                    float diffArg = newArg - origArg;
                    float newValue = prevValue.x + diffArg;
                    if (io.KeyCtrl) {
                        newValue = radians(round(degrees(newValue) / 5) * 5);
                    }

                    if (armedParam) {
                        changeParameter(selectedNode, armedParam, "transform.r.z", index, newValue);
                    } else {
                        selectedNode.localTransform.rotation.vector[2] = newValue;
                    }
                } else {
                    if (!armedParam) {
                        if (selectedNode.localTransform.rotation.vector[2] != prevValue.x) {
                            status.actions["Z"] =
                                new NodeValueChangeAction!(Node, float)("Z", selectedNode, prevValue.x,
                                    selectedNode.localTransform.rotation.vector[2], &selectedNode.localTransform.rotation.vector[2]);
                        }
                    }
                    status.commitActions();

                    incEndDrag(btn);
                    incEndDragOnHandle(btn, name);
                }
            }
            incBeginViewportToolArea(name, ImVec2(bounds.z, bounds.y - 32));
            igButton("", ImVec2(32, 32));
            if (igIsItemHovered() && igIsMouseDown(btn)) {
                if (!incDragStartedOnHandle(btn, name)) {
                    incBeginDrag(btn);
                    if (armedParam) {
                        ValueParameterBinding b;
                        b = cast(ValueParameterBinding)param.getBinding(selectedNode, "transform.r.z");
                        auto origZ = (b !is null)? b.getValue(index) : 1;
                        incBeginDragOnHandle(btn, name, vec2(origZ, 0));
                    } else
                        incBeginDragOnHandle(btn, name, vec2(selectedNode.localTransform.rotation.vector[2], 0));
                }
            }
            incEndViewportToolArea();
            /*
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
            incBeginViewportToolArea(name, ImVec2(bounds.z, bounds.w));
            igButton("", ImVec2(32, 32));
            if (igIsItemHovered() && igIsMouseDown(btn)) {
                if (!incDragStartedOnHandle(btn, name)) {
                    incBeginDrag(btn);
                    incBeginDragOnHandle(btn, name);
                }
            }
            incEndViewportToolArea();
            */
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
    enum LockedOrientation {
        None, Horizontal, Vertical
    };
    class DraggingOnHandle {
        bool dragged;
        vec2 dragOrigin;
        vec2 prevValue;
        Action[string] actions;
        LockedOrientation locked;

        this(vec2 origin=vec2(0,0), vec2 value=vec2(0, 0)) {
            dragged = true;
            dragOrigin = origin;
            prevValue = value;
            locked = LockedOrientation.None;
        }

        void lockOrientation(LockedOrientation orientation) {
            if (orientation == LockedOrientation.None)
                locked = orientation;
            else if (locked != LockedOrientation.None)
                return;
            else
                locked = orientation;
        }

        void commitActions() {
            if (actions.length == 1) {
                foreach (action; actions)
                    incActionPush(action);
            } else if (actions.length > 0) {
                GroupAction groupAction = null;
                foreach (key; sort(actions.keys)) {
                    auto action = actions[key];
                    LazyBoundAction laction = cast(LazyBoundAction)action;
                    if (laction)
                        laction.updateNewState();
                    if (!groupAction)
                        groupAction = new GroupAction();
                        groupAction.addAction(action);
                }
                if (groupAction)
                    incActionPush(groupAction);
            }
        }
    }
    bool[ImGuiMouseButton.COUNT] isDraggingInViewport;
    DraggingOnHandle[string][ImGuiMouseButton.COUNT] isDraggingOnHandle;
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
