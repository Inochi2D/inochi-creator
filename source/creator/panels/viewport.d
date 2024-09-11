/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.viewport;
import creator.viewport;
import creator.widgets;
import creator.widgets.viewport;
import creator.core;
import creator.core.colorbleed;
import creator.panels;
import creator.actions;
import creator;
import inochi2d;
import inochi2d.core.dbg;
import bindbc.imgui;
import std.string;
import i18n;

/**
    A viewport
*/
class ViewportPanel : Panel {
private:
    ImVec2 lastSize;
    bool actingInViewport;


    ImVec2 priorWindowPadding;

protected:
    override
    void onBeginUpdate() {
        
        ImGuiWindowClass wmclass;
        wmclass.DockNodeFlagsOverrideSet = ImGuiDockNodeFlagsI.NoTabBar;
        igSetNextWindowClass(&wmclass);
        priorWindowPadding = igGetStyle().WindowPadding;
        igPushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(0, 2));
        igSetNextWindowDockID(incGetViewportDockSpace(), ImGuiCond.Always);

        flags |= ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoScrollWithMouse;
        super.onBeginUpdate();
    }

    override void onEndUpdate() {
        super.onEndUpdate();
        igPopStyleVar();
    }

    override
    void onUpdate() {

        auto io = igGetIO();
        auto camera = inGetCamera();
        auto drawList = igGetWindowDrawList();
        auto window = igGetCurrentWindow();

        // Draw viewport itself
        ImVec2 currSize;
        igGetContentRegionAvail(&currSize);

        // We do not want the viewport to be NaN
        // That will crash the app
        if (currSize.x.isNaN || currSize.y.isNaN) {
            currSize = ImVec2(0, 0);
        }

        // Resize Inochi2D viewport according to frame
        // Also viewport of 0 is too small, minimum 128.
        currSize = ImVec2(clamp(currSize.x, 128, float.max), clamp(currSize.y, 128, float.max));
        
        foreach(btn; 0..cast(int)ImGuiMouseButton.COUNT) {
            if (!incStartedDrag(btn)) {
                if (io.MouseDown[btn]) {
                    if (igIsWindowHovered(ImGuiHoveredFlags.ChildWindows)) {
                        incBeginDragInViewport(btn);
                    }
                    incBeginDrag(btn);
                }
            }

            if (incStartedDrag(btn) && !io.MouseDown[btn]) {
                incEndDrag(btn);
                incEndDragInViewport(btn);
            }
        }
        if (igBeginChild("##ViewportView", ImVec2(0, -32), false, flags)) {
            igGetContentRegionAvail(&currSize);
            currSize = ImVec2(
                clamp(currSize.x, 128, float.max), 
                clamp(currSize.y, 128, float.max)
            );

            if (currSize != lastSize) {
                inSetViewport(cast(int)(currSize.x*incGetUIScale()), cast(int)(currSize.y*incGetUIScale()));
            }

            incViewportPoll();

            // Ignore events within child windows *unless* drag started within
            // viewport.
            ImGuiHoveredFlags winFlags = ImGuiHoveredFlags.None;
            if (actingInViewport) winFlags |= ImGuiHoveredFlags.ChildWindows | ImGuiHoveredFlags.AllowWhenBlockedByActiveItem;
            if (igIsWindowHovered(winFlags)) {
                actingInViewport = igIsMouseDown(ImGuiMouseButton.Left) ||
                    igIsMouseDown(ImGuiMouseButton.Middle) ||
                    igIsMouseDown(ImGuiMouseButton.Right);
                incViewportUpdate();
            } else if (incViewportAlwaysUpdate()) {
                incViewportUpdate(true);
            }

            auto style = igGetStyle();
            if (incShouldMirrorViewport) {
                camera.scale.x *= -1;
                incViewportDraw();
                camera.scale.x *= -1;
            } else {
                incViewportDraw();
            }

            int width, height;
            inGetViewport(width, height);

            ImVec4 color;
            inGetClearColor(color.x, color.y, color.z, color.w);

            ImRect rect = ImRect(
                ImVec2(
                    window.InnerRect.Max.x-1,
                    window.InnerRect.Max.y,
                ),
                ImVec2(
                    window.InnerRect.Min.x+1,
                    window.InnerRect.Max.y+currSize.y,
                ),
            );

            // Render background color
            ImDrawList_AddRectFilled(drawList,
                rect.Min,
                rect.Max,
                igGetColorU32(color),
            );

            // Render our viewport
            ImDrawList_AddImage(
                drawList,
                cast(void*)inGetRenderImage(),
                rect.Min,
                rect.Max,
                ImVec2((0.5/width), 1-(0.5/height)), 
                ImVec2(1-(0.5/width), (0.5/height)), 
                0xFFFFFFFF,
            );
            igItemAdd(rect, igGetID("###VIEWPORT_DISP"));
            
            // Popup right click menu
            igPushStyleVar(ImGuiStyleVar.WindowPadding, priorWindowPadding);
            if (incViewportHasMenu()) {
                static ImVec2 downPos;
                ImVec2 currPos;
                if (igIsItemHovered()) {
                    if (igIsItemClicked(ImGuiMouseButton.Right)) {
                        igGetMousePos(&downPos);
                    }

                    if (!igIsPopupOpen("ViewportMenu") && igIsMouseReleased(ImGuiMouseButton.Right)) {
                        igGetMousePos(&currPos);
                        float dist = sqrt(((downPos.x-currPos.x)^^2)+((downPos.y-currPos.y)^^2));
                        
                        if (dist < 16) {
                            incViewportMenuOpening();
                            igOpenPopup("ViewportMenu");
                        }
                    }
                }

                if (igBeginPopup("ViewportMenu")) {
                    incViewportMenu();
                    igEndPopup();
                }
            }
            igPopStyleVar();

            igPushStyleVar(ImGuiStyleVar.FrameBorderSize, 0);
                incBeginViewportToolArea("ToolArea", ImGuiDir.Left);
                    igPushStyleVar_Vec2(ImGuiStyleVar.FramePadding, ImVec2(6, 6));
                        incViewportDrawTools();
                    igPopStyleVar();
                incEndViewportToolArea();

                incBeginViewportToolArea("OptionsArea", ImGuiDir.Right);
                    igPushStyleVar_Vec2(ImGuiStyleVar.FramePadding, ImVec2(6, 6));
                        incViewportDrawOptions();
                    igPopStyleVar();
                incEndViewportToolArea();

                incBeginViewportToolArea("ConfirmArea", ImGuiDir.Left, ImGuiDir.Down, false);
                    incViewportDrawConfirmBar();
                incEndViewportToolArea();
                if (incEditMode == EditMode.ModelEdit)
                    incViewportTransformHandle();
            igPopStyleVar();

            lastSize = currSize;
            igEndChild();
        }

        // Draw line in a better way
        ImDrawList_AddLine(drawList, 
            ImVec2(
                window.InnerRect.Max.x-1,
                window.InnerRect.Max.y+currSize.y,
            ),
            ImVec2(
                window.InnerRect.Min.x+1,
                window.InnerRect.Max.y+currSize.y,
            ), 
            igColorConvertFloat4ToU32(*igGetStyleColorVec4(ImGuiCol.Separator)), 
            2
        );

        // FILE DRAG & DROP
        if (igBeginDragDropTarget()) {
            const(ImGuiPayload)* payload = igAcceptDragDropPayload("__PARTS_DROP");
            if (payload !is null) {
                string[] files = *cast(string[]*)payload.Data;
                import std.path : baseName, extension;
                import std.uni : toLower;
                mainLoop: foreach(file; files) {
                    string fname = file.baseName;

                    switch(fname.extension.toLower) {
                    case ".png", ".tga", ".jpeg", ".jpg":
                        incCreatePartsFromFiles([file]);
                        break;

                    // Allow dragging PSD in to main window
                    case ".psd":
                        incAskImportPSD(file);
                        break mainLoop;

                    // Allow dragging KRA in to main window
                    case ".kra":
                        incAskImportKRA(file);
                        break mainLoop;

                    default:
                        incDialog(__("Error"), _("%s is not supported").format(fname)); 
                        break;
                    }
                }

                // Finish the file drag
                incFinishFileDrag();
            }

            igEndDragDropTarget();
        }

        // BOTTOM VIEWPORT CONTROLS
        igGetContentRegionAvail(&currSize);
        if (igBeginChild("##ViewportControls", ImVec2(0, currSize.y), false, flags.NoScrollbar)) {
            igSetCursorPosY(igGetCursorPosY()+4);
            igPushItemWidth(72);
                igSpacing();
                igSameLine(0, 8);
                if (igSliderFloat(
                    "##Zoom", 
                    &incViewportZoom, 
                    incVIEWPORT_ZOOM_MIN, 
                    incVIEWPORT_ZOOM_MAX, 
                    "%s%%\0".format(cast(int)(incViewportZoom*100)).ptr, 
                    ImGuiSliderFlags.NoRoundToFormat)
                ) {
                    camera.scale = vec2(incViewportZoom);
                    incViewportTargetZoom = incViewportZoom;
                }
                if (incViewportTargetZoom != 1) {
                    igSameLine(0, 8);
                    if (igButton("", ImVec2(0, 0))) {
                        incViewportTargetZoom = 1;
                    }
                }

                igSameLine(0, 8);
                igSeparatorEx(ImGuiSeparatorFlags.Vertical);

                igSameLine(0, 8);
                incText("x = %.2f y = %.2f".format(incViewportTargetPosition.x, incViewportTargetPosition.y));
                if (incViewportTargetPosition != vec2(0)) {
                    igSameLine(0, 8);
                    if (igButton("##2", ImVec2(0, 0))) {
                        incViewportTargetPosition = vec2(0, 0);
                    }
                }


            igPopItemWidth();
        }
        igEndChild();

        // Handle smooth move
        incViewportZoom = fdampen(incViewportZoom, incViewportTargetZoom, cast(float)deltaTime);
        camera.scale = vec2(incViewportZoom, incViewportZoom);
        camera.position = vec2(fdampen(camera.position, incViewportTargetPosition, cast(float)deltaTime));
    }

public:
    this() {
        super("Viewport", _("Viewport"), true);
        this.alwaysVisible = true;
    }

}

mixin incPanel!ViewportPanel;


import inmath.util;
import std.traits;
V fdampen(V, T)(V current, V target, T delta, T maxSpeed = 50) if(isVector!V && isFloatingPoint!T) {
    V out_ = current;
    V diff = current - target;

    // Actual damping
    if (diff.length > 0) {
        V direction = (diff).normalized;

        T speed = min(
            max(0.001, 5.0*(target - current).length) * delta,
            maxSpeed
        );
        V velocity = direction * speed;

        // Set target out
        out_ = ((target + diff) - velocity);

        // Handle overshooting
        diff = target - current;
        if (diff.dot(out_ - target) > 0.0f) {
            out_ = target;
        }
    }
    return out_;
}

T fdampen(T)(T current, T target, T delta, T maxSpeed = 50) if(isFloatingPoint!T) {
    T out_ = current;
    T diff = current - target;
    T diffLen = sqrt(diff^^2);
    T direction = diff/diffLen;

    // Actual damping
    if (diffLen > 0) {

        T speed = min(
            max(0.001, 5.0*sqrt((target - current)^^2)) * delta,
            maxSpeed
        );
        T velocity = direction * speed;

        // Set target out
        out_ = ((target + diff) - velocity);

        // Handle overshooting
        diff = target - current;
        if (diff * (out_ - target) > 0.0f) {
            out_ = target;
        }
    }
    return out_;
}