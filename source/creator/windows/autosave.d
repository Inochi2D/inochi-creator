module creator.windows.autosave;

import creator;
import creator.windows;
import creator.widgets;
import creator.widgets.dummy;
import creator.widgets.label : incText;
import creator.io.autosave;
import i18n;
import std.path : stripExtension;

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
        float availX = incAvailableSpace().x;
        if (igBeginChild("RestoreSaveMessage", ImVec2(0, -28), true)) {
            incText(_("Previous Inochi Creator session closed unexpectedly."));
            incText(_("Restore unsaved data?"));
        }
        igEndChild();

        if (igBeginChild("RestoreSaveButtons", ImVec2(0, 0), false, ImGuiWindowFlags.NoScrollbar)) {
            incDummy(ImVec2(-128, 0));
            igSameLine(0, 0);

            if (igButton(__("No"), ImVec2(64, 24))) {
                incOpenProject(projectPath, "");
                this.close();
                incPopWelcomeWindow();
            }
            igSameLine(0, 0);

            if (igButton(__("Yes"), ImVec2(64, 24))) {
                string backupDir = getAutosaveDir(projectPath.stripExtension);
                auto entries = currentBackups(backupDir);
                incOpenProject(projectPath, entries[$-1]);
                this.close();
                incPopWelcomeWindow();
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
