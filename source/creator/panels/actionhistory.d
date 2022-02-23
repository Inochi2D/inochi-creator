/*
    Copyright © 2020, Inochi2D Project
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

        igText("Undo History");
        igSeparator();

        ImVec2 avail;
        igGetContentRegionAvail(&avail);

        igBeginChild("##ActionList", ImVec2(0, avail.y-30));
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
        igEndChild();
        

        igSeparator();
        igSpacing();
        if (igButton("Clear History", ImVec2(0, 0))) {
            incActionClearHistory();
        }
        igSameLine(0, 0);

        // Ugly hack to please imgui
        string count = (_("%d of %d")~"\0").format(incActionHistory().length, incActionGetUndoHistoryLength());
        ImVec2 len = incMeasureString(count);
        incDummy(ImVec2(-(len.x-8), 1));
        igSameLine(0, 0);
        igText(count.ptr);
    }

public:
    this() {
        super(_("History"), true);
        flags |= ImGuiWindowFlags.NoScrollbar;
    }
}

/**
    Generate logger frame
*/
mixin incPanel!ActionHistoryPanel;


