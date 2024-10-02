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
import inmath;


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

        igColorEdit3(
            __("Scene Light Color"), 
            &inSceneLightColor.vector, 
            ImGuiColorEditFlags.PickerHueWheel |
                ImGuiColorEditFlags.NoInputs
        );

        igSliderFloat3(
            __("Light Direction"),
            cast(float[3]*)inSceneLightDirection.ptr,
            -1, 1
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



