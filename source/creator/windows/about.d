/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.about;
import creator.widgets.dummy;
import creator.windows;
import creator.core;
import creator;
import std.string;
import creator.utils.link;
import inochi2d;

class AboutWindow : Window {
protected:
    override
    void onBeginUpdate(int id) {
        igSetNextWindowSize(ImVec2(640, 512), ImGuiCond.Appearing);
        igSetNextWindowSizeConstraints(ImVec2(640, 512), ImVec2(float.max, float.max));
        super.onBeginUpdate(0);
    }

    override
    void onUpdate() {

        igBeginChild("##LogoArea", ImVec2(0, 72*incGetUIScale()));
            igImage(
                cast(void*)incGetLogo(), 
                ImVec2(64*incGetUIScale(), 64*incGetUIScale()), 
                ImVec2(0, 0), 
                ImVec2(1, 1), 
                ImVec4(1, 1, 1, 1), 
                ImVec4(0, 0, 0, 0)
            );
            
            igSameLine(0, 8);
            igSeparatorEx(ImGuiSeparatorFlags.Vertical);
            igSameLine(0, 8);
            igBeginChild("##LogoTextArea");

                igText("Inochi Creator");
                igText("%s", (INC_VERSION~"\0").ptr);
                igSeparator();
                igTextColored(ImVec4(0.5, 0.5, 0.5, 1), "I2D v. %s", (IN_VERSION~"\0").ptr);
                igTextColored(ImVec4(0.5, 0.5, 0.5, 1), "imgui v. %s", igGetVersion());
            igEndChild();
        igEndChild();
        igBeginChild("##CreditsArea", ImVec2(0, -28*incGetUIScale()));

            igText("Created By");
            igSeparator();

            igText(import("CONTRIBUTORS.md"));

        igEndChild();

        igBeginChild("##ButtonArea", ImVec2(0, 0));
            ImVec2 space = incAvailableSpace();
            incDummy(ImVec2(space.x/2, space.y));
            igSameLine(0, 0);

            space = incAvailableSpace();
            float spacing = (space.x/3)-8;

            if (igButton("GitHub", ImVec2(8+spacing, 0))) {
                incOpenLink("https://github.com/Inochi2D/inochi-creator");
            }

            igSameLine(0, 8);

            if (igButton("Twitter", ImVec2(spacing, 0))) {
                incOpenLink("https://twitter.com/Inochi2D");
            }

            igSameLine(0, 8);

            if (igButton("Donate", ImVec2(spacing, 0))) {
                incOpenLink("https://www.patreon.com/clipsey");
            }
        igEndChild();


    }

public:
    this() {
        super("About");
        this.onlyOne = true;
    }
}