/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.viewport.anim;
import creator.core.input;
import creator;
import inochi2d;
import bindbc.imgui;

// No overlay in deform mode
void incViewportAnimOverlay() { }

void incViewportAnimUpdate(ImGuiIO* io, Camera camera) {
    
}

void incViewportAnimDraw(Camera camera) {
    incActivePuppet.update();
    incActivePuppet.draw();
}

void incViewportAnimToolbar() {

}

void incViewportAnimPresent() {

}

void incViewportAnimWithdraw() {

}