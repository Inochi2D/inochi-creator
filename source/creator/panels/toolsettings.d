/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.toolsettings;
import creator.viewport;
import creator.panels;
import creator.windows;
import creator : incActivePuppet;
import bindbc.imgui;
import inochi2d;
import std.conv;
import i18n;

/**
    A list of tool settings
*/
class ToolSettingsPanel : Panel {
private:

protected:
    override
    void onUpdate() {
        incViewportToolSettings();
    }

public:
    this() {
        super("Tool Settings", _("Tool Settings"), false);
    }
}

/**
    Generate logger frame
*/
mixin incPanel!ToolSettingsPanel;


