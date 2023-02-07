module creator.viewport.common.mesheditor.tools.pathdeform;
import creator.viewport.common.mesheditor.tools.select;
import creator.viewport.common.mesheditor.base;
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

    override bool update(ImGuiIO* io, IncMeshEditorOne impl, out bool changed) {
        super.update(io, impl, changed);
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
            int idx = impl.path.findPoint(impl.mousePos);
            if (idx != -1) impl.path.removePoint(idx);
            else impl.path.addPoint(impl.mousePos);
            impl.pathDragTarget = -1;
            impl.path.mapReference();
        } else if (igIsMouseClicked(ImGuiMouseButton.Left)) {
            impl.pathDragTarget = editPath.findPoint(impl.mousePos);
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