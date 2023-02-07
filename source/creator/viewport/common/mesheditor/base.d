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



    interface Tool(T) {
        bool update(ImGuiIO* io, IncMeshEditorOneImpl!T impl, out bool changed);
    }


    interface Draggable(T) {
        bool onDragStart(vec2 mousePos, IncMeshEditorOneImpl!T impl);
        bool onDragUpdate(vec2 mousePos, IncMeshEditorOneImpl!T impl);
        bool onDragEnd(vec2 mousePos, IncMeshEditorOneImpl!T impl);
    }


    class NodeSelect(T) : Draggable!T {
        override bool onDragStart(vec2 mousePos, IncMeshEditorOneImpl impl) {
            if (!impl.isSelecting) {
                impl.isDragging = true;
                impl.getDeformAction();
                return true;
            }
            return false;
        }

        override bool onDragEnd(vec2 mousePos, IncMeshEditorOneImpl impl) {
            impl.isDragging = false;
            if (impl.isSelecting) {
                if (impl.mutateSelection) {
                    if (!impl.invertSelection) {
                        foreach(v; impl.newSelected) {
                            auto idx = impl.selected.countUntil(v);
                            if (idx == -1) impl.selected ~= v;
                        }
                    } else {
                        foreach(v; impl.newSelected) {
                            auto idx = impl.selected.countUntil(v);
                            if (idx != -1) impl.selected = impl.selected.remove(idx);
                        }
                    }
                    impl.updateMirrorSelected();
                    impl.newSelected.length = 0;
                } else {
                    impl.selected = newSelected;
                    impl.newSelected = [];
                    impl.updateMirrorSelected();
                }

                impl.isSelecting = false;
            }
            impl.pushDeformAction();
            return true;
        }

        override bool onDragUpdate(vec2 mousePos, IncMeshEditorOneImpl impl) {
            if (impl.isDragging) {
                foreach(select; impl.selected) {
                    foreachMirror((uint axis) {
                        MeshVertex *v = impl.mirrorVertex(axis, select);
                        if (v is null) return;
                        impl.updateAddVertexAction(v);
                        impl.markActionDirty();
                        v.position += impl.mirror(axis, mousePos - impl.lastMousePos);
                    });
                }
                impl.refreshMesh();
                return true;
            }

            return false;
        }
    }


    class PointTool(T) : Tool!T {

        bool updateMeshEdit(ImGuiIO* io, IncMeshEditorOneImpl!T impl, out bool changed) {
            incStatusTooltip(_("Select"), _("Left Mouse"));
            incStatusTooltip(_("Create"), _("Ctrl+Left Mouse"));
            
            void addOrRemoveVertex(bool selectedOnly) {
                // Check if mouse is over a vertex
                if (impl.vtxAtMouse !is null) {
                    changed = impl.removeVertex(io, selectedOnly);
                } else {
                    changed = impl.addVertex(io);
                }
            }

            //FROM:-------------should be updateDeformEdit --------------------
            // Key actions
            if (incInputIsKeyPressed(ImGuiKey.Delete)) {
                impl.foreachMirror((uint axis) {
                    foreach(v; selected) {
                        MeshVertex *v2 = impl.mirrorVertex(axis, v);
                        if (v2 !is null) impl.removeMeshVertex(v2);
                    }
                });
                impl.selected = [];
                impl.updateMirrorSelected();
                impl.refreshMesh();
                impl.vertexMapDirty = true;
                changed = true;
            }
            void shiftSelection(vec2 delta) {
                float magnitude = 10.0;
                if (io.KeyAlt) magnitude = 1.0;
                else if (io.KeyShift) magnitude = 100.0;
                delta *= magnitude;

                impl.foreachMirror((uint axis) {
                    vec2 mDelta = impl.mirrorDelta(axis, delta);
                    foreach(v; impl.selected) {
                        MeshVertex *v2 = impl.mirrorVertex(axis, v);
                        if (v2 !is null) v2.position += mDelta;
                    }
                });
                impl.refreshMesh();
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
            //TO:-------------should be updateDeformEdit --------------------

            // Left click selection
            if (igIsMouseClicked(ImGuiMouseButton.Left)) {
                if (io.KeyCtrl && !io.KeyShift) {
                    // Add/remove action
                    addOrRemoveVertex(false);
                } else {
                    //FROM:-------------should be updateDeformEdit --------------------
                    Action action;
                    // Select / drag start
//                        action = getCleanDeformAction();

                    if (impl.isPointOver(mousePos)) {
                        if (io.KeyShift) impl.toggleSelect(impl.vtxAtMouse);
                        else if (!impl.isSelected(impl.vtxAtMouse))  impl.selectOne(impl.vtxAtMouse);
                        else impl.maybeSelectOne = impl.vtxAtMouse;
                    } else {
                        impl.selectOrigin = impl.mousePos;
                        impl.isSelecting = true;
                    }
                    //TO:-------------should be updateDeformEdit --------------------
                }
            }
            if (!impl.isDragging && !impl.isSelecting &&
                incInputIsMouseReleased(ImGuiMouseButton.Left) && impl.maybeSelectOne !is null) {
                impl.selectOne(impl.maybeSelectOne);
            }

            // Left double click action
            if (igIsMouseDoubleClicked(ImGuiMouseButton.Left) && !io.KeyShift && !io.KeyCtrl) {
                addOrRemoveVertex(true);
            }

            // Dragging
            if (incDragStartedInViewport(ImGuiMouseButton.Left) && igIsMouseDown(ImGuiMouseButton.Left) && incInputIsDragRequested(ImGuiMouseButton.Left)) {
                foreach (d; impl.draggables) {
                    if (d.onDragStart(mousePos, impl))
                        break;
                }
            }

            foreach (d; impl.draggables) {
                if (d.onDragUpdate(mousePos, impl)) {
                    changed = true;
                    break;
                }
            }
            return true;
        }

        bool updateDeformEdit(ImGuiIO* io, IncMeshEditorOneImpl!T impl, out bool changed) {

            incStatusTooltip(_("Select"), _("Left Mouse"));

            void shiftSelection(vec2 delta) {
                float magnitude = 10.0;
                if (io.KeyAlt) magnitude = 1.0;
                else if (io.KeyShift) magnitude = 100.0;
                delta *= magnitude;

                foreachMirror((uint axis) {
                    vec2 mDelta = impl.mirrorDelta(axis, delta);
                    foreach(v; impl.selected) {
                        MeshVertex *v2 = impl.mirrorVertex(axis, v);
                        if (v2 !is null) v2.position += mDelta;
                    }
                });
                impl.refreshMesh();
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
                Action action;
                // Select / drag start
                action = impl.getCleanDeformAction();

                if (impl.isPointOver(mousePos)) {
                    if (io.KeyShift) impl.toggleSelect(impl.vtxAtMouse);
                    else if (!impl.isSelected(impl.vtxAtMouse))  impl.selectOne(impl.vtxAtMouse);
                    else impl.maybeSelectOne = impl.vtxAtMouse;
                } else {
                    impl.selectOrigin = impl.mousePos;
                    impl.isSelecting = true;
                }
            }
            if (!impl.isDragging && !impl.isSelecting &&
                incInputIsMouseReleased(ImGuiMouseButton.Left) && impl.maybeSelectOne !is null) {
                impl.selectOne(maybeSelectOne);
            }

            // Dragging
            if (incDragStartedInViewport(ImGuiMouseButton.Left) && igIsMouseDown(ImGuiMouseButton.Left) && incInputIsDragRequested(ImGuiMouseButton.Left)) {
                foreach (d; impl.draggables) {
                    if (d.onDragStart(mousePos, impl))
                        break;
                }
            }

            foreach (d; impl.draggables) {
                if (d.onDragUpdate(mousePos, impl)) {
                    changed = true;
                    break;
                }
            }
            return true;
        }


        override bool update(ImGuiIO* io, IncMeshEditorOneImpl!T impl, out bool changed) {
            if (deformOnly)
                updateDeformEdit(io, impl, changed);
            else
                updateMeshEdit(io, impl, changed);
            return changed;
        }

    }


    class ConnectTool(T) : Tool!T {

        bool updateMeshEdit(ImGuiIO* io, IncMeshEditorOneImpl!T impl, out bool changed) {
            if (impl.selected.length == 0) {
                incStatusTooltip(_("Select"), _("Left Mouse"));
            } else{
                incStatusTooltip(_("Connect/Disconnect"), _("Left Mouse"));
                incStatusTooltip(_("Connect Multiple"), _("Shift+Left Mouse"));
            }

            if (igIsMouseClicked(ImGuiMouseButton.Left)) {
                if (impl.vtxAtMouse !is null) {
                    auto prev = impl.selectOne(impl.vtxAtMouse);
                    if (prev !is null) {
                        if (prev != impl.selected[$-1]) {

                            // Connect or disconnect between previous and this node
                            if (!prev.isConnectedTo(selected[$-1])) {
                                impl.foreachMirror((uint axis) {
                                    MeshVertex *mPrev = impl.mirrorVertex(axis, prev);
                                    MeshVertex *mSel = impl.mirrorVertex(axis, impl.selected[$-1]);
                                    if (mPrev !is null && mSel !is null) mPrev.connect(mSel);
                                });
                                changed = true;
                            } else {
                                impl.foreachMirror((uint axis) {
                                    MeshVertex *mPrev = impl.mirrorVertex(axis, prev);
                                    MeshVertex *mSel = impl.mirrorVertex(axis, selected[$-1]);
                                    if (mPrev !is null && mSel !is null) mPrev.disconnect(mSel);
                                });
                                changed = true;
                            }
                            if (!io.KeyShift) impl.deselectAll();
                        } else {

                            // Selecting the same vert twice unselects it
                            impl.deselectAll();
                        }
                    }

                    impl.refreshMesh();
                } else {
                    // Clicking outside a vert deselect verts
                    impl.deselectAll();
                }
            }
            return true;
        }

        override bool update(ImGuiIO* io, IncMeshEditorOneImpl!T impl, out bool changed) {
            if (!deformOnly)
                updateMeshEdit(io, impl, changed);
            return changed;
        }
    }


    class PathDeformTool(T) : Tool!T {

        override bool update(ImGuiIO* io, IncMeshEditorOneImpl!T impl, out bool changed) {
            if (impl.deforming) {
                incStatusTooltip(_("Deform"), _("Left Mouse"));
                incStatusTooltip(_("Switch Mode"), _("TAB"));
            } else {
                incStatusTooltip(_("Create/Destroy"), _("Left Mouse (x2)"));
                incStatusTooltip(_("Switch Mode"), _("TAB"));
            }
            
            impl.vtxAtMouse = null; // Do not need this in this mode

            if (incInputIsKeyPressed(ImGuiKey.Tab)) {
                if (impl.path.target is null) {
                    impl.createPathTarget();
                    impl.getCleanDeformAction();
                } else {
                    if (impl.hasAction()) {
                        impl.pushDeformAction();
                        impl.getCleanDeformAction();
                    }
                }
                impl.deforming = !impl.deforming;
                if (impl.deforming) {
                    impl.getCleanDeformAction();
                    impl.updatePathTarget();
                }
                else impl.resetPathTarget();
                changed = true;
            }

            CatmullSpline editPath = impl.path;
            if (impl.deforming) {
                if (!impl.hasAction())
                    impl.getCleanDeformAction();
                editPath = impl.path.target;
            }

            if (igIsMouseDoubleClicked(ImGuiMouseButton.Left) && !impl.deforming) {
                int idx = impl.path.findPoint(mousePos);
                if (idx != -1) impl.path.removePoint(idx);
                else impl.path.addPoint(mousePos);
                impl.pathDragTarget = -1;
                impl.path.mapReference();
            } else if (igIsMouseClicked(ImGuiMouseButton.Left)) {
                impl.pathDragTarget = editPath.findPoint(mousePos);
            }

            if (incDragStartedInViewport(ImGuiMouseButton.Left) && igIsMouseDown(ImGuiMouseButton.Left) && incInputIsDragRequested(ImGuiMouseButton.Left)) {
                if (impl.pathDragTarget != -1)  {
                    impl.isDragging = true;
                    impl.getDeformAction();
                }
            }

            if (impl.isDragging && impl.pathDragTarget != -1) {
                vec2 relTranslation = impl.mousePos - impl.lastMousePos;
                editPath.points[impl.pathDragTarget].position += relTranslation;

                editPath.update();
                if (impl.deforming) {
                    mat4 trans = impl.updatePathTarget();
                    if (impl.hasAction())
                        impl.markActionDirty();
                    changed = true;
                } else {
                    impl.path.mapReference();
                }
            }

            if (changed) impl.refreshMesh();
            return changed;
        }
    }

    Draggable!T[] draggables;
    Tool!T[VertexToolMode] tools;

public:
    this(bool deformOnly) {
        super(deformOnly);
        draggables = [new NodeSelect!T, ];
        tools[VertexToolMode.Points] = new PointTool!T;
        tools[VertexToolMode.Connect] = new ConnectTool!T;
        tools[VertexToolMode.PathDeform] = new PathDeformTool!T;
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
            foreach (d; draggables) {
                if (d.onDragEnd(mousePos, this))
                    break;
            }
        }

        if (igIsMouseClicked(ImGuiMouseButton.Left)) maybeSelectOne = null;

        if (toolMode in tools) {
            tools[toolMode].update(io, this, changed);
        } else {
            assert(0);
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