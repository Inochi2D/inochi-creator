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
    bool useOpenDyslexic;
    bool changesRequiresRestart;

    int tmpUIScale;
    float targetUIScale;

    SettingsPane settingsPane = SettingsPane.LookAndFeel;

    void beginSection(string title) {
        incText(title);
        incDummy(ImVec2(0, 4));
        igIndent();
    }
    
    void endSection() {
        igUnindent();
        igNewLine();
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

        // Sidebar
        if (igBeginChild("SettingsSidebar", ImVec2(128, -28), true)) {
            if (igSelectable(__("Look and Feel"), settingsPane == SettingsPane.LookAndFeel)) {
                settingsPane = SettingsPane.LookAndFeel;
            }
            
            if (igSelectable(__("Viewport"), settingsPane == SettingsPane.Viewport)) {
                settingsPane = SettingsPane.Viewport;
            }
            
            if (igSelectable(__("Accessbility"), settingsPane == SettingsPane.Accessibility)) {
                settingsPane = SettingsPane.Accessibility;
            }
        }
        igEndChild();
        
        // Nice spacing
        igSameLine(0, 4);

        // Contents
        if (igBeginChild("SettingsContent", ImVec2(0, -28), true)) {
            float availX = incAvailableSpace().x;

            // Begins section, REMEMBER TO END IT
            beginSection(_(cast(string)settingsPane));

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

                        beginSection(_("Undo History"));
                            int maxHistory = cast(int)incActionGetUndoHistoryLength();
                            if (igDragInt(__("Max Undo History"), &maxHistory, 1, 1, 1000, "%d")) {
                                incActionSetUndoHistoryLength(maxHistory);
                            }
                        endSection();

                        version(linux) {
                            beginSection(_("Linux Tweaks"));
                                bool disableCompositor = incSettingsGet!bool("DisableCompositor");
                                if (igCheckbox(__("Disable Compositor"), &disableCompositor)) {
                                    incSettingsSet("DisableCompositor", disableCompositor);
                                }
                            endSection();
                        }
                        break;
                    default:
                        incText(_("No settings for this category."));
                        break;
                }
            igPopItemWidth();
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


        // igPushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(4, 4));
        //     if (igBeginChild("SettingsWindowChild", ImVec2(512, 512))) {
        //         if (igBeginTabBar("SettingsWindowTabs", ImGuiTabBarFlags.NoCloseWithMiddleMouseButton)) {
        //             if(igBeginTabItem(__("General"), &generalTabOpen, ImGuiTabItemFlagsI.NoCloseButton | ImGuiTabItemFlags.NoCloseWithMiddleMouseButton)) {
        //                 if (igBeginChild("#GeneralTabItems", ImVec2(0, -26))) {
        //                     incText(_("Look and Feel"));
        //                     igSeparator();
        //                     if(igBeginCombo(__("Color Theme"), incGetDarkMode() ? __("Dark") : __("Light"))) {
        //                         if (igSelectable(__("Dark"), incGetDarkMode())) incSetDarkMode(true);
        //                         if (igSelectable(__("Light"), !incGetDarkMode())) incSetDarkMode(false);

        //                         igEndCombo();
        //                     }
                            
        //                     import std.string : toStringz;
        //                     if(igBeginCombo(__("Language"), incLocaleCurrentName().toStringz)) {
        //                         if (igSelectable("English")) incLocaleSet(null);
        //                         foreach(entry; incLocaleGetEntries()) {
        //                             if (igSelectable(entry.humanNameC)) incLocaleSet(entry.code);
        //                         }
        //                         igEndCombo();
        //                     }

        //                     version (UseUIScaling) {
        //                         if (igInputInt(__("UI Scale"), &tmpUIScale, 25, 50, ImGuiInputTextFlags.EnterReturnsTrue)) {
        //                             tmpUIScale = clamp(tmpUIScale, 100, 200);
        //                             incSetUIScale(cast(float)tmpUIScale/100.0);
        //                         }
        //                     }

        //                     version(linux) {
        //                         bool disableCompositor = incSettingsGet!bool("DisableCompositor");
        //                         if (igCheckbox(__("Disable Compositor"), &disableCompositor)) {
        //                             incSettingsSet("DisableCompositor", disableCompositor);
        //                         }
        //                     }

        //                     version(InGallium) {
        //                         bool useSWRender = incSettingsGet!bool("SoftwareRenderer");
        //                         if (igCheckbox(__("Use software rendering"), &useSWRender)) {
        //                             incSettingsSet("SoftwareRenderer", useSWRender);
        //                         }
        //                     }


        //                     igSpacing();
        //                     igSpacing();

        //                     incText(_("Undo/Redo History"));
        //                     igSeparator();
                            
        //                     int maxHistory = cast(int)incActionGetUndoHistoryLength();
        //                     if (igSliderInt(__("Max Undo History"), &maxHistory, 0, 1000, "%d")) {
        //                         incActionSetUndoHistoryLength(maxHistory);
        //                     }

        //                 }
        //                 igEndChild();

        //                 igEndTabItem();
        //             }

        //             if(igBeginTabItem(__("Accessibility"), &generalTabOpen, ImGuiTabItemFlagsI.NoCloseButton | ImGuiTabItemFlags.NoCloseWithMiddleMouseButton)) {
                        
        //                 if (igBeginChild("#GeneralTabItems", ImVec2(0, -26))) {
        //                 }
        //                 igEndChild();

        //                 igEndTabItem();
        //             }

        //             if(igBeginTabItem(__("Other"), &otherTabOpen, ImGuiTabItemFlagsI.NoCloseButton | ImGuiTabItemFlags.NoCloseWithMiddleMouseButton)) {

        //                 if (igBeginChild("#OtherTabItems", ImVec2(0, -26))) {
        //                 }
        //                 igEndChild();

        //                 igEndTabItem();
        //             }

        //             igEndTabBar();
        //         }

        //         // Save button
        //         if (igButton(__("Save"), ImVec2(0, 0))) {
        //             this.close();
        //         }

        //         igEndChild();
        //     }
        // igPopStyleVar();
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