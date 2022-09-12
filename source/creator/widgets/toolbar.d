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

                    if (incButtonColored("", ImVec2(32, 32), incActivePuppet().enableDrivers ? ImVec4.init : ImVec4(0.6f, 0.6f, 0.6f, 1f))) {
                        incActivePuppet().enableDrivers = !incActivePuppet().enableDrivers;
                    }
                    incTooltip(_("Enable physics"));

                    igSameLine(0, 0);

                    if (incButtonColored("", ImVec2(32, 32), incShouldPostProcess ? ImVec4.init : ImVec4(0.6f, 0.6f, 0.6f, 1f))) {
                        incShouldPostProcess = !incShouldPostProcess;
                    }
                    incTooltip(_("Enable post processing"));

                    if (incButtonColored("", ImVec2(32, 32), ImVec4.init)) {
                        incActivePuppet().resetDrivers();
                    }
                    incTooltip(_("Reset physics"));

                    // Draw the toolbar relevant for that viewport
                    incViewportToolbar();
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

bool incBeginInnerToolbar(float height, bool matchTitlebar=false) {

    auto style = igGetStyle();
    auto window = igGetCurrentWindow();

    auto barColor = matchTitlebar ? (
        igIsWindowFocused(ImGuiFocusedFlags.RootAndChildWindows) ? 
            style.Colors[ImGuiCol.TitleBgActive] : 
            style.Colors[ImGuiCol.TitleBg]
    ) : style.Colors[ImGuiCol.MenuBarBg];

    igPushStyleVar(ImGuiStyleVar.FrameRounding, 0);
    igPushStyleVar(ImGuiStyleVar.ChildBorderSize, 0);
    igPushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(0, 0));
    igPushStyleVar(ImGuiStyleVar.FrameBorderSize, 0);
    igPushStyleColor(ImGuiCol.ChildBg, barColor);
    igPushStyleColor(ImGuiCol.Button, barColor);

    if (!window.IsExplicitChild) {
        igPushClipRect(ImVec2(window.OuterRectClipped.Max.x, window.OuterRectClipped.Max.y-1), ImVec2(window.OuterRectClipped.Min.x, window.OuterRectClipped.Min.y), false);
        igSetCursorPosY(igGetCursorPosY()-1);
    }
    
    bool visible = igBeginChild("###Toolbar", ImVec2(0, height), false, ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoScrollWithMouse);
    if (visible) igSetCursorPosX(igGetCursorPosX()+style.FramePadding.x);
    return visible;
}

void incEndInnerToolbar() {
    igPopClipRect();

    igEndChild();
    igPopStyleColor(2);
    igPopStyleVar(4);

    // Move cursor up
    igSetCursorPosY(igGetCursorPosY()-igGetStyle().ItemSpacing.y);
}

/**
    A toolbar button
*/
bool incToolbarButton(const(char)* text, float width = 0) {
    bool clicked = igButton(text, ImVec2(width, incAvailableSpace().y));
    igSameLine(0, 0);
    return clicked;
}

/**
    A toolbar button
*/
void incToolbarSpacer(float space) {
    incDummy(ImVec2(space, 0));
    igSameLine(0, 0);
}

/**
    Vertical separator for toolbar
*/
void incToolbarSeparator() {
    igSeparatorEx(ImGuiSeparatorFlags.Vertical);
}