/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.viewport.model;
import creator.widgets.tooltip;
import creator.core.input;
import creator.core;
import creator;
import inochi2d;
import bindbc.imgui;
import i18n;

void incViewportModelOverlay() {
    igPushFont(incIconFont());
        if (igButton("", ImVec2(0, 0))) {
            incShowVertices = !incShowVertices;
        }
    igPopFont();
    incTooltip(_("Show/hide Vertices"));
        
    igPushFont(incIconFont());
        igSameLine(0, 0);
        if (igButton("", ImVec2(0, 0))) {
            incShowBounds = !incShowBounds;
        }
    igPopFont();
    incTooltip(_("Show/hide Bounds"));

    igPushFont(incIconFont());
        igSameLine(0, 0);
        if (igButton("", ImVec2(0, 0))) {
            incShowOrientation = !incShowOrientation;
        }
    igPopFont();
    incTooltip(_("Show/hide Orientation Gizmo"));
}

void incViewportModelUpdate(ImGuiIO* io, Camera camera) { }

void incViewportModelDraw(Camera camera) {
    incActivePuppet.update();
    incActivePuppet.draw();

    if (incSelectedNodes.length > 0) {
        foreach(selectedNode; incSelectedNodes) {
            if (selectedNode is null) continue; 
            if (incShowOrientation) selectedNode.drawOrientation();
            if (incShowBounds) selectedNode.drawBounds();

            if (Drawable selectedDraw = cast(Drawable)selectedNode) {

                if (incShowVertices || incEditMode != EditMode.ModelEdit) {
                    selectedDraw.drawMeshLines();
                    selectedDraw.drawMeshPoints();
                }
            }
            
        }
    }
}

void incViewportModelPresent() {

}

void incViewportModelWithdraw() {

}

void incViewportModelToolbar() {
    
}