/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets.statusbar;
import bindbc.sdl;
import bindbc.imgui;
import creator.core;
import creator.widgets;
import creator.utils.link;
import app : incUpdateNoEv;
import std.string;

private {
    size_t itemIdx;
    ToolTipItem[] items;

    struct ToolTipItem {
        string action;
        string key;
    }
}

void incStatusTooltip(string action, string key) {
    if (itemIdx >= items.length) items.length = itemIdx+1;
    items[itemIdx++] = ToolTipItem(action, key);
}

/**
    Draws the custom titlebar
*/
void incStatusbar() {
    auto flags = 
        ImGuiWindowFlags.NoSavedSettings |
        ImGuiWindowFlags.NoScrollbar |
        ImGuiWindowFlags.MenuBar;
    
    if (incGetDarkMode()) igPushStyleColor(ImGuiCol.MenuBarBg, ImVec4(0.1, 0.1, 0.1, 1));
    else igPushStyleColor(ImGuiCol.MenuBarBg, ImVec4(0.9, 0.9, 0.9, 1));
    if (igBeginViewportSideBar("##Statusbar", igGetMainViewport(), ImGuiDir.Down, 22, flags)) {
        if (igBeginMenuBar()) {
            
            igPushStyleColor(ImGuiCol.Separator, ImVec4(1.000f, 1.000f, 1.000f, 0.098f));
            foreach(i, item; items) {

                // We've reached the end
                if (i == itemIdx) break;
                
                float startX = igGetCursorPosX();

                // Render the tooltip
                ImVec2 size = incMeasureString(item.action);
                incText(item.action);
                igSameLine(startX+(size.x-8), 0);
                incText(":");
                igSameLine(0, 4);
                incText(item.key);

                igSeparator(); 
            }

            if (incTaskLength() > 0) {
                if (incTaskGetProgress() >= 0) {
                    igProgressBar(incTaskGetProgress(), ImVec2(128, 0));
                }

                incText(incTaskGetStatus());

                if (incGetStatus().length > 0) {
                    igSpacing();
                    igSeparator();
                    igSpacing();
                }
            }
            
            incText(incGetStatus());

            igEndMenuBar();
        }
        incEnd();
    }
    igPopStyleColor();

    itemIdx = 0;
}