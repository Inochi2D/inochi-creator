/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.settings;
import creator.windows;
import creator.widgets;
import creator.core;
import creator.core.i18n;
import std.string;
import creator.utils.link;
import i18n;
import inmath;

bool incIsSettingsOpen;

enum SettingsPane : string {
    LookAndFeel = "Look and Feel",
    Viewport = "Viewport",
    Accessibility = "Accessbility"
}

/**
    Settings window
*/
class SettingsWindow : Window {
private:
    bool generalTabOpen = true;
    bool otherTabOpen = true;
    bool changesRequiresRestart;

    int tmpUIScale;
    float targetUIScale;

    SettingsPane settingsPane = SettingsPane.LookAndFeel;

    void beginSection(const(char)* title) {
        incBeginCategory(title, IncCategoryFlags.NoCollapse);
        incDummy(ImVec2(0, 4));
    }
    
    void endSection() {
        incDummy(ImVec2(0, 4));
        incEndCategory();
    }
protected:
    override
    void onBeginUpdate() {
        flags |= ImGuiWindowFlags.NoSavedSettings;
        incIsSettingsOpen = true;
        
        ImVec2 wpos = ImVec2(
            igGetMainViewport().Pos.x+(igGetMainViewport().Size.x/2),
            igGetMainViewport().Pos.y+(igGetMainViewport().Size.y/2),
        );

        ImVec2 uiSize = ImVec2(
            512, 
            256+128
        );

        igSetNextWindowPos(wpos, ImGuiCond.Appearing, ImVec2(0.5, 0.5));
        igSetNextWindowSize(uiSize, ImGuiCond.Appearing);
        igSetNextWindowSizeConstraints(uiSize, ImVec2(float.max, float.max));
        super.onBeginUpdate();
    }

    override
    void onUpdate() {
        float availX = incAvailableSpace().x;

        // Sidebar
        if (igBeginChild("SettingsSidebar", ImVec2(availX/3.5, -28), true)) {
            igPushTextWrapPos(128);
                if (igSelectable(__("Look and Feel"), settingsPane == SettingsPane.LookAndFeel)) {
                    settingsPane = SettingsPane.LookAndFeel;
                }
                
                if (igSelectable(__("Viewport"), settingsPane == SettingsPane.Viewport)) {
                    settingsPane = SettingsPane.Viewport;
                }
                
                if (igSelectable(__("Accessbility"), settingsPane == SettingsPane.Accessibility)) {
                    settingsPane = SettingsPane.Accessibility;
                }
            igPopTextWrapPos();
        }
        igEndChild();
        
        // Nice spacing
        igSameLine(0, 4);

        // Contents
        if (igBeginChild("SettingsContent", ImVec2(0, -28), true)) {
            availX = incAvailableSpace().x;

            // Begins section, REMEMBER TO END IT
            beginSection(__(cast(string)settingsPane));

            // Start settings panel elements
            igPushItemWidth(availX/2);
                switch(settingsPane) {
                    case SettingsPane.LookAndFeel:
                        if(igBeginCombo(__("Color Theme"), incGetDarkMode() ? __("Dark") : __("Light"))) {
                            if (igSelectable(__("Dark"), incGetDarkMode())) incSetDarkMode(true);
                            if (igSelectable(__("Light"), !incGetDarkMode())) incSetDarkMode(false);

                            igEndCombo();
                        }
                        
                        import std.string : toStringz;
                        if(igBeginCombo(__("Language"), incLocaleCurrentName().toStringz)) {
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

                        version (UseUIScaling) {
                            if (igInputInt(__("UI Scale"), &tmpUIScale, 25, 50, ImGuiInputTextFlags.EnterReturnsTrue)) {
                                tmpUIScale = clamp(tmpUIScale, 100, 200);
                                incSetUIScale(cast(float)tmpUIScale/100.0);
                            }
                        }
                        endSection();

                        beginSection(__("Undo History"));
                            int maxHistory = cast(int)incActionGetUndoHistoryLength();
                            if (igDragInt(__("Max Undo History"), &maxHistory, 1, 1, 1000, "%d")) {
                                incActionSetUndoHistoryLength(maxHistory);
                            }
                        endSection();

                        version(linux) {
                            beginSection(__("Linux Tweaks"));
                                bool disableCompositor = incSettingsGet!bool("DisableCompositor");
                                if (igCheckbox(__("Disable Compositor"), &disableCompositor)) {
                                    incSettingsSet("DisableCompositor", disableCompositor);
                                }
                            endSection();
                        }
                        break;
                    case SettingsPane.Accessibility:
                        bool disableCompositor = incSettingsGet!bool("useOpenDyslexic");
                        if (igCheckbox(__("Use OpenDyslexic Font"), &disableCompositor)) {
                            incSettingsSet("useOpenDyslexic", disableCompositor);
                            changesRequiresRestart = true;
                        }
                        incTooltip("Use the OpenDyslexic font for Latin text characters.");
                        endSection();
                        break;
                    default:
                        incLabelOver(_("No settings for this category."), ImVec2(0, 0), true);
                        break;
                }
            igPopItemWidth();

            endSection();
        }
        igEndChild();

        // Bottom buttons
        if (igBeginChild("SettingsButtons", ImVec2(0, 0), false, ImGuiWindowFlags.NoScrollbar)) {
            if (changesRequiresRestart) {
                igPushTextWrapPos(256+128);
                    incTextColored(
                        ImVec4(0.8, 0.2, 0.2, 1), 
                        _("Inochi Creator needs to be restarted for some changes to take effect.")
                    );
                igPopTextWrapPos();
                igSameLine(0, 0);
            }
            incDummy(ImVec2(-64, 0));
            igSameLine(0, 0);

            if (igButton(__("Done"), ImVec2(64, 24))) {
                this.close();
            }
        }
        igEndChild();
    }

    override
    void onClose() {
        incSettingsSave();
        incIsSettingsOpen = false;
    }

public:
    this() {
        super(_("Settings"));
        targetUIScale = incGetUIScale();
        tmpUIScale = cast(int)(incGetUIScale()*100);
    }
}