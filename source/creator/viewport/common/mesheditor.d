/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors:
    - Luna Nielsen
    - Asahi Lina
*/
module creator.viewport.common.mesheditor;
import creator.viewport;
import creator.viewport.common.mesh;
import creator.core.input;
import creator;
import inochi2d;
import inochi2d.core.dbg;
import bindbc.opengl;
import bindbc.imgui;
import std.algorithm.mutation;
import std.algorithm.searching;

enum VertexToolMode {
    Points,
    Connect
}

class IncMeshEditor {
private:
    bool deformOnly = false;
    bool vertexMapDirty = false;

    Drawable target;
    VertexToolMode toolMode = VertexToolMode.Points;
    MeshVertex*[] selected;
    MeshVertex*[] newSelected;

    vec2 lastMousePos;
    vec2 mousePos;

    bool isDragging = false;
    bool isSelecting = false;
    bool mutateSelection = false;
    bool invertSelection = false;
    MeshVertex* maybeSelectOne;
    vec2 selectOrigin;
    IncMesh previewMesh;

    bool isSelected(MeshVertex* vert) {
        import std.algorithm.searching : canFind;
        return selected.canFind(vert);
    }

    void toggleSelect(MeshVertex* vert) {
        import std.algorithm.searching : countUntil;
        import std.algorithm.mutation : remove;
        auto idx = selected.countUntil(vert);
        if (isSelected(vert)) {
            selected = selected.remove(idx);
        } else {
            selected ~= vert;
        }
    }

    MeshVertex* selectOne(MeshVertex* vert) {
        if (selected.length > 0) {
            auto lastSel = selected[$-1];

            selected = [vert];
            return lastSel;
        }

        selected = [vert];
        return null;
    }

    void deselectAll() {
        selected.length = 0;
    }

    vec2 mirrorH(vec2 point) {
        return 2 * vec2(mirrorOrigin.x, 0) + vec2(-point.x, point.y);
    }

    vec2 mirrorV(vec2 point) {
        return 2 * vec2(0, mirrorOrigin.x) + vec2(point.x, -point.y);
    }

    vec2 mirrorHV(vec2 point) {
        return 2 * mirrorOrigin - point;
    }

    vec2 mirror(uint axis, vec2 point) {
        switch (axis) {
            case 0: return point;
            case 1: return mirrorH(point);
            case 2: return mirrorV(point);
            case 3: return mirrorHV(point);
            default: assert(false, "bad axis");
        }
    }

    MeshVertex *mirrorVertex(uint axis, MeshVertex *vtx) {
        if (axis == 0) return vtx;
        MeshVertex *v = mesh.getVertexFromPoint(mirror(axis, vtx.position));
        if (v is vtx) return null;
        return v;
    }

    void foreachMirror(void delegate(uint axis) func) {
        if (mirrorHoriz) func(1);
        if (mirrorVert) func(2);
        if (mirrorHoriz && mirrorVert) func(3);
        func(0);
    }

public:
    IncMesh mesh;
    bool previewTriangulate = false;
    bool mirrorHoriz = false;
    bool mirrorVert = false;
    vec2 mirrorOrigin = vec2(0, 0);

    this(bool deformOnly) {
        this.deformOnly = deformOnly;
    }

    Drawable getTarget() {
        return target;
    }

    void setTarget(Drawable target) {
        this.target = target;
        mesh = new IncMesh(target.getMesh());
        refreshMesh();
    }

    ref IncMesh getMesh() {
        return mesh;
    }

    VertexToolMode getToolMode() {
        return toolMode;
    }

    void setToolMode(VertexToolMode toolMode) {
        assert(!deformOnly || toolMode == VertexToolMode.Points);
        this.toolMode = toolMode;
        deselectAll();
    }

    void resetMesh() {
        mesh.reset();
    }

    void refreshMesh() {
        mesh.refresh();
        if (previewTriangulate) {
            previewMesh = mesh.autoTriangulate();
        } else {
            previewMesh = null;
        }
    }

    void importMesh(MeshData data) {
        mesh.import_(data);
        mesh.refresh();
    }

    void applyOffsets(vec2[] offsets) {
        assert(deformOnly);

        mesh.applyOffsets(offsets);
    }

    vec2[] getOffsets() {
        assert(deformOnly);

        return mesh.getOffsets();
    }

    void applyToTarget() {
        // Export mesh
        MeshData data = mesh.export_();
        data.fixWinding();

        // Fix UVs
        foreach(i; 0..data.uvs.length) {
            if (Part part = cast(Part)target) {

                // Texture 0 is always albedo texture
                auto tex = part.textures[0];

                // By dividing by width and height we should get the values in UV coordinate space.
                data.uvs[i].x /= cast(float)tex.width;
                data.uvs[i].y /= cast(float)tex.height;
                data.uvs[i] += vec2(0.5, 0.5);
            }
        }

        if (data.vertices.length != target.vertices.length)
            vertexMapDirty = true;

        if (vertexMapDirty) {
            // Remove incompatible Deforms

            foreach (param; incActivePuppet().parameters) {
                ParameterBinding binding = param.getBinding(target, "deform");
                if (binding) param.removeBinding(binding);
            }
            vertexMapDirty = false;
        }

        // Apply the model
        target.rebuffer(data);
    }

    void applyPreview() {
        mesh = previewMesh;
        previewMesh = null;
        previewTriangulate = false;
    }

    bool update(ImGuiIO* io, Camera camera) {
        bool changed = false;

        lastMousePos = mousePos;

        mousePos = incInputGetMousePosition();
        if (deformOnly) {
            vec4 pIn = vec4(-mousePos.x, -mousePos.y, 0, 1);
            mat4 tr = target.transform.matrix().inverse();
            vec4 pOut = tr * pIn;
            mousePos = vec2(pOut.x, pOut.y);
        } else {
            mousePos = -mousePos;
        }

        if (incInputIsMouseReleased(ImGuiMouseButton.Left)) {
            isDragging = false;
            if (isSelecting) {
                if (mutateSelection) {
                    if (!invertSelection) {
                        foreach(v; newSelected) {
                            auto idx = selected.countUntil(v);
                            if (idx == -1) selected ~= v;
                        }
                    } else {
                        foreach(v; newSelected) {
                            auto idx = selected.countUntil(v);
                            if (idx != -1) selected = selected.remove(idx);
                        }
                    }
                    newSelected.length = 0;
                } else {
                    selected = newSelected;
                    newSelected = [];
                }

                isSelecting = false;
            }
        }

        if (igIsMouseClicked(ImGuiMouseButton.Left)) maybeSelectOne = null;

        switch(toolMode) {
            case VertexToolMode.Points:

                // Left click selection
                if (igIsMouseClicked(ImGuiMouseButton.Left)) {
                    if (mesh.isPointOverVertex(mousePos)) {
                        auto vtx = mesh.getVertexFromPoint(mousePos);
                        if (io.KeyShift) toggleSelect(vtx);
                        else if (!isSelected(vtx)) selectOne(mesh.getVertexFromPoint(mousePos));
                        else maybeSelectOne = vtx;
                    } else {
                        selectOrigin = mousePos;
                        isSelecting = true;
                    }
                }
                if (!isDragging && !isSelecting &&
                    incInputIsMouseReleased(ImGuiMouseButton.Left) && maybeSelectOne !is null) {
                    selectOne(maybeSelectOne);
                }

                // Left double click action
                if (!deformOnly && igIsMouseDoubleClicked(ImGuiMouseButton.Left) && !io.KeyShift) {

                    // Check if mouse is over a vertex
                    if (mesh.isPointOverVertex(mousePos)) {

                        // In the case that it is, double clicking would remove an item
                        if (isSelected(mesh.getVertexFromPoint(mousePos))) {
                            foreachMirror((uint axis) {
                                mesh.removeVertexAt(mirror(axis, mousePos));
                            });
                            refreshMesh();
                            vertexMapDirty = true;
                            changed = true;
                            selected.length = 0;
                        }
                    } else {
                        ulong off = mesh.vertices.length;
                        foreachMirror((uint axis) {
                            mesh.vertices ~= new MeshVertex(mirror(axis, mousePos));
                        });
                        refreshMesh();
                        vertexMapDirty = true;
                        changed = true;
                        selectOne(mesh.vertices[off]);
                    }
                }

                // Dragging
                if (igIsMouseDown(ImGuiMouseButton.Left) && incInputIsDragRequested(ImGuiMouseButton.Left)) {
                    if (!isSelecting) isDragging = true;
                }

                if (isDragging) {
                    foreach(select; selected) {
                        foreachMirror((uint axis) {
                            MeshVertex *v = mirrorVertex(axis, select);
                            if (v is null) return;
                            v.position += mirror(axis, mousePos - lastMousePos);
                        });
                    }
                    changed = true;
                    refreshMesh();
                }

                break;
            case VertexToolMode.Connect:
                assert(!deformOnly);

                if (igIsMouseClicked(ImGuiMouseButton.Left)) {
                    if (mesh.isPointOverVertex(mousePos)) {
                        auto prev = selectOne(mesh.getVertexFromPoint(mousePos));
                        if (prev !is null) {
                            if (prev != selected[$-1]) {

                                // Connect or disconnect between previous and this node
                                if (!prev.isConnectedTo(selected[$-1])) {
                                    foreachMirror((uint axis) {
                                        MeshVertex *mPrev = mirrorVertex(axis, prev);
                                        MeshVertex *mSel = mirrorVertex(axis, selected[$-1]);
                                        if (mPrev !is null && mSel !is null) mPrev.connect(mSel);
                                    });
                                    changed = true;
                                } else {
                                    foreachMirror((uint axis) {
                                        MeshVertex *mPrev = mirrorVertex(axis, prev);
                                        MeshVertex *mSel = mirrorVertex(axis, selected[$-1]);
                                        if (mPrev !is null && mSel !is null) mPrev.disconnect(mSel);
                                    });
                                    changed = true;
                                }
                                if (!io.KeyShift) deselectAll();
                            } else {

                                // Selecting the same vert twice unselects it
                                deselectAll();
                            }
                        }

                        refreshMesh();
                    } else {
                        // Clicking outside a vert deselect verts
                        deselectAll();
                    }
                }
                break;
            default: assert(0);
        }

        if (isSelecting) {
            newSelected = mesh.getInRect(selectOrigin, mousePos);
            mutateSelection = io.KeyShift;
            invertSelection = io.KeyCtrl;
        }

        if (changed)
            mesh.changed = true;

        if (mesh.changed) {
            if (previewTriangulate)
                previewMesh = mesh.autoTriangulate();
            mesh.changed = false;
        }
        return changed;
    }

    void draw(Camera camera) {
        mat4 trans = mat4.identity;
        if (deformOnly) trans = target.transform.matrix();

        if (previewMesh) {
            previewMesh.drawLines(trans, vec4(0.7, 0.7, 0, 1));
            mesh.drawPoints(trans);
        } else {
            mesh.draw(trans);
        }

        if (selected.length) {
            if (isSelecting && !mutateSelection)
                mesh.drawPointSubset(selected, vec4(0.6, 0, 0, 1), trans);
            else
                mesh.drawPointSubset(selected, vec4(1, 0, 0, 1), trans);
        }

        if (isSelecting) {
            vec3[] rectLines = [
                vec3(selectOrigin.x, selectOrigin.y, 0),
                vec3(mousePos.x, selectOrigin.y, 0),
                vec3(mousePos.x, selectOrigin.y, 0),
                vec3(mousePos.x, mousePos.y, 0),
                vec3(mousePos.x, mousePos.y, 0),
                vec3(selectOrigin.x, mousePos.y, 0),
                vec3(selectOrigin.x, mousePos.y, 0),
                vec3(selectOrigin.x, selectOrigin.y, 0),
            ];
            inDbgSetBuffer(rectLines);
            if (!mutateSelection) inDbgDrawLines(vec4(1, 0, 0, 1), trans);
            else if(invertSelection) inDbgDrawLines(vec4(0, 1, 1, 0.8), trans);
            else inDbgDrawLines(vec4(0, 1, 0, 0.8), trans);

            if (newSelected.length) {
                if (mutateSelection && invertSelection)
                    mesh.drawPointSubset(newSelected, vec4(1, 0, 1, 1), trans);
                else
                    mesh.drawPointSubset(newSelected, vec4(1, 0, 0, 1), trans);
            }
        }

        vec2 camSize = camera.getRealSize();
        vec2 camPosition = camera.position;
        vec3[] axisLines;
        if (mirrorHoriz) {
            axisLines ~= vec3(mirrorOrigin.x, -camSize.y - camPosition.y, 0);
            axisLines ~= vec3(mirrorOrigin.x, camSize.y - camPosition.y, 0);
        }
        if (mirrorVert) {
            axisLines ~= vec3(-camSize.x - camPosition.x, mirrorOrigin.y, 0);
            axisLines ~= vec3(camSize.x - camPosition.x, mirrorOrigin.y, 0);
        }

        if (axisLines.length > 0) {
            inDbgSetBuffer(axisLines);
            inDbgDrawLines(vec4(0.8, 0, 0, 1), trans);
        }

    }
}