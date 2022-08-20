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

/**
    Settings window
*/
class SettingsWindow : Window {
private:
    bool generalTabOpen = true;
    bool otherTabOpen = true;
    bool useOpenDyslexic;

    int tmpUIScale;
    float targetUIScale;

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
            if (igBeginChild("SettingsWindowChild", ImVec2(512, 512))) {
                if (igBeginTabBar("SettingsWindowTabs", ImGuiTabBarFlags.NoCloseWithMiddleMouseButton)) {
                    if(igBeginTabItem(__("General"), &generalTabOpen, ImGuiTabItemFlagsI.NoCloseButton | ImGuiTabItemFlags.NoCloseWithMiddleMouseButton)) {
                        if (igBeginChild("#GeneralTabItems", ImVec2(0, -26))) {
                            incText(_("Look and Feel"));
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

                            version (UseUIScaling) {
                                if (igInputInt(__("UI Scale"), &tmpUIScale, 25, 50, ImGuiInputTextFlags.EnterReturnsTrue)) {
                                    tmpUIScale = clamp(tmpUIScale, 100, 200);
                                    incSetUIScale(cast(float)tmpUIScale/100.0);
                                }
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

                            incText(_("Undo/Redo History"));
                            igSeparator();
                            
                            int maxHistory = cast(int)incActionGetUndoHistoryLength();
                            if (igSliderInt(__("Max Undo History"), &maxHistory, 0, 1000, "%d")) {
                                incActionSetUndoHistoryLength(maxHistory);
                            }

                        }
                        igEndChild();

                        igEndTabItem();
                    }

                    if(igBeginTabItem(__("Accessibility"), &generalTabOpen, ImGuiTabItemFlagsI.NoCloseButton | ImGuiTabItemFlags.NoCloseWithMiddleMouseButton)) {
                        
                        if (igBeginChild("#GeneralTabItems", ImVec2(0, -26))) {
                        }
                        igEndChild();

                        igEndTabItem();
                    }

                    if(igBeginTabItem(__("Other"), &otherTabOpen, ImGuiTabItemFlagsI.NoCloseButton | ImGuiTabItemFlags.NoCloseWithMiddleMouseButton)) {

                        if (igBeginChild("#OtherTabItems", ImVec2(0, -26))) {
                        }
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
            }
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
        targetUIScale = incGetUIScale();
        tmpUIScale = cast(int)(incGetUIScale()*100);
    }
}