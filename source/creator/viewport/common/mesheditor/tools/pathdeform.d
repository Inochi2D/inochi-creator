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

class PathDeformTool : NodeSelect {

    CatmullSpline path;
    uint pathDragTarget;

    override
    void setToolMode(VertexToolMode toolMode, IncMeshEditorOne impl) {
        pathDragTarget = -1;
        super.setToolMode(toolMode, impl);
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
            path.mapReference();
        } else if (igIsMouseClicked(ImGuiMouseButton.Left)) {
            pathDragTarget = editPath.findPoint(impl.mousePos);
        }

        if (incDragStartedInViewport(ImGuiMouseButton.Left) && igIsMouseDown(ImGuiMouseButton.Left) && incInputIsDragRequested(ImGuiMouseButton.Left)) {
            if (pathDragTarget != -1)  {
                isDragging = true;
                impl.getDeformAction();
            }
        }

        if (isDragging && pathDragTarget != -1) {
            vec2 relTranslation = impl.mousePos - impl.lastMousePos;
            editPath.points[pathDragTarget].position += relTranslation;

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

        if (changed) impl.refreshMesh();
        return changed;
    }

    override
    void draw(Camera camera, IncMeshEditorOne impl) {
        super.draw(camera, impl);

        if (path && path.target && impl.deforming) {
            path.draw(impl.transform, vec4(0, 0.6, 0.6, 1));
            path.target.draw(impl.transform, vec4(0, 1, 0, 1));
        } else if (path) {
            if (path.target) path.target.draw(impl.transform, vec4(0, 0.6, 0, 1));
            path.draw(impl.transform, vec4(0, 1, 1, 1));
        }
    }

}