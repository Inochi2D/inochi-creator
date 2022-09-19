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
import creator.widgets.dragdrop;
import creator.widgets.colorbutton;
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
    mloop: foreach(ref Part part; incActivePuppet.getAllParts()) {
        rect b = rect(part.bounds.x, part.bounds.y, part.bounds.z-part.bounds.x, part.bounds.w-part.bounds.y);
        if (b.intersects(mpos)) {

            // Skip already selected parts
            foreach(pn; incSelectedNodes()) {
                if (pn.uuid == part.uuid) continue mloop;
            }
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
    if (incSelectedNode() != incActivePuppet().root) {
        if (igMenuItem(__("Focus Selected"))) {
            incFocusCamera(incSelectedNode());
        }
    }
    
    if (igBeginChild("FOUND_PARTS", ImVec2(256, 256), false)) {
        if (foundParts.length > 0) {
            ImVec2 avail = incAvailableSpace();
            ImVec2 cursorPos;
            foreach(Part part; foundParts) {
                igPushID(part.uuid);
                    ImVec2 nameSize = incMeasureString(part.name);

                    // Selectable
                    igGetCursorPos(&cursorPos);
                    if (igSelectable("###PartSelectable", false, ImGuiSelectableFlags.None, ImVec2(avail.x, ENTRY_SIZE))) {
                        
                        // Add selection if ctrl is down, otherwise set selection
                        if (igIsKeyDown(ImGuiKey.LeftCtrl) || igIsKeyDown(ImGuiKey.RightCtrl)) incAddSelectNode(part);
                        else incSelectNode(part);

                        // Escape early, we're already done.
                        igPopID();
                        igEndChild();
                        igCloseCurrentPopup();
                        return;
                    }
                    igSetItemAllowOverlap();

                    if(igBeginDragDropSource(ImGuiDragDropFlags.SourceAllowNullID)) {
                        igSetDragDropPayload("_PUPPETNTREE", cast(void*)&part, (&part).sizeof, ImGuiCond.Always);
                        incDragdropNodeList(part);
                        igEndDragDropSource();
                    }

                    // ICON
                    igSetCursorPos(ImVec2(cursorPos.x+2, cursorPos.y+2));
                    incTextureSlotUntitled("ICON", part.textures[0], ImVec2(ENTRY_SIZE-4, ENTRY_SIZE-4), 24, ImGuiWindowFlags.NoInputs);
                    
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

void incViewportModelTools() {
    if (incArmedParameter()) {
        incViewportModelDeformTools();
    }
}

void incViewportModelOptions() {
    if (!incArmedParameter()) {
        if (incButtonColored("", ImVec2(0, 0), incShowVertices ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
            incShowVertices = !incShowVertices;
        }
        incTooltip(incShowVertices ? _("Hide Vertices") : _("Show Vertices"));
            
        igSameLine(0, 0);
        if (incButtonColored("", ImVec2(0, 0), incShowBounds ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
            incShowBounds = !incShowBounds;
        }
        incTooltip(incShowBounds ? _("Hide Bounds") : _("Show Bounds"));

        igSameLine(0, 0);
        if (incButtonColored("", ImVec2(0, 0), incShowOrientation ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
            incShowOrientation = !incShowOrientation;
        }
        incTooltip(incShowOrientation ? _("Hide Orientation Gizmo") : _("Show Orientation Gizmo"));
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