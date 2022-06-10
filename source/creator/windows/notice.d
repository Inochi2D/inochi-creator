/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.notice;
import creator.widgets.label;
import creator.windows;
import creator.core;
import std.string;
import creator.utils.link;
import i18n;

class NoticeWindow : Window {
private:
    bool doNotShowAgain = false;

protected:
    override
    void onBeginUpdate() {
        flags |= ImGuiWindowFlags.NoResize;
        igSetNextWindowSize(ImVec2(512, 384), ImGuiCond.Appearing);
        igSetNextWindowSizeConstraints(ImVec2(512, 384), ImVec2(float.max, float.max));
        super.onBeginUpdate();
    }

    override
    void onUpdate() {

        if (igBeginChild("##LogoArea", ImVec2(0, 72))) {

            version (InBranding) {
                igImage(
                    cast(void*)incGetLogo(), 
                    ImVec2(64, 64), 
                    ImVec2(0, 0), 
                    ImVec2(1, 1), 
                    ImVec4(1, 1, 1, 1), 
                    ImVec4(0, 0, 0, 0)
                );
            }
            
            igSameLine(0, 8);
            igSeparatorEx(ImGuiSeparatorFlags.Vertical);
            igSameLine(0, 8);

            igPushFont(incBiggerFont());
                incText("Inochi Creator");
            igPopFont();
        }
        igEndChild();

        if (igBeginChild("##CreditsArea", ImVec2(0, -48))) {

            igPushFont(incBiggerFont());
                igTextColored(ImVec4(1, 0, 0, 1), _("THIS IS BETA SOFTWARE!").toStringz);
            igPopFont();
            igSpacing();
            incText(_("Inochi2D and Inochi Creator is currently under heavy development\nUsing Inochi Creator in production is not advised, it *will* crash\nout of nowhere and there's still plenty of bugs to fix.\n\nThe Inochi2D project is not to be held liable for broken\npuppet files or crashes resulting from using this beta \nsoftware.\n\nIf you accept this press the \"Close\" button to continue"));

        }
        igEndChild();

        if (igCheckbox(__("Don't show again"), &doNotShowAgain)) {
            incSettingsSet("ShowWarning", !doNotShowAgain);
        }

        if (igButton(__("Close"), ImVec2(0, 0))) {
            this.close();
        }

    }

public:
    this() {
        super(_("Under Construction"));
    }
}