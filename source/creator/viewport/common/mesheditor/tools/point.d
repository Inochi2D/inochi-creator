module creator.viewport.common.mesheditor.tools.point;

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

class PointTool : NodeSelect {

    bool updateMeshEdit(ImGuiIO* io, IncMeshEditorOne impl, out bool changed) {
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
                foreach(v; impl.selected) {
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

                if (impl.isPointOver(impl.mousePos)) {
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
            onDragStart(impl.mousePos, impl);
        }

        onDragUpdate(impl.mousePos, impl);
        return true;
    }

    bool updateDeformEdit(ImGuiIO* io, IncMeshEditorOne impl, out bool changed) {

        incStatusTooltip(_("Select"), _("Left Mouse"));

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

        // Left click selection
        if (igIsMouseClicked(ImGuiMouseButton.Left)) {
            Action action;
            // Select / drag start
            action = impl.getCleanDeformAction();

            if (impl.isPointOver(impl.mousePos)) {
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
            impl.selectOne(impl.maybeSelectOne);
        }

        // Dragging
        if (incDragStartedInViewport(ImGuiMouseButton.Left) && igIsMouseDown(ImGuiMouseButton.Left) && incInputIsDragRequested(ImGuiMouseButton.Left)) {
            onDragStart(impl.mousePos, impl);
        }

        onDragUpdate(impl.mousePos, impl);
        return true;
    }


    override bool update(ImGuiIO* io, IncMeshEditorOne impl, out bool changed) {
        super.update(io, impl, changed);

        if (impl.deformOnly)
            updateDeformEdit(io, impl, changed);
        else
            updateMeshEdit(io, impl, changed);
        return changed;
    }

}