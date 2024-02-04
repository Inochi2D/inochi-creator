module creator.viewport.common.mesheditor.tools.brush;

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

class BrushTool : NodeSelect {
    float radius = 300;
    bool flow = false;
    float[] weights;

    float getRadius() { return radius; }
    void setRadius(float value) { radius = value; }
    bool getFlow() { return flow; }
    void setFlow(bool value) { flow = value; }

    override bool onDragStart(vec2 mousePos, IncMeshEditorOne impl) {
        if (isDragging) {
            if (!flow)
                weights = impl.getVerticesInBrush(impl.mousePos, radius);
        }
        return super.onDragStart(mousePos, impl);
    }

    override bool onDragEnd(vec2 mousePos, IncMeshEditorOne impl) {
        return super.onDragEnd(mousePos, impl);
    }

    override bool onDragUpdate(vec2 mousePos, IncMeshEditorOne impl) {
        if (isDragging && !impl.isSelecting) {
            if (flow)
                weights = impl.getVerticesInBrush(impl.mousePos, radius);
            auto diffPos = mousePos - impl.lastMousePos;
            foreach (idx, weight; weights) {
                MeshVertex* v = impl.getVerticesByIndex([idx])[0];
                if (v is null)
                    continue;
                if (weight > 0) {
                    v.position += diffPos * weight;
                    impl.markActionDirty();
                }
            }

            impl.refreshMesh();
            return true;
        }
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

        if (!isDragging && incDragStartedInViewport(ImGuiMouseButton.Left) && igIsMouseDown(ImGuiMouseButton.Left) && incInputIsDragRequested(ImGuiMouseButton.Left)) {
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

        if (isDragging) {
            changed = onDragUpdate(impl.mousePos, impl) || changed;
        }

        if (changed) impl.refreshMesh();
        return changed;
    }

    override
    void draw(Camera camera, IncMeshEditorOne impl) {
        super.draw(camera, impl);

        vec3[] drawPoints;
        drawPoints ~= vec3(impl.mousePos, 0);
        inDbgSetBuffer(drawPoints);
        inDbgPointsSize(radius * incViewportZoom * 2 + 4);
        inDbgDrawPoints(vec4(0, 0, 0, 0.1), impl.transform);
        inDbgPointsSize(2 * radius * incViewportZoom);
        inDbgDrawPoints(vec4(1, 1, 1, 0.3), impl.transform);
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

            igBeginGroup();
                igPushID("BRUSH_RADIUS");
                igSetNextItemWidth(64);
                if (incDragFloat(
                    "brush_radius", &brushTool.radius, 1,
                    1, 2000, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
                ) {
                    foreach (e; editors) {
                        auto bt = cast(BrushTool)(e.getTool());
                        if (bt)
                            bt.setRadius(brushTool.radius);
                    }
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