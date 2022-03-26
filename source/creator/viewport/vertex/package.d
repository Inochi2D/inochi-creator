/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.viewport.vertex;
public import creator.viewport.vertex.mesh;
import i18n;
import creator.viewport;
import creator.core.input;
import creator.widgets;
import creator;
import inochi2d;
import bindbc.imgui;
import std.stdio;
import bindbc.opengl;

enum VertexToolMode {
    Points,
    Connect
}

VertexToolMode incVertexToolMode;
private {
    MeshVertex*[] selected;
    bool isDragging = false;
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

        incMeshEditGetMesh().refresh();
    }

    
    MeshVertex* selectOne(MeshVertex* vert) {
        foreach(ref sel; selected) {
            sel.selected = false;
        }

        vert.selected = true;
        incMeshEditGetMesh().refresh();

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
        incMeshEditGetMesh().refresh();
    }
}



// No overlay in vertex mode
void incViewportVertexOverlay() {
    igPushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0));

        if (incButtonColored("", ImVec2(28, 28), incVertexToolMode == VertexToolMode.Points ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
            incVertexToolMode = VertexToolMode.Points;
            deselectAll();
        }
        incTooltip(_("Vertex Tool"));

        igSameLine(0, 0);
        if (incButtonColored("", ImVec2(28, 28), incVertexToolMode == VertexToolMode.Connect ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
            incVertexToolMode = VertexToolMode.Connect;
            deselectAll();
        }
        incTooltip(_("Line Tool"));

    igPopStyleVar();

}


void incViewportVertexUpdate(ImGuiIO* io, Camera camera) {
    lastMousePos = mousePos;
    mousePos = -incInputGetMousePosition();

    if (incInputIsMouseReleased(ImGuiMouseButton.Left)) isDragging = false;

    switch(incVertexToolMode) {
        case VertexToolMode.Points:

            // Left click selection
            if (igIsMouseClicked(ImGuiMouseButton.Left)) {
                if (incMeshEditGetMesh().isPointOverVertex(mousePos)) {
                    if (io.KeyCtrl) toggleSelect(incMeshEditGetMesh().getVertexFromPoint(mousePos));
                    else selectOne(incMeshEditGetMesh().getVertexFromPoint(mousePos));
                }
            }

            // Left double click action
            if (igIsMouseDoubleClicked(ImGuiMouseButton.Left)) {

                // Check if mouse is over a vertex
                if (incMeshEditGetMesh().isPointOverVertex(mousePos)) {

                    // In the case that it is, double clicking would remove an item
                    if (isSelected(incMeshEditGetMesh().getVertexFromPoint(mousePos))) {
                        incMeshEditGetMesh().removeVertexAt(mousePos);
                    }
                } else {
                    incMeshEditGetMesh().vertices ~= new MeshVertex(mousePos, [], false);
                    selectOne(incMeshEditGetMesh().vertices[$-1]);
                }
                incMeshEditGetMesh().refresh();
            }

            // Dragging
            if (igIsMouseDown(ImGuiMouseButton.Left) && incInputIsDragRequested(ImGuiMouseButton.Left)) {
                isDragging = true;
            }
            
            if (isDragging) {
                foreach(select; selected) {
                    select.position += mousePos-lastMousePos;
                }
                incMeshEditGetMesh().refresh();
            }
            

            break;
        case VertexToolMode.Connect:
            if (igIsMouseClicked(ImGuiMouseButton.Left)) {
                if (incMeshEditGetMesh().isPointOverVertex(mousePos)) {
                    auto prev = selectOne(incMeshEditGetMesh().getVertexFromPoint(mousePos));
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
                    

                    incMeshEditGetMesh().refresh();
                } else {

                        // Clicking outside a vert deselect verts
                        deselectAll();
                }
            }
            break;
        default: assert(0);
    }
}

void incViewportVertexDraw(Camera camera) {
    vec2 mousePos = incInputGetMousePosition();


    // Draw the part that is currently being edited
    if (incVertexEditGetTarget() !is null) {
        if (Part part = cast(Part)incVertexEditGetTarget()) {

            // Draw albedo texture at 0, 0
            inDrawTextureAtPosition(part.textures[0], vec2(0, 0));
        }
    }

    // Draw the points being edited
    incMeshEditDraw();
}

void incViewportVertexToolbar() { }

void incViewportVertexToolSettings() {

}

void incViewportVertexPresent() { }

void incViewportVertexWithdraw() { }