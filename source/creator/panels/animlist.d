/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.animlist;
import creator.panels;
import creator : EditMode;
import i18n;
import bindbc.imgui;
import creator;
import std.string;
import inochi2d;
import creator.widgets;
import creator.windows;

/**
    The logger frame
*/
class AnimListPanel : Panel {
private:

protected:
    override
    void onUpdate() {
        auto canim = incAnimationGet();
        string currAnimName = canim ? canim.name : "";

        if (igBeginChild("ANIM_LIST", ImVec2(0, -32), true)) {
            foreach(name, ref anim; incActivePuppet().getAnimations()) {
                if (igSelectable(name.toStringz, name == currAnimName)) {
                    incAnimationChange(name);
                }
            }
        }
        igEndChild();

        incDummy(ImVec2(0, 2));

        if (igBeginChild("ANIM_BTNS", ImVec2(0, 0), false, ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoScrollWithMouse)) {

            incDummy(ImVec2(-26, 0));
            igSameLine(0, 0);

            if (igButton("", ImVec2(24, 24))) {
                incPushWindow(new NewAnimationWindow());
            }
        }
    }

public:
    this() {
        super("Animation List", _("Animation List"), false);
        activeModes = EditMode.AnimEdit;
    }
}

/**
    Generate logger frame
*/
mixin incPanel!AnimListPanel;


