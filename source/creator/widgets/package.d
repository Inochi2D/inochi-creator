/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets;

public import bindbc.imgui;
public import creator.widgets.inputtext;
public import creator.widgets.progress;
public import creator.widgets.controller;
public import creator.widgets.toolbar;
public import creator.widgets.mainmenu;
public import creator.widgets.tooltip;
public import creator.widgets.statusbar;
public import creator.widgets.secrets;
public import creator.widgets.dummy;
public import creator.widgets.drag;
public import creator.widgets.lockbutton;
public import creator.widgets.colorbutton;
public import creator.widgets.dialog;
public import creator.widgets.label;

bool incBegin(const(char)* name, bool* pOpen, ImGuiWindowFlags flags) {
    version (NoUIScaling) {
        return igBegin(
            name, 
            pOpen, 
            incIsWayland() ? flags : flags | ImGuiWindowFlags.NoDecoration
        );
    } else version (UseUIScaling) {
        return igBegin(
            name, 
            pOpen, 
            flags
        );
    }
}

void incEnd() {
    igEnd();
}