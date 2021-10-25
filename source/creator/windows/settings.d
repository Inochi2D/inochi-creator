/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.settings;
import creator.windows;
import creator.widgets;
import creator.core;
import std.string;
import creator.utils.link;

bool incIsSettingsOpen;

/**
    Settings window
*/
class SettingsWindow : Window {
private:
    bool generalTabOpen = true;
    bool otherTabOpen = true;
    bool useOpenDyslexic;

protected:
    override
    void onBeginUpdate(int id) {
        flags |= ImGuiWindowFlags.NoResize;
        flags |= ImGuiWindowFlags.NoSavedSettings;
        super.onBeginUpdate(0);
        incIsSettingsOpen = true;
    }

    override
    void onUpdate() {
        igPushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(4, 4));
            igBeginChild("SettingsWindowChild", ImVec2(512*incGetUIScale(), 512*incGetUIScale()));
                if (igBeginTabBar("SettingsWindowTabs", ImGuiTabBarFlags.NoCloseWithMiddleMouseButton)) {
                    if(igBeginTabItem("General", &generalTabOpen, ImGuiTabItemFlagsI.NoCloseButton | ImGuiTabItemFlags.NoCloseWithMiddleMouseButton)) {
                        igBeginChild("#GeneralTabItems", ImVec2(0, -26));
                            igText("Look and Feel");
                            igSeparator();
                            if(igBeginCombo("Color Theme", incGetDarkMode() ? "Dark" : "Light")) {
                                if (igSelectable("Dark", incGetDarkMode())) incSetDarkMode(true);
                                if (igSelectable("Light", !incGetDarkMode())) incSetDarkMode(false);

                                igEndCombo();
                            }
                            if(igBeginCombo("Language", "English")) {
                                igEndCombo();
                            }

                            if(igBeginCombo("UI Scale (EXPERIMENTAL)", incGetUIScaleText().toStringz)) {
                                if (igSelectable("100%")) incSetUIScale(1.0);
                                if (igSelectable("150%")) incSetUIScale(1.5);
                                if (igSelectable("200%")) incSetUIScale(2.0);

                                igEndCombo();
                            }

                            if (incCanUseAppTitlebar) {
                                bool useNative = incGetUseNativeTitlebar();
                                if (igCheckbox("Use Native Titlebar", &useNative)) {
                                    incSettingsSet("UseNativeTitleBar", useNative);
                                    incSetUseNativeTitlebar(useNative);
                                }
                            }


                            igSpacing();
                            igSpacing();

                            igText("Undo/Redo History");
                            igSeparator();
                            
                            int maxHistory = cast(int)incActionGetUndoHistoryLength();
                            if (igSliderInt("Max Undo History", &maxHistory, 0, 1000, "%d")) {
                                incActionSetUndoHistoryLength(maxHistory);
                            }

                        igEndChild();

                        igEndTabItem();
                    }

                    if(igBeginTabItem("Accessibility", &generalTabOpen, ImGuiTabItemFlagsI.NoCloseButton | ImGuiTabItemFlags.NoCloseWithMiddleMouseButton)) {
                        
                        igBeginChild("#GeneralTabItems", ImVec2(0, -26));

                        igEndChild();
                        igEndTabItem();
                    }

                    if(igBeginTabItem("Other", &otherTabOpen, ImGuiTabItemFlagsI.NoCloseButton | ImGuiTabItemFlags.NoCloseWithMiddleMouseButton)) {

                        igBeginChild("#OtherTabItems", ImVec2(0, -26));

                        igEndChild();
                        igEndTabItem();
                    }

                    igEndTabBar();
                }

                // Save button
                if (igButton("Save", ImVec2(0, 0))) {
                    this.close();
                }

            igEndChild();
        igPopStyleVar();
    }

    override
    void onClose() {
        incSettingsSave();
        incIsSettingsOpen = false;
    }

public:
    this() {
        super("Settings");
    }
}