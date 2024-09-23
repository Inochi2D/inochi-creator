/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.paramprop;
import creator.windows;
import creator.widgets;
import creator.core;
import creator.actions;
import creator.ext;
import creator;
import std.string;
import creator.utils.link;
import i18n;
import inochi2d;

class ParamPropWindow : Window {
private:
    Parameter param;
    string paramName;
    vec2 min;
    vec2 max;
    bool markSave = false;

    bool isValidName() {
        if (paramName == "") return false;

        Parameter fparam = (cast(ExPuppet)incActivePuppet()).findParameter(paramName);
        return fparam is null || fparam.uuid == param.uuid;
    }

protected:
    override
    void onBeginUpdate() {
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
                    incInputText("Name", paramName);
                igUnindent();

                incText(_("Parameter Constraints"));
                igIndent();
                    igSetNextItemWidth(256);

                    if (param.isVec2) incText("X");
                    if (param.isVec2) igIndent();
                        
                        // X MINIMUM
                        igSetNextItemWidth(64);
                        igPushID(0);
                            incDragFloat("adj_x_min", &min.vector[0], 1, -float.max, max.x-1, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
                        igPopID();

                        igSameLine(0, 4);

                        // X MAXIUMUM
                        igSetNextItemWidth(64);
                        igPushID(1);
                            incDragFloat("adj_x_max", &max.vector[0], 1, min.x+1, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
                        igPopID();
                    if (param.isVec2) igUnindent();
                        
                    if (param.isVec2) {

                        incText("Y");

                        igIndent();

                            // Y MINIMUM
                            igSetNextItemWidth(64);
                            igPushID(2);
                                incDragFloat("adj_y_min", &min.vector[1], 1, -float.max, max.y-1, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
                            igPopID();

                            igSameLine(0, 4);

                            // Y Maximum
                            igSetNextItemWidth(64);
                            igPushID(3);
                                incDragFloat("adj_y_max", &max.vector[1], 1, min.y+1, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
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
                    
                    if (!isValidName) {
                        incDialog(__("Error"), _("Name is already taken or empty"));
                        markSave = false;
                    } else {
                        markSave = true;
                        this.close();
                    }
                }
            }
            igEndChild();

        igPopID();
    }

    override
    void onClose() {
        if (!markSave) return;

        param.name = paramName;
        param.makeIndexable();

        param.min = min;
        param.max = max;
        if (min.x != param.min.x) incActionPush(new ParameterValueChangeAction!float("min X", param, incGetDragFloatInitialValue("adj_x_min"), param.min.vector[0], &param.min.vector[0]));
        if (min.y != param.min.y) incActionPush(new ParameterValueChangeAction!float("min Y", param, incGetDragFloatInitialValue("adj_y_min"), param.min.vector[1], &param.min.vector[1]));
        if (max.x != param.max.x) incActionPush(new ParameterValueChangeAction!float("max X", param, incGetDragFloatInitialValue("adj_x_max"), param.max.vector[0], &param.max.vector[0]));
        if (max.y != param.max.y) incActionPush(new ParameterValueChangeAction!float("max Y", param, incGetDragFloatInitialValue("adj_y_max"), param.max.vector[1], &param.max.vector[1]));
    }

public:
    this(ref Parameter param) {
        this.param = param;

        paramName = param.name.dup;
        min.vector = param.min.vector.dup;
        max.vector = param.max.vector.dup;

        // Title for the parameter properties window.
        super(_("Parameter Properties"));
    }
}