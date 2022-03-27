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
    bool verticesOnly = false;
    vec2 lastMousePos;
    vec2 mousePos;

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

        mesh.refresh();
    }

    MeshVertex* selectOne(MeshVertex* vert) {
        foreach(ref sel; selected) {
            sel.selected = false;
        }

        vert.selected = true;
        mesh.refresh();

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
        mesh.refresh();
    }

public:
    IncMesh mesh;

    this(bool verticesOnly) {
        this.verticesOnly = verticesOnly;
    }

    Drawable getTarget() {
        return target;
    }

    void setTarget(Drawable target) {
        this.target = target;
        mesh = new IncMesh(target.getMesh());
    }

    ref IncMesh getMesh() {
        return mesh;
    }

    VertexToolMode getToolMode() {
        return toolMode;
    }

    void setToolMode(VertexToolMode toolMode) {
        assert(!verticesOnly || toolMode == VertexToolMode.Points);
        this.toolMode = toolMode;
        deselectAll();
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

    void update(ImGuiIO* io, Camera camera) {
        lastMousePos = mousePos;
        mousePos = -incInputGetMousePosition();

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
                if (igIsMouseDoubleClicked(ImGuiMouseButton.Left)) {

                    // Check if mouse is over a vertex
                    if (mesh.isPointOverVertex(mousePos)) {

                        // In the case that it is, double clicking would remove an item
                        if (isSelected(mesh.getVertexFromPoint(mousePos))) {
                            mesh.removeVertexAt(mousePos);
                        }
                    } else {
                        mesh.vertices ~= new MeshVertex(mousePos, [], false);
                        selectOne(mesh.vertices[$-1]);
                    }
                    mesh.refresh();
                }

                // Dragging
                if (igIsMouseDown(ImGuiMouseButton.Left) && incInputIsDragRequested(ImGuiMouseButton.Left)) {
                    isDragging = true;
                }

                if (isDragging) {
                    foreach(select; selected) {
                        select.position += mousePos-lastMousePos;
                    }
                    mesh.refresh();
                }


                break;
            case VertexToolMode.Connect:
                if (igIsMouseClicked(ImGuiMouseButton.Left)) {
                    if (mesh.isPointOverVertex(mousePos)) {
                        auto prev = selectOne(mesh.getVertexFromPoint(mousePos));
                        if (prev !is null) {
                            if (prev != selected[$-1]) {

                                // Connect or disconnect between previous and this node
                                if (!prev.isConnectedTo(selected[$-1])) {
                                    prev.connect(selected[$-1]);
                                } else {
                                    prev.disconnect(selected[$-1]);
                                }
                                if (!io.KeyShift) deselectAll();
                            } else {

                                // Selecting the same vert twice unselects it
                                deselectAll();
                            }
                        }


                        mesh.refresh();
                    } else {

                            // Clicking outside a vert deselect verts
                            deselectAll();
                    }
                }
                break;
            default: assert(0);
        }
    }

    void draw(Camera camera) {
        vec2 mousePos = incInputGetMousePosition();

        // Draw the part that is currently being edited
        if (target !is null) {
            if (Part part = cast(Part)target) {

                // Draw albedo texture at 0, 0
                inDrawTextureAtPosition(part.textures[0], vec2(0, 0));
            }
        }

        // Draw the points being edited
        mesh.draw();
    }
}