module creator.viewport.common.mesheditor.tools.connect;

import creator.viewport.common.mesheditor.tools.enums;
import creator.viewport.common.mesheditor.tools.base;
import creator.viewport.common.mesheditor.tools.select;
import creator.viewport.common.mesheditor.operations;
import i18n;
import creator.viewport;
import creator.viewport.common;
import creator.viewport.common.mesh;
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
import std.stdio;

class ConnectTool : NodeSelect {

    bool updateMeshEdit(ImGuiIO* io, IncMeshEditorOne impl, out bool changed) {

        if (incInputIsMouseReleased(ImGuiMouseButton.Left)) {
            onDragEnd(impl.mousePos, impl);
        }

        if (igIsMouseClicked(ImGuiMouseButton.Left)) impl.maybeSelectOne = ulong(-1);

        if (impl.selected.length == 0) {
            incStatusTooltip(_("Select"), _("Left Mouse"));
        } else{
            incStatusTooltip(_("Connect/Disconnect"), _("Left Mouse"));
            incStatusTooltip(_("Connect Multiple"), _("Shift+Left Mouse"));
        }

        if (igIsMouseClicked(ImGuiMouseButton.Left)) {
            if (impl.vtxAtMouse != ulong(-1)) {
                auto prevIndex = impl.selectOne(impl.vtxAtMouse);
                auto prev = impl.getVerticesByIndex([prevIndex])[0];
                auto lastSelected = impl.getVerticesByIndex([impl.selected[$-1]])[0];
                if (prev !is null) {
                    if (prevIndex != impl.selected[$-1]) {
                        auto implDrawable = cast(IncMeshEditorOneDrawable)(impl);
                        auto mesh = implDrawable.getMesh();

                        // Connect or disconnect between previous and this node
                        if (!prev.isConnectedTo(lastSelected)) {
                            auto action = new MeshConnectAction(impl.getTarget().name, impl, mesh);
                            impl.foreachMirror((uint axis) {
                                MeshVertex*[] mPrevSel = impl.getVerticesByIndex([impl.mirrorVertex(axis, prevIndex), impl.mirrorVertex(axis, impl.selected[$-1])]);
                                MeshVertex* mPrev = mPrevSel[0];
                                MeshVertex* mSel  = mPrevSel[1];
                                if (mPrev !is null && mSel !is null) {
                                    action.connect(mPrev, mSel);
//                                    mPrev.connect(mSel);
                                }
                            });
                            action.updateNewState();
                            incActionPush(action);
                            changed = true;
                        } else {
                            auto action = new MeshDisconnectAction(impl.getTarget().name, impl, mesh);
                            impl.foreachMirror((uint axis) {
                                MeshVertex*[] mPrevSel = impl.getVerticesByIndex([impl.mirrorVertex(axis, prevIndex), impl.mirrorVertex(axis, impl.selected[$-1])]);
                                MeshVertex* mPrev = mPrevSel[0];
                                MeshVertex* mSel  = mPrevSel[1];
                                if (mPrev !is null && mSel !is null) {
                                    action.disconnect(mPrev, mSel);
//                                    mPrev.disconnect(mSel);
                                }
                            });
                            action.updateNewState();
                            incActionPush(action);
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

    override bool update(ImGuiIO* io, IncMeshEditorOne impl, int action, out bool changed) {
        super.update(io, impl, action, changed);

        if (!impl.deformOnly)
            updateMeshEdit(io, impl, changed);
        return changed;
    }
}

class ToolInfoImpl(T: ConnectTool) : ToolInfoBase!(T) {
    override
    bool viewportTools(bool deformOnly, VertexToolMode toolMode, IncMeshEditorOne[Node] editors) {
        if (!deformOnly)
            return super.viewportTools(deformOnly, toolMode, editors);
        return false;
    }
    override VertexToolMode mode() { return VertexToolMode.Connect; };
    override string icon() { return "";}
    override string description() { return _("Path Deform Tool");}
}