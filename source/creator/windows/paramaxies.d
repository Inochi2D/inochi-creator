/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.paramaxies;
import std.algorithm.mutation : remove;
import creator.windows;
import creator.widgets;
import creator.core;
import std.string;
import creator.utils.link;
import i18n;
import inochi2d;

class ParamAxiesWindow : Window {
private:
    Parameter param;
    float[][2] newAxies;

protected:
    override
    void onBeginUpdate(int id) {
        flags |= ImGuiWindowFlags.NoResize;
        igSetNextWindowSize(ImVec2(384, 192), ImGuiCond.Appearing);
        igSetNextWindowSizeConstraints(ImVec2(384, 192), ImVec2(float.max, float.max));
        super.onBeginUpdate(id);
    }

    override
    void onUpdate() {
        igPushID(cast(void*)param);
            ImVec2 avail = incAvailableSpace();
            float reqSpace = param.isVec2 ? 128 : 32;


            if (igBeginChild("###ControllerView", ImVec2(192, -28))) {
                incControllerAxisDemo("###CONTROLLER", param, newAxies, ImVec2(avail.x/2, reqSpace));
                igEndChild();
            }

            igSameLine(0, 0);

            igBeginGroup();
                if (igBeginChild("###ControllerSettings", ImVec2(0, -(28)-34))) {
                    if (param.isVec2) {
                        // Skip start and end point
                        igText("X");
                        igIndent();
                            avail = incAvailableSpace();
                            igPushID(0);
                                foreach(x; 2..newAxies[0].length) {
                                    igSetNextItemWidth(avail.x-64);
                                    igPushID(cast(int)x);
                                        incDragFloat("adj_offset", &newAxies[0][x], 0.01, param.min.x+0.01, param.max.x-0.01, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
                                        igSameLine(0, 0);
                                        incDummy(ImVec2(-24, 32));
                                        igSameLine(0, 0);
                                        if (igButton("", ImVec2(24, 24))) {
                                            newAxies[0] = newAxies[0].remove(x);
                                        }
                                    igPopID();
                                }
                            igPopID();
                        igUnindent();

                        igText("Y");
                        igIndent();
                            avail = incAvailableSpace();
                            igPushID(1);
                                foreach(y; 2..newAxies[1].length) {
                                    igSetNextItemWidth(avail.x-64);
                                    igPushID(cast(int)y);
                                        incDragFloat("adj_offset", &newAxies[1][y], 0.01, param.min.y+0.01, param.max.y-0.01, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
                                        igSameLine(0, 0);
                                        incDummy(ImVec2(-24, 0));
                                        igSameLine(0, 0);
                                        if (igButton("", ImVec2(24, 24))) {
                                            newAxies[1] = newAxies[1].remove(y);
                                        }
                                    igPopID();
                                }
                            igPopID();
                        igUnindent();

                    } else {

                        // Points where the user can set parameter values
                        igText(__("Breakpoints"));
                        igIndent();
                            avail = incAvailableSpace();
                            igPushID(0);
                                foreach(x; 2..newAxies[0].length) {
                                    igSetNextItemWidth(avail.x-64);
                                    igPushID(cast(int)x);
                                        incDragFloat("adj_offset", &newAxies[0][x], 0.01, param.min.x+0.01, param.max.x-0.01, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
                                        igSameLine(0, 0);
                                        incDummy(ImVec2(-24, 24));
                                        igSameLine(0, 0);
                                        if (igButton("", ImVec2(24, 24))) {
                                            newAxies[0] = newAxies[0].remove(x);
                                        }
                                    igPopID();
                                }
                            igPopID();
                        igUnindent();
                    }
                    igEndChild();
                }

                if (igBeginChild("###ControllerAddRemove", ImVec2(0, 32))) {     
                    if (igBeginPopup("###AddAxis")) {
                        if (igMenuItem("X", "", false, true)) {
                            newAxies[0] ~= param.min.x + ((param.max.x-param.min.x)/2);
                        }
                        if (igMenuItem("Y", "", false, true)) {
                            newAxies[1] ~= param.min.y + ((param.max.y-param.min.y)/2);
                        }
                        igEndPopup();
                    }

                    avail = incAvailableSpace();
                    if (param.isVec2) {
                        incDummy(ImVec2(-32, 32));
                        igSameLine(0, 0);
                        if (igButton("", ImVec2(32, 32))) {
                            igOpenPopup("###AddAxis");
                        }
                    } else {
                        incDummy(ImVec2(-32, 32));
                        igSameLine(0, 0);
                        if (igButton("", ImVec2(32, 32))) {
                            newAxies[0] ~= param.min.x + ((param.max.x-param.min.x)/2);
                        }
                    }
                    igEndChild();
                }
            igEndGroup();
            
            if (igBeginChild("###SettingsBtns", ImVec2(0, 0))) {
                incDummy(ImVec2(-132, 0));
                igSameLine(0, 0);

                // Cancels the edited state for the axies points
                if (igButton(__("Cancel"), ImVec2(64, 24))) {
                    this.close();
                }

                igSameLine(0, 4);

                // Actually saves the edited state for the axies points
                if (igButton(__("Save"), ImVec2(64, 24))) {
                    foreach(i, offsetList; newAxies) {
                        foreach(ix, offset; offsetList) {

                            // Can't delete offsets at the start and end.
                            if (ix < 2) continue;

                            // Convert to space suitable for insertAxisPoint
                            float tmpOffset = offset;
                            if (i == 0) tmpOffset = param.adjustValue(vec2(offset, 0)).x;
                            if (i == 1) tmpOffset = param.adjustValue(vec2(0, offset)).y;
                            
                            // Delete point if it's already there
                            // Add new point if not
                            import std.algorithm.searching : canFind, countUntil;
                            if (param.axisPoints[i].canFind(offset) && param.axisPoints[i].length > 2) {
                                param.deleteAxisPoint(cast(uint)i, cast(uint)param.axisPoints[i].countUntil(tmpOffset));
                            } else param.insertAxisPoint(cast(uint)i, tmpOffset);
                        }
                    }
                    this.close();
                }
                igEndChild();
            }
        igPopID();
    }

public:
    this(ref Parameter param) {
        this.param = param;

        static foreach(i; 0..2) {
            newAxies[i].length = param.axisPoints[i].length;
            if (newAxies[i].length > 0) {
                newAxies[i][0..$] = param.axisPoints[i][0..$];
            }
        }

        // Title for the parameter axis points window
        // This window allows adjusting axies in the
        // Parameter it's attached to.
        // Keypoints show up on every intersecting axis line.
        super(_("Parameter Axies Points"));
    }
}