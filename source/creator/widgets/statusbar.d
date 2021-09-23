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

/**
    Draws the custom titlebar
*/
void incStatusbar() {
    auto flags = 
        ImGuiWindowFlags.NoSavedSettings |
        ImGuiWindowFlags.NoScrollbar |
        ImGuiWindowFlags.MenuBar;
    
    if (incGetDarkMode()) igPushStyleColor(ImGuiCol.MenuBarBg, ImVec4(0.1, 0.1, 0.1, 1));
    else  igPushStyleColor(ImGuiCol.MenuBarBg, ImVec4(0.9, 0.9, 0.9, 1));
    if (igBeginViewportSideBar("##Statusbar", igGetMainViewport(), ImGuiDir.Down, 24, flags)) {
        if (igBeginMenuBar()) {
            igText(incTaskGetStatus().toStringz);
            igEndMenuBar();
        }
        igEnd();
    }
    igPopStyleColor();
}