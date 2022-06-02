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
    void onBeginUpdate() {
        flags |= ImGuiWindowFlags.NoResize;
        flags |= ImGuiWindowFlags.NoSavedSettings;
        incIsSettingsOpen = true;
        super.onBeginUpdate();
    }

    override
    void onUpdate() {
        igPushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(4, 4));
            igBeginChild("SettingsWindowChild", ImVec2(512*incGetUIScale(), 512*incGetUIScale()));
                if (igBeginTabBar("SettingsWindowTabs", ImGuiTabBarFlags.NoCloseWithMiddleMouseButton)) {
                    if(igBeginTabItem(__("General"), &generalTabOpen, ImGuiTabItemFlagsI.NoCloseButton | ImGuiTabItemFlags.NoCloseWithMiddleMouseButton)) {
                        igBeginChild("#GeneralTabItems", ImVec2(0, -26));
                            igText(__("Look and Feel"));
                            igSeparator();
                            if(igBeginCombo(__("Color Theme"), incGetDarkMode() ? __("Dark") : __("Light"))) {
                                if (igSelectable(__("Dark"), incGetDarkMode())) incSetDarkMode(true);
                                if (igSelectable(__("Light"), !incGetDarkMode())) incSetDarkMode(false);

                                igEndCombo();
                            }
                            
                            import std.string : toStringz;
                            if(igBeginCombo(__("Language"), incLocaleCurrentName().toStringz)) {
                                if (igSelectable("English")) incLocaleSet(null);
                                foreach(entry; incLocaleGetEntries()) {
                                    if (igSelectable(entry.humanNameC)) incLocaleSet(entry.code);
                                }
                                igEndCombo();
                            }

                            if(igBeginCombo(__("UI Scale (EXPERIMENTAL)"), incGetUIScaleText().toStringz)) {
                                if (igSelectable("100%")) incSetUIScale(1.0);
                                if (igSelectable("150%")) incSetUIScale(1.5);
                                if (igSelectable("200%")) incSetUIScale(2.0);

                                igEndCombo();
                            }

                            version(linux) {
                                bool disableCompositor = incSettingsGet!bool("DisableCompositor");
                                if (igCheckbox(__("Disable Compositor"), &disableCompositor)) {
                                    incSettingsSet("DisableCompositor", disableCompositor);
                                }
                            }

                            version(InGallium) {
                                bool useSWRender = incSettingsGet!bool("SoftwareRenderer");
                                if (igCheckbox(__("Use software rendering"), &useSWRender)) {
                                    incSettingsSet("SoftwareRenderer", useSWRender);
                                }
                            }


                            igSpacing();
                            igSpacing();

                            igText(__("Undo/Redo History"));
                            igSeparator();
                            
                            int maxHistory = cast(int)incActionGetUndoHistoryLength();
                            if (igSliderInt(__("Max Undo History"), &maxHistory, 0, 1000, "%d")) {
                                incActionSetUndoHistoryLength(maxHistory);
                            }

                        igEndChild();

                        igEndTabItem();
                    }

                    if(igBeginTabItem(__("Accessibility"), &generalTabOpen, ImGuiTabItemFlagsI.NoCloseButton | ImGuiTabItemFlags.NoCloseWithMiddleMouseButton)) {
                        
                        igBeginChild("#GeneralTabItems", ImVec2(0, -26));

                        igEndChild();
                        igEndTabItem();
                    }

                    if(igBeginTabItem(__("Other"), &otherTabOpen, ImGuiTabItemFlagsI.NoCloseButton | ImGuiTabItemFlags.NoCloseWithMiddleMouseButton)) {

                        igBeginChild("#OtherTabItems", ImVec2(0, -26));

                        igEndChild();
                        igEndTabItem();
                    }

                    igEndTabBar();
                }

                // Save button
                if (igButton(__("Save"), ImVec2(0, 0))) {
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
        super(_("Settings"));
    }
}