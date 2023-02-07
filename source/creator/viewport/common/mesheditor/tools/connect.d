module creator.viewport.common.mesheditor.tools.connect;

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

class ConnectTool : NodeSelect {

    bool updateMeshEdit(ImGuiIO* io, IncMeshEditorOne impl, out bool changed) {
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
                        if (!prev.isConnectedTo(impl.selected[$-1])) {
                            impl.foreachMirror((uint axis) {
                                MeshVertex *mPrev = impl.mirrorVertex(axis, prev);
                                MeshVertex *mSel = impl.mirrorVertex(axis, impl.selected[$-1]);
                                if (mPrev !is null && mSel !is null) mPrev.connect(mSel);
                            });
                            changed = true;
                        } else {
                            impl.foreachMirror((uint axis) {
                                MeshVertex *mPrev = impl.mirrorVertex(axis, prev);
                                MeshVertex *mSel = impl.mirrorVertex(axis, impl.selected[$-1]);
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

    override bool update(ImGuiIO* io, IncMeshEditorOne impl, out bool changed) {
        super.update(io, impl, changed);
        if (!impl.deformOnly)
            updateMeshEdit(io, impl, changed);
        return changed;
    }
}