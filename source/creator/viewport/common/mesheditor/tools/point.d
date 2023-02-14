module creator.viewport.common.mesheditor.tools.point;

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

class PointTool : NodeSelect {
    Action action;

    override bool onDragStart(vec2 mousePos, IncMeshEditorOne impl) {
        if (!impl.deformOnly) {
            if (!impl.isSelecting && !isDragging) {
                auto implDrawable = cast(IncMeshEditorOneDrawable)impl;
                auto mesh = implDrawable.getMesh();

                isDragging = true;
                action = new MeshMoveAction(impl.getTarget().name, impl, mesh);
                return true;
            }
            return false;
        } else
            return super.onDragStart(mousePos, impl);
    }

    override bool onDragEnd(vec2 mousePos, IncMeshEditorOne impl) {
        if (!impl.deformOnly) {
            if (action !is null) {
                if (auto meshAction = cast(MeshAction)(action)) {
                    if (meshAction.dirty) {
                        meshAction.updateNewState();
                        incActionPush(action);
                    }
                }
                action = null;
            }
        }
        return super.onDragEnd(mousePos, impl);
    }

    override bool onDragUpdate(vec2 mousePos, IncMeshEditorOne impl) {
        if (!impl.deformOnly) { 
            if (isDragging) {
                if (auto meshAction = cast(MeshMoveAction)action) {
                    foreach(select; impl.selected) {
                        impl.foreachMirror((uint axis) {
                            MeshVertex *v = impl.mirrorVertex(axis, select);
                            if (v is null) return;
                            meshAction.moveVertex(v, v.position + impl.mirror(axis, mousePos - impl.lastMousePos));
                        });
                    }
                }

                if (impl.selected.length > 0)
                    impl.maybeSelectOne = null;
                impl.refreshMesh();
                return true;
            }
            return false;
        } else {
            return super.onDragUpdate(mousePos, impl);
        }
    }

    enum PointActionID {
        Add = cast(int)(SelectActionID.End),
        Remove,
        Translate,
        TranslateUp,
        TranslateDown,
        TranslateLeft,
        TranslateRight,
        End
    }


    bool updateMeshEdit(ImGuiIO* io, IncMeshEditorOne impl, out bool changed) {
        incStatusTooltip(_("Select"), _("Left Mouse"));
        incStatusTooltip(_("Create"), _("Ctrl+Left Mouse"));

        if (incInputIsMouseReleased(ImGuiMouseButton.Left)) {
            onDragEnd(impl.mousePos, impl);
        }

        if (igIsMouseClicked(ImGuiMouseButton.Left)) impl.maybeSelectOne = null;

        auto implDrawable = cast(IncMeshEditorOneDrawable)impl;
        auto mesh = implDrawable.getMesh();

        assert(implDrawable !is null);
        
        void addOrRemoveVertex(bool selectedOnly) {
            // Check if mouse is over a vertex
            if (impl.vtxAtMouse !is null) {
                auto action = new MeshRemoveAction(impl.getTarget().name, impl, mesh);

                if (!selectedOnly || impl.isSelected(impl.vtxAtMouse)) {
                    impl.foreachMirror((uint axis) {
                        MeshVertex* vertex = mesh.getVertexFromPoint(impl.mirror(axis, impl.mousePos));
                        action.removeVertex(vertex);
                    });
                    impl.refreshMesh();
                    impl.vertexMapDirty = true;
                    impl.selected.length = 0;
                    impl.updateMirrorSelected();
                    impl.maybeSelectOne = null;
                    impl.vtxAtMouse = null;
                    changed = true;
                }

                action.updateNewState();
                incActionPush(action);
            } else {
                auto action = new MeshAddAction(impl.getTarget().name, impl, mesh);

                ulong off = mesh.vertices.length;
                if (impl.isOnMirror(impl.mousePos, impl.meshEditAOE)) {
                    impl.placeOnMirror(impl.mousePos, impl.meshEditAOE);
                } else {
                    impl.foreachMirror((uint axis) {
                        MeshVertex* vertex = new MeshVertex(impl.mirror(axis, impl.mousePos));
                        action.addVertex(vertex);
                    });
                }
                impl.refreshMesh();
                impl.vertexMapDirty = true;
                if (io.KeyCtrl) impl.selectOne(mesh.vertices[$-1]);
                else impl.selectOne(mesh.vertices[off]);
                changed = true;

                action.updateNewState();
                incActionPush(action);
            }
        }

        // Key actions
        if (incInputIsKeyPressed(ImGuiKey.Delete)) {
            auto action = new MeshRemoveAction(impl.getTarget().name, impl, mesh);

            impl.foreachMirror((uint axis) {
                foreach(v; impl.selected) {
                    MeshVertex *v2 = impl.mirrorVertex(axis, v);
                    if (v2 !is null) {
                        action.removeVertex(v2);
                    }
                }
            });

            action.updateNewState();
            incActionPush(action);

            impl.selected = [];
            impl.updateMirrorSelected();
            impl.refreshMesh();
            impl.vertexMapDirty = true;
            changed = true;
        }

        MeshMoveAction moveAction = null;
        void shiftSelection(vec2 delta) {
            float magnitude = 10.0;
            if (io.KeyAlt) magnitude = 1.0;
            else if (io.KeyShift) magnitude = 100.0;
            delta *= magnitude;

            impl.foreachMirror((uint axis) {
                vec2 mDelta = impl.mirrorDelta(axis, delta);
                foreach(v; impl.selected) {
                    MeshVertex *v2 = impl.mirrorVertex(axis, v);
                    if (v2 !is null) {
                        if (moveAction is null) {
                            moveAction = new MeshMoveAction(implDrawable.getTarget().name, impl, mesh);
                        }
                        moveAction.moveVertex(v2, v2.position + mDelta);
                    }
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

        if (moveAction !is null) {
            moveAction.updateNewState();
            incActionPush(moveAction);
        }

        // Left click selection
        if (igIsMouseClicked(ImGuiMouseButton.Left)) {
            if (io.KeyCtrl && !io.KeyShift) {
                // Add/remove action
                addOrRemoveVertex(false);
            } else {
                // Select / drag start
                if (impl.isPointOver(impl.mousePos)) {
                    if (io.KeyShift) impl.toggleSelect(impl.vtxAtMouse);
                    else if (!impl.isSelected(impl.vtxAtMouse))  impl.selectOne(impl.vtxAtMouse);
                    else impl.maybeSelectOne = impl.vtxAtMouse;
                } else {
                    impl.selectOrigin = impl.mousePos;
                    impl.isSelecting = true;
                }
            }
        }
        if (!isDragging && !impl.isSelecting &&
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


    int peekDeformEdit(ImGuiIO* io, IncMeshEditorOne impl) {

        if (incInputIsMouseReleased(ImGuiMouseButton.Left)) {
            onDragEnd(impl.mousePos, impl);
        }

        if (igIsMouseClicked(ImGuiMouseButton.Left)) impl.maybeSelectOne = null;

        if (incInputIsKeyPressed(ImGuiKey.LeftArrow)) {
            return PointActionID.TranslateLeft;
        } else if (incInputIsKeyPressed(ImGuiKey.RightArrow)) {
            return PointActionID.TranslateRight;
        } else if (incInputIsKeyPressed(ImGuiKey.DownArrow)) {
            return PointActionID.TranslateDown;
        } else if (incInputIsKeyPressed(ImGuiKey.UpArrow)) {
            return PointActionID.TranslateUp;
        }

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
            incInputIsMouseReleased(ImGuiMouseButton.Left) && impl.maybeSelectOne !is null) {
            return SelectActionID.SelectMaybeSelectOne;
        }


        if (isDragging) {
            return PointActionID.Translate;
        }

        // Dragging
        if (incDragStartedInViewport(ImGuiMouseButton.Left) && igIsMouseDown(ImGuiMouseButton.Left) && incInputIsDragRequested(ImGuiMouseButton.Left)) {
            if (!impl.isSelecting) {
                return SelectActionID.StartDrag;
            }
        }

        return SelectActionID.None;
    }

    bool updateDeformEdit(ImGuiIO* io, IncMeshEditorOne impl, int action, out bool changed) {

        incStatusTooltip(_("Select"), _("Left Mouse"));

        bool keyboardMoved = false;
        void shiftSelection(vec2 delta) {
            float magnitude = 10.0;
            if (io.KeyAlt) magnitude = 1.0;
            else if (io.KeyShift) magnitude = 100.0;
            delta *= magnitude;

            impl.foreachMirror((uint axis) {
                vec2 mDelta = impl.mirrorDelta(axis, delta);
                foreach(v; impl.selected) {
                    MeshVertex *v2 = impl.mirrorVertex(axis, v);
                    impl.getDeformAction();
                    impl.updateAddVertexAction(v);
                    impl.markActionDirty();
                    keyboardMoved = true;
                    if (v2 !is null) v2.position += mDelta;
                }
            });
            impl.refreshMesh();
            changed = true;
        }

        if (action == PointActionID.TranslateLeft) {
            shiftSelection(vec2(-1, 0));
        } else if (action == PointActionID.TranslateRight) {
            shiftSelection(vec2(1, 0));
        } else if (action == PointActionID.TranslateDown) {
            shiftSelection(vec2(0, 1));
        } else if (action == PointActionID.TranslateUp) {
            shiftSelection(vec2(0, -1));
        }
        if (keyboardMoved)
            impl.pushDeformAction();

        // Left click selection
        if (action == SelectActionID.ToggleSelect) {
            if (impl.vtxAtMouse)
                impl.toggleSelect(impl.vtxAtMouse);
        } else if (action == SelectActionID.SelectOne) {  
            if (impl.vtxAtMouse)
                impl.selectOne(impl.vtxAtMouse);
            else
                impl.deselectAll();
        } else if (action == SelectActionID.MaybeSelectOne) {
            if (impl.vtxAtMouse)
                impl.maybeSelectOne = impl.vtxAtMouse;
        } else if (action == SelectActionID.SelectArea) {
            impl.selectOrigin = impl.mousePos;
            impl.isSelecting = true;
        }

        if (action == SelectActionID.SelectMaybeSelectOne) {
            if (impl.maybeSelectOne !is null)
                impl.selectOne(impl.maybeSelectOne);
        }

        // Dragging
        if (action == SelectActionID.StartDrag) {
            onDragStart(impl.mousePos, impl);
        }

        if (action == PointActionID.Translate)
            changed = onDragUpdate(impl.mousePos, impl) || changed;
        return true;
    }

    override int peek(ImGuiIO* io, IncMeshEditorOne impl) {
        super.peek(io, impl);
        if (impl.deformOnly)
            return peekDeformEdit(io, impl);
        else
            return 0;
    }

    override int unify(int[] actions) {
        int[int] priorities;
        priorities[PointActionID.Add] = 2;
        priorities[PointActionID.Remove] = 2;
        priorities[PointActionID.Translate] = 1;
        priorities[PointActionID.TranslateUp] = 0;
        priorities[PointActionID.TranslateDown] = 0;
        priorities[PointActionID.TranslateLeft] = 0;
        priorities[PointActionID.TranslateRight] = 0;
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

    override bool update(ImGuiIO* io, IncMeshEditorOne impl, int action, out bool changed) {
        super.update(io, impl, action, changed);
        if (impl.deformOnly)
            updateDeformEdit(io, impl, action, changed);
        else
            updateMeshEdit(io, impl, changed);
        return changed;
    }

}