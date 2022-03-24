/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors:
    - Luna Nielsen
    - Asahi Lina
*/
module creator.windows.paramaxes;
import std.algorithm.mutation : remove;
import creator.windows;
import creator.widgets;
import creator.core;
import std.string;
import creator.utils.link;
import i18n;
import inochi2d;
import std.math;

class ParamAxesWindow : Window {
private:
    Parameter param;
    EditableAxisPoint[][2] points;


protected:
    override
    void onBeginUpdate() {
        flags |= ImGuiWindowFlags.NoResize;
        igSetNextWindowSize(ImVec2(384, 192), ImGuiCond.Appearing);
        igSetNextWindowSizeConstraints(ImVec2(384, 192), ImVec2(float.max, float.max));
        super.onBeginUpdate();
    }

    void axisPointList(ulong axis, ImVec2 avail) {
        int deleteIndex = -1;

        igIndent();
            igPushID(cast(int)axis);
                if (igBeginChild("###AXIS_ADJ", ImVec2(0, avail.y-26))) {
                    foreach(x, ref pt; points[axis]) {
                        if (pt.fixed) continue;

                        // Do not allow existing points to cross over
                        vec2 range;
                        if (pt.origIndex != -1) {
                            range = vec2(points[axis][x - 1].value, points[axis][x + 1].value);
                        } else if (axis == 0) {
                            range = vec2(param.min.x, param.max.x);
                        } else {
                            range = vec2(param.min.y, param.max.y);
                        }

                        // Offset range so points cannot overlap
                        range = range + vec2(0.01, -0.01);

                        igSetNextItemWidth(80);
                        igPushID(cast(int)x);
                            if (incDragFloat(
                                "adj_offset", &pt.value, 0.01,
                                range.x, range.y, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
                            ) {
                                pt.normValue = param.mapAxis(cast(uint)axis, pt.value);
                            }
                            igSameLine(0, 0);
                            incDummy(ImVec2(-24, 32));
                            igSameLine(0, 0);
                            if (igButton("", ImVec2(24, 24))) {
                                deleteIndex = cast(int)x;
                            }
                        igPopID();
                    }
                    igEndChild();
                }
                
                incDummy(ImVec2(-24, 24));
                igSameLine(0, 0);
                if (igButton("", ImVec2(24, 24))) {
                    createPoint(axis);
                }
            igPopID();
        igUnindent();

        if (deleteIndex != -1) {
            points[axis] = points[axis].remove(cast(uint)deleteIndex);
        }
    }

    void createPoint(ulong axis) {
        float normValue = (points[axis][0].normValue + points[axis][1].normValue) / 2;
        float value = param.unmapAxis(cast(uint)axis, normValue);
        points[axis] ~= EditableAxisPoint(-1, false, value, normValue);
    }

    override
    void onUpdate() {
        igPushID(cast(void*)param);
            ImVec2 avail = incAvailableSpace();
            float reqSpace = param.isVec2 ? 128 : 32;

            if (igBeginChild("###ControllerView", ImVec2(192, reqSpace))) {
                incControllerAxisDemo("###CONTROLLER", param, points, ImVec2(192, reqSpace));
                igEndChild();
            }

            igSameLine(0, 0);

            igBeginGroup();
                if (igBeginChild("###ControllerSettings", ImVec2(0, -(28)))) {
                    avail = incAvailableSpace();
                    if (param.isVec2) {

                        // Skip start and end point
                        igText("X");
                        axisPointList(0, ImVec2(avail.x, (avail.y/2)-24));

                        igText("Y");
                        axisPointList(1, ImVec2(avail.x, (avail.y/2)-24));
                    } else {

                        // Points where the user can set parameter values
                        igText("Breakpoints");
                        axisPointList(0, ImVec2(avail.x, avail.y-24));
                    }
                    igEndChild();
                }

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
                        foreach (axis, axisPoints; points) {
                            int skew = 0;
                            foreach (i, ref point; axisPoints) {
                                if (point.origIndex != -1) {
                                    // Update point

                                    // If we skipped over some original points, they were deleted,
                                    // so delete them here
                                    while (point.origIndex != -1 && (i + skew) < point.origIndex) {
                                        param.deleteAxisPoint(cast(uint)axis, cast(uint)i);
                                        skew++;
                                    }

                                    // Do not touch fixed points
                                    if (!point.fixed)
                                        param.axisPoints[axis][i] = point.normValue;
                                } else {
                                    // Add point
                                    param.insertAxisPoint(cast(uint)axis, point.normValue);
                                }
                            }
                        }
                        this.close();
                    }
                    igEndChild();
                }
            igEndGroup();
        igPopID();
    }

public:
    this(ref Parameter param) {
        this.param = param;
        foreach(i, ref axisPoints; points) {
            axisPoints.length = param.axisPoints[i].length;
            foreach(j, ref point; axisPoints) {
                point.origIndex = cast(int)j;
                point.normValue = param.axisPoints[i][j];
                point.value = param.unmapAxis(cast(uint)i, point.normValue);
            }
            axisPoints[0].fixed = true;
            axisPoints[$ - 1].fixed = true;
        }

        // Title for the parameter axis points window
        // This window allows adjusting axies in the
        // Parameter it's attached to.
        // Keypoints show up on every intersecting axis line.
        super(_("Parameter Axes Points"));
    }
}