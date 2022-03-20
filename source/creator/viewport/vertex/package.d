/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.viewport.vertex;
public import creator.viewport.vertex.mesh;
import creator.viewport;
import creator.core.input;
import creator;
import inochi2d;
import bindbc.imgui;
import std.stdio;
import bindbc.opengl;

// No overlay in vertex mode
void incViewportVertexOverlay() { }

void incViewportVertexUpdate(ImGuiIO* io, Camera camera) { }

void incViewportVertexDraw(Camera camera) {
    glDisable(GL_CULL_FACE);

    if (incVertexEditGetTarget() !is null) {
        if (Part part = cast(Part)incVertexEditGetTarget()) {

            // Draw albedo texture at 0, 0
            inDrawTextureAtPosition(part.textures[0], vec2(0, 0));
        }
    }
    glEnable(GL_CULL_FACE);
}

void incViewportVertexPresent() {

}

void incViewportVertexWithdraw() {

}