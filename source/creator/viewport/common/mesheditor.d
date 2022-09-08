/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors:
    - Luna Nielsen
    - Asahi Lina
*/
module creator.viewport.common.mesheditor;
import i18n;
import creator.viewport;
import creator.viewport.common;
import creator.viewport.common.mesh;
import creator.viewport.common.spline;
import creator.core.input;
import creator.core.actionstack;
import creator.actions;
import creator.widgets;
import creator;
import inochi2d;
import inochi2d.core.dbg;
import bindbc.opengl;
import bindbc.imgui;
import std.algorithm.mutation;
import std.algorithm.searching;

enum VertexToolMode {
    Points,
    Connect,
    PathDeform,
}

class IncMeshEditor {
private:
    bool deformOnly = false;
    bool vertexMapDirty = false;

    Drawable target;
    VertexToolMode toolMode = VertexToolMode.Points;
    MeshVertex*[] selected;
    MeshVertex*[] mirrorSelected;
    MeshVertex*[] newSelected;

    vec2 lastMousePos;
    vec2 mousePos;

    bool isDragging = false;
    bool isSelecting = false;
    bool mutateSelection = false;
    bool invertSelection = false;
    MeshVertex* maybeSelectOne;
    MeshVertex* vtxAtMouse;
    vec2 selectOrigin;
    IncMesh previewMesh;

    bool deforming = false;
    CatmullSpline path;
    uint pathDragTarget;

    MeshEditorDeformationAction deformAction = null;

    bool isSelected(MeshVertex* vert) {
        import std.algorithm.searching : canFind;
        return selected.canFind(vert);
    }

    void toggleSelect(MeshVertex* vert) {
        import std.algorithm.searching : countUntil;
        import std.algorithm.mutation : remove;
        auto idx = selected.countUntil(vert);
        if (isSelected(vert)) {
            selected = selected.remove(idx);
        } else {
            selected ~= vert;
        }
        updateMirrorSelected();
    }

    MeshVertex* selectOne(MeshVertex* vert) {
        if (selected.length > 0) {
            auto lastSel = selected[$-1];

            selected = [vert];
            if (deformAction)
                deformAction.addVertex(vert);
            return lastSel;
        }

        selected = [vert];
        if (deformAction)
            deformAction.addVertex(vert);
        updateMirrorSelected();
        return null;
    }

    void deselectAll() {
        selected.length = 0;
        if (deformAction)
            deformAction.clear();
        updateMirrorSelected();
    }

    vec2 mirrorH(vec2 point) {
        return 2 * vec2(mirrorOrigin.x, 0) + vec2(-point.x, point.y);
    }

    vec2 mirrorV(vec2 point) {
        return 2 * vec2(0, mirrorOrigin.x) + vec2(point.x, -point.y);
    }

    vec2 mirrorHV(vec2 point) {
        return 2 * mirrorOrigin - point;
    }

    vec2 mirror(uint axis, vec2 point) {
        switch (axis) {
            case 0: return point;
            case 1: return mirrorH(point);
            case 2: return mirrorV(point);
            case 3: return mirrorHV(point);
            default: assert(false, "bad axis");
        }
    }

    vec2 mirrorDelta(uint axis, vec2 point) {
        switch (axis) {
            case 0: return point;
            case 1: return vec2(-point.x, point.y);
            case 2: return vec2(point.x, -point.y);
            case 3: return vec2(-point.x, -point.y);
            default: assert(false, "bad axis");
        }
    }

    MeshVertex *mirrorVertex(uint axis, MeshVertex *vtx) {
        if (axis == 0) return vtx;
        MeshVertex *v = mesh.getVertexFromPoint(mirror(axis, vtx.position));
        if (v is vtx) return null;
        return v;
    }

    void foreachMirror(void delegate(uint axis) func) {
        if (mirrorHoriz) func(1);
        if (mirrorVert) func(2);
        if (mirrorHoriz && mirrorVert) func(3);
        func(0);
    }

    void updateMirrorSelected() {
        mirrorSelected.length = 0;
        if (!mirrorHoriz && !mirrorVert) return;

        // Avoid duplicate selections...
        MeshVertex*[] tmpSelected;
        foreach(v; selected) {
            if (mirrorSelected.canFind(v)) continue;
            tmpSelected ~= v;

            foreachMirror((uint axis) {
                MeshVertex *v2 = mirrorVertex(axis, v);
                if (v2 is null) return;
                if (axis != 0) {
                    if (!tmpSelected.canFind(v2) && !mirrorSelected.canFind(v2))
                        mirrorSelected ~= v2;
                }
            });
        }
        if (deformAction) {
            foreach (v; mirrorSelected) {
                deformAction.addVertex(v);
            }
        }
        selected = tmpSelected;
    }


public:
    IncMesh mesh;
    bool previewTriangulate = false;
    bool mirrorHoriz = false;
    bool mirrorVert = false;
    vec2 mirrorOrigin = vec2(0, 0);

    this(bool deformOnly) {
        this.deformOnly = deformOnly;
    }

    Drawable getTarget() {
        return target;
    }

    void setTarget(Drawable target) {
        this.target = target;
        mesh = new IncMesh(target.getMesh());
        refreshMesh();
    }

    ref IncMesh getMesh() {
        return mesh;
    }

    VertexToolMode getToolMode() {
        return toolMode;
    }

    void setToolMode(VertexToolMode toolMode) {
        assert(!deformOnly || toolMode != VertexToolMode.Connect);
        this.toolMode = toolMode;
        isDragging = false;
        isSelecting = false;
        pathDragTarget = -1;
        deselectAll();
    }

    bool previewingTriangulation() {
         return previewTriangulate && toolMode == VertexToolMode.Points;
    }

    void resetMesh() {
        mesh.reset();
    }

    void refreshMesh() {
        mesh.refresh();
        if (previewingTriangulation()) {
            previewMesh = mesh.autoTriangulate();
        } else {
            previewMesh = null;
        }
        updateMirrorSelected();
    }

    void importMesh(MeshData data) {
        mesh.import_(data);
        mesh.refresh();
    }

    void applyOffsets(vec2[] offsets) {
        assert(deformOnly);

        mesh.applyOffsets(offsets);
    }

    vec2[] getOffsets() {
        assert(deformOnly);

        return mesh.getOffsets();
    }

    void applyToTarget() {
        // Export mesh
        MeshData data = mesh.export_();
        data.fixWinding();

        // Fix UVs
        foreach(i; 0..data.uvs.length) {
            if (Part part = cast(Part)target) {

                // Texture 0 is always albedo texture
                auto tex = part.textures[0];

                // By dividing by width and height we should get the values in UV coordinate space.
                data.uvs[i].x /= cast(float)tex.width;
                data.uvs[i].y /= cast(float)tex.height;
                data.uvs[i] += vec2(0.5, 0.5);
            }
        }

        if (data.vertices.length != target.vertices.length)
            vertexMapDirty = true;

        // Apply the model
        auto action = new DrawableChangeAction(target.name, target);
        target.rebuffer(data);

        if (vertexMapDirty) {
            // Remove incompatible Deforms

            foreach (param; incActivePuppet().parameters) {
                ParameterBinding binding = param.getBinding(target, "deform");
                if (binding) {
                    param.removeBinding(binding);
                    action.addBinding(param, binding);
                }
            }
            vertexMapDirty = false;
        }

        action.updateNewState();
        incActionPush(action);
    }

    void applyPreview() {
        mesh = previewMesh;
        previewMesh = null;
        previewTriangulate = false;
    }

    void pushDeformAction() {
        if (deformAction && deformAction.dirty) {
            deformAction.updateNewState();
            incActionPush(deformAction);
            deformAction = null;
        }        
    }

    MeshEditorDeformationAction getDeformAction(bool reset = false)() {
        if (reset)
            pushDeformAction();
        if (deformAction is null || !deformAction.isApplyable()) {
            switch (toolMode) {
            case VertexToolMode.Points:
                deformAction = new MeshEditorDeformationAction(target.name);
                break;
            case VertexToolMode.PathDeform:
                deformAction = new MeshEditorPathDeformAction(target.name);
                break;
            default:
            }
        } else {
            if (reset)
                deformAction.clear();
        }
        return deformAction;
    }
    alias getCleanDeformAction = getDeformAction!true;

    bool update(ImGuiIO* io, Camera camera) {
        bool changed = false;

        lastMousePos = mousePos;

        mousePos = incInputGetMousePosition();
        if (deformOnly) {
            vec4 pIn = vec4(-mousePos.x, -mousePos.y, 0, 1);
            mat4 tr = target.transform.matrix().inverse();
            vec4 pOut = tr * pIn;
            mousePos = vec2(pOut.x, pOut.y);
        } else {
            mousePos = -mousePos;
        }

        vtxAtMouse = mesh.getVertexFromPoint(mousePos);

        if (incInputIsMouseReleased(ImGuiMouseButton.Left)) {
            isDragging = false;
            if (isSelecting) {
                if (mutateSelection) {
                    if (!invertSelection) {
                        foreach(v; newSelected) {
                            auto idx = selected.countUntil(v);
                            if (idx == -1) selected ~= v;
                        }
                    } else {
                        foreach(v; newSelected) {
                            auto idx = selected.countUntil(v);
                            if (idx != -1) selected = selected.remove(idx);
                        }
                    }
                    updateMirrorSelected();
                    newSelected.length = 0;
                } else {
                    selected = newSelected;
                    newSelected = [];
                    updateMirrorSelected();
                }

                isSelecting = false;
            }
            pushDeformAction();
        }

        if (igIsMouseClicked(ImGuiMouseButton.Left)) maybeSelectOne = null;

        switch(toolMode) {
            case VertexToolMode.Points:

                if (deformOnly) {
                    incStatusTooltip(_("Select"), _("Left Mouse"));
                } else {
                    incStatusTooltip(_("Select"), _("Left Mouse"));
                    incStatusTooltip(_("Create"), _("Ctrl+Left Mouse"));
                }
                
                void addOrRemoveVertex(bool selectedOnly) {
                    if (deformOnly) return;
                    // Check if mouse is over a vertex
                    if (vtxAtMouse !is null) {

                        // In the case that it is, double clicking would remove an item
                        if (!selectedOnly || isSelected(vtxAtMouse)) {
                            foreachMirror((uint axis) {
                                mesh.removeVertexAt(mirror(axis, mousePos));
                            });
                            refreshMesh();
                            vertexMapDirty = true;
                            changed = true;
                            selected.length = 0;
                            updateMirrorSelected();
                            maybeSelectOne = null;
                            vtxAtMouse = null;
                        }
                    } else {
                        ulong off = mesh.vertices.length;
                        foreachMirror((uint axis) {
                            mesh.vertices ~= new MeshVertex(mirror(axis, mousePos));
                        });
                        refreshMesh();
                        vertexMapDirty = true;
                        changed = true;
                        selectOne(mesh.vertices[off]);
                    }
                }

                // Key actions
                if (!deformOnly && incInputIsKeyPressed(ImGuiKey.Delete)) {
                    foreachMirror((uint axis) {
                        foreach(v; selected) {
                            MeshVertex *v2 = mirrorVertex(axis, v);
                            if (v2 !is null) mesh.remove(v2);
                        }
                    });
                    selected = [];
                    updateMirrorSelected();
                    refreshMesh();
                    vertexMapDirty = true;
                    changed = true;
                }
                void shiftSelection(vec2 delta) {
                    float magnitude = 10.0;
                    if (io.KeyAlt) magnitude = 1.0;
                    else if (io.KeyShift) magnitude = 100.0;
                    delta *= magnitude;

                    foreachMirror((uint axis) {
                        vec2 mDelta = mirrorDelta(axis, delta);
                        foreach(v; selected) {
                            MeshVertex *v2 = mirrorVertex(axis, v);
                            if (v2 !is null) v2.position += mDelta;
                        }
                    });
                    refreshMesh();
                    changed = true;
                }

                if (incInputIsKeyPressed(ImGuiKey.LeftArrow)) {
                    shiftSelection(vec2(-1, 0));
                } else if (incInputIsKeyPressed(ImGuiKey.RightArrow)) {
                    shiftSelection(vec2(1, 0));
                } else if (incInputIsKeyPressed(ImGuiKey.DownArrow)) {
                    shiftSelection(vec2(0, 1));
                } else if (incInputIsKeyPressed(ImGuiKey.UpArrow)) {
                    shiftSelection(vec2(0, -1));
                }

                // Left click selection
                if (igIsMouseClicked(ImGuiMouseButton.Left)) {
                    if (!deformOnly && io.KeyCtrl && !io.KeyShift) {
                        // Add/remove action
                        addOrRemoveVertex(false);
                    } else {
                        MeshEditorDeformationAction action;
                        // Select / drag start
                        if (deformOnly) {
                            action = getCleanDeformAction();
                        } 

                        if (mesh.isPointOverVertex(mousePos)) {
                            if (io.KeyShift) toggleSelect(vtxAtMouse);
                            else if (!isSelected(vtxAtMouse))  selectOne(vtxAtMouse);
                            else maybeSelectOne = vtxAtMouse;
                        } else {
                            selectOrigin = mousePos;
                            isSelecting = true;
                        }
                    }
                }
                if (!isDragging && !isSelecting &&
                    incInputIsMouseReleased(ImGuiMouseButton.Left) && maybeSelectOne !is null) {
                    selectOne(maybeSelectOne);
                }

                // Left double click action
                if (!deformOnly && igIsMouseDoubleClicked(ImGuiMouseButton.Left) && !io.KeyShift && !io.KeyCtrl) {
                    addOrRemoveVertex(true);
                }

                // Dragging
                if (igIsMouseDown(ImGuiMouseButton.Left) && incInputIsDragRequested(ImGuiMouseButton.Left)) {
                    if (!isSelecting) {
                        isDragging = true;
                        getDeformAction();
                    }
                }

                if (isDragging) {
                    foreach(select; selected) {
                        foreachMirror((uint axis) {
                            MeshVertex *v = mirrorVertex(axis, select);
                            if (v is null) return;
                            if (deformAction) {
                                deformAction.addVertex(v);
                                deformAction.markAsDirty();
                            }
                            v.position += mirror(axis, mousePos - lastMousePos);
                        });
                    }
                    changed = true;
                    refreshMesh();
                }

                break;
            case VertexToolMode.Connect:
                assert(!deformOnly);
                if (selected.length == 0) {
                    incStatusTooltip(_("Select"), _("Left Mouse"));
                } else{
                    incStatusTooltip(_("Connect/Disconnect"), _("Left Mouse"));
                    incStatusTooltip(_("Connect Multiple"), _("Shift+Left Mouse"));
                }

                if (igIsMouseClicked(ImGuiMouseButton.Left)) {
                    if (vtxAtMouse !is null) {
                        auto prev = selectOne(vtxAtMouse);
                        if (prev !is null) {
                            if (prev != selected[$-1]) {

                                // Connect or disconnect between previous and this node
                                if (!prev.isConnectedTo(selected[$-1])) {
                                    foreachMirror((uint axis) {
                                        MeshVertex *mPrev = mirrorVertex(axis, prev);
                                        MeshVertex *mSel = mirrorVertex(axis, selected[$-1]);
                                        if (mPrev !is null && mSel !is null) mPrev.connect(mSel);
                                    });
                                    changed = true;
                                } else {
                                    foreachMirror((uint axis) {
                                        MeshVertex *mPrev = mirrorVertex(axis, prev);
                                        MeshVertex *mSel = mirrorVertex(axis, selected[$-1]);
                                        if (mPrev !is null && mSel !is null) mPrev.disconnect(mSel);
                                    });
                                    changed = true;
                                }
                                if (!io.KeyShift) deselectAll();
                            } else {

                                // Selecting the same vert twice unselects it
                                deselectAll();
                            }
                        }

                        refreshMesh();
                    } else {
                        // Clicking outside a vert deselect verts
                        deselectAll();
                    }
                }
                break;
            case VertexToolMode.PathDeform:
                if (deforming) {
                    incStatusTooltip(_("Deform"), _("Left Mouse"));
                    incStatusTooltip(_("Switch Mode"), _("TAB"));
                } else {
                    incStatusTooltip(_("Create/Destroy"), _("Left Mouse (x2)"));
                    incStatusTooltip(_("Switch Mode"), _("TAB"));
                }
                
                vtxAtMouse = null; // Do not need this in this mode

                if (incInputIsKeyPressed(ImGuiKey.Tab)) {
                    if (path.target is null) {
                        path.createTarget(mesh);
                        getCleanDeformAction();
                    } else {
                        if (deformAction !is null) {
                            pushDeformAction();
                            getCleanDeformAction();
                        }
                    }
                    deforming = !deforming;
                    if (deforming) {
                        getCleanDeformAction();
                        path.updateTarget(mesh);
                    }
                    else path.resetTarget(mesh);
                    changed = true;
                }

                CatmullSpline editPath = path;
                if (deforming) {
                    if (deformAction is null)
                        getCleanDeformAction();
                    editPath = path.target;
                }

                if (igIsMouseDoubleClicked(ImGuiMouseButton.Left) && !deforming) {
                    int idx = path.findPoint(mousePos);
                    if (idx != -1) path.removePoint(idx);
                    else path.addPoint(mousePos);
                    pathDragTarget = -1;
                    path.mapReference();
                } else if (igIsMouseClicked(ImGuiMouseButton.Left)) {
                    pathDragTarget = editPath.findPoint(mousePos);
                }

                if (igIsMouseDown(ImGuiMouseButton.Left) && incInputIsDragRequested(ImGuiMouseButton.Left)) {
                    if (pathDragTarget != -1)  {
                        isDragging = true;
                        getDeformAction();
                    }
                }

                if (isDragging && pathDragTarget != -1) {
                    editPath.points[pathDragTarget].position += mousePos - lastMousePos;
                    editPath.update();
                    if (deforming) {
                        path.updateTarget(mesh);
                        if (deformAction)
                            deformAction.markAsDirty();
                        changed = true;
                    } else {
                        path.mapReference();
                    }
                }

                if (changed) refreshMesh();

                break;
            default: assert(0);
        }

        if (isSelecting) {
            newSelected = mesh.getInRect(selectOrigin, mousePos);
            mutateSelection = io.KeyShift;
            invertSelection = io.KeyCtrl;
        }

        if (changed)
            mesh.changed = true;

        if (mesh.changed) {
            if (previewingTriangulation())
                previewMesh = mesh.autoTriangulate();
            mesh.changed = false;
        }
        return changed;
    }

    void draw(Camera camera) {
        mat4 trans = mat4.identity;
        if (deformOnly) trans = target.transform.matrix();

        if (vtxAtMouse !is null && !isSelecting) {
            MeshVertex*[] one = [vtxAtMouse];
            mesh.drawPointSubset(one, vec4(1, 1, 1, 0.3), trans, 15);
        }

        if (previewMesh) {
            previewMesh.drawLines(trans, vec4(0.7, 0.7, 0, 1));
            mesh.drawPoints(trans);
        } else {
            mesh.draw(trans);
        }

        if (selected.length) {
            if (isSelecting && !mutateSelection)
                mesh.drawPointSubset(selected, vec4(0.6, 0, 0, 1), trans);
            else
                mesh.drawPointSubset(selected, vec4(1, 0, 0, 1), trans);
        }

        if (mirrorSelected.length)
            mesh.drawPointSubset(mirrorSelected, vec4(1, 0, 1, 1), trans);

        if (isSelecting) {
            vec3[] rectLines = incCreateRectBuffer(selectOrigin, mousePos);
            inDbgSetBuffer(rectLines);
            if (!mutateSelection) inDbgDrawLines(vec4(1, 0, 0, 1), trans);
            else if(invertSelection) inDbgDrawLines(vec4(0, 1, 1, 0.8), trans);
            else inDbgDrawLines(vec4(0, 1, 0, 0.8), trans);

            if (newSelected.length) {
                if (mutateSelection && invertSelection)
                    mesh.drawPointSubset(newSelected, vec4(1, 0, 1, 1), trans);
                else
                    mesh.drawPointSubset(newSelected, vec4(1, 0, 0, 1), trans);
            }
        }

        vec2 camSize = camera.getRealSize();
        vec2 camPosition = camera.position;
        vec3[] axisLines;
        if (mirrorHoriz) {
            axisLines ~= incCreateLineBuffer(
                vec2(mirrorOrigin.x, -camSize.y - camPosition.y),
                vec2(mirrorOrigin.x, camSize.y - camPosition.y)
            );
        }
        if (mirrorVert) {
            axisLines ~= incCreateLineBuffer(
                vec2(-camSize.x - camPosition.x, mirrorOrigin.y),
                vec2(camSize.x - camPosition.x, mirrorOrigin.y)
            );
        }

        if (axisLines.length > 0) {
            inDbgSetBuffer(axisLines);
            inDbgDrawLines(vec4(0.8, 0, 0.8, 1), trans);
        }

        if (path && path.target && deforming) {
            path.draw(trans, vec4(0, 0.6, 0.6, 1));
            path.target.draw(trans, vec4(0, 1, 0, 1));
        } else if (path) {
            if (path.target) path.target.draw(trans, vec4(0, 0.6, 0, 1));
            path.draw(trans, vec4(0, 1, 1, 1));
        }
    }

    void viewportOverlay() {
        igPushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0));
            if (incButtonColored("", ImVec2(0, 0), getToolMode() == VertexToolMode.Points ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
                setToolMode(VertexToolMode.Points);
                path = null;
                refreshMesh();
            }
            incTooltip(_("Vertex Tool"));

            if (!deformOnly) {
                igSameLine(0, 0);
                if (incButtonColored("", ImVec2(0, 0), getToolMode() == VertexToolMode.Connect ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
                    setToolMode(VertexToolMode.Connect);
                    path = null;
                    refreshMesh();
                }
                incTooltip(_("Edge Tool"));
            }

            igSameLine(0, 0);
            if (incButtonColored("", ImVec2(0, 0), getToolMode() == VertexToolMode.PathDeform ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
                setToolMode(VertexToolMode.PathDeform);
                path = new CatmullSpline;
                deforming = false;
                refreshMesh();
            }
            incTooltip(_("Path Deform Tool"));

        igPopStyleVar();
    }


    CatmullSpline getPath() {
        return path;
    }
    void setPath(CatmullSpline path) {
        this.path = path;

    }
}