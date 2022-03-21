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


// No overlay in vertex mode
void incViewportVertexOverlay() { }

void incViewportVertexUpdate(ImGuiIO* io, Camera camera) { }

void incViewportVertexDraw(Camera camera) {
    vec2 mpos = incInputGetMousePosition();


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

void incViewportVertexToolbar() {
    igPushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0));

        if (incButtonColored("", ImVec2(32, 32), incVertexToolMode == VertexToolMode.Points ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
            incVertexToolMode = VertexToolMode.Points;
        }
        incTooltip(_("Allows you to place vertices on to the part"));

        if (incButtonColored("", ImVec2(32, 32), incVertexToolMode == VertexToolMode.Connect ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
            incVertexToolMode = VertexToolMode.Connect;
        }
        incTooltip(_("Allows you to connect vertices on to the part"));

    igPopStyleVar();
}

void incViewportVertexPresent() { }

void incViewportVertexWithdraw() { }