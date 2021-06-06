module creator.windows.notice;
import creator.windows;
import creator.core;
import std.string;
import creator.utils.link;

class NoticeWindow : Window {
private:
    bool doNotShowAgain = false;

protected:
    override
    void onBeginUpdate(int id) {
        flags |= ImGuiWindowFlags_NoResize;
        super.onBeginUpdate(0);
    }

    override
    void onUpdate() {

        igBeginChildStr("##LogoArea", ImVec2(512, 72), false, 0);
            igImage(
                cast(void*)incGetLogo(), 
                ImVec2(64, 64), 
                ImVec2(0, 0), 
                ImVec2(1, 1), 
                ImVec4(1, 1, 1, 1), 
                ImVec4(0, 0, 0, 0)
            );
            
            igSameLine(0, 8);
            igSeparatorEx(ImGuiSeparatorFlags_Vertical);
            igSameLine(0, 8);

            igPushFont(incBiggerFont());
                igText("Inochi Creator");
            igPopFont();
        igEndChild();
        igBeginChildStr("##CreditsArea", ImVec2(512, 232), false, 0);

            igPushFont(incBiggerFont());
                igTextColored(ImVec4(1, 0, 0, 1), "THIS IS BETA SOFTWARE!");
            igPopFont();
            igSpacing();
            igText("Inochi2D and Inochi Creator is currently under heavy development
Using Inochi Creator in production is not advised, it *will* crash
out of nowhere and there's still plenty of bugs to fix.

The Inochi2D project is not to be held liable for broken
puppet files or crashes resulting from using this beta 
software.

If you accept this press the \"Close\" button to continue");

        igEndChild();

        if (igCheckbox("Don't show again", &doNotShowAgain)) {
            incSettingsSet("ShowWarning", !doNotShowAgain);
        }

        if (igButton("Close", ImVec2(0, 0))) {
            this.close();
        }

    }

public:
    this() {
        super("Under Construction");
    }
}