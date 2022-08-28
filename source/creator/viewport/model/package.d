/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.viewport.model;
import creator.viewport.model.deform;
import creator.widgets.tooltip;
import creator.widgets.label;
import creator.widgets.texture;
import creator.widgets.dummy;
import creator.core.input;
import creator.core;
import creator;
import inochi2d;
import bindbc.imgui;
import i18n;
import std.stdio;

private {
    Part[] foundParts;

    enum ENTRY_SIZE = 48;
}

void incViewportModelMenuOpening() {
    foundParts.length = 0;

    vec2 mpos = incInputGetMousePosition()*-1;
    foreach(ref Part part; incActivePuppet.getAllParts()) {
        rect b = rect(part.bounds.x, part.bounds.y, part.bounds.z-part.bounds.x, part.bounds.w-part.bounds.y);
        if (b.intersects(mpos)) {
            foundParts ~= part;
        }
    }

    import std.algorithm.sorting : sort;
    import std.algorithm.mutation : SwapStrategy;
    import std.math : cmp;
    sort!((a, b) => cmp(
        a.zSortNoOffset, 
        b.zSortNoOffset) < 0, SwapStrategy.stable)(foundParts);
}

void incViewportModelMenu() {
    if (igBeginChild("FOUND_PARTS", ImVec2(256, 256))) {
        if (foundParts.length > 0) {
            ImVec2 avail = incAvailableSpace();
            ImVec2 cursorPos;
            foreach(Part part; foundParts) {
                igPushID(part.uuid);
                    ImVec2 nameSize = incMeasureString(part.name);

                    // Selectable
                    igGetCursorPos(&cursorPos);
                    if (igSelectable("###PartSelectable", false, ImGuiSelectableFlags.None, ImVec2(avail.x, ENTRY_SIZE))) {
                        if (incSelectedNode() == part) {
                            incFocusCamera(part);
                        } else incSelectNode(part);

                        // Escape early, we're already done.
                        igPopID();
                        igEndChild();
                        igCloseCurrentPopup();
                        return;
                    }
                    igSetItemAllowOverlap();

                    // ICON
                    igSetCursorPos(ImVec2(cursorPos.x+2, cursorPos.y+2));
                    incTextureSlotUntitled("ICON", part.textures[0], ImVec2(ENTRY_SIZE-4, ENTRY_SIZE-4), 16, ImGuiWindowFlags.NoInputs);
                    
                    // Name
                    igSetCursorPos(ImVec2(cursorPos.x + ENTRY_SIZE + 4, cursorPos.y + (ENTRY_SIZE/2) - (nameSize.y/2)));
                    incText(part.name);

                    // Move to next line
                    igSetCursorPos(ImVec2(cursorPos.x, cursorPos.y + ENTRY_SIZE + 3));
                igPopID();
            }
        } else {
            incText(_("No parts found"));
        }
    }
    igEndChild();
}

void incViewportModelOverlay() {
    if (incArmedParameter()) {
        igSameLine(0, 0);
        incViewportModelDeformOverlay();
    } else {
        if (igButton("", ImVec2(0, 0))) {
            incShowVertices = !incShowVertices;
        }
        incTooltip(_("Show/hide Vertices"));
            
        igSameLine(0, 0);
        if (igButton("", ImVec2(0, 0))) {
            incShowBounds = !incShowBounds;
        }
        incTooltip(_("Show/hide Bounds"));

        igSameLine(0, 0);
        if (igButton("", ImVec2(0, 0))) {
            incShowOrientation = !incShowOrientation;
        }
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