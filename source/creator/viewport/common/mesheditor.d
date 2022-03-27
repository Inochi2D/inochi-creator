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
import inochi2d;
import inochi2d.core.dbg;
import bindbc.opengl;
import bindbc.imgui;

enum VertexToolMode {
    Points,
    Connect
}

class IncMeshEditor {
private:
    Drawable target;
    VertexToolMode toolMode = VertexToolMode.Points;
    MeshVertex*[] selected;
    bool isDragging = false;
    bool deformOnly = false;
    vec2 lastMousePos;
    vec2 mousePos;
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
            vert.selected = false;
            selected = selected.remove(idx);
        } else {
            vert.selected = true;
            selected ~= vert;
        }

        refreshMesh();
    }

    MeshVertex* selectOne(MeshVertex* vert) {
        foreach(ref sel; selected) {
            sel.selected = false;
        }

        vert.selected = true;
        refreshMesh();

        if (selected.length > 0) {
            auto lastSel = selected[$-1];

            selected = [vert];
            return lastSel;
        }

        selected = [vert];
        return null;
    }

    void deselectAll() {
        foreach(ref sel; selected) {
            sel.selected = false;
        }
        selected.length = 0;
        refreshMesh();
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
            mat4 tr = target.transform.matrix()*mat4.translation(mousePos.x, mousePos.y, 0);
            mousePos = vec2(tr.matrix[0][3]*-1, tr.matrix[1][3]*-1);
        } else {
            mousePos = -mousePos;
        }

        if (incInputIsMouseReleased(ImGuiMouseButton.Left)) isDragging = false;

        switch(toolMode) {
            case VertexToolMode.Points:

                // Left click selection
                if (igIsMouseClicked(ImGuiMouseButton.Left)) {
                    if (mesh.isPointOverVertex(mousePos)) {
                        if (io.KeyCtrl) toggleSelect(mesh.getVertexFromPoint(mousePos));
                        else selectOne(mesh.getVertexFromPoint(mousePos));
                    }
                }

                // Left double click action
                if (!deformOnly && igIsMouseDoubleClicked(ImGuiMouseButton.Left)) {

                    // Check if mouse is over a vertex
                    if (mesh.isPointOverVertex(mousePos)) {

                        // In the case that it is, double clicking would remove an item
                        if (isSelected(mesh.getVertexFromPoint(mousePos))) {
                            foreachMirror((uint axis) {
                                mesh.removeVertexAt(mirror(axis, mousePos));
                            });
                            changed = true;
                        }
                    } else {
                        ulong off = mesh.vertices.length;
                        foreachMirror((uint axis) {
                            mesh.vertices ~= new MeshVertex(mirror(axis, mousePos), [], false);
                        });
                        changed = true;
                        selectOne(mesh.vertices[off]);
                    }
                }

                // Dragging
                if (igIsMouseDown(ImGuiMouseButton.Left) && incInputIsDragRequested(ImGuiMouseButton.Left)) {
                    isDragging = true;
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
        if (deformOnly) {
            mesh.draw(target.transform.matrix());
        } else if (previewMesh) {
            previewMesh.drawLines(mat4.identity, vec4(0.7, 0.7, 0, 1));
            mesh.drawPoints();
        } else {
            mesh.draw();
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
            inDbgDrawLines(vec4(0.8, 0, 0, 1));
        }

    }
}