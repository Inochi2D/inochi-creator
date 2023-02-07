/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors:
    - Luna Nielsen
    - Asahi Lina
*/
module creator.viewport.common.mesheditor.base;

import i18n;
import creator.viewport;
import creator.viewport.common;
import creator.viewport.common.mesh;
import creator.viewport.common.spline;
import creator.core.input;
import creator.core.actionstack;
import creator.actions;
import creator.ext;
import creator.widgets;
import creator;
import inochi2d;
import inochi2d.core.dbg;
import bindbc.opengl;
import bindbc.imgui;
import std.algorithm.mutation;
import std.algorithm.searching;
import std.stdio;

enum VertexToolMode {
    Points,
    Connect,
    PathDeform,
}


class IncMeshEditorOne {
protected:
    abstract void substituteMeshVertices(MeshVertex* meshVertex);
    abstract MeshVertex* getVertexFromPoint(vec2 mousePos);
    abstract void removeVertexAt(vec2 vertex);
    abstract bool removeVertex(ImGuiIO* io, bool selectedOnly);
    abstract bool addVertex(ImGuiIO* io);
    abstract bool updateChanged(bool changed);
    abstract void removeMeshVertex(MeshVertex* v2);
    
    abstract bool isPointOver(vec2 mousePos);
    abstract MeshVertex*[] getInRect(vec2 min, vec2 max);
    abstract bool hasAction();
    abstract void updateAddVertexAction(MeshVertex* vertex);
    abstract void clearAction();
    abstract void markActionDirty();

    bool deformOnly = false;
    bool vertexMapDirty = false;

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
    float meshEditAOE = 4;

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
        MeshVertex* lastSel = null;
        if (selected.length > 0) {
            lastSel = selected[$-1];
        }
        selected = [vert];
        updateAddVertexAction(vert);
        if (lastSel)
            updateMirrorSelected();
        return lastSel;
    }

    void deselectAll() {
        selected.length = 0;
        clearAction();
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
        MeshVertex *v = getVertexFromPoint(mirror(axis, vtx.position));
        if (v is vtx) return null;
        return v;
    }

    bool isOnMirror(vec2 pos, float aoe) {
        return 
            (mirrorVert && pos.y > -aoe && pos.y < aoe) ||
            (mirrorHoriz && pos.x > -aoe && pos.x < aoe);
    }

    bool isOnMirrorCenter(vec2 pos, float aoe) {
        return 
            (mirrorVert && pos.y > -aoe && pos.y < aoe) &&
            (mirrorHoriz && pos.x > -aoe && pos.x < aoe);
    }

    void placeOnMirror(vec2 pos, float aoe) {
        if (isOnMirror(pos, aoe)) {
            if (mirrorHoriz && mirrorVert && isOnMirrorCenter(pos, aoe)) pos = vec2(0, 0);
            else if (mirrorVert) pos.y = 0;
            else if (mirrorHoriz) pos.x = 0;
            substituteMeshVertices(new MeshVertex(pos));
        }
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
        foreach (v; mirrorSelected) {
            updateAddVertexAction(v);
        }
        selected = tmpSelected;
    }


public:
    bool previewTriangulate = false;
    bool mirrorHoriz = false;
    bool mirrorVert = false;
    vec2 mirrorOrigin = vec2(0, 0);
    mat4 transform = mat4.identity;

    this(bool deformOnly) {
        this.deformOnly = deformOnly;
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

    abstract Node getTarget();
    abstract void setTarget(Node target);
    abstract void resetMesh();
    abstract void refreshMesh();
    abstract void importMesh(MeshData data);
    abstract void applyOffsets(vec2[] offsets);
    abstract vec2[] getOffsets();

    abstract void applyToTarget();
    abstract void applyPreview();
    abstract void createPathTarget();
    abstract mat4 updatePathTarget();
    abstract void resetPathTarget();
    abstract void remapPathTarget(ref CatmullSpline p, mat4 trans);

    abstract void pushDeformAction();
    abstract Action getDeformAction();
    abstract Action getCleanDeformAction();
    abstract void forceResetAction();


    abstract bool update(ImGuiIO* io, Camera camera);
    abstract void draw(Camera camera);

    CatmullSpline getPath() {
        return path;
    }

    void setPath(CatmullSpline path) {
        this.path = path;
    }

    abstract void viewportTools(VertexToolMode mode);

    abstract void adjustPathTransform();

}


class IncMeshEditorOneImpl(T) : IncMeshEditorOne {
protected:
    T target;

/*
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
        MeshVertex* lastSel = null;
        if (selected.length > 0) {
            lastSel = selected[$-1];
        }
        selected = [vert];
        updateAddVertexAction(vert);
        if (lastSel)
            updateMirrorSelected();
        return lastSel;
    }

    void deselectAll() {
        selected.length = 0;
        clearAction();
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
        MeshVertex *v = getVertexFromPoint(mirror(axis, vtx.position));
        if (v is vtx) return null;
        return v;
    }

    bool isOnMirror(vec2 pos, float aoe) {
        return 
            (mirrorVert && pos.y > -aoe && pos.y < aoe) ||
            (mirrorHoriz && pos.x > -aoe && pos.x < aoe);
    }

    bool isOnMirrorCenter(vec2 pos, float aoe) {
        return 
            (mirrorVert && pos.y > -aoe && pos.y < aoe) &&
            (mirrorHoriz && pos.x > -aoe && pos.x < aoe);
    }

    void placeOnMirror(vec2 pos, float aoe) {
        if (isOnMirror(pos, aoe)) {
            if (mirrorHoriz && mirrorVert && isOnMirrorCenter(pos, aoe)) pos = vec2(0, 0);
            else if (mirrorVert) pos.y = 0;
            else if (mirrorHoriz) pos.x = 0;
            substituteMeshVertices(new MeshVertex(pos));
        }
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
        foreach (v; mirrorSelected) {
            updateAddVertexAction(v);
        }
        selected = tmpSelected;
    }
*/


public:
    this(bool deformOnly) {
        super(deformOnly);
    }

    override
    Node getTarget() {
        return target;
    }

    override
    void setTarget(Node target) {
        this.target = cast(T)(target);
    }

    override
    bool update(ImGuiIO* io, Camera camera) {
        bool changed = false;

        lastMousePos = mousePos;

        mousePos = incInputGetMousePosition();
        if (deformOnly) {
            vec4 pIn = vec4(-mousePos.x, -mousePos.y, 0, 1);
            mat4 tr = transform.inverse();
            vec4 pOut = tr * pIn;
            mousePos = vec2(pOut.x, pOut.y);
        } else {
            mousePos = -mousePos;
        }

        vtxAtMouse = getVertexFromPoint(mousePos);

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
                        changed = removeVertex(io, selectedOnly);
                    } else {
                        changed = addVertex(io);
                    }
                }

                // Key actions
                if (!deformOnly && incInputIsKeyPressed(ImGuiKey.Delete)) {
                    foreachMirror((uint axis) {
                        foreach(v; selected) {
                            MeshVertex *v2 = mirrorVertex(axis, v);
                            if (v2 !is null) removeMeshVertex(v2);
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
                        Action action;
                        // Select / drag start
                        if (deformOnly) {
                            action = getCleanDeformAction();
                        } 

                        if (isPointOver(mousePos)) {
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
                if (incDragStartedInViewport(ImGuiMouseButton.Left) && igIsMouseDown(ImGuiMouseButton.Left) && incInputIsDragRequested(ImGuiMouseButton.Left)) {
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
                            updateAddVertexAction(v);
                            markActionDirty();
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
                        createPathTarget();
                        getCleanDeformAction();
                    } else {
                        if (hasAction()) {
                            pushDeformAction();
                            getCleanDeformAction();
                        }
                    }
                    deforming = !deforming;
                    if (deforming) {
                        getCleanDeformAction();
                        updatePathTarget();
                    }
                    else resetPathTarget();
                    changed = true;
                }

                CatmullSpline editPath = path;
                if (deforming) {
                    if (!hasAction())
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

                if (incDragStartedInViewport(ImGuiMouseButton.Left) && igIsMouseDown(ImGuiMouseButton.Left) && incInputIsDragRequested(ImGuiMouseButton.Left)) {
                    if (pathDragTarget != -1)  {
                        isDragging = true;
                        getDeformAction();
                    }
                }

                if (isDragging && pathDragTarget != -1) {
                    vec2 relTranslation = mousePos - lastMousePos;
                    editPath.points[pathDragTarget].position += relTranslation;

                    editPath.update();
                    if (deforming) {
                        mat4 trans = updatePathTarget();
                        if (hasAction())
                            markActionDirty();
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
            newSelected = getInRect(selectOrigin, mousePos);
            mutateSelection = io.KeyShift;
            invertSelection = io.KeyCtrl;
        }

        return updateChanged(changed);
    }

    override
    void viewportTools(VertexToolMode mode) {
        switch (mode) {
        case VertexToolMode.Points:
            setToolMode(VertexToolMode.Points);
            path = null;
            refreshMesh();
            break;
        case VertexToolMode.Connect:
            setToolMode(VertexToolMode.Connect);
            path = null;
            refreshMesh();
            break;
        case VertexToolMode.PathDeform:
            import std.stdio;
            setToolMode(VertexToolMode.PathDeform);
            path = new CatmullSpline;
            deforming = false;
            refreshMesh();
            break;
        default:       
        }
    }
}