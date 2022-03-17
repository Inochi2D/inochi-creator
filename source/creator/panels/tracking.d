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
    bool trackDummy;

    // vmc
    int portN = 39540;


    // osf

    // dummy
protected:
    override
    void onUpdate() {
        // TODO: check if in model test mode

        if (igCheckbox(__("VMC Receiver"), &trackVMC)) trackOSF = false;
        incTooltip(_("A reciever which uses your phone and associated app to track your body"));
        if (trackVMC) {
            if (igInputInt(__("Port"), &portN, 1, 1000, ImGuiInputTextFlags.None)) {
                portN = clamp(portN, 0, 65535);
            }
        }

        if (igCheckbox(__("OpenSeeFace Receiver"), &trackOSF)) trackVMC = false;
        incTooltip(_("A reciever which uses a webcam connected to your computer to track your body"));
        if (trackOSF) {

        }

        if (igCheckbox(__("Dummy Receiver"), &trackDummy)) trackVMC = false;
        incTooltip(_("A reciever which randomly adjusts chosen parameters"));
        if (trackOSF) {

        }
    }

public:
    this() {
        super("Tracking", _("Tracking"), false);
    }
}

/**
    Generate tracking panel frame
*/
mixin incPanel!TrackingPanel;


