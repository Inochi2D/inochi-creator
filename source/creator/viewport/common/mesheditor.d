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

private:
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
    abstract void remapPathTarget(ref CatmullSpline p);

    abstract void pushDeformAction();
    abstract Action getDeformAction();
    abstract Action getCleanDeformAction();


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
private:
    T target;

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
//            mat4 tr = target.transform.matrix().inverse();
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
            transform = target ? target.transform.matrix : mat4.identity;
            deforming = false;
            refreshMesh();
            break;
        default:       
        }
    }

    void updatePathTransformPosition(mat4 trans) {
        ref CatmullSpline doAdjust(ref CatmullSpline p) {
            for (int i; i < p.points.length; i++) {
                p.points[i].position = (trans * vec4(p.points[i].position, 0, 1)).xy;
            }
            p.update();
            return p;
        }
        if (path) {
            if (path.target)
                path.target = doAdjust(path.target);
            path = doAdjust(path);
        }
        lastMousePos = (trans * vec4(lastMousePos, 0, 1)).xy;
        transform = trans.inverse() * transform;

    }

    override
    void adjustPathTransform() {
        mat4 invTr = transform;
        mat4 tr    = this.target.transform.matrix.inverse();
        ref CatmullSpline doAdjust(ref CatmullSpline p) {
            for (int i; i < p.points.length; i++) {
                p.points[i].position = (tr * (invTr * vec4(p.points[i].position, 0, 1))).xy;
            }
            p.update();
            remapPathTarget(p);
            return p;
        }
        if (path) {
            if (path.target)
                path.target = doAdjust(path.target);
            path = doAdjust(path);
        }
        lastMousePos = (tr * invTr * vec4(lastMousePos, 0, 1)).xy;
        transform = this.target.transform.matrix;
    }

}


class IncMeshEditorOneDrawable : IncMeshEditorOneImpl!Drawable {
protected:
    override
    void substituteMeshVertices(MeshVertex* meshVertex) {
        mesh.vertices ~= meshVertex;
    }
private:
    IncMesh previewMesh;
    MeshEditorAction!DeformationAction editorAction = null;

public:
    IncMesh mesh;

    this(bool deformOnly) {
        super(deformOnly);
        this.deformOnly = deformOnly;
    }

    override
    void setTarget(Node target) {
        Drawable drawable = cast(Drawable)target;
        if (drawable is null)
            return;
        super.setTarget(target);
        mesh = new IncMesh(drawable.getMesh());
        refreshMesh();
    }

    ref IncMesh getMesh() {
        return mesh;
    }

    override
    void resetMesh() {
        mesh.reset();
    }

    override
    void refreshMesh() {
        mesh.refresh();
        if (previewingTriangulation()) {
            previewMesh = mesh.autoTriangulate();
        } else {
            previewMesh = null;
        }
        updateMirrorSelected();
    }

    override
    void importMesh(MeshData data) {
        mesh.import_(data);
        mesh.refresh();
    }

    override
    void applyOffsets(vec2[] offsets) {
        assert(deformOnly);

        mesh.applyOffsets(offsets);
    }

    override
    vec2[] getOffsets() {
        assert(deformOnly);

        return mesh.getOffsets();
    }

    override
    void applyToTarget() {
        // Apply the model
        auto action = new DrawableChangeAction(target.name, target);

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

        if (vertexMapDirty) {
            void alterDeform(ParameterBinding binding) {
                auto deformBinding = cast(DeformationParameterBinding)binding;
                if (!deformBinding)
                    return;
                foreach (uint x; 0..cast(uint)deformBinding.values.length) {
                    foreach (uint y; 0..cast(uint)deformBinding.values[x].length) {
                        auto deform = deformBinding.values[x][y];
                        if (deformBinding.isSet(vec2u(x, y))) {
                            auto newDeform = mesh.deformByDeformationBinding(deformBinding, vec2u(x, y), false);
                            if (newDeform) 
                                deformBinding.values[x][y] = *newDeform;
                        }
                    }
                }
                deformBinding.reInterpolate();
            }

            foreach (param; incActivePuppet().parameters) {
                if (auto group = cast(ExParameterGroup)param) {
                    foreach(x, ref xparam; group.children) {
                        ParameterBinding binding = xparam.getBinding(target, "deform");
                        if (binding)
                            action.addAction(new ParameterChangeBindingsAction("Deformation recalculation on mesh update", xparam, null));
                        alterDeform(binding);
                    }
                } else {
                    ParameterBinding binding = param.getBinding(target, "deform");
                    if (binding)
                        action.addAction(new ParameterChangeBindingsAction("Deformation recalculation on mesh update", param, null));
                    alterDeform(binding);
                }
            }
            vertexMapDirty = false;
        }

        target.rebuffer(data);

        action.updateNewState();
        incActionPush(action);
    }

    override
    void applyPreview() {
        mesh = previewMesh;
        previewMesh = null;
        previewTriangulate = false;
    }

    override
    void pushDeformAction() {
        if (editorAction && editorAction.action.dirty) {
            editorAction.updateNewState();
            incActionPush(editorAction);
            editorAction = null;
        }        
    }

    override
    MeshVertex* getVertexFromPoint(vec2 mousePos) {
        return mesh.getVertexFromPoint(mousePos);
    }

    override
    void removeVertexAt(vec2 vertex) {
        mesh.removeVertexAt(vertex); // mirror(axis, mousePos)
    }

    override
    bool removeVertex(ImGuiIO* io, bool selectedOnly) {
        // In the case that it is, double clicking would remove an item
        if (!selectedOnly || isSelected(vtxAtMouse)) {
            foreachMirror((uint axis) {
                removeVertexAt(mirror(axis, mousePos));
            });
            refreshMesh();
            vertexMapDirty = true;
            selected.length = 0;
            updateMirrorSelected();
            maybeSelectOne = null;
            vtxAtMouse = null;
            return true;
        }
        return false;
    }

    override
    bool addVertex(ImGuiIO* io) {
        ulong off = mesh.vertices.length;
        if (isOnMirror(mousePos, meshEditAOE)) {
            placeOnMirror(mousePos, meshEditAOE);
        } else {
            foreachMirror((uint axis) {
                substituteMeshVertices(new MeshVertex(mirror(axis, mousePos)));
            });
        }
        refreshMesh();
        vertexMapDirty = true;
        if (io.KeyCtrl) selectOne(mesh.vertices[$-1]);
        else selectOne(mesh.vertices[off]);
        return true;
    }

    override
    bool updateChanged(bool changed) {
        if (changed)
            mesh.changed = true;

        if (mesh.changed) {
            if (previewingTriangulation())
                previewMesh = mesh.autoTriangulate();
            mesh.changed = false;
        }
        return changed;
    }

    override
    void removeMeshVertex(MeshVertex* v2) {
        mesh.remove(v2);
    }

    override
    bool isPointOver(vec2 mousePos) {
        return mesh.isPointOverVertex(mousePos);
    }

    override
    MeshVertex*[] getInRect(vec2 min, vec2 max) { 
        return mesh.getInRect(selectOrigin, mousePos);
    }

    override
    void createPathTarget() {
        path.createTarget(mesh);
    }

    override
    mat4 updatePathTarget() {
        return path.updateTarget(mesh);
    }

    override
    void resetPathTarget() {
        path.resetTarget(mesh);
    }

    override
    void remapPathTarget(ref CatmullSpline p) {
        p.remapTarget(mesh);
    }

    override
    bool hasAction() { return editorAction !is null; }

    override
    void updateAddVertexAction(MeshVertex* vertex) {
        if (editorAction) {
            editorAction.action.addVertex(vertex);
        }
    }

    override
    void clearAction() {
        if (editorAction)
            editorAction.action.clear();
    }

    override
    void markActionDirty() {
        if (editorAction)
            editorAction.action.markAsDirty();
    }

    Action getDeformActionImpl(bool reset = false)() {
        if (reset)
            pushDeformAction();
        if (editorAction is null || !editorAction.action.isApplyable()) {
            auto deformAction = new DeformationAction(target.name, target);
            switch (toolMode) {
            case VertexToolMode.PathDeform:
                editorAction = new MeshEditorPathDeformAction!DeformationAction(target, deformAction);
                break;
            default:
                editorAction = new MeshEditorAction!DeformationAction(target, deformAction);
            }

        } else {
            if (reset)
                editorAction.clear();
        }
        return editorAction;
    }

    override
    Action getDeformAction() {
        return getDeformActionImpl!false();
    }

    override
    Action getCleanDeformAction() {
        return getDeformActionImpl!true();
    }

    override
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
}


import std.stdio;
class IncMeshEditorOneNode : IncMeshEditorOneImpl!Node {
protected:
    override
    void substituteMeshVertices(MeshVertex* meshVertex) {
        translation = meshVertex.position;
        target.setValue("transform.t.x", translation.x);
        target.setValue("transform.t.y", translation.y);
    }
private:
    vec2 translation;
    MeshEditorAction!GroupAction editorAction;
public:
    float selectRadius = 16f;
    this(bool deformOnly) {
        super(deformOnly);
        this.deformOnly = deformOnly;
    }

    override
    void setTarget(Node target) {
        super.setTarget(target);
        refreshMesh();
    }

    override
    void resetMesh() {
        translation = vec2(target.getValue("transform.t.x"), target.getValue("transform.t.y"));
    }

    override
    void refreshMesh() {
        translation = vec2(target.getValue("transform.t.x"), target.getValue("transform.t.y"));
    }

    override void importMesh(MeshData data) {}

    override
    void applyOffsets(vec2[] offsets) {
        assert(deformOnly);
        translation = offsets[0];
    }

    override
    vec2[] getOffsets() {
        assert(deformOnly);
        return [translation];
    }

    override
    void applyToTarget() {
        auto action = new GroupAction();

        if (vertexMapDirty) {
            void alterDeform(ParameterBinding binding, float value) {
                auto deformBinding = cast(ValueParameterBinding)binding;
                if (!deformBinding)
                    return;
                foreach (uint x; 0..cast(uint)deformBinding.values.length) {
                    foreach (uint y; 0..cast(uint)deformBinding.values[x].length) {
                        auto deform = deformBinding.values[x][y];
                        if (deformBinding.isSet(vec2u(x, y))) {
                            deformBinding.values[x][y] = value;
                        }
                    }
                }
                deformBinding.reInterpolate();
            }

            foreach (param; incActivePuppet().parameters) {
                if (auto group = cast(ExParameterGroup)param) {
                    foreach(x, ref xparam; group.children) {
                        ParameterBinding binding = xparam.getBinding(target, "transform.t.x");
                        if (binding)
                            action.addAction(new ParameterChangeBindingsAction("Deformation of translation", xparam, null));
                        alterDeform(binding, translation.x);
                        binding = xparam.getBinding(target, "transform.t.y");
                        if (binding)
                            action.addAction(new ParameterChangeBindingsAction("Deformation of translation", xparam, null));
                        alterDeform(binding, translation.y);
                    }
                } else {
                    ParameterBinding binding = param.getBinding(target, "transform.t.x");
                    if (binding)
                        action.addAction(new ParameterChangeBindingsAction("Deformation of translation", param, null));
                    alterDeform(binding, translation.x);
                    binding = param.getBinding(target, "transform.t.y");
                    if (binding)
                        action.addAction(new ParameterChangeBindingsAction("Deformation of translation", param, null));
                    alterDeform(binding, translation.y);
                }
            }
            vertexMapDirty = false;
        }
        incActionPush(action);
    }

    override void applyPreview() { }

    Action getDeformActionImpl(bool reset = false)() {
        auto armedParam = incArmedParameter();
        vec2u index = armedParam.findClosestKeypoint();
        void registerBinding(string name, GroupAction groupAction) {
            ValueParameterBinding binding = cast(ValueParameterBinding)armedParam.getBinding(target, name);
            if (binding is null) {
                binding = cast(ValueParameterBinding)armedParam.createBinding(target, name);
                armedParam.addBinding(binding);
                groupAction.addAction(new ParameterBindingAddAction(armedParam, binding));
            }
            auto transAction = new ParameterBindingValueChangeAction!float(binding.getName(), binding, index.x, index.y);
            groupAction.addAction(transAction);
            p.update();
            p.remapTarget(mesh);
            return p;
        }
        if (reset)
            pushDeformAction();
        if (editorAction is null) {
            GroupAction groupAction = new GroupAction();
            registerBinding("transform.t.x", groupAction);
            registerBinding("transform.t.y", groupAction);
            registerBinding("transform.r.z", groupAction);
            switch (toolMode) {
            case VertexToolMode.PathDeform:
                editorAction = new MeshEditorPathDeformAction!GroupAction(target, groupAction);
                break;
            default:
                editorAction = new MeshEditorAction!GroupAction(target, groupAction);
            }
        } else {
            if (reset) {
                editorAction.action.actions.length = 0;
                registerBinding("transform.t.x", editorAction.action);
                registerBinding("transform.t.y", editorAction.action);
                registerBinding("transform.r.z", editorAction.action);
            }
        }
        return editorAction;
    }

    override
    Action getDeformAction() {
        return getDeformActionImpl!false();
    }

    override
    Action getCleanDeformAction() {
        return getDeformActionImpl!true();
    }

    override
    void pushDeformAction() {
        if (editorAction !is null) {
            bool dirty = false;
            foreach (action; editorAction.action.actions) {
                auto changeAction = cast(ParameterBindingValueChangeAction!float)action;
                if (changeAction !is null) {
                    dirty = dirty || changeAction.dirty();
                    if (dirty)
                        break;
                }
            }
            if (dirty) {
                editorAction.updateNewState();
                foreach (a; editorAction.action.actions) {
                    if (auto laction = cast(LazyBoundAction)a)
                        laction.updateNewState();
                }
                incActionPush(editorAction);
                editorAction = null;
            }
        }
    }

    override
    MeshVertex* getVertexFromPoint(vec2 mousePos) {
        if (abs(translation.distance(mousePos)) < selectRadius/incViewportZoom) return new MeshVertex(translation, []);
        return null;
    }

    override void removeVertexAt(vec2 vertex) {}
    override bool removeVertex(ImGuiIO* io, bool selectedOnly) { return false; }
    override bool addVertex(ImGuiIO* io) { return false; }
    override bool updateChanged(bool changed) { return changed; }
    override void removeMeshVertex(MeshVertex* v2) {}

    override
    bool isPointOver(vec2 mousePos) {
        if (abs(translation.distance(mousePos)) < selectRadius/incViewportZoom) return true;
        return false;
    }

    override
    MeshVertex*[] getInRect(vec2 min, vec2 max) { 
        if (min.x > max.x) swap(min.x, max.x);
        if (min.y > max.y) swap(min.y, max.y);

        if (min.x > translation.x) return [];
        if (min.y > translation.y) return [];
        if (max.x < translation.x) return [];
        if (max.y < translation.y) return [];
        return [new MeshVertex(translation)];
    }

    override
    void createPathTarget() {
        path.createTarget(target);
    }

    override
    mat4 updatePathTarget() {
        return path.updateTarget(target);
    }

    override
    void resetPathTarget() {
        path.resetTarget(target);
    }

    override
    void remapPathTarget(ref CatmullSpline p) {
        p.remapTarget(target);
    }

    override
    bool hasAction() { return editorAction !is null; }

    override
    void updateAddVertexAction(MeshVertex* vertex) {
    }

    override
    void clearAction() {
        if (editorAction) {
            foreach (action; editorAction.action.actions) {
                auto changeAction = cast(ParameterBindingValueChangeAction!float)action;
                if (changeAction)
                    changeAction.clear();
            }

        }
    }

    override
    void markActionDirty() {
        foreach (action; editorAction.action.actions) {
            auto changeAction = cast(ParameterBindingValueChangeAction!float)action;
            if (changeAction)
                changeAction.markAsDirty();
        }
    }

    override
    void draw(Camera camera) {
        mat4 trans = mat4.identity;
        if (deformOnly) trans = target.transform.matrix();

        if (vtxAtMouse !is null && !isSelecting) {
            MeshVertex*[] one = [vtxAtMouse];
//            mesh.drawPointSubset(one, vec4(1, 1, 1, 0.3), trans, 15);
        }

        if (isSelecting) {
            vec3[] rectLines = incCreateRectBuffer(selectOrigin, mousePos);
            inDbgSetBuffer(rectLines);
        }

        if (path && path.target && deforming) {
            path.draw(transform, vec4(0, 0.6, 0.6, 1));
            path.target.draw(transform, vec4(0, 1, 0, 1));
        } else if (path) {
            if (path.target) path.target.draw(transform, vec4(0, 0.6, 0, 1));
            path.draw(transform, vec4(0, 1, 1, 1));
        }
    }
}


class IncMeshEditor {
private:
    IncMeshEditorOne[Node] editors;
    bool previewTriangulate = false;
    bool mirrorHoriz = false;
    bool mirrorVert = false;
    VertexToolMode toolMode = VertexToolMode.Points;

public:
    bool deformOnly;

    this(bool deformOnly) {
        this.deformOnly = deformOnly;
    }

    void setTarget(Node target) {
        if (target is null) {
        } else {
            addTarget(target);
        }
    }

    IncMeshEditorOne getEditorFor(Node drawing) {
        if (drawing in editors)
            return editors[drawing];
        return null;
    }

    void addTarget(Node target) {
        if (target in editors)
            return;
        IncMeshEditorOneDrawable subEditor = new IncMeshEditorOneDrawable(deformOnly);
        subEditor.setTarget(target);
        subEditor.mirrorHoriz = mirrorHoriz;
        subEditor.mirrorVert  = mirrorVert;
        subEditor.previewTriangulate = previewTriangulate;
        editors[target] = subEditor;
    }

    void setTargets(Node[] targets) {
        IncMeshEditorOne[Node] newEditors;
        foreach (t; targets) {
            if (t in editors) {
                newEditors[t] = editors[t];
            } else {
                Drawable drawable = cast(Drawable)t;
                IncMeshEditorOne subEditor = null;
                if (drawable) {
                    subEditor = new IncMeshEditorOneDrawable(deformOnly);
                    (cast(IncMeshEditorOneDrawable)subEditor).setTarget(drawable);
                } else {
                    subEditor = new IncMeshEditorOneNode(deformOnly);
                    (cast(IncMeshEditorOneNode)subEditor).setTarget(t);
                }
                subEditor.mirrorHoriz = mirrorHoriz;
                subEditor.mirrorVert  = mirrorVert;
                subEditor.previewTriangulate = previewTriangulate;
                newEditors[t] = subEditor;
            }
        }
        editors = newEditors;
    }

    void removeTarget(Node target) {
        if (target in editors)
            editors.remove(target);
    }

    Node[] getTargets() {
        return editors.keys();
    }

    void refreshMesh() {
        foreach (drawing, editor; editors) {
            editor.refreshMesh();
        }
    }

    void resetMesh() {
        foreach (drawing, editor; editors) {
            editor.resetMesh();
        }
    }

    void applyPreview() {
        foreach (drawing, editor; editors) {
            editor.applyPreview();
        }
    }

    void applyToTarget() {
        foreach (drawing, editor; editors) {
            editor.applyToTarget();
        }
    }

    bool update(ImGuiIO* io, Camera camera) {
        bool result = false;
        incActionPushGroup();
        foreach (drawing, editor; editors) {
            result = editor.update(io, camera) || result;
        }
        incActionPopGroup();
        return result;
    }


    void draw(Camera camera) {
        foreach (drawing, editor; editors) {
            editor.draw(camera);
        }
    }

    void setToolMode(VertexToolMode toolMode) {
        this.toolMode = toolMode;
        foreach (drawing, editor; editors) {
            editor.setToolMode(toolMode);
        }
    }

    VertexToolMode getToolMode() {
        return toolMode;
    }

    void viewportTools() {
        igSetWindowFontScale(1.30);
            igPushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(1, 1));
            igPushStyleVar(ImGuiStyleVar.FramePadding, ImVec2(8, 10));
                if (incButtonColored("", ImVec2(0, 0), getToolMode() == VertexToolMode.Points ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
                    setToolMode(VertexToolMode.Points);
                    foreach (e; editors)
                        e.viewportTools(VertexToolMode.Points);
                }
                incTooltip(_("Vertex Tool"));

                if (!deformOnly) {
                    if (incButtonColored("", ImVec2(0, 0), getToolMode() == VertexToolMode.Connect ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
                        setToolMode(VertexToolMode.Connect);
                        foreach (e; editors)
                            e.viewportTools(VertexToolMode.Connect);
                    }
                    incTooltip(_("Edge Tool"));
                }

                if (incButtonColored("", ImVec2(0, 0), getToolMode() == VertexToolMode.PathDeform ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
                    setToolMode(VertexToolMode.PathDeform);
                    foreach (e; editors)
                        e.viewportTools(VertexToolMode.PathDeform);
                }
                incTooltip(_("Path Deform Tool"));

            igPopStyleVar(2);
        igSetWindowFontScale(1);
    }

    void setMirrorHoriz(bool mirrorHoriz) {
        this.mirrorHoriz = mirrorHoriz;
        foreach (e; editors) {
            e.mirrorHoriz = mirrorHoriz;
        }
    }

    bool getMirrorHoriz() {
        return mirrorHoriz;
    }

    void setMirrorVert(bool mirrorVert) {
        this.mirrorVert = mirrorVert;
        foreach (e; editors) {
            e.mirrorHoriz = mirrorVert;
        }
    }

    bool getMirrorVert() {
        return mirrorVert;
    }

    void setPreviewTriangulate(bool previewTriangulate) {
        this.mirrorVert = mirrorVert;
        foreach (e; editors) {
            e.previewTriangulate = previewTriangulate;
        }
    }

    bool getPreviewTriangulate() {
        return previewTriangulate;
    }

    bool previewingTriangulation() {
        foreach (e; editors) {
            if (!e.previewingTriangulation())
                return false;
        }
        return true;
    }

}

