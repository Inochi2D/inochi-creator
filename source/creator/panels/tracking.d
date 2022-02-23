/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.tracking;
import creator.panels;
import creator.windows;
import creator.widgets;
import creator : incActivePuppet;
import bindbc.imgui;
import inochi2d;
import std.conv;
import i18n;

/**
    The textures frame
*/
class TrackingPanel : Panel {
private:
    bool trackVMC;
    bool trackOSF;
    int portN = 39540;

protected:
    override
    void onUpdate() {
        // TODO: check if in model test mode

        if (igCheckbox(__("VMC Receiver"), &trackVMC)) trackOSF = false;
        if (trackVMC) {
            if (igInputInt(__("Port"), &portN, 1, 1000, ImGuiInputTextFlags.None)) {
                portN = clamp(portN, 0, 65535);
            }
        }

        if (igCheckbox(__("OpenSeeFace Receiver"), &trackOSF)) trackVMC = false;
        if (trackOSF) {

        }
    }

public:
    this() {
        super(_("Tracking"), false);
    }
}

/**
    Generate tracking panel frame
*/
mixin incPanel!TrackingPanel;


