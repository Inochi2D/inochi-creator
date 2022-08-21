/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets.toolbar;
import creator.viewport;
import creator.widgets;
import creator.core;
import creator;
import i18n;

void incToolbar() {
    auto flags = 
        ImGuiWindowFlags.NoSavedSettings |
        ImGuiWindowFlags.NoScrollbar |
        ImGuiWindowFlags.MenuBar;

    igPushStyleColor(ImGuiCol.Border, ImVec4(0, 0, 0, 0));
    igPushStyleColor(ImGuiCol.BorderShadow, ImVec4(0, 0, 0, 0));
    igPushStyleColor(ImGuiCol.Separator, ImVec4(0, 0, 0, 0));
        igPushStyleVar(ImGuiStyleVar.FramePadding, ImVec2(0, 10));
        if (igBeginViewportSideBar("##Toolbar", igGetMainViewport(), ImGuiDir.Up, 32, flags)) {
            
            if (igBeginMenuBar()) {
                igPopStyleVar();
                
                ImVec2 pos;
                igGetCursorPos(&pos);
                igSetCursorPos(ImVec2(pos.x-igGetStyle().WindowPadding.x, pos.y));

                // Render toolbar
                igPushStyleVar(ImGuiStyleVar.FramePadding, ImVec2(0, 0));
                igPushStyleVar(ImGuiStyleVar.FrameRounding, 0);
                    igPushFont(incIconFont());

                        if (incButtonColored("", ImVec2(32, 32), incActivePuppet().enableDrivers ? ImVec4.init : ImVec4(0.6f, 0.6f, 0.6f, 1f))) {
                            incActivePuppet().enableDrivers = !incActivePuppet().enableDrivers;
                        }
                        incTooltip(_("Enable physics"));

                        if (incButtonColored("", ImVec2(32, 32), ImVec4.init)) {
                            incActivePuppet().resetDrivers();
                        }
                        incTooltip(_("Reset physics"));

                        // Draw the toolbar relevant for that viewport
                        incViewportToolbar();
                    igPopFont();
                igPopStyleVar(2);

                // Render mode switch buttons
                ImVec2 avail;
                igGetContentRegionAvail(&avail);
                igDummy(ImVec2(avail.x-(32*3), 0));

                igPushStyleVar(ImGuiStyleVar.FramePadding, ImVec2(0, 0));
                igPushStyleVar(ImGuiStyleVar.FrameRounding, 0);
                    igPushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0));
                        if(incEditMode != EditMode.VertexEdit) {
                            if (incButtonColored("", ImVec2(32, 32), incEditMode == EditMode.ModelEdit ? ImVec4.init : ImVec4(0.6f, 0.6f, 0.6f, 1f))) {
                                incSetEditMode(EditMode.ModelEdit);
                            }
                            incTooltip(_("Edit Puppet"));

                            if (incButtonColored("", ImVec2(32, 32), incEditMode == EditMode.AnimEdit ? ImVec4.init : ImVec4(0.6f, 0.6f, 0.6f, 1f))) {
                                incSetEditMode(EditMode.AnimEdit);
                            }
                            incTooltip(_("Edit Animation"));

                            if (incButtonColored("", ImVec2(32, 32), incEditMode == EditMode.ModelTest ? ImVec4.init : ImVec4(0.6f, 0.6f, 0.6f, 1f))) {
                                incSetEditMode(EditMode.ModelTest);
                            }
                            incTooltip(_("Test Puppet"));
                        }
                    igPopStyleVar();
                igPopStyleVar(2);

                igEndMenuBar();
            } else {
                igPopStyleVar();
            }

            incEnd();
        } else {
            igPopStyleVar();
        }
    igPopStyleColor();
    igPopStyleColor();
    igPopStyleColor();
}