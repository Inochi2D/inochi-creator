module creator.viewport.common.mesheditor.tools.pathdeform;

import creator.viewport.common.mesheditor.tools.enums;
import creator.viewport.common.mesheditor.tools.base;
import creator.viewport.common.mesheditor.tools.select;
import creator.viewport.common.mesheditor.operations;
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
import std.math;

class PathDeformTool : NodeSelect {
    CatmullSpline path;
    uint pathDragTarget;
    uint lockedPoint;

    enum Mode {
        Define,
        Transform
    }

    enum PathDeformActionID {
        SwitchMode = cast(int)(SelectActionID.End),
        RemovePoint,
        AddPoint,
        TranslatePoint,
        StartTransform,
        StartShiftTransform,
        Transform,
        Rotate,
        SetRotateCenter,
        UnsetRotateCenter,
        Shift
    }

    Mode mode = Mode.Define;
    Mode prevMode = Mode.Define;
    bool _isShiftMode = false;
    bool _isRotateMode = false;

    override
    void setToolMode(VertexToolMode toolMode, IncMeshEditorOne impl) {
        pathDragTarget = -1;
        lockedPoint = -1;
        super.setToolMode(toolMode, impl);
    }

    void setPath(CatmullSpline path) {
        if (path is null || this.path != path) {
            this.path = path;
            pathDragTarget = -1;
            lockedPoint = -1;
        }
    }

    Mode getMode() { return mode; }
    void setMode(Mode mode) { this.mode = mode; }
    bool getIsShiftMode() { return _isShiftMode; }
    void setIsShiftMode(bool value) { _isShiftMode = value; }
    bool getIsRotateMode() { return _isRotateMode; }
    void setIsRotateMode(bool value) { _isRotateMode = value; }

    override 
    int peek(ImGuiIO* io, IncMeshEditorOne impl) {
        super.peek(io, impl);

        if (incInputIsMouseReleased(ImGuiMouseButton.Left)) {
            if (impl.isSelecting)
                impl.adjustPathTransform();
            onDragEnd(impl.mousePos, impl);
        }

        if (igIsMouseClicked(ImGuiMouseButton.Left)) impl.maybeSelectOne = ulong(-1);
        

        if (mode != prevMode || incInputIsKeyPressed(ImGuiKey.Tab)) {
            return PathDeformActionID.SwitchMode;
        }

        CatmullSpline editPath = path;
        if (impl.deforming) {
            if (!impl.hasAction())
                impl.getCleanDeformAction();
            editPath = path.target;
        }

        if (igIsMouseDoubleClicked(ImGuiMouseButton.Left) && !impl.deforming) {
            int idx = path.findPoint(impl.mousePos);
            if (idx != -1) return PathDeformActionID.RemovePoint;
            else return PathDeformActionID.AddPoint;

        } else if (igIsMouseClicked(ImGuiMouseButton.Left)) {
            auto target = editPath.findPoint(impl.mousePos);
            if (target != -1 && (io.KeyCtrl || _isRotateMode)) {
                if (target == lockedPoint)
                    return PathDeformActionID.UnsetRotateCenter;
                else if (target != -1)
                    return PathDeformActionID.SetRotateCenter;
            } else {
                pathDragTarget = target;
            }
        }

        int action = SelectActionID.None;

        bool preDragging = isDragging;
        if (incDragStartedInViewport(ImGuiMouseButton.Left) && igIsMouseDown(ImGuiMouseButton.Left) && incInputIsDragRequested(ImGuiMouseButton.Left)) {
            if (pathDragTarget != -1)  {
                isDragging = true;
            }
        }

        if (isDragging && pathDragTarget != -1) {
            if (pathDragTarget != lockedPoint) {
                if (lockedPoint != -1) {
                    action = PathDeformActionID.Rotate;
                } else if (io.KeyShift || _isShiftMode) {
                    if (isDragging != preDragging)
                        action = PathDeformActionID.StartShiftTransform;
                    else
                        action = PathDeformActionID.Shift;
                } else {
                    if (isDragging != preDragging)
                        action = PathDeformActionID.StartTransform;
                    else
                        action = PathDeformActionID.Transform;
                }
            }
        }

        if (action != SelectActionID.None)
            return action;

        if (pathDragTarget == -1 && io.KeyAlt) {
            // Left click selection
            if (igIsMouseClicked(ImGuiMouseButton.Left)) {
                if (impl.isPointOver(impl.mousePos)) {
                    if (io.KeyShift) return SelectActionID.ToggleSelect;
                    else if (!impl.isSelected(impl.vtxAtMouse))  return SelectActionID.SelectOne;
                    else return SelectActionID.MaybeSelectOne;
                } else {
                    return SelectActionID.SelectArea;
                }
            }
            if (!isDragging && !impl.isSelecting &&
                incInputIsMouseReleased(ImGuiMouseButton.Left) && impl.maybeSelectOne != ulong(-1)) {
                return SelectActionID.SelectMaybeSelectOne;
            }

            // Dragging
            if (incDragStartedInViewport(ImGuiMouseButton.Left) && igIsMouseDown(ImGuiMouseButton.Left) && incInputIsDragRequested(ImGuiMouseButton.Left)) {
                if (!impl.isSelecting) {
                    return SelectActionID.StartDrag;
                }
            }
        }

        return SelectActionID.None;

    }

    override
    int unify(int[] actions) {
        int[int] priorities;
        priorities[PathDeformActionID.SwitchMode] = 2;
        priorities[PathDeformActionID.RemovePoint] = 1;
        priorities[PathDeformActionID.AddPoint] = 1;
        priorities[PathDeformActionID.TranslatePoint] = 0;
        priorities[PathDeformActionID.StartTransform] = 0;
        priorities[PathDeformActionID.StartShiftTransform] = 0;
        priorities[PathDeformActionID.Shift] = 0;
        priorities[PathDeformActionID.Transform] = 0;
        priorities[PathDeformActionID.Rotate] = 0;
        priorities[PathDeformActionID.SetRotateCenter] = 0;
        priorities[PathDeformActionID.UnsetRotateCenter] = 0;
        priorities[SelectActionID.None]                 = 10;
        priorities[SelectActionID.SelectArea]           = 5;
        priorities[SelectActionID.ToggleSelect]         = 2;
        priorities[SelectActionID.SelectOne]            = 2;
        priorities[SelectActionID.MaybeSelectOne]       = 2;
        priorities[SelectActionID.StartDrag]            = 2;
        priorities[SelectActionID.SelectMaybeSelectOne] = 2;

        int action = SelectActionID.None;
        int curPriority = priorities[action];
        foreach (a; actions) {
            auto newPriority = priorities[a];
            if (newPriority < curPriority) {
                curPriority = newPriority;
                action = a;
            }
        }
        return action;

    }

    override 
    bool update(ImGuiIO* io, IncMeshEditorOne impl, int action, out bool changed) {

        if (impl.deforming) {
            incStatusTooltip(_("Deform"), _("Left Mouse"));
            incStatusTooltip(_("Switch Mode"), _("TAB"));
        } else {
            incStatusTooltip(_("Create/Destroy"), _("Left Mouse (x2)"));
            incStatusTooltip(_("Switch Mode"), _("TAB"));
        }
        incStatusTooltip(_("Toggle locked point"), _("Ctrl"));
        incStatusTooltip(_("Move point along with the path"), _("Shift"));
        
        if (action == PathDeformActionID.SwitchMode) {
            if (path.target is null) {
                impl.createPathTarget();
                impl.getCleanDeformAction();
            } else {
                if (impl.hasAction()) {
                    impl.pushDeformAction();
                    impl.getCleanDeformAction();
                }
            }
            impl.deforming = !impl.deforming;
            mode = impl.deforming? Mode.Transform: Mode.Define;
            if (impl.deforming) {
                impl.getCleanDeformAction();
                impl.updatePathTarget();
            }
            else impl.resetPathTarget();
            changed = true;
        }

        CatmullSpline editPath = path;
        if (impl.deforming) {
            if (!impl.hasAction())
                impl.getCleanDeformAction();
            editPath = path.target;
        }

        if (action == PathDeformActionID.StartTransform || action == PathDeformActionID.StartShiftTransform) {
            auto deform = (cast(MeshEditorAction!DeformationAction)(impl.getDeformAction()));
            if(deform !is null) deform.clear();
        }

        if (action == PathDeformActionID.RemovePoint || action == PathDeformActionID.AddPoint) {
            if (action == PathDeformActionID.RemovePoint) {
                int idx = path.findPoint(impl.mousePos);
                if(idx != -1) path.removePoint(idx);
            } else if (action == PathDeformActionID.AddPoint) {
                path.addPoint(impl.mousePos);
            }
            pathDragTarget = -1;
            lockedPoint    = -1;
            path.mapReference();

        } else if (action == PathDeformActionID.UnsetRotateCenter) {
            lockedPoint = -1;
            pathDragTarget = -1;
            _isRotateMode = false;

        } else if (action == PathDeformActionID.SetRotateCenter) {
            auto target = editPath.findPoint(impl.mousePos);
            lockedPoint = target;
            pathDragTarget = -1;
            _isRotateMode = false;

        } else if (action == PathDeformActionID.Rotate) {
            int step = (pathDragTarget > lockedPoint)? 1: -1;
            vec2 prevRelPosition = impl.lastMousePos - editPath.points[lockedPoint].position;
            vec2 relPosition     = impl.mousePos - editPath.points[lockedPoint].position;
            float prevAngle = atan2(prevRelPosition.y, prevRelPosition.x);
            float angle     = atan2(relPosition.y, relPosition.x);
            float relAngle = angle - prevAngle;
            mat4 rotate = mat4.identity.translate(vec3(-editPath.points[lockedPoint].position, 0)).rotateZ(relAngle).translate(vec3(editPath.points[lockedPoint].position, 0));

            for (int i = lockedPoint + step; 0 <= i && i < editPath.points.length; i += step) {
                editPath.points[i].position = (rotate * vec4(editPath.points[i].position, 0, 1)).xy;
            }

        } else if (action == PathDeformActionID.Shift || action == PathDeformActionID.StartShiftTransform) {
            if(pathDragTarget != -1){
                float off = path.findClosestPointOffset(impl.mousePos);
                vec2 pos  = path.eval(off);
                editPath.points[pathDragTarget].position = pos;
            }
        
        } else if (action == PathDeformActionID.Transform || action == PathDeformActionID.StartTransform) {
            if(pathDragTarget != -1){
                vec2 relTranslation = impl.mousePos - impl.lastMousePos;
                editPath.points[pathDragTarget].position += relTranslation;
            }
        }

        editPath.update();
        if (impl.deforming) {
            mat4 trans = impl.updatePathTarget();
            if (impl.hasAction())
                impl.markActionDirty();
            changed = true;
        } else {
            path.mapReference();
        }

        this.prevMode = this.mode;

        // Left click selection
        if (action == SelectActionID.ToggleSelect) {
            if (impl.vtxAtMouse != ulong(-1))
                impl.toggleSelect(impl.vtxAtMouse);
        } else if (action == SelectActionID.SelectOne) {
            if (impl.vtxAtMouse != ulong(-1))
                impl.selectOne(impl.vtxAtMouse);
            else
                impl.deselectAll();
        } else if (action == SelectActionID.MaybeSelectOne) {
            if (impl.vtxAtMouse != ulong(-1))
                impl.maybeSelectOne = impl.vtxAtMouse;
        } else if (action == SelectActionID.SelectArea) {
            impl.selectOrigin = impl.mousePos;
            impl.isSelecting = true;
        }

        if (action == SelectActionID.SelectMaybeSelectOne) {
            if (impl.maybeSelectOne != ulong(-1))
                impl.selectOne(impl.maybeSelectOne);
        }

        // Dragging
        if (action == SelectActionID.StartDrag) {
            onDragStart(impl.mousePos, impl);
        }

        this.prevMode = this.mode;

        if (changed) impl.refreshMesh();
        return changed;
    }

    override
    void draw(Camera camera, IncMeshEditorOne impl) {
        super.draw(camera, impl);

        if (path && path.target && impl.deforming) {
            path.draw(impl.transform, vec4(0, 0.6, 0.6, 1), lockedPoint);
            path.target.draw(impl.transform, vec4(0, 1, 0, 1), lockedPoint);
        } else if (path) {
            if (path.target) path.target.draw(impl.transform, vec4(0, 0.6, 0, 1), lockedPoint);
            path.draw(impl.transform, vec4(0, 1, 1, 1), lockedPoint);
        }
    }

    override
    MeshEditorAction!DeformationAction editorAction(Node target, DeformationAction action) {
        return new MeshEditorPathDeformAction!(DeformationAction)(target, action);
    }

    override
    MeshEditorAction!GroupAction editorAction(Node target, GroupAction action) {
        return new MeshEditorPathDeformAction!(GroupAction)(target, action);
    }

    override
    MeshEditorAction!DeformationAction editorAction(Drawable target, DeformationAction action) {
        return new MeshEditorPathDeformAction!(DeformationAction)(target, action);
    }

    override
    MeshEditorAction!GroupAction editorAction(Drawable target, GroupAction action) {
        return new MeshEditorPathDeformAction!(GroupAction)(target, action);
    }
}

class PathDeformToolInfo : ToolInfoBase!PathDeformTool {
    override
    void setupToolMode(IncMeshEditorOne e, VertexToolMode mode) {
        e.setToolMode(mode);
        e.setPath(new CatmullSpline);
        e.deforming = false;
        e.refreshMesh();
    }

    override
    bool viewportTools(bool deformOnly, VertexToolMode toolMode, IncMeshEditorOne[Node] editors) {
        if (deformOnly) {
            return super.viewportTools(deformOnly, toolMode, editors);
        }
        return false;
    }
    
    override
    bool displayToolOptions(bool deformOnly, VertexToolMode toolMode, IncMeshEditorOne[Node] editors) { 
        igPushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0));
        igPushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(4, 4));
        auto deformTool = cast(PathDeformTool)(editors.length == 0 ? null: editors.values()[0].getTool());
        igBeginGroup();
            if (incButtonColored("", ImVec2(0, 0), (deformTool !is null && deformTool.mode == PathDeformTool.Mode.Define)? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) { // path definition
                foreach (e; editors) {
                    auto deform = cast(PathDeformTool)(e.getTool());
                    if (deform !is null)
                        deform.setMode(PathDeformTool.Mode.Define);
                }
            }
            incTooltip(_("Define paths"));

            igSameLine(0, 0);

            if (incButtonColored("", ImVec2(0, 0), (deformTool !is null && deformTool.mode == PathDeformTool.Mode.Transform) ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) { // path deformation
                foreach (e; editors) {
                    auto deform = cast(PathDeformTool)(e.getTool());
                    if (deform !is null)
                        deform.setMode(PathDeformTool.Mode.Transform);
                }
            }
            incTooltip(_("Transform path"));
        igEndGroup();

        igSameLine(0, 4);

        igBeginGroup();
            if (incButtonColored("", ImVec2(0, 0), (deformTool !is null && deformTool.getIsRotateMode()) ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) { // rotation mode
                foreach (e; editors) {
                    auto deform = cast(PathDeformTool)(e.getTool());
                    if (deform !is null)
                        deform.setIsRotateMode(!deform.getIsRotateMode());
                }
            }
            incTooltip(_("Set rotation center"));
        igEndGroup();

        igSameLine(0, 4);

        igBeginGroup();
            if (incButtonColored("", ImVec2(0, 0), (deformTool !is null && deformTool.getIsShiftMode()) ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) { // move shift
                foreach (e; editors) {
                    auto deform = cast(PathDeformTool)(e.getTool());
                    if (deform !is null)
                        deform.setIsShiftMode(!deform.getIsShiftMode());
                }
            }
            incTooltip(_("Move points along the path"));
        igEndGroup();
        igPopStyleVar(2);
        return false;
    }
    override VertexToolMode mode() { return VertexToolMode.PathDeform; }
    override string icon() { return "";}
    override string description() { return _("Path Deform Tool");}
}