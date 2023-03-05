module creator.viewport.common.mesheditor.tools.grid;

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

class GridTool : NodeSelect {
    GridActionID currentAction;
    int numCut = 3;
    vec2 dragOrigin;
    vec2 dragEnd;

    enum GridActionID {
        Add = cast(int)(SelectActionID.End),
        Remove,
        Create,
        Translate,
        TranslateUp,
        TranslateDown,
        TranslateLeft,
        TranslateRight,
        End
    }

    override
    void setToolMode(VertexToolMode toolMode, IncMeshEditorOne impl) {
        assert(!impl.deformOnly || toolMode != VertexToolMode.Grid);
        isDragging = false;
        impl.isSelecting = false;
        impl.deselectAll();
    }

    override bool onDragStart(vec2 mousePos, IncMeshEditorOne impl) {
        if (impl.vtxAtMouse) {
            currentAction = GridActionID.Translate;
            dragOrigin = mousePos;
            return true;
        } else {
            currentAction = GridActionID.Create;
            dragOrigin = mousePos;
            return true;
        }
    }

    override bool onDragEnd(vec2 mousePos, IncMeshEditorOne impl) {
        if (currentAction == GridActionID.Translate) {
            currentAction = GridActionID.End;
            return true;
        } else if (currentAction == GridActionID.Create) {
            dragEnd = mousePos;
            vec4 bounds = vec4(min(dragOrigin.x, dragEnd.x), min(dragOrigin.y, dragEnd.y),
                               max(dragOrigin.x, dragEnd.x), max(dragOrigin.y, dragEnd.y));
            float width  = bounds.z - bounds.x;
            float height = bounds.w - bounds.y;

            auto implDrawable = cast(IncMeshEditorOneDrawable)(impl);
            assert(implDrawable !is null);

            auto mesh = implDrawable.getMesh();
            MeshData meshData;
            
            meshData.gridAxes = [[], []];
            for (int i = 0; i < numCut; i ++) {
                meshData.gridAxes[0] ~= bounds.y + height * i / (numCut - 1);
                meshData.gridAxes[1] ~= bounds.x + width  * i / (numCut - 1);
            }
            meshData.regenerateGrid();
            mesh.copyFromMeshData(meshData);
            impl.refreshMesh();
            currentAction = GridActionID.End;
            return true;
        }
        return false;
    }

    override bool onDragUpdate(vec2 mousePos, IncMeshEditorOne impl) {
        if (currentAction == GridActionID.Translate) {

        } else if (currentAction == GridActionID.Create) {
            dragEnd = mousePos;
            return true;
        }

        return false;
    }

    bool updateMeshEdit(ImGuiIO* io, IncMeshEditorOne impl, out bool changed) {

        if (isDragging && incInputIsMouseReleased(ImGuiMouseButton.Left)) {
            onDragEnd(impl.mousePos, impl);
            isDragging = false;
        }

        if (igIsMouseClicked(ImGuiMouseButton.Left)) impl.maybeSelectOne = null;

        if (impl.selected.length == 0) {
            incStatusTooltip(_("Select"), _("Left Mouse"));
        } else{
            incStatusTooltip(_("Connect/Disconnect"), _("Left Mouse"));
            incStatusTooltip(_("Connect Multiple"), _("Shift+Left Mouse"));
        }

        if (igIsMouseClicked(ImGuiMouseButton.Left)) {
            if (impl.vtxAtMouse !is null) {
                auto prev = impl.selectOne(impl.vtxAtMouse);
                auto implDrawable = cast(IncMeshEditorOneDrawable)(impl);
                auto mesh = implDrawable.getMesh();
                if (prev !is null) {
                }

                impl.refreshMesh();
            } else {
                
                // Clicking outside a vert deselect verts
                impl.deselectAll();
            }
        }

        if (!isDragging && incInputIsMouseReleased(ImGuiMouseButton.Left) && impl.maybeSelectOne !is null) {
            impl.selectOne(impl.maybeSelectOne);
        }

        // Left double click action
        if (igIsMouseDoubleClicked(ImGuiMouseButton.Left) && !io.KeyShift && !io.KeyCtrl) {
            // Remove axis point from gridAxes
        }

        // Dragging
        if (!isDragging && incDragStartedInViewport(ImGuiMouseButton.Left) && igIsMouseDown(ImGuiMouseButton.Left) && incInputIsDragRequested(ImGuiMouseButton.Left)) {
            onDragStart(impl.mousePos, impl);
            isDragging = true;
        }
        if (isDragging)
            onDragUpdate(impl.mousePos, impl);

        return true;
    }

    override bool update(ImGuiIO* io, IncMeshEditorOne impl, int action, out bool changed) {
        super.update(io, impl, action, changed);

        if (!impl.deformOnly)
            updateMeshEdit(io, impl, changed);
        return changed;
    }

    override void draw (Camera camera, IncMeshEditorOne impl) {
        if (currentAction == GridActionID.Create) {
            vec3[] lines;
            vec4 color = vec4(0.2, 0.9, 0.9, 1);

            vec4 bounds = vec4(min(dragOrigin.x, dragEnd.x), min(dragOrigin.y, dragEnd.y),
                               max(dragOrigin.x, dragEnd.x), max(dragOrigin.y, dragEnd.y));
            float width  = bounds.z - bounds.x;
            float height = bounds.w - bounds.y;
            
            for (int i;  i < numCut; i ++) {
                float offy = bounds.y + height * i / (numCut - 1);
                float offx = bounds.x + width  * i / (numCut - 1);
                lines ~= [vec3(bounds.x, offy, 0), vec3(bounds.z, offy, 0)];
                lines ~= [vec3(offx, bounds.y, 0), vec3(offx, bounds.w, 0)];
            }
            inDbgSetBuffer(lines);
            inDbgDrawLines(color, mat4.identity());

        } else if (currentAction == GridActionID.Translate) {

        } else {

        }
    }
}