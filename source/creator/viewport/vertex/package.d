/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.viewport.vertex;
import creator.core.input;
import creator;
import inochi2d;
import bindbc.imgui;

// No overlay in vertex mode
void incViewportVertexOverlay() { }

void incViewportVertexUpdate(ImGuiIO* io, Camera camera) {
    
}

void incViewportVertexDraw(Camera camera) {
    incActivePuppet.update();
    incActivePuppet.draw();
}