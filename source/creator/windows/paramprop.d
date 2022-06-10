/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.paramprop;
import creator.windows;
import creator.widgets;
import creator.core;
import std.string;
import creator.utils.link;
import i18n;
import inochi2d;

class ParamPropWindow : Window {
private:
    Parameter param;

protected:
    override
    void onBeginUpdate() {
        flags |= ImGuiWindowFlags.NoResize;
        igSetNextWindowSize(ImVec2(384, 192), ImGuiCond.Appearing);
        igSetNextWindowSizeConstraints(ImVec2(384, 192), ImVec2(float.max, float.max));
        super.onBeginUpdate();
    }

    override
    void onUpdate() {
        igPushID(cast(void*)param);
            if (igBeginChild("###MainSettings", ImVec2(0, -28))) {
                incText(_("Parameter Name"));
                igIndent();
                    if (incInputText("Name", param.name)) {
                        param.makeIndexable();
                    }
                igUnindent();

                incText(_("Parameter Constraints"));
                igIndent();
                    igSetNextItemWidth(256);

                    if (param.isVec2) incText("X");
                    if (param.isVec2) igIndent();
                        
                        // X MINIMUM
                        igSetNextItemWidth(64);
                        igPushID(0);
                                incDragFloat("adj_x_min", &param.min.vector[0], 1, -float.max, param.max.x-1, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
                        igPopID();

                        igSameLine(0, 4);

                        // X MAXIUMUM
                        igSetNextItemWidth(64);
                        igPushID(1);
                            incDragFloat("adj_x_max", &param.max.vector[0], 1, param.min.x+1, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
                        igPopID();
                    if (param.isVec2) igUnindent();
                        
                    if (param.isVec2) {

                        incText("Y");

                        igIndent();

                            // Y MINIMUM
                            igSetNextItemWidth(64);
                            igPushID(2);
                                incDragFloat("adj_y_min", &param.min.vector[1], 1, -float.max, param.min.y-1, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
                            igPopID();

                            igSameLine(0, 4);

                            // Y Maximum
                            igSetNextItemWidth(64);
                            igPushID(3);
                                incDragFloat("adj_y_max", &param.max.vector[1], 1, param.min.y+1, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
                            igPopID();
                        igUnindent();
                    }
                igUnindent();
            }
            igEndChild();

            if (igBeginChild("###SettingsBtns", ImVec2(0, 0))) {
                incDummy(ImVec2(-64, 0));
                igSameLine(0, 0);

                // Settings are autosaved, but in case the user
                // feels more safe with a save button then we have
                // it here.
                if (igButton(__("Save"), ImVec2(64, 24))) {
                    this.close();
                }
            }
            igEndChild();

        igPopID();
    }

public:
    this(ref Parameter param) {
        this.param = param;

        // Title for the parameter properties window.
        super(_("Parameter Properties"));
    }
}