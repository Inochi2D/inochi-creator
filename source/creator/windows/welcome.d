/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.welcome;
import creator.widgets.label;
import creator.widgets.dummy;
import creator.windows;
import creator.core;
import creator.core.i18n;
import std.string;
import creator.utils.link;
import i18n;
import inochi2d;
import creator.ver;
import creator.io;
import creator;

class WelcomeWindow : Window {
private:
    int step = 1;
    Texture banner;
    ImVec2 origWindowPadding;
    bool firstFrame = true;

protected:
    override
    void onBeginUpdate() {
        flags |= ImGuiWindowFlags.NoResize;
        flags |= ImGuiWindowFlags.NoDecoration;

        ImVec2 wpos = ImVec2(
            igGetMainViewport().Pos.x+(igGetMainViewport().Size.x/2),
            igGetMainViewport().Pos.y+(igGetMainViewport().Size.y/2),
        );

        igSetNextWindowPos(wpos, ImGuiCond.Always, ImVec2(0.5, 0.5));
        igSetNextWindowSize(ImVec2(512, 384), ImGuiCond.Appearing);
        igSetNextWindowSizeConstraints(ImVec2(512, 384), ImVec2(float.max, float.max));
        origWindowPadding = igGetStyle().WindowPadding;
        igPushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(0, 0));
        super.onBeginUpdate();
    }

    override
    void onEndUpdate() {
        igPopStyleVar();
        super.onEndUpdate();
    }

    override
    void onUpdate() {
        
        // Fix styling for subwindows
        igPushStyleVar(ImGuiStyleVar.WindowPadding, origWindowPadding);
        auto windowViewport = igGetWindowViewport();
        windowViewport.Flags |= ImGuiViewportFlags.TopMost;
        windowViewport.Flags |= ImGuiViewportFlags.NoDecoration;
        windowViewport.Flags |= ImGuiViewportFlags.NoTaskBarIcon;
        

        ImVec2 origin;
        igGetCursorStartPos(&origin);

        version(InBranding) {

            if (igBeginChild("##BANNER", ImVec2(0, 200))) {

                // Banner Image
                igImage(cast(void*)banner.getTextureId(), ImVec2(512, 200));
                
                // Version String
                ImVec2 vsSize = incMeasureString(INC_VERSION);
                igSetCursorPos(ImVec2(512-(vsSize.x+8), 8));
                incTextShadowed(INC_VERSION);
            }
            igEndChild();
        }
        igSetCursorPos(ImVec2(origin.x, origin.y+192));

        
        igIndent();
            if (igBeginChild("##CONFIG_AREA", ImVec2(-4, 0), false, ImGuiWindowFlags.NoScrollbar)) {
                ImVec2 avail = incAvailableSpace();
                igPushTextWrapPos(avail.x);
                switch(step) {

                    // SETUP PAGE
                    case 0:
                        incDummy(ImVec2(0, 4));

                        incTextShadowed(_("Quick Setup"));
                        igNewLine();

                        incDummy(ImVec2(avail.x/6, 64));
                        igSameLine(0, 0);
                        igBeginGroup();
                            igPushItemWidth(avail.x/3);
                                auto comboFlags = 
                                    ImGuiComboFlags.NoArrowButton | 
                                    ImGuiComboFlags.HeightLargest;
                                
                                if(igBeginCombo(__("Language"), incLocaleCurrentName().toStringz, comboFlags)) {
                                    if (igSelectable("English")) incLocaleSet(null);
                                    foreach(entry; incLocaleGetEntries()) {
                                        if (igSelectable(entry.humanNameC)) incLocaleSet(entry.code);
                                    }
                                    igEndCombo();
                                }

                                if(igBeginCombo(__("Color Theme"), incGetDarkMode() ? __("Dark") : __("Light"), comboFlags)) {
                                    if (igSelectable(__("Dark"), incGetDarkMode())) incSetDarkMode(true);
                                    if (igSelectable(__("Light"), !incGetDarkMode())) incSetDarkMode(false);

                                    igEndCombo();
                                }
                            igPopItemWidth();
                        igEndGroup();

                        // Move down to where we want our button
                        incDummy(ImVec2(0, -32));

                        // Move button to the right
                        incDummy(ImVec2(-64, 24));
                        igSameLine(0, 0);
                        if (igButton(__("Next"), ImVec2(64, 24))) {
                            incSettingsSet!bool("hasDoneQuickSetup", true);
                            step++;
                        }
                        break;

                    // WELCOME PAGE
                    case 1:
                        incDummy(ImVec2(0, 4));

                        // Left hand side
                        if (igBeginChild("##LHS", ImVec2((avail.x-8)/2, 0), false, ImGuiWindowFlags.NoScrollbar)) {
                            incTextShadowed(_("Create Project"));
                            incDummy(ImVec2(0, 2));
                            igIndent();
                                if (incTextLinkWithIcon("", _("New..."))) {
                                    incNewProject();
                                    this.close();
                                }

                                if (incTextLinkWithIcon("", _("Open..."))) {
                                    string file = incShowOpenDialog();
                                    if (file) {
                                        incOpenProject(file);
                                        this.close();
                                    }
                                }


                                if (incTextLinkWithIcon("", _("Import PSD..."))) {
                                    if (incImportShowPSDDialog()) {
                                        this.close();
                                    }
                                }

                            igUnindent();

                            incDummy(ImVec2(0, 6));
                            incTextShadowed(_("Recent Projects..."));
                            incDummy(ImVec2(0, 2));
                            igIndent();
                                if (incGetPrevProjects().length > 0) {
                                    foreach(i, recent; incGetPrevProjects()) {
                                        if (i >= 4) break;

                                        import std.path : baseName;
                                        if (incTextLinkWithIcon("", recent.baseName)) {
                                            incOpenProject(recent);
                                            this.close();
                                        }
                                    }
                                } else {
                                    incTextShadowed("No recent projects...");
                                }
                            igUnindent();
                        }
                        igEndChild();

                        igSameLine(0, 4);

                        // Right hand side
                        if (igBeginChild("##RHS", ImVec2((avail.x-8)/2, 0), false, ImGuiWindowFlags.NoScrollbar)) {
                            incTextShadowed(_("On the Web"));
                            incDummy(ImVec2(0, 2));
                            igIndent();

                                if (incTextLinkWithIcon("", _("Website"))) {
                                    incOpenLink("https://inochi2d.com");
                                }

                                if (incTextLinkWithIcon("", _("Documentation"))) {
                                    incOpenLink("https://github.com/Inochi2D/Inochi-creator/wiki");
                                }

                                igNewLine();
                                igNewLine();
                                if (incTextLinkWithIcon("", _("Patreon"))) {
                                    incOpenLink("https://www.patreon.com/LunaFoxgirlVT");
                                }
                                if (incTextLinkWithIcon("", _("Github Sponsors"))) {
                                    incOpenLink("https://github.com/sponsors/LunaTheFoxgirl/");
                                }
                            igUnindent();
                        }
                        igEndChild();
                        break;

                    default:
                        this.close();
                        break;
                }
                igPopTextWrapPos(); 
            }
            igEndChild();
        igUnindent();
        igPopStyleVar();
    }

    override
    void onClose() {
        if (step > 0) incSettingsSet!bool("hasDoneQuickSetup", true);
    }

public:
    this() {
        super(_("Inochi Creator Start"));

        version(InBranding) {
            auto bannerTex = ShallowTexture(cast(ubyte[])import("ui/banner.png"));
            //inTexPremultiply(bannerTex.data);
            banner = new Texture(bannerTex);
        }
        if (!incSettingsGet!bool("hasDoneQuickSetup", false)) step = 0;
    }
}