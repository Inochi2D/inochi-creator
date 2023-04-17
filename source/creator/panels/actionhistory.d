/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.actionhistory;
import creator.panels;
import bindbc.imgui;
import creator.core.actionstack;
import std.string;
import creator.widgets;
import std.format;
import i18n;

/**
    The logger panel
*/
class ActionHistoryPanel : Panel {
private:

protected:
    override
    void onUpdate() {

        incText(_("Undo History"));
        igSeparator();

        ImVec2 avail;
        igGetContentRegionAvail(&avail);

        if (igBeginChild("##ActionList", ImVec2(0, avail.y-30))) {
            if (incActionHistory().length > 0) {
                foreach(i, action; incActionHistory()) {
                    igPushID(cast(int)i);
                        if (i == 0) {
                            igPushID("ASBEGIN");
                                if (igSelectable(action.describeUndo().toStringz, i <= cast(ptrdiff_t)incActionIndex())) {
                                    incActionSetIndex(0);
                                }
                            igPopID();
                        }
                        if (igSelectable(action.describe().toStringz, i+1 <= incActionIndex())) {
                            incActionSetIndex(i+1);
                        }
                    igPopID();
                }
            }

        }
        igEndChild();
        

        igSeparator();
        igSpacing();
        if (igButton(__("Clear History"), ImVec2(0, 0))) {
            incActionClearHistory(ActionStackClear.CurrentLevel);
        }
        igSameLine(0, 0);

        // Ugly hack to please imgui
        string count = _("%d of %d").format(incActionHistory().length, incActionGetUndoHistoryLength());
        ImVec2 len = incMeasureString(count);
        incDummy(ImVec2(-len.x, 1));
        igSameLine(0, 0);
        incText(count);
    }

public:
    this() {
        super("History", _("History"), true);
        flags |= ImGuiWindowFlags.NoScrollbar;
    }
}

/**
    Generate logger frame
*/
mixin incPanel!ActionHistoryPanel;


