module creator.viewport.common.mesheditor.tools.grid;

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
import std.array;
import std.algorithm.searching: countUntil;
import std.algorithm.mutation;
import std.algorithm.sorting;

class GridTool : NodeSelect {
    GridActionID currentAction;
    int numCut = 3;
    vec2 dragOrigin;
    vec2 dragEnd;
    int dragTargetXIndex = 0;
    int dragTargetYIndex = 0;

    enum GridActionID {
        Add = cast(int)(SelectActionID.End),
        Remove,
        Create,
        TranslateFree,
        TranslateX,
        TranslateY,
        TranslateUp,
        TranslateDown,
        TranslateLeft,
        TranslateRight,
        End
    }

    static float selectRadius = 16f;

    bool isOnGrid(IncMesh mesh, int axis, vec2 mousePos, float threshold, out float value) {
        if (mesh.axes.length != 2)
            return false;
        if (mousePos.vector[axis] >= mesh.axes[1-axis][0] - threshold && mousePos.vector[axis] <= mesh.axes[1-axis][$-1] + threshold) {
            foreach (v ;mesh.axes[axis]) {
                if (abs(mousePos.vector[1-axis] - v) < threshold) {
                    value = v;
                    return true;
                }
            }
        }
        return false;
    }
    bool isOnEdge(IncMesh mesh, int axis, vec2 mousePos, float threshold, out float value) {
        if (mesh.axes.length != 2)
            return false;
        if (mousePos.vector[axis] >= mesh.axes[1-axis][0] - threshold && mousePos.vector[axis] <= mesh.axes[1-axis][$-1] + threshold) {
            if (abs(mousePos.vector[1-axis] - mesh.axes[axis][0]) < threshold) {
                value = mesh.axes[axis][0];
                return true;
            } else if (abs(mousePos.vector[1-axis] - mesh.axes[axis][$-1]) < threshold) {
                value = mesh.axes[axis][$-1];
                return true;
            }
        }
        return false;
    }


    override
    void setToolMode(VertexToolMode toolMode, IncMeshEditorOne impl) {
        assert(!impl.deformOnly || toolMode != VertexToolMode.Grid);
        isDragging = false;
        impl.isSelecting = false;
        impl.deselectAll();
    }

    override bool onDragStart(vec2 mousePos, IncMeshEditorOne impl) {
        auto implDrawable = cast(IncMeshEditorOneDrawable)(impl);
        assert(implDrawable !is null);
        auto mesh = implDrawable.getMesh();

        auto vtxAtMouse = impl.getVerticesByIndex([impl.vtxAtMouse])[0];
        if (vtxAtMouse) {
            if (mesh.axes.length != 2) {
                currentAction = GridActionID.End;
                return false;
            }

            currentAction = mesh.axes.length == 2 ? GridActionID.TranslateFree : GridActionID.End;
            vtxAtMouse = impl.getVerticesByIndex([impl.vtxAtMouse])[0];
            dragOrigin = vtxAtMouse.position;

            float threshold = selectRadius/incViewportZoom;
            float xValue, yValue;
            bool foundY = isOnEdge(mesh, 0, dragOrigin, threshold, yValue);
            bool foundX = isOnEdge(mesh, 1, dragOrigin, threshold, xValue);

            if (foundY) {
                dragOrigin.y = yValue;
                if (!foundX) {
                    currentAction = GridActionID.TranslateX;
                } else {
                    dragTargetXIndex = cast(int)mesh.axes[1].countUntil(vtxAtMouse.position.x);
                    if (dragTargetXIndex < 0)
                        currentAction = GridActionID.End;
                }
            }

            if (foundX) {
                dragOrigin.x = xValue;
                if (!foundY) {
                    currentAction = GridActionID.TranslateY;
                } else {
                    dragTargetYIndex = cast(int)mesh.axes[0].countUntil(vtxAtMouse.position.y);
                    if (dragTargetYIndex < 0)
                        currentAction = GridActionID.End;
                }
            }
            if (!foundX) {
                dragTargetXIndex = cast(int)mesh.axes[1].countUntil(vtxAtMouse.position.x);
                if (dragTargetXIndex < 0)
                    currentAction = GridActionID.End;
            }
            if (!foundY) {
                dragTargetYIndex = cast(int)mesh.axes[0].countUntil(vtxAtMouse.position.y);
                if (dragTargetYIndex < 0)
                    currentAction = GridActionID.End;
            }

            return true;
        } else if (mesh.axes.length < 2 || mesh.vertices.length == 0) {
            currentAction = GridActionID.Create;
            dragOrigin = mousePos;
            return true;
        }
        return false;
    }

    override bool onDragEnd(vec2 mousePos, IncMeshEditorOne impl) {
        if (currentAction == GridActionID.TranslateX || currentAction == GridActionID.TranslateY || currentAction == GridActionID.TranslateFree) {
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
        auto implDrawable = cast(IncMeshEditorOneDrawable)(impl);
        assert(implDrawable !is null);
        auto mesh = implDrawable.getMesh();
        dragEnd = impl.mousePos;

        if (currentAction == GridActionID.TranslateX) {
            mesh.axes[1][dragTargetXIndex] = mousePos.x;
            mesh.axes[1].sort();
            dragTargetXIndex = cast(int)mesh.axes[1].countUntil(mousePos.x);
            MeshData meshData;
            meshData.gridAxes = mesh.axes[];
            meshData.regenerateGrid();
            mesh.copyFromMeshData(meshData);
            impl.refreshMesh();
            return true;
        } else if (currentAction == GridActionID.TranslateY) {
            mesh.axes[0][dragTargetYIndex] = mousePos.y;
            mesh.axes[0].sort();
            dragTargetYIndex = cast(int)mesh.axes[0].countUntil(mousePos.y);
            MeshData meshData;
            meshData.gridAxes = mesh.axes[];
            meshData.regenerateGrid();
            mesh.copyFromMeshData(meshData);
            impl.refreshMesh();
            return true;
        } else if (currentAction == GridActionID.TranslateFree) {
            mesh.axes[0][dragTargetYIndex] = mousePos.y;
            mesh.axes[0].sort();
            dragTargetYIndex = cast(int)mesh.axes[0].countUntil(mousePos.y);

            mesh.axes[1][dragTargetXIndex] = mousePos.x;
            mesh.axes[1].sort();
            dragTargetXIndex = cast(int)mesh.axes[1].countUntil(mousePos.x);
            MeshData meshData;
            meshData.gridAxes = mesh.axes[];
            meshData.regenerateGrid();
            mesh.copyFromMeshData(meshData);
            impl.refreshMesh();
            return true;
        } else if (currentAction == GridActionID.Create) {
            return true;
        }

        return false;
    }

    bool updateMeshEdit(ImGuiIO* io, IncMeshEditorOne impl, out bool changed) {
        auto implDrawable = cast(IncMeshEditorOneDrawable)(impl);
        assert(implDrawable !is null);
        auto mesh = implDrawable.getMesh();

        if (isDragging && incInputIsMouseReleased(ImGuiMouseButton.Left)) {
            onDragEnd(impl.mousePos, impl);
            isDragging = false;
        }

        if (igIsMouseClicked(ImGuiMouseButton.Left)) impl.maybeSelectOne = ulong(-1);

        incStatusTooltip(_("Drag to define 2x2 mesh"), _("Left Mouse"));
        incStatusTooltip(_("Add/remove key points to axes"), _("Left Mouse"));
        incStatusTooltip(_("Change key point position in the axis"), _("Left Mouse"));

        if (!isDragging && incInputIsMouseReleased(ImGuiMouseButton.Left) && impl.maybeSelectOne != ulong(-1)) {
            impl.selectOne(impl.maybeSelectOne);
        }

        // Left double click action
        if (igIsMouseDoubleClicked(ImGuiMouseButton.Left)) {
            auto vtxAtMouse = impl.getVerticesByIndex([impl.vtxAtMouse])[0];
            if (vtxAtMouse !is null) {
                // Remove axis point from gridAxes
                float x = vtxAtMouse.position.x;
                float y = vtxAtMouse.position.y;
                if (mesh.axes.length == 2) {
                    auto ycount = mesh.axes[0].countUntil(y);
                    auto xcount = mesh.axes[1].countUntil(x);
                    if ((xcount == 0 || xcount == mesh.axes[1].length - 1) &&
                        (ycount == 0 || ycount == mesh.axes[0].length - 1)) {
                    } else if (xcount == 0 || xcount == mesh.axes[1].length - 1) {
                        // Removes only y axis
                        mesh.axes[0] = mesh.axes[0].remove(ycount);
                    } else if (ycount == 0 || ycount == mesh.axes[0].length - 1) {
                        // Removes only x axis
                        mesh.axes[1] = mesh.axes[1].remove(xcount);
                    } else {
                        mesh.axes[0] = mesh.axes[0].remove(ycount);
                        mesh.axes[1] = mesh.axes[1].remove(xcount);
                    }
                    MeshData meshData;
                    meshData.gridAxes = mesh.axes[];
                    meshData.regenerateGrid();
                    mesh.copyFromMeshData(meshData);
                    impl.refreshMesh();
                    impl.updateVtxAtMouse(ulong(-1));
                }

            } else {
                // Add axis point to grid Axes
                if (mesh.axes.length == 2) {
                    float x, y;
                    float threshold = selectRadius/incViewportZoom;
                    auto mousePos = impl.mousePos;
                    float yValue, xValue;
                    bool foundY = isOnGrid(mesh, 0, mousePos, threshold, yValue);
                    bool foundX = isOnGrid(mesh, 1, mousePos, threshold, xValue);

                    if (!foundY) {
                        y = mousePos.y;
                        for (int i = 0; i < mesh.axes[0].length; i ++)
                            if (y < mesh.axes[0][i]) {
                                mesh.axes[0].insertInPlace(i, y);
                                break;
                            }
                    }
                    if (!foundX) {
                        x = mousePos.x;
                        for (int i = 0; i < mesh.axes[1].length; i ++)
                            if (x < mesh.axes[1][i]) {
                                mesh.axes[1].insertInPlace(i, x);
                                break;
                            }
                    }
                    MeshData meshData;
                    meshData.gridAxes = mesh.axes[];
                    meshData.regenerateGrid();
                    mesh.copyFromMeshData(meshData);
                    impl.refreshMesh();
                }
            }

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

        } else if (currentAction == GridActionID.TranslateX || currentAction == GridActionID.TranslateY || currentAction == GridActionID.TranslateFree) {

        } else {

        }
    }
}

class GridToolInfo : ToolInfoBase!GridTool {
    override
    void setupToolMode(IncMeshEditorOne e, VertexToolMode mode) {
        e.setToolMode(mode);
        e.setPath(null);
        e.deforming = false;
        e.refreshMesh();
    }

    override
    bool viewportTools(bool deformOnly, VertexToolMode toolMode, IncMeshEditorOne[Node] editors) {
        if (!deformOnly)
            return super.viewportTools(deformOnly, toolMode, editors);
        return false;
    }
    override VertexToolMode mode() { return VertexToolMode.Grid; };
    override string icon() { return "";}
    override string description() { return _("Grid Vertex Tool");}
}