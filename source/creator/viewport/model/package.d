/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.viewport.model;
import creator.viewport.model.deform;
import creator.widgets.tooltip;
import creator.core.input;
import creator.core;
import creator;
import inochi2d;
import bindbc.imgui;
import i18n;

void incViewportModelOverlay() {
    if (incArmedParameter()) {
        igSameLine(0, 0);
        incViewportModelDeformOverlay();
    } else {
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
}

void incViewportModelNodeSelectionChanged() {
    incViewportModelDeformNodeSelectionChanged();
}

void incViewportModelUpdate(ImGuiIO* io, Camera camera) {
    if (Parameter param = incArmedParameter()) {
        incViewportModelDeformUpdate(io, camera, param);
    }    
}

void incViewportModelDraw(Camera camera) {
    Parameter param = incArmedParameter();
    incActivePuppet.update();
    incActivePuppet.draw();

    if (param) {
        incViewportModelDeformDraw(camera, param);
    } else {
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
                
                if (Driver selectedDriver = cast(Driver)selectedNode) {
                    selectedDriver.drawDebug();
                }
            }
        }
    }
}

void incViewportModelToolSettings() {
    incViewportModelDeformToolSettings();
}

void incViewportModelPresent() {

}

void incViewportModelWithdraw() {

}

void incViewportModelToolbar() {
    
}