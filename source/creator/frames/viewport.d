/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.frames.viewport;
import creator.widgets;
import creator.core;
import creator.core.colorbleed;
import creator.frames;
import creator.core.input;
import creator.actions;
import creator;
import inochi2d;
import inochi2d.core.dbg;
import bindbc.imgui;
import std.string;

/**
    A viewport
*/
class ViewportFrame : Frame {
private:
    ImVec2 lastSize;
    float zoom = 1;

    bool isMovingViewport;
    float sx, sy;
    float csx, csy;

    bool isMovingPart;

    void _updateMode() {
        ImGuiIO* io = igGetIO();
        vec2 mpos = incInputGetMousePosition();

        switch(incEditMode) {
            case EditMode.ModelEdit:
                if (igIsMouseClicked(ImGuiMouseButton.Left)) {
                    // TODO: allow selecting
                }

                if (igIsMouseClicked(ImGuiMouseButton.Right)) {
                    // TODO: Allow selecting from everything in the area of the click
                }
                
                // TODO: Allow dragging elements
                if (!isMovingPart && igIsMouseDragging(ImGuiMouseButton.Left)) {
                    isMovingPart = true;
                }
                if (isMovingPart) {
                    // TODO: Show drag
                }
                if (igIsMouseReleased(ImGuiMouseButton.Left)) {
                    // TODO: settle dragged element
                }
                break;
            
            case EditMode.DeformEdit:
                break;

            case EditMode.VertexEdit:
                break;
            
            default: assert(0);
        }
    }

    void _drawMode() {

        switch(incEditMode) {
            case EditMode.ModelEdit:
                break;
            
            case EditMode.DeformEdit:
                break;

            case EditMode.VertexEdit:
                break;
            
            default: assert(0);
        }
    }
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

            if (igIsWindowHovered(ImGuiHoveredFlags.ChildWindows)) {

                // HANDLE MOVE VIEWPORT
                if (!isMovingViewport && io.MouseDown[1]) {
                    isMovingViewport = true;
                    sx = io.MousePos.x;
                    sy = io.MousePos.y;
                    csx = camera.position.x;
                    csy = camera.position.y;
                }

                if (isMovingViewport && !io.MouseDown[1]) {
                    isMovingViewport = false;
                }

                if (isMovingViewport) {

                    camera.position = vec2(
                        csx+((io.MousePos.x-sx)/zoom),
                        csy+((io.MousePos.y-sy)/zoom)
                    );

                    incTargetPosition = camera.position;
                }

                // HANDLE ZOOM
                if (io.MouseWheel != 0) {
                    zoom += (io.MouseWheel/50)*zoom;
                    zoom = clamp(zoom, incVIEWPORT_ZOOM_MIN, incVIEWPORT_ZOOM_MAX);
                    camera.scale = vec2(zoom);
                    incTargetZoom = zoom;
                }
            }

            incBeginUpdate();
                incInputBegin();
                    ImVec2 pos;
                    ImVec2 mpos;
                    igGetItemRectMin(&pos);
                    igGetMousePos(&mpos);
                    incInputSetViewportMouse(pos.x-mpos.x, pos.y-mpos.y);

                    _updateMode();
                    incUpdateActiveProject();
                    _drawMode();

                // NOTE: No End Needed
            incEndUpdate();

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
                    igBeginChild("##ViewportMainControls", ImVec2(128, 28));
                        igPushStyleVar_Vec2(ImGuiStyleVar.FramePadding, ImVec2(6, 6));

                            igPushFont(incIconFont());
                                if (igButton("", ImVec2(0, 0))) {
                                    incShowVertices = !incShowVertices;
                                }
                            igPopFont();
                            incTooltip("Show/hide Vertices");
                                
                            igPushFont(incIconFont());
                                igSameLine(0, 0);
                                if (igButton("", ImVec2(0, 0))) {
                                    incShowBounds = !incShowBounds;
                                }
                            igPopFont();
                            incTooltip("Show/hide Bounds");

                            igPushFont(incIconFont());
                                igSameLine(0, 0);
                                if (igButton("", ImVec2(0, 0))) {
                                    incShowOrientation = !incShowOrientation;
                                }
                            igPopFont();
                            incTooltip("Show/hide Orientation Gizmo");

                        igPopStyleVar();
                    igEndChild();
                igPopStyleVar();

            igSetCursorScreenPos(sPosA);

            lastSize = currSize;
        igEndChild();

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
                        incAddChildWithHistory(
                            inCreateSimplePart(*tex, null, fname), 
                            incSelectedNode(), 
                            fname
                        );

                        // We've added new stuff, rescan nodes
                        incActivePuppet().rescanNodes();

                        foreach(Part part; incActivePuppet().getRootParts()) {
                            import std.stdio : writeln;
                            writeln(part);
                        }
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

        igGetContentRegionAvail(&currSize);
        igBeginChild("##ViewportControls", ImVec2(0, currSize.y), false, flags.NoScrollbar);
            igPushItemWidth(72);
                igSpacing();
                igSameLine(0, 8);
                if (igSliderFloat(
                    "##Zoom", 
                    &zoom, 
                    incVIEWPORT_ZOOM_MIN, 
                    incVIEWPORT_ZOOM_MAX, 
                    "%s%%\0".format(cast(int)(zoom*100)).ptr, 
                    ImGuiSliderFlags.NoRoundToFormat)
                ) {
                    camera.scale = vec2(zoom);
                    incTargetZoom = zoom;
                }
                if (incTargetZoom != 1) {
                    igPushFont(incIconFont());
                        igSameLine(0, 8);
                        if (igButton("", ImVec2(0, 0))) {
                            incTargetZoom = 1;
                        }
                    igPopFont();
                }
                igSameLine(0, 8);
                igSeparatorEx(ImGuiSeparatorFlags.Vertical);

                igSameLine(0, 8);
                igText("x = %.2f y = %.2f", incTargetPosition.x, incTargetPosition.y);
                if (incTargetPosition != vec2(0)) {
                    igSameLine(0, 8);
                    igPushFont(incIconFont());
                        if (igButton("##2", ImVec2(0, 0))) {
                            incTargetPosition = vec2(0, 0);
                        }
                    igPopFont();
                }


            igPopItemWidth();
        igEndChild();

        // Handle smooth move
        zoom = dampen(zoom, incTargetZoom, deltaTime, 1);
        camera.scale = vec2(zoom, zoom);
        camera.position = vec2(dampen(camera.position, incTargetPosition, deltaTime, 1.5));
    }

public:
    this() {
        super("Viewport", true);
        this.alwaysVisible = true;
    }

}

mixin incFrame!ViewportFrame;
