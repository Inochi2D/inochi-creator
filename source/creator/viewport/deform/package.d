/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.viewport.deform;
import creator.core.input;
import creator;
import inochi2d;
import bindbc.imgui;

// No overlay in deform mode
void incViewportDeformOverlay() { }

void incViewportDeformUpdate(ImGuiIO* io, Camera camera) {
    
}

void incViewportDeformDraw(Camera camera) {
    incActivePuppet.update();
    incActivePuppet.draw();

}