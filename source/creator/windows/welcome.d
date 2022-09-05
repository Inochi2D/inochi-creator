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
    Texture bannerLogo;
    ImVec2 origWindowPadding;
    bool firstFrame = true;
    bool changesRequiresRestart;
    
    // Temporary variables for setup
    int tmpUIScale;

protected:
    override
    void onBeginUpdate() {
        flags |= ImGuiWindowFlags.NoResize;
        flags |= ImGuiWindowFlags.NoDecoration;

        ImVec2 wpos = ImVec2(
            igGetMainViewport().Pos.x+(igGetMainViewport().Size.x/2),
            igGetMainViewport().Pos.y+(igGetMainViewport().Size.y/2),
        );

        ImVec2 uiSize = ImVec2(
            512, 
            384
        );

        igSetNextWindowPos(wpos, ImGuiCond.Always, ImVec2(0.5, 0.5));
        igSetNextWindowSize(uiSize, ImGuiCond.Appearing);
        igSetNextWindowSizeConstraints(uiSize, uiSize);
        origWindowPadding = igGetStyle().WindowPadding;
        igPushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(0, 0));
        igPushStyleVar(ImGuiStyleVar.WindowRounding, 10);
        super.onBeginUpdate();
    }

    override
    void onEndUpdate() {
        igPopStyleVar(2);
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
                igPushStyleColor(ImGuiCol.Text, 0xFFFFFFFF);
                    // Banner Image
                    igImage(cast(void*)banner.getTextureId(), ImVec2(512, 200));

                    //Logo
                    igSetCursorPos(origin);
                    igImage(cast(void*)bannerLogo.getTextureId(), ImVec2(296, 100));
                    
                    // Version String
                    ImVec2 vsSize = incMeasureString(INC_VERSION);
                    igSetCursorPos(ImVec2(512-(vsSize.x+8), 8));
                    incTextShadowed(INC_VERSION);
                igPopStyleColor();
            }
            igEndChild();
        } else {
            igSetWindowFontScale(3);
                igText("Inochi Creator (Unsupported)");
            igSetWindowFontScale(1);
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
                                    if (igSelectable("English")) {
                                        incLocaleSet(null);
                                        changesRequiresRestart = true;
                                    }
                                    foreach(entry; incLocaleGetEntries()) {
                                        if (igSelectable(entry.humanNameC)) {
                                            incLocaleSet(entry.code);
                                            changesRequiresRestart = true;
                                        }
                                    }
                                    igEndCombo();
                                }

                                if(igBeginCombo(__("Color Theme"), incGetDarkMode() ? __("Dark") : __("Light"), comboFlags)) {
                                    if (igSelectable(__("Dark"), incGetDarkMode())) incSetDarkMode(true);
                                    if (igSelectable(__("Light"), !incGetDarkMode())) incSetDarkMode(false);

                                    igEndCombo();
                                }

                                version (UseUIScaling) {
                                    if (igInputInt(__("UI Scale"), &tmpUIScale, 25, 50, ImGuiInputTextFlags.EnterReturnsTrue)) {
                                        tmpUIScale = clamp(tmpUIScale, 100, 200);
                                        incSetUIScale(cast(float)tmpUIScale/100.0);
                                    }
                                }

                                if (changesRequiresRestart) {
                                    igNewLine();
                                    igPushTextWrapPos(avail.x/1.15);
                                        incTextColored(
                                            ImVec4(0.8, 0.2, 0.2, 1), 
                                            _("Inochi Creator needs to be restarted for some changes to take effect.")
                                        );
                                    igPopTextWrapPos();
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
                            incTextShadowed(_("Recent Projects"));
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
            auto bannerLogoTex = ShallowTexture(cast(ubyte[])import("ui/banner-logo.png"));

            //inTexPremultiply(bannerTex.data);
            
            banner = new Texture(bannerTex);
            bannerLogo = new Texture(bannerLogoTex);
        }
        if (!incSettingsGet!bool("hasDoneQuickSetup", false)) step = 0;

        // Load UI scale
        tmpUIScale = cast(int)(incGetUIScale()*100);
    }
}