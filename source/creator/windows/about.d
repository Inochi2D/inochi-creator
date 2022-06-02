/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.about;
import creator.widgets.dummy;
import creator.widgets.tooltip;
import creator.windows;
import creator.core;
import creator;
import std.string;
import creator.utils.link;
import inochi2d;
import i18n;
import std.stdio;

class AboutWindow : Window {
private:
    version (InBranding) {
        Texture ada;
        enum ADA_SIZE = 373;
        enum ADA_SIZE_PARTIAL = ADA_SIZE/6;
        vec2 ada_float;
    }

protected:
    override
    void onBeginUpdate() {
        igSetNextWindowSize(ImVec2(640, 512), ImGuiCond.Appearing);
        igSetNextWindowSizeConstraints(ImVec2(640, 512), ImVec2(float.max, float.max));
        super.onBeginUpdate();
    }

    override
    void onUpdate() {

        // Draw Ada
        ImVec2 sPos;
        igGetCursorScreenPos(&sPos);


        version (InBranding) {
            ImVec2 avail = incAvailableSpace();
            igSetCursorScreenPos(ImVec2(
                sPos.x+(avail.x-(ADA_SIZE-ADA_SIZE_PARTIAL)), 
                sPos.y+(avail.y-(ADA_SIZE+28))+(sin(currentTime())*4)
            ));
            igImage(
                cast(void*)ada.getTextureId(),
                ImVec2(ADA_SIZE, ADA_SIZE),
                ImVec2(0, 0),
                ImVec2(1, 1), 
                ImVec4(1, 1, 1, 0.4), ImVec4(0, 0, 0, 0)
            );
        }

        // Draw the actual about dialog
        igSetCursorScreenPos(sPos);
        igBeginChild("##LogoArea", ImVec2(0, 92*incGetUIScale()));

            version (InBranding) {
                igImage(
                    cast(void*)incGetLogo(), 
                    ImVec2(64*incGetUIScale(), 64*incGetUIScale()), 
                    ImVec2(0, 0), 
                    ImVec2(1, 1), 
                    ImVec4(1, 1, 1, 1), 
                    ImVec4(0, 0, 0, 0)
                );
            }
            
            igSameLine(0, 8);
            igSeparatorEx(ImGuiSeparatorFlags.Vertical);
            igSameLine(0, 8);
            igBeginChild("##LogoTextArea", ImVec2(0, -24));

                igText("Inochi Creator");
                igText("%s", (INC_VERSION~"\0").ptr);
                igSeparator();
                igTextColored(ImVec4(0.5, 0.5, 0.5, 1), "I2D v. %s", (IN_VERSION~"\0").ptr);
                igTextColored(ImVec4(0.5, 0.5, 0.5, 1), "imgui v. %s", igGetVersion());
            igEndChild();
            
            igSpacing();
            igText("Credits");
            igSeparator();
        igEndChild();

        igBeginChild("##CreditsArea", ImVec2(0, -28*incGetUIScale()));

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

            if (igButton(__("Donate"), ImVec2(spacing, 0))) {
                incOpenLink("https://www.patreon.com/clipsey");
            }
        igEndChild();
    }

public:
    ~this() {
        version(InBranding) destroy(ada);
    }

    this() {
        super(_("About"));
        this.onlyOne = true;

        // Only load Ada in official builds
        version(InBranding) {
            ada_float = vec2(0);
            auto adaData = ShallowTexture(cast(ubyte[])import("ada-tex.png"));
            inTexPremultiply(adaData.data);
            ada = new Texture(adaData);
        }
    }
}