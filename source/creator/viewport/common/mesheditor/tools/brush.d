module creator.viewport.common.mesheditor.tools.brush;

import creator.viewport.common.mesheditor.tools.enums;
import creator.viewport.common.mesheditor.tools.base;
import creator.viewport.common.mesheditor.tools.select;
import creator.viewport.common.mesheditor.operations;
import creator.viewport.common.mesheditor.brushes;
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
import std.string;
import std.range;

private {
    Brush _currentBrush;
    Brush currentBrush() {
        if (_currentBrush is null) {
            _currentBrush = incBrushList()[0];
        }
        return _currentBrush;
    }
    void setCurrentBrush(Brush brush) {
        if (brush !is null)
            _currentBrush = brush;
    }
}

class BrushTool : NodeSelect {
    bool flow = false;
    float[] weights;
    vec2 initPos;
    int axisDirection; // 0: none, 1: lock to horizontal move only, 2: lock to vertical move only

    bool getFlow() { return flow; }
    void setFlow(bool value) { flow = value; }

    override bool onDragStart(vec2 mousePos, IncMeshEditorOne impl) {
        if (isDragging) {
            if (!flow)
                weights = impl.getVerticesInBrush(impl.mousePos, currentBrush);
            initPos = impl.mousePos;
            axisDirection = 0;
        }
        return super.onDragStart(mousePos, impl);
    }

    override bool onDragEnd(vec2 mousePos, IncMeshEditorOne impl) {
        return super.onDragEnd(mousePos, impl);
    }

    override bool onDragUpdate(vec2 mousePos, IncMeshEditorOne impl) {
        return super.onDragUpdate(mousePos, impl);
    }


    enum BrushActionID {
        Drawing = cast(int)(SelectActionID.End),
        End
    }

    override
    void setToolMode(VertexToolMode toolMode, IncMeshEditorOne impl) {
        super.setToolMode(toolMode, impl);
        incViewportSetAlwaysUpdate(true);
    }

    override 
    int peek(ImGuiIO* io, IncMeshEditorOne impl) {
        super.peek(io, impl);

        if (incInputIsMouseReleased(ImGuiMouseButton.Left)) {
            onDragEnd(impl.mousePos, impl);
        }

        if (igIsMouseClicked(ImGuiMouseButton.Left)) impl.maybeSelectOne = ulong(-1);
        
        int action = SelectActionID.None;

        if (!isDragging && !impl.isSelecting && 
            incDragStartedInViewport(ImGuiMouseButton.Left) && igIsMouseDown(ImGuiMouseButton.Left) && incInputIsDragRequested(ImGuiMouseButton.Left)) {
            isDragging = true;
            onDragStart(impl.mousePos, impl);
        }

        if (isDragging) {
            action = BrushActionID.Drawing;
        }

        if (action != SelectActionID.None)
            return action;

        if (io.KeyAlt) {
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
        priorities[BrushActionID.Drawing] = 0;
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

        if (action == BrushActionID.Drawing) {
            if (io.KeyShift) {
                static int THRESHOLD = 32;
                if (axisDirection == 0) {
                    vec2 diffToInit = impl.mousePos - initPos;
                    if (abs(diffToInit.x) / incViewportZoom > THRESHOLD)
                        axisDirection = 1;
                    else if (abs(diffToInit.y) / incViewportZoom > THRESHOLD)
                        axisDirection = 2;
                }
                if (axisDirection == 1)
                    impl.mousePos.y = initPos.y;
                else if (axisDirection == 2)
                    impl.mousePos.x = initPos.x;
            }
            if (flow)
                weights = impl.getVerticesInBrush(impl.mousePos, currentBrush);
            auto diffPos = impl.mousePos - impl.lastMousePos;
            ulong[] selected = (impl.selected && impl.selected.length > 0)? impl.selected: array(iota(weights.length));
            foreach (idx; selected) {
                float weight = weights[idx];
                MeshVertex* v = impl.getVerticesByIndex([idx])[0];
                if (v is null)
                    continue;
                if (weight > 0) {
                    v.position += diffPos * weight;
                    impl.markActionDirty();
                }
            }

            impl.refreshMesh();
            changed = true;
        } else if (isDragging)
            onDragUpdate(impl.mousePos, impl);

        if (changed) impl.refreshMesh();
        return changed;
    }

    override
    void draw(Camera camera, IncMeshEditorOne impl) {
        super.draw(camera, impl);
        if (!(igGetIO().KeyAlt))
            currentBrush.draw(impl.mousePos, impl.transform);
    }

}

class ToolInfoImpl(T: BrushTool) : ToolInfoBase!(T) {
    override
    bool viewportTools(bool deformOnly, VertexToolMode toolMode, IncMeshEditorOne[Node] editors) {
        if (deformOnly)
            return super.viewportTools(deformOnly, toolMode, editors);
        return false;
    }
    override
    bool displayToolOptions(bool deformOnly, VertexToolMode toolMode, IncMeshEditorOne[Node] editors) {
        igPushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0));
        igPushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(4, 4));
        auto brushTool = cast(BrushTool)(editors.length == 0 ? null: editors.values()[0].getTool());
            igBeginGroup();
                if (incButtonColored("", ImVec2(0, 0), (brushTool !is null && !brushTool.getFlow())? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) { // path definition
                    foreach (e; editors) {
                        auto bt = cast(BrushTool)(e.getTool());
                        if (bt)
                            bt.setFlow(false);
                    }
                }
                incTooltip(_("Drag mode"));

                igSameLine(0, 0);
                if (incButtonColored("", ImVec2(0, 0), (brushTool !is null && brushTool.getFlow())? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) { // path definition
                    foreach (e; editors) {
                        auto bt = cast(BrushTool)(e.getTool());
                        if (bt)
                            bt.setFlow(true);
                    }
                }
                incTooltip(_("Flow mode"));

            igEndGroup();

            igSameLine(0, 4);
            currentBrush.configure();
            igSameLine(0, 4);

            igBeginGroup();
            igPushID("BRUSH_SELECT");
                auto brushName = currentBrush.name();
                if(igBeginCombo("###Brushes", brushName.toStringz)) {
                    foreach (brush; incBrushList) {
                        if (igSelectable(brush.name().toStringz)) {
                            setCurrentBrush(brush);
                        }
                    }
                    igEndCombo();
                }
            igPopID();

            igEndGroup();
        igPopStyleVar(2);
        return false;
    }
    override VertexToolMode mode() { return VertexToolMode.Brush; };
    override string icon() { return "";}
    override string description() { return _("Brush Tool");}
}