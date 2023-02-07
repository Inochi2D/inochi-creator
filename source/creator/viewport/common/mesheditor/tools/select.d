module creator.viewport.common.mesheditor.tools.select;

import creator.viewport.common.mesheditor.tools.base;
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

class NodeSelect : Tool, Draggable {

    override
    void setToolMode(VertexToolMode toolMode, IncMeshEditorOne impl) {
        assert(!impl.deformOnly || toolMode != VertexToolMode.Connect);
        impl.isDragging = false;
        impl.isSelecting = false;
        impl.deselectAll();
    }


    override bool update(ImGuiIO* io, IncMeshEditorOne impl, out bool changed) {
        impl.lastMousePos = impl.mousePos;

        impl.mousePos = incInputGetMousePosition();
        if (impl.deformOnly) {
            vec4 pIn = vec4(-impl.mousePos.x, -impl.mousePos.y, 0, 1);
            mat4 tr = impl.transform.inverse();
            vec4 pOut = tr * pIn;
           impl. mousePos = vec2(pOut.x, pOut.y);
        } else {
            impl.mousePos = -impl.mousePos;
        }

        impl.vtxAtMouse = impl.getVertexFromPoint(impl.mousePos);

        if (incInputIsMouseReleased(ImGuiMouseButton.Left)) {
            onDragEnd(impl.mousePos, impl);
        }

        if (igIsMouseClicked(ImGuiMouseButton.Left)) impl.maybeSelectOne = null;
        return false;
    }

    override bool onDragStart(vec2 mousePos, IncMeshEditorOne impl) {
        if (!impl.isSelecting) {
            impl.isDragging = true;
            impl.getDeformAction();
            return true;
        }
        return false;
    }

    override bool onDragEnd(vec2 mousePos, IncMeshEditorOne impl) {
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
                impl.selected = impl.newSelected;
                impl.newSelected = [];
                impl.updateMirrorSelected();
            }

            impl.isSelecting = false;
        }
        impl.pushDeformAction();
        return true;
    }

    override bool onDragUpdate(vec2 mousePos, IncMeshEditorOne impl) {
        if (impl.isDragging) {
            foreach(select; impl.selected) {
                impl.foreachMirror((uint axis) {
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

    override
    void draw(Camera camera, IncMeshEditorOne impl) {
    }
}