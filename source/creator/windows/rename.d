/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.rename;
import creator.widgets;
import creator.windows;
import creator.core;
import creator;
import std.string;
import creator.utils.link;
import inochi2d;
import i18n;
import std.stdio;

class RenameWindow : Window {
private:
    string strcpy;
    string* output;

    void apply() {
        *output = strcpy.dup;
        this.close();
    }

protected:
    override
    void onBeginUpdate() {
        enum WIDTH = 320;
        enum HEIGHT = 120;
        igSetNextWindowSize(ImVec2(WIDTH, HEIGHT), ImGuiCond.Appearing);
        igSetNextWindowSizeConstraints(ImVec2(WIDTH, HEIGHT), ImVec2(float.max, HEIGHT));
        super.onBeginUpdate();
    }

    override
    void onUpdate() {

        // Textbox
        float doneLength = clamp(incMeasureString(_("Rename")).x, 64, float.max);
        ImVec2 avail = incAvailableSpace();
        incDummy(ImVec2(0, avail.y/5));
        igIndent(16);
            avail = incAvailableSpace();
            if (incInputText("RENAME", avail.x-16, strcpy, ImGuiInputTextFlags.EnterReturnsTrue)) {
                this.apply();
            }
        igUnindent(16);

        // Done button
        avail = incAvailableSpace();
        incDummy(ImVec2(0, -24));
        incDummy(ImVec2(avail.x-(doneLength+8), 20));
        igSameLine(0, 0);
        if (igButton(__("Rename"), ImVec2(doneLength+8, 20))) {
            this.apply();
        }
    }

public:
    this(ref string toRename) {
        super(_("Rename %s...").format(toRename));

        output = &toRename;

        // Add secret null terminator
        strcpy = cast(string)(toRename.dup~"\0");
        strcpy = strcpy[0..$-1];
    }
}