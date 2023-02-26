/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors:
    - Luna Nielsen
    - Asahi Lina
*/
module creator.widgets.controller;
import creator.widgets;
import inochi2d;
import std.stdio;

struct EditableAxisPoint {
    int origIndex;
    bool fixed;
    float value;
    float normValue;
};

/**
    A Parameter controller
*/
bool incController(string strId, ref Parameter param, ImVec2 size, bool forceSnap = false, string grabParam = "") {
    ImGuiWindow* window = igGetCurrentWindow();
    if (window.SkipItems) return false;

    ImGuiID id = igGetID(strId.ptr, strId.ptr+strId.length);

    ImVec2 avail;
    igGetContentRegionAvail(&avail);
    if (size.x <= 0) size.x = avail.x-size.x;
    if (!param.isVec2) size.y = 32;
    else if (size.y <= 0) size.y = avail.y-size.y;

    ImGuiContext* ctx = igGetCurrentContext();
    ImGuiStyle* style = &ctx.Style;
    ImGuiStorage* storage = igGetStateStorage();
    ImGuiIO* io = igGetIO();


    ImVec2 mPos;
    ImVec2 vPos;
    igGetCursorScreenPos(&vPos);
    bool bModified = false;
    
    if (param.isVec2) {
        float oRectOffsetX = 24;
        float oRectOffsetY = 12;
        ImRect fRect = ImRect(
            vPos,
            ImVec2(vPos.x + size.x, vPos.y + size.y)
        );

        ImRect oRect = ImRect(
            ImVec2(vPos.x+oRectOffsetX, vPos.y+oRectOffsetY), 
            ImVec2((vPos.x + size.x)-oRectOffsetX, (vPos.y + size.y)-oRectOffsetY)
        );

        igPushID(id);

            igRenderFrame(oRect.Min, oRect.Max, igGetColorU32(ImGuiCol.FrameBg));

            float sDeltaX = param.max.x-param.min.x;
            float sDeltaY = param.max.y-param.min.y;
            
            ImVec2 vSecurity = ImVec2(15, 15);
            ImRect frameBB = ImRect(ImVec2(oRect.Min.x - vSecurity.x, oRect.Min.y - vSecurity.y), ImVec2(oRect.Max.x + vSecurity.x, oRect.Max.y + vSecurity.y));

            bool shouldSnap = forceSnap || io.KeyShift;
            bool hovered;
            bool held;
            bool pressed = igButtonBehavior(frameBB, igGetID("##Zone"), &hovered, &held);
            if (hovered && igIsMouseDown(ImGuiMouseButton.Right)) {
                held = true;
            }
            if ((grabParam == param.name) || (hovered && held)) {
                igGetMousePos(&mPos);
                ImVec2 vCursorPos = ImVec2(mPos.x - oRect.Min.x, mPos.y - oRect.Min.y);

                param.value = vec2(
                    clamp(vCursorPos.x / (oRect.Max.x - oRect.Min.x) * sDeltaX + param.min.x, param.min.x, param.max.x),
                    clamp(vCursorPos.y / (oRect.Max.y - oRect.Min.y) * -sDeltaY + param.max.y, param.min.y, param.max.y)
                );

                // Snap to closest point mode
                if (shouldSnap) param.value = param.getClosestKeypointValue();

                bModified = true;
            }

            float fXLimit = 10f / ImRect_GetWidth(&oRect);
            float fYLimit = 10f / ImRect_GetHeight(&oRect);
            float fScaleX;
            float fScaleY;
            ImVec2 vCursorPos;

            ImDrawList* drawList = igGetWindowDrawList();
            
            ImS32 uDotColor = igGetColorU32(ImVec4(1f, 0f, 0f, 1f));
            ImS32 uDotColorOff = igGetColorU32(ImVec4(0.5f, 0.2f, 0.2f, 1f));
            ImS32 uLineColor = igGetColorU32(style.Colors[ImGuiCol.Text]);
            ImS32 uDotKeyColor = igGetColorU32(style.Colors[ImGuiCol.TextDisabled]);
            ImS32 uDotKeyPartial = igGetColorU32(ImVec4(1f, 1f, 0f, 1f));
            ImS32 uDotKeyComplete = igGetColorU32(ImVec4(0f, 1f, 0f, 1f));

            // AXES LINES
            foreach(xIdx; 0..param.axisPoints[0].length) {
                float xVal = param.axisPoints[0][xIdx];
                float xPos = (oRect.Max.x - oRect.Min.x) * xVal + oRect.Min.x;
                
                ImDrawList_AddLineDashed(
                    drawList, 
                    ImVec2(
                        xPos, 
                        oRect.Min.y
                    ), 
                    ImVec2(
                        xPos, 
                        oRect.Max.y
                    ), 
                    uDotKeyColor, 
                    1f, 
                    24, 
                    1.2f
                );
            
            }

            foreach(yIdx; 0..param.axisPoints[1].length) {
                float yVal = 1 - param.axisPoints[1][yIdx];
                float yPos = (oRect.Max.y - oRect.Min.y) * yVal + oRect.Min.y;
                
                ImDrawList_AddLineDashed(
                    drawList, 
                    ImVec2(
                        oRect.Min.x,
                        yPos, 
                    ), 
                    ImVec2(
                        oRect.Max.x,
                        yPos, 
                    ), 
                    uDotKeyColor, 
                    1f, 
                    40, 
                    1.2f
                );
            }

            // OUTSIDE FRAME
            ImDrawList_AddLine(drawList, ImVec2(oRect.Min.x, oRect.Min.y), ImVec2(oRect.Max.x, oRect.Min.y), uLineColor, 2f);
            ImDrawList_AddLine(drawList, ImVec2(oRect.Min.x, oRect.Max.y), ImVec2(oRect.Max.x, oRect.Max.y), uLineColor, 2f);
            ImDrawList_AddLine(drawList, ImVec2(oRect.Min.x, oRect.Min.y), ImVec2(oRect.Min.x, oRect.Max.y), uLineColor, 2f);
            ImDrawList_AddLine(drawList, ImVec2(oRect.Max.x, oRect.Min.y), ImVec2(oRect.Max.x, oRect.Max.y), uLineColor, 2f);
            
            // AXES POINTS
            foreach(xIdx; 0..param.axisPoints[0].length) {
                float xVal = param.axisPoints[0][xIdx];
                foreach(yIdx; 0..param.axisPoints[1].length) {
                    float yVal = 1 - param.axisPoints[1][yIdx];

                    vCursorPos = ImVec2(
                        (oRect.Max.x - oRect.Min.x) * xVal + oRect.Min.x, 
                        (oRect.Max.y - oRect.Min.y) * yVal + oRect.Min.y
                    );

                    ImDrawList_AddCircleFilled(drawList, vCursorPos, 6.0f, uDotKeyColor, 16);

                    bool isPartial = false;
                    bool isComplete = true;
                    foreach(binding; param.bindings) {
                        if (binding.getIsSet()[xIdx][yIdx]) {
                            isPartial = true;
                        } else {
                            isComplete = false;
                        }
                    }

                    if (isComplete && isPartial)
                        ImDrawList_AddCircleFilled(drawList, vCursorPos, 4f, uDotKeyComplete, 16);
                    else if (isPartial)
                        ImDrawList_AddCircleFilled(drawList, vCursorPos, 4f, uDotKeyPartial, 16);
                }
            }

            // OFFSET VALUE
            fScaleX = ((param.value.x+param.ivalue.x) - param.min.x) / sDeltaX;
            fScaleY = 1 - ((param.value.y+param.ivalue.y) - param.min.y) / sDeltaY;
            vCursorPos = ImVec2(
                (oRect.Max.x - oRect.Min.x) * fScaleX + oRect.Min.x, 
                (oRect.Max.y - oRect.Min.y) * fScaleY + oRect.Min.y
            );
            
            ImDrawList_AddCircleFilled(drawList, vCursorPos, 4f, uDotColorOff, 16);

            // PARAM VALUE
            fScaleX = (param.value.x - param.min.x) / sDeltaX;
            fScaleY = 1 - (param.value.y - param.min.y) / sDeltaY;
            vCursorPos = ImVec2(
                (oRect.Max.x - oRect.Min.x) * fScaleX + oRect.Min.x, 
                (oRect.Max.y - oRect.Min.y) * fScaleY + oRect.Min.y
            );
            
            ImDrawList_AddCircleFilled(drawList, vCursorPos, 4f, uDotColor, 16);
        
        igPopID(); 

        igItemAdd(fRect, id);
        igItemSize(size);
    } else {
        const float lineHeight = 16;

        float oRectOffsetX = 24;
        float oRectOffsetY = 12;
        ImRect fRect = ImRect(
            vPos,
            ImVec2(vPos.x + size.x, vPos.y + size.y)
        );

        ImRect oRect = ImRect(
            ImVec2(vPos.x+oRectOffsetX, vPos.y+oRectOffsetY), 
            ImVec2((vPos.x + size.x)-oRectOffsetX, (vPos.y + size.y)-oRectOffsetY)
        );

        igPushID(id);

            igRenderFrame(oRect.Min, oRect.Max, igGetColorU32(ImGuiCol.FrameBg));
            float sDeltaX = param.max.x-param.min.x;
            
            ImVec2 vSecurity = ImVec2(15, 15);
            ImRect frameBB = ImRect(ImVec2(oRect.Min.x - vSecurity.x, oRect.Min.y - vSecurity.y), ImVec2(oRect.Max.x + vSecurity.x, oRect.Max.y + vSecurity.y));

            bool shouldSnap = forceSnap || io.KeyShift;
            bool hovered;
            bool held;
            bool pressed = igButtonBehavior(frameBB, igGetID("##Zone"), &hovered, &held);
            if (hovered && igIsMouseDown(ImGuiMouseButton.Right)) {
                held = true;
            }
            if ((grabParam == param.name) || (hovered && held)) {
                igGetMousePos(&mPos);
                ImVec2 vCursorPos = ImVec2(mPos.x - oRect.Min.x, mPos.y - oRect.Min.y);

                param.value.x = clamp(vCursorPos.x / (oRect.Max.x - oRect.Min.x) * sDeltaX + param.min.x, param.min.x, param.max.x);

                // Snap to closest point mode
                if (shouldSnap) {
                    vec2 closestPoint = param.value;
                    float closestDist = float.infinity;
                    foreach(xIdx; 0..param.axisPoints[0].length) {
                        vec2 pos = vec2(
                            (param.max.x - param.min.x) * param.axisPoints[0][xIdx] + param.min.x,
                            0
                        );

                        float dist = param.value.distance(pos);
                        if (dist < closestDist) {
                            closestDist = dist;
                            closestPoint = pos;
                        }
                    }

                    // clamp to closest point
                    param.value = closestPoint;
                }

                bModified = true;
            }

            float fYCenter = oRect.Min.y+(ImRect_GetHeight(&oRect)/2);
            float fYCenterLineLen1th = lineHeight/2;
            float fScaleX;
            float fScaleY;
            ImVec2 vCursorPos;

            ImDrawList* drawList = igGetWindowDrawList();
            
            ImS32 uDotColor = igGetColorU32(ImVec4(1f, 0f, 0f, 1f));
            ImS32 uDotColorOff = igGetColorU32(ImVec4(0.8f, 0f, 0f, 1f));
            ImS32 uLineColor = igGetColorU32(style.Colors[ImGuiCol.Text]);
            ImS32 uDotKeyColor = igGetColorU32(style.Colors[ImGuiCol.TextDisabled]);
            ImS32 uDotKeyFilled = igGetColorU32(ImVec4(0f, 1f, 0f, 1f));

            // AXES LINES
            foreach(xIdx; 0..param.axisPoints[0].length) {
                float xVal = param.axisPoints[0][xIdx];
                float xPos = (oRect.Max.x - oRect.Min.x) * xVal + oRect.Min.x;
                
                ImDrawList_AddLine(
                    drawList, 
                    ImVec2(
                        xPos, 
                        fYCenter-fYCenterLineLen1th-(fYCenterLineLen1th/4)
                    ), 
                    ImVec2(
                        xPos, 
                        fYCenter+fYCenterLineLen1th
                    ), 
                    uLineColor, 
                    2f, 
                );
            
            }

            // REF LINE
            ImDrawList_AddLine(drawList, ImVec2(oRect.Min.x, fYCenter), ImVec2(oRect.Max.x, fYCenter), uLineColor, 2f);
            
            // AXES POINTS
            foreach(xIdx; 0..param.axisPoints[0].length) {
                float xVal = param.axisPoints[0][xIdx];

                vCursorPos = ImVec2(
                    (oRect.Max.x - oRect.Min.x) * xVal + oRect.Min.x, 
                    fYCenter
                );

                ImDrawList_AddCircleFilled(drawList, vCursorPos, 6.0f, uDotKeyColor, 16);
                foreach(binding; param.bindings) {
                    if (binding.getIsSet()[xIdx][0]) {
                        ImDrawList_AddCircleFilled(drawList, vCursorPos, 4f, uDotKeyFilled, 16);
                        break;
                    }
                }
            }

            // OFFSET VALUE
            fScaleX = ((param.value.x+param.ivalue.x) - param.min.x) / sDeltaX;
            vCursorPos = ImVec2(
                (oRect.Max.x - oRect.Min.x) * fScaleX + oRect.Min.x, 
                fYCenter
            );
            
            ImDrawList_AddCircleFilled(drawList, vCursorPos, 4f, uDotColorOff, 16);

            // PARAM VALUE
            fScaleX = (param.value.x - param.min.x) / sDeltaX;
            vCursorPos = ImVec2(
                (oRect.Max.x - oRect.Min.x) * fScaleX + oRect.Min.x, 
                fYCenter
            );
            
            ImDrawList_AddCircleFilled(drawList, vCursorPos, 4f, uDotColor, 16);
        
        igPopID(); 

        igItemAdd(fRect, id);
        igItemSize(size);
    }

    return bModified;
}

/**
    A fake controller that lets you demonstrate additional axis points
*/
void incControllerAxisDemo(string strId, ref Parameter param, ref EditableAxisPoint[][2] axisPoints, ImVec2 size) {
    ImGuiWindow* window = igGetCurrentWindow();
    if (window.SkipItems) return;

    ImGuiID id = igGetID(strId.ptr, strId.ptr+strId.length);

    ImVec2 avail;
    igGetContentRegionAvail(&avail);
    if (size.x <= 0) size.x = avail.x-size.x;
    if (!param.isVec2) size.y = 32;
    else if (size.y <= 0) size.y = avail.y-size.y;

    ImGuiContext* ctx = igGetCurrentContext();
    ImGuiStyle* style = &ctx.Style;
    ImGuiStorage* storage = igGetStateStorage();
    ImGuiIO* io = igGetIO();


    ImVec2 mPos;
    ImVec2 vPos;
    igGetCursorScreenPos(&vPos);
    
    if (param.isVec2) {
        float oRectOffsetX = 24;
        float oRectOffsetY = 12;
        ImRect fRect = ImRect(
            vPos,
            ImVec2(vPos.x + size.x, vPos.y + size.y)
        );

        ImRect oRect = ImRect(
            ImVec2(vPos.x+oRectOffsetX, vPos.y+oRectOffsetY), 
            ImVec2((vPos.x + size.x)-oRectOffsetX, (vPos.y + size.y)-oRectOffsetY)
        );

        igPushID(id);

            igRenderFrame(oRect.Min, oRect.Max, igGetColorU32(ImGuiCol.FrameBg));
            ImVec2 vCursorPos;
            ImDrawList* drawList = igGetWindowDrawList();
            
            ImS32 uLineColor = igGetColorU32(style.Colors[ImGuiCol.Text]);
            ImS32 uDotKeyColor = igGetColorU32(style.Colors[ImGuiCol.TextDisabled]);
            ImS32 uDotKeyFilled = igGetColorU32(ImVec4(0f, 1f, 0f, 1f));

            // AXES LINES
            foreach(xIdx; 0..axisPoints[0].length) {
                float xVal = axisPoints[0][xIdx].normValue;
                float xPos = (oRect.Max.x - oRect.Min.x) * xVal + oRect.Min.x;
                
                ImDrawList_AddLineDashed(
                    drawList, 
                    ImVec2(
                        xPos, 
                        oRect.Min.y
                    ), 
                    ImVec2(
                        xPos, 
                        oRect.Max.y
                    ), 
                    uDotKeyColor, 
                    1f, 
                    24, 
                    1.2f
                );
            }

            foreach(yIdx; 0..axisPoints[1].length) {
                float yVal = 1 - axisPoints[1][yIdx].normValue;
                float yPos = (oRect.Max.y - oRect.Min.y) * yVal + oRect.Min.y;
                
                ImDrawList_AddLineDashed(
                    drawList, 
                    ImVec2(
                        oRect.Min.x,
                        yPos, 
                    ), 
                    ImVec2(
                        oRect.Max.x,
                        yPos, 
                    ), 
                    uDotKeyColor, 
                    1f, 
                    40, 
                    1.2f
                );
            }

            // OUTSIDE FRAME
            ImDrawList_AddLine(drawList, ImVec2(oRect.Min.x, oRect.Min.y), ImVec2(oRect.Max.x, oRect.Min.y), uLineColor, 2f);
            ImDrawList_AddLine(drawList, ImVec2(oRect.Min.x, oRect.Max.y), ImVec2(oRect.Max.x, oRect.Max.y), uLineColor, 2f);
            ImDrawList_AddLine(drawList, ImVec2(oRect.Min.x, oRect.Min.y), ImVec2(oRect.Min.x, oRect.Max.y), uLineColor, 2f);
            ImDrawList_AddLine(drawList, ImVec2(oRect.Max.x, oRect.Min.y), ImVec2(oRect.Max.x, oRect.Max.y), uLineColor, 2f);
            
            // AXES POINTS
            foreach(xIdx; 0..axisPoints[0].length) {
                float xVal = axisPoints[0][xIdx].normValue;
                foreach(yIdx; 0..axisPoints[1].length) {
                    float yVal = 1 - axisPoints[1][yIdx].normValue;

                    vCursorPos = ImVec2(
                        (oRect.Max.x - oRect.Min.x) * xVal + oRect.Min.x, 
                        (oRect.Max.y - oRect.Min.y) * yVal + oRect.Min.y
                    );

                    ImDrawList_AddCircleFilled(drawList, vCursorPos, 6.0f, uDotKeyColor, 16);
                }
            }        
        igPopID(); 

        igItemAdd(fRect, id);
        igItemSize(size);
    } else {
        const float lineHeight = 16;

        float oRectOffsetX = 24;
        float oRectOffsetY = 12;
        ImRect fRect = ImRect(
            vPos,
            ImVec2(vPos.x + size.x, vPos.y + size.y)
        );

        ImRect oRect = ImRect(
            ImVec2(vPos.x+oRectOffsetX, vPos.y+oRectOffsetY), 
            ImVec2((vPos.x + size.x)-oRectOffsetX, (vPos.y + size.y)-oRectOffsetY)
        );

        igPushID(id);

            igRenderFrame(oRect.Min, oRect.Max, igGetColorU32(ImGuiCol.FrameBg));
            float sDeltaX = param.max.x-param.min.x;
            
            ImVec2 vSecurity = ImVec2(15, 15);
            ImRect frameBB = ImRect(ImVec2(oRect.Min.x - vSecurity.x, oRect.Min.y - vSecurity.y), ImVec2(oRect.Max.x + vSecurity.x, oRect.Max.y + vSecurity.y));
            float fYCenter = oRect.Min.y+(ImRect_GetHeight(&oRect)/2);
            float fYCenterLineLen1th = lineHeight/2;
            ImVec2 vCursorPos;

            ImDrawList* drawList = igGetWindowDrawList();
            
            ImS32 uLineColor = igGetColorU32(style.Colors[ImGuiCol.Text]);
            ImS32 uDotKeyColor = igGetColorU32(style.Colors[ImGuiCol.TextDisabled]);
            ImS32 uDotKeyFilled = igGetColorU32(ImVec4(0f, 1f, 0f, 1f));

            // AXES LINES
            foreach(xIdx; 0..axisPoints[0].length) {
                float xVal = axisPoints[0][xIdx].normValue;
                float xPos = (oRect.Max.x - oRect.Min.x) * xVal + oRect.Min.x;
                
                ImDrawList_AddLine(
                    drawList, 
                    ImVec2(
                        xPos, 
                        fYCenter-fYCenterLineLen1th-(fYCenterLineLen1th/4)
                    ), 
                    ImVec2(
                        xPos, 
                        fYCenter+fYCenterLineLen1th
                    ), 
                    uLineColor, 
                    2f, 
                );
            
            }

            // REF LINE
            ImDrawList_AddLine(drawList, ImVec2(oRect.Min.x, fYCenter), ImVec2(oRect.Max.x, fYCenter), uLineColor, 2f);
            
            // AXES POINTS
            foreach(xIdx; 0..axisPoints[0].length) {
                float xVal = axisPoints[0][xIdx].normValue;

                vCursorPos = ImVec2(
                    (oRect.Max.x - oRect.Min.x) * xVal + oRect.Min.x, 
                    fYCenter
                );

                ImDrawList_AddCircleFilled(drawList, vCursorPos, 6.0f, uDotKeyColor, 16);
            }

        igPopID(); 

        igItemAdd(fRect, id);
        igItemSize(size);
    }
}


/**
    Draws dashed lines
*/
void ImDrawList_AddLineDashed(ImDrawList* self, ImVec2 a, ImVec2 b, ImU32 col, float thickness = 1f, int segments = 50, float lineScale = 1f) {
    if ((col >> 24) == 0)
        return;

    ImVec2 dir = ImVec2(
        (b.x - a.x) / segments, 
        (b.y - a.y) / segments
    );

    bool on = true;
    ImVec2[2] points;
    foreach(i; 0..segments) {
        points[i%2] = ImVec2(a.x + dir.x * i, a.y + dir.y * i);

        if (i != 0 && i%2 == 0) {
            if (on) {
                ImDrawList_PathLineTo(self, ImVec2(points[0].x-(dir.x*lineScale), points[0].y-(dir.y*lineScale)));
                ImDrawList_PathLineTo(self, ImVec2(points[1].x+(dir.x*lineScale), points[1].y+(dir.y*lineScale)));
                ImDrawList_PathStroke(self, col, ImDrawFlags.None, thickness);
            }

            on = !on;
        }
    }
    ImDrawList_PathClear(self);
    
}