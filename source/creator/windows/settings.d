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
        flags |= ImGuiWindowFlags.NoResize;
        super.onBeginUpdate(0);
        incIsSettingsOpen = true;
    }

    override
    void onUpdate() {
        igBeginChild("SettingsWindowChild", ImVec2(512, 512));
            if (igBeginTabBar("SettingsWindowTabs", ImGuiTabBarFlags.NoCloseWithMiddleMouseButton)) {

                ImVec2 avail;
                igGetContentRegionAvail(&avail);

                if(igBeginTabItem("General", &generalTabOpen, ImGuiTabItemFlagsI.NoCloseButton | ImGuiTabItemFlags.NoCloseWithMiddleMouseButton)) {
                    igBeginChild("#GeneralTabItems", ImVec2(0, avail.y-24));
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

                        useOpenDyslexic = incSettingsGet!bool("UseOpenDyslexic");
                        if(igCheckbox("Use OpenDyslexic", &useOpenDyslexic)) {
                            incUseOpenDyslexic(useOpenDyslexic);
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

                if(igBeginTabItem("Other", &otherTabOpen, ImGuiTabItemFlagsI.NoCloseButton | ImGuiTabItemFlags.NoCloseWithMiddleMouseButton)) {

                    igBeginChild("#OtherTabItems", ImVec2(0, avail.y-24));

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