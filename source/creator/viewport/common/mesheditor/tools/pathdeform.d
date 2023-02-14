module creator.viewport.common.mesheditor.tools.pathdeform;
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

    override bool update(ImGuiIO* io, IncMeshEditorOne impl, int action, out bool changed) {
        super.update(io, impl, action, changed);

        if (incInputIsMouseReleased(ImGuiMouseButton.Left)) {
            onDragEnd(impl.mousePos, impl);
        }

        if (igIsMouseClicked(ImGuiMouseButton.Left)) impl.maybeSelectOne = null;
        
        if (impl.deforming) {
            incStatusTooltip(_("Deform"), _("Left Mouse"));
            incStatusTooltip(_("Switch Mode"), _("TAB"));
        } else {
            incStatusTooltip(_("Create/Destroy"), _("Left Mouse (x2)"));
            incStatusTooltip(_("Switch Mode"), _("TAB"));
        }
        incStatusTooltip(_("Toggle locked point"), _("Ctrl"));
        incStatusTooltip(_("Move point along with the path"), _("Shift"));
        
        impl.vtxAtMouse = null; // Do not need this in this mode

        if (incInputIsKeyPressed(ImGuiKey.Tab)) {
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

        if (igIsMouseDoubleClicked(ImGuiMouseButton.Left) && !impl.deforming) {
            int idx = path.findPoint(impl.mousePos);
            if (idx != -1) path.removePoint(idx);
            else path.addPoint(impl.mousePos);
            pathDragTarget = -1;
            lockedPoint    = -1;
            path.mapReference();
        } else if (igIsMouseClicked(ImGuiMouseButton.Left)) {
            auto target = editPath.findPoint(impl.mousePos);
            if (io.KeyCtrl) {
                if (target == lockedPoint)
                    lockedPoint = -1;
                else
                    lockedPoint = target;
                pathDragTarget = -1;
            } else {
                pathDragTarget = target;
            }
        }

        if (incDragStartedInViewport(ImGuiMouseButton.Left) && igIsMouseDown(ImGuiMouseButton.Left) && incInputIsDragRequested(ImGuiMouseButton.Left)) {
            if (pathDragTarget != -1)  {
                isDragging = true;
                impl.getDeformAction();
            }
        }

        if (isDragging && pathDragTarget != -1) {
            if (pathDragTarget != lockedPoint) {
                if (lockedPoint != -1) {
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
                } else if (io.KeyShift) {
                    float off = path.findClosestPointOffset(impl.mousePos);
                    vec2 pos  = path.eval(off);
                    editPath.points[pathDragTarget].position = pos;
                } else {
                    vec2 relTranslation = impl.mousePos - impl.lastMousePos;
                    editPath.points[pathDragTarget].position += relTranslation;
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
            }
        }

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

}