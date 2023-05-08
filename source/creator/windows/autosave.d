/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors:
        PanzerKern
        Luna Nielsen
*/
module creator.windows.autosave;

import creator;
import creator.windows;
import creator.widgets;
import creator.widgets.dummy;
import creator.widgets.label : incText;
import creator.io.autosave;
import i18n;
import std.path : stripExtension;
import bindbc.imgui;

class RestoreSaveWindow : Window {
private:
    string projectPath;

protected:
    override
    void onBeginUpdate() {
        ImVec2 middlepos = ImVec2(
            igGetMainViewport().Pos.x+(igGetMainViewport().Size.x/2),
            igGetMainViewport().Pos.y+(igGetMainViewport().Size.y/2),
        );
        igSetNextWindowPos(middlepos, ImGuiCond.Appearing, ImVec2(0.5, 0.5));
        igSetNextWindowSize(ImVec2(400, 128), ImGuiCond.Appearing);
        igSetNextWindowSizeConstraints(ImVec2(400, 128), ImVec2(float.max, float.max));
        super.onBeginUpdate();
    }

    override
    void onUpdate() {
        // TODO: Add ada error icon

        float availX = incAvailableSpace().x;
        if (igBeginChild("RestoreSaveMessage", ImVec2(0, -28), true)) {
            igPushTextWrapPos(availX);
                incText(_("Inochi Creator closed unexpectedly while editing this file."));
                incText(_("Restore data from a backup?"));
            igPopTextWrapPos();
        }
        igEndChild();

        if (igBeginChild("RestoreSaveButtons", ImVec2(0, 0), false, ImGuiWindowFlags.NoScrollbar)) {
            incDummy(ImVec2(-128, 0));
            igSameLine(0, 0);

            if (igButton(__("Discard"), ImVec2(64, 24))) {
                incOpenProject(projectPath, "");
                this.close();
            }
            igSameLine(0, 0);

            if (igButton(__("Restore"), ImVec2(64, 24))) {
                string backupDir = getAutosaveDir(projectPath.stripExtension);
                auto entries = currentBackups(backupDir);
                incOpenProject(projectPath, entries[$-1]);
                this.close();
            }
        }
        igEndChild();
    }
public:
    this(string projectPath) {
        super(_("Restore Autosave"));
        this.projectPath = projectPath;
    }
}
