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

protected:
    override
    void onBeginUpdate() {
        
        ImGuiWindowClass wmclass;
        wmclass.DockNodeFlagsOverrideSet = ImGuiDockNodeFlagsI.NoTabBar;
        igSetNextWindowClass(&wmclass);
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
        

        igBeginChild("##ViewportView", ImVec2(0, -30));
            igGetContentRegionAvail(&currSize);
            currSize = ImVec2(
                clamp(currSize.x, 128, float.max), 
                clamp(currSize.y, 128, float.max)-4
            );

            if (currSize != lastSize) {
                inSetViewport(cast(int)currSize.x, cast(int)currSize.y);
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
                ImVec2(width, height), 
                ImVec2(0, 1), 
                ImVec2(1, 0), 
                ImVec4(1, 1, 1, 1), ImVec4(0, 0, 0, 0)
            );
            igGetCursorScreenPos(&sPosA);

            // Render our fancy in-viewport buttons
            igSetCursorScreenPos(ImVec2(sPos.x+8, sPos.y+8));
                igSetItemAllowOverlap();
                
                igPushStyleVar(ImGuiStyleVar.FrameRounding, 0);
                    igBeginChild("##ViewportMainControls", ImVec2(200, 28 * incGetUIScale()));
                        igPushStyleVar_Vec2(ImGuiStyleVar.FramePadding, ImVec2(6, 6));
                            incViewportDrawOverlay();
                        igPopStyleVar();
                    igEndChild();
                igPopStyleVar();

            igSetCursorScreenPos(sPosA);

            lastSize = currSize;
        igEndChild();


        // FILE DRAG & DROP
        if (igBeginDragDropTarget()) {
            ImGuiPayload* payload = igAcceptDragDropPayload("__PARTS_DROP");
            if (payload !is null) {
                string[] files = *cast(string[]*)payload.Data;
                import std.path : baseName, extension;
                import std.uni : toLower;
                mainLoop: foreach(file; files) {
                    string fname = file.baseName;

                    switch(fname.extension.toLower) {
                    case ".png", ".tga", ".jpeg", ".jpg":

                        auto tex = new ShallowTexture(file);
                        incColorBleedPixels(tex);
                        inTexPremultiply(tex.data);
                        incAddChildWithHistory(
                            inCreateSimplePart(*tex, null, fname), 
                            incSelectedNode(), 
                            fname
                        );

                        // We've added new stuff, rescan nodes
                        incActivePuppet().rescanNodes();
                        break;

                    // Allow dragging PSD in to main window
                    case ".psd":
                        incImportPSD(file);
                        break mainLoop;

                    default: break;
                    }
                }

                // Finish the file drag
                incFinishFileDrag();
            }

            igEndDragDropTarget();
        }

        // BOTTOM VIEWPORT CONTROLS
        igGetContentRegionAvail(&currSize);
        igBeginChild("##ViewportControls", ImVec2(0, currSize.y), false, flags.NoScrollbar);
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
                    igPushFont(incIconFont());
                        igSameLine(0, 8);
                        if (igButton("", ImVec2(0, 0))) {
                            incViewportTargetZoom = 1;
                        }
                    igPopFont();
                }
                igSameLine(0, 8);
                igSeparatorEx(ImGuiSeparatorFlags.Vertical);

                igSameLine(0, 8);
                igText("x = %.2f y = %.2f", incViewportTargetPosition.x, incViewportTargetPosition.y);
                if (incViewportTargetPosition != vec2(0)) {
                    igSameLine(0, 8);
                    igPushFont(incIconFont());
                        if (igButton("##2", ImVec2(0, 0))) {
                            incViewportTargetPosition = vec2(0, 0);
                        }
                    igPopFont();
                }


            igPopItemWidth();
        igEndChild();

        // Handle smooth move
        incViewportZoom = dampen(incViewportZoom, incViewportTargetZoom, deltaTime, 1);
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
