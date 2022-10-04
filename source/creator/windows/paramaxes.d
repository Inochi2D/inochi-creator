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
    vec2 endPoint;

    void findEndPoint() {
        foreach(i, x; points[0]) {
            if (!x.fixed) endPoint.x = i;
        }

        foreach(i, y; points[1]) {
            if (!y.fixed) endPoint.y = i;
        }
    }

protected:
    override
    void onBeginUpdate() {
        igSetNextWindowSize(ImVec2(384*2, 192*2), ImGuiCond.Appearing);
        igSetNextWindowSizeConstraints(ImVec2(384*2, 192*2), ImVec2(float.max, float.max));
        super.onBeginUpdate();
    }

    void axisPointList(ulong axis, ImVec2 avail) {
        int deleteIndex = -1;

        igIndent();
            igPushID(cast(int)axis);
                if (igBeginChild("###AXIS_ADJ", ImVec2(0, avail.y))) {
                    if (points[axis].length > 2) {
                        int ix;
                        foreach(i, ref pt; points[axis]) {
                            ix++;
                            if (pt.fixed) continue;

                            // Do not allow existing points to cross over
                            vec2 range;
                            if (pt.origIndex != -1) {
                                range = vec2(points[axis][i - 1].value, points[axis][i + 1].value);
                            } else if (axis == 0) {
                                range = vec2(param.min.x, param.max.x);
                            } else {
                                range = vec2(param.min.y, param.max.y);
                            }

                            // Offset range so points cannot overlap
                            range = range + vec2(0.01, -0.01);

                            igSetNextItemWidth(80);
                            igPushID(cast(int)i);
                                if (incDragFloat(
                                    "adj_offset", &pt.value, 0.01,
                                    range.x, range.y, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
                                ) {
                                    pt.normValue = param.mapAxis(cast(uint)axis, pt.value);
                                }
                                igSameLine(0, 0);

                                if (i == endPoint.vector[axis]) {
                                    incDummy(ImVec2(-52, 32));
                                    igSameLine(0, 0);
                                    if (igButton("", ImVec2(24, 24))) {
                                        deleteIndex = cast(int)i;
                                    }
                                    igSameLine(0, 0);
                                    if (igButton("", ImVec2(24, 24))) {
                                        createPoint(axis);
                                    }

                                } else {
                                    incDummy(ImVec2(-28, 32));
                                    igSameLine(0, 0);
                                    if (igButton("", ImVec2(24, 24))) {
                                        deleteIndex = cast(int)i;
                                    }
                                }
                            igPopID();
                        }
                    } else {
                        incDummy(ImVec2(-28, 24));
                        igSameLine(0, 0);
                        if (igButton("", ImVec2(24, 24))) {
                            createPoint(axis);
                        }
                    }
                }
                igEndChild();
            igPopID();
        igUnindent();

        if (deleteIndex != -1) {
            points[axis] = points[axis].remove(cast(uint)deleteIndex);
            this.findEndPoint();
        }
    }

    void createPoint(ulong axis) {
        float normValue = (points[axis][0].normValue + points[axis][1].normValue) / 2;
        float value = param.unmapAxis(cast(uint)axis, normValue);
        points[axis] ~= EditableAxisPoint(-1, false, value, normValue);
        this.findEndPoint();
    }

    override
    void onUpdate() {
        igPushID(cast(void*)param);
            ImVec2 avail = incAvailableSpace();
            float reqSpace = param.isVec2 ? 128 : 32;

            if (igBeginChild("###ControllerView", ImVec2(192, avail.y))) {
                incDummy(ImVec2(0, (avail.y/2)-(reqSpace/2)));
                incControllerAxisDemo("###CONTROLLER", param, points, ImVec2(192, reqSpace));
            }
            igEndChild();

            igSameLine(0, 0);

            igBeginGroup();
                if (igBeginChild("###ControllerSettings", ImVec2(0, -(28)))) {
                    avail = incAvailableSpace();
                    if (param.isVec2) {

                        // Skip start and end point
                        if (incBeginCategory("X")) {
                            axisPointList(0, ImVec2(avail.x, (avail.y/2)-42));
                        }
                        incEndCategory();

                        if (incBeginCategory("Y")) {
                            axisPointList(1, ImVec2(avail.x, (avail.y/2)-42));
                        }
                        incEndCategory();
                    } else {

                        // Points where the user can set parameter values
                        if (incBeginCategory(__("Breakpoints"))) {
                            axisPointList(0, ImVec2(avail.x, avail.y-38));
                        }
                        incEndCategory();
                    }
                }
                igEndChild();

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
                        bool success = true;
                        
                        // Make sure there isn't any invalid state
                        iloop: foreach(axis; 0..points.length) {
                            
                            foreach(x; 0..points[0].length) {
                                foreach(xi; 0..points[0].length) {
                                    if (x == xi) continue;

                                    if (points[0][x].normValue == points[0][xi].normValue) {
                                        incDialog(__("Error"), _("One or more axes points are overlapping, this is not allowed."));
                                        success = false;
                                        break iloop;
                                    }
                                }
                            }
                        }

                        if (success) {
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
                    }
                }
                igEndChild();
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
        this.findEndPoint();

        // Title for the parameter axis points window
        // This window allows adjusting axies in the
        // Parameter it's attached to.
        // Keypoints show up on every intersecting axis line.
        super(_("Parameter Axes Points"));
    }
}