module creator.windows.about;
import creator.windows;
import creator.core;
import std.string;
import creator.utils.link;

class AboutWindow : Window {
protected:
    override
    void onBeginUpdate(int id) {
        super.onBeginUpdate(id);
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
        igBeginChildStr("##CreditsArea", ImVec2(512, 256), false, 0);

            igText("Created By");
            igSeparator();

            igText(import("CONTRIBUTORS.md"));

        igEndChild();

        if (igButton("Fork us on GitHub", ImVec2(0, 0))) {
            openLink("https://github.com/Inochi2D/inochi-creator");
        }

        igSameLine(0, 8);

        if (igButton("Donate", ImVec2(0, 0))) {
            openLink("https://www.patreon.com/clipsey");
        }

        igSameLine(0, 8);

        if (igButton("Follow us on Twitter", ImVec2(0, 0))) {
            openLink("https://twitter.com/Inochi2D");
        }


    }

public:
    this() {
        super("About");
    }
}