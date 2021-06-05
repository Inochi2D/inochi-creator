module creator.windows.settings;
import creator.windows;
import creator.core;
import std.string;
import creator.utils.link;

/**
    Settings window
*/
class SettingsWindow : Window {
private:
    bool generalTabOpen = true;
    bool otherTabOpen = true;

protected:
    override
    void onBeginUpdate(int id) {
        super.onBeginUpdate(id);
    }

    override
    void onUpdate() {
        if (igBeginChildStr("SettingsWindowChild", ImVec2(512, 512), false, 0)) {
            if (igBeginTabBar("SettingsWindowTabs", ImGuiTabBarFlags_NoCloseWithMiddleMouseButton)) {

                ImVec2 avail;
                igGetContentRegionAvail(&avail);

                if(igBeginTabItem("General", &generalTabOpen, ImGuiTabItemFlags_NoCloseButton | ImGuiTabItemFlags_NoCloseWithMiddleMouseButton)) {

                    if (igBeginChildStr("#GeneralTabItems", ImVec2(0, avail.y-24), false, 0)) {

                        igText("Undo/Redo History");
                        igSeparator();
                        
                        int maxHistory = cast(int)incActionGetUndoHistoryLength();
                        if (igSliderInt("Max Undo History", &maxHistory, 0, 1000, "%d", 0)) {
                            incActionSetUndoHistoryLength(maxHistory);
                        }

                        igEndChild();
                    }

                    igEndTabItem();
                }

                if(igBeginTabItem("Other", &otherTabOpen, ImGuiTabItemFlags_NoCloseButton | ImGuiTabItemFlags_NoCloseWithMiddleMouseButton)) {

                    if (igBeginChildStr("#OtherTabItems", ImVec2(0, avail.y-24), false, 0)) {

                        igEndChild();
                    }
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
    }

    override
    void onClose() {
        incSettingsSave();
    }

public:
    this() {
        super("Settings");
    }
}