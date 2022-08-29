/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.viewport;
import creator.viewport;
import creator.widgets;
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
        igPushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(1, 2));
        igSetNextWindowDockID(incGetViewportDockSpace(), ImGuiCond.Always);
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
        

        if (igBeginChild("##ViewportView", ImVec2(0, -30))) {
            igGetContentRegionAvail(&currSize);
            currSize = ImVec2(
                clamp(currSize.x, 128, float.max), 
                clamp(currSize.y, 128, float.max)-4
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
            inSetClearColor(style.Colors[ImGuiCol.WindowBg].x, style.Colors[ImGuiCol.WindowBg].y, style.Colors[ImGuiCol.WindowBg].z, 1);
            incViewportDraw();

            int width, height;
            inGetViewport(width, height);

            // Render our viewport
            ImVec2 sPos;
            ImVec2 sPosA;
            igGetCursorScreenPos(&sPos);
            
            igImage(
                cast(void*)inGetRenderImage(), 
                ImVec2(ceil(width/incGetUIScale()), ceil(height/incGetUIScale())), 
                ImVec2((0.5/width), 1-(0.5/height)), 
                ImVec2(1-(0.5/width), (0.5/height)), 
                ImVec4(1, 1, 1, 1), ImVec4(0, 0, 0, 0)
            );

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

            igGetCursorScreenPos(&sPosA);

            // Render our fancy in-viewport buttons
            igSetCursorScreenPos(ImVec2(sPos.x+8, sPos.y+8));
                igSetItemAllowOverlap();
                
                igPushStyleVar(ImGuiStyleVar.FrameRounding, 0);
                    if (igBeginChild("##ViewportMainControls", ImVec2(200, 28))) {
                        igPushStyleVar_Vec2(ImGuiStyleVar.FramePadding, ImVec2(6, 6));
                            incViewportDrawOverlay();
                        igPopStyleVar();
                    }
                    igEndChild();
                igPopStyleVar();

            igSetCursorScreenPos(sPosA);

            lastSize = currSize;
            igEndChild();
        }


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

                        try {
                            auto tex = new ShallowTexture(file);
                            incColorBleedPixels(tex);
                            inTexPremultiply(tex.data);
                            incAddChildWithHistory(
                                inCreateSimplePart(*tex, null, fname), 
                                incSelectedNode(), 
                                fname
                            );
                        } catch(Exception ex) {
                            if (ex.msg[0..11] == "unsupported") {
                                incDialog(__("Error"), _("%s is not supported").format(fname));
                            } else incDialog(__("Error"), ex.msg);
                        }

                        // We've added new stuff, rescan nodes
                        incActivePuppet().rescanNodes();
                        break;

                    // Allow dragging PSD in to main window
                    case ".psd":
                        incImportPSD(file);
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
        incViewportZoom = dampen(incViewportZoom, incViewportTargetZoom, deltaTime);
        camera.scale = vec2(incViewportZoom, incViewportZoom);
        camera.position = vec2(dampen(camera.position, incViewportTargetPosition, deltaTime, 1.5));
    }

public:
    this() {
        super("Viewport", _("Viewport"), true);
        this.alwaysVisible = true;
    }

}

mixin incPanel!ViewportPanel;
