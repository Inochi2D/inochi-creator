module creator.windows.settings;
import creator.windows;
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
        flags |= ImGuiWindowFlags_NoResize;
        super.onBeginUpdate(0);
        incIsSettingsOpen = true;
    }

    override
    void onUpdate() {
        igBeginChildStr("SettingsWindowChild", ImVec2(512, 512), false, 0);
            if (igBeginTabBar("SettingsWindowTabs", ImGuiTabBarFlags_NoCloseWithMiddleMouseButton)) {

                ImVec2 avail;
                igGetContentRegionAvail(&avail);

                if(igBeginTabItem("General", &generalTabOpen, ImGuiTabItemFlags_NoCloseButton | ImGuiTabItemFlags_NoCloseWithMiddleMouseButton)) {

                    igBeginChildStr("#GeneralTabItems", ImVec2(0, avail.y-24), false, 0);
                        igText("Look and Feel");
                        igSeparator();
                        if(igBeginCombo("Color Theme", incGetDarkMode() ? "Dark" : "Light", 0)) {

                            if (igSelectableBool("Dark", incGetDarkMode(), 0, ImVec2(0, 0))) incSetDarkMode(true);
                            if (igSelectableBool("Light", !incGetDarkMode(), 0, ImVec2(0, 0))) incSetDarkMode(false);

                            igEndCombo();
                        }
                        if(igBeginCombo("Language", "English", 0)) {
                            igEndCombo();
                        }

                        useOpenDyslexic = incSettingsGet!bool("UseOpenDyslexic");
                        if(igCheckbox("Use OpenDyslexic", &useOpenDyslexic)) {
                            incUseOpenDyslexic(useOpenDyslexic);
                        }



                        igSpacing();
                        igSpacing();

                        igText("Undo/Redo History");
                        igSeparator();
                        
                        int maxHistory = cast(int)incActionGetUndoHistoryLength();
                        if (igSliderInt("Max Undo History", &maxHistory, 0, 1000, "%d", 0)) {
                            incActionSetUndoHistoryLength(maxHistory);
                        }

                    igEndChild();

                    igEndTabItem();
                }

                if(igBeginTabItem("Other", &otherTabOpen, ImGuiTabItemFlags_NoCloseButton | ImGuiTabItemFlags_NoCloseWithMiddleMouseButton)) {

                    igBeginChildStr("#OtherTabItems", ImVec2(0, avail.y-24), false, 0);

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