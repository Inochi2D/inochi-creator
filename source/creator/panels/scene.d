/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.scene;
import creator.core;
import creator.viewport.test;
import creator.panels;
import creator.windows;
import creator.widgets;
import creator;
import bindbc.imgui;
import inochi2d;
import std.conv;
import i18n;
import std.string;


/**
    The textures frame
*/
class ScenePanel : Panel {
protected:
    override
    void onUpdate() {
        igColorEdit3(
            __("Ambient Light"), 
            &inSceneAmbientLight.vector, 
            ImGuiColorEditFlags.PickerHueWheel |
                ImGuiColorEditFlags.NoInputs
        );
    }

public:
    this() {
        super("Scene", _("Scene"), false);
    }
}

/**
    Generate scene panel frame
*/
mixin incPanel!ScenePanel;



