module creator.frames.viewport;
import creator.core;
import creator.frames;
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

protected:
    override
    void onBeginUpdate() {
        
        ImGuiWindowClass wmclass;
        wmclass.DockNodeFlagsOverrideSet = ImGuiDockNodeFlagsI.NoTabBar;
        igSetNextWindowClass(&wmclass);
        igSetNextWindowDockID(incGetViewportDockSpace(), ImGuiCond.Always);
        super.onBeginUpdate();
    }

    override void onEndUpdate() {
        super.onEndUpdate();
    }

    override
    void onUpdate() {

        auto io = igGetIO();
        auto camera = inGetCamera();

        // Resize Inochi2D viewport according to frame
        igBeginChild("##ViewportMainControls", ImVec2(0, 32));
            if (igButton("P", ImVec2(0, 0))) {
                inDbgDrawMeshVertexPoints = !inDbgDrawMeshVertexPoints;
            }
            igSameLine(0, 8);
            if (igButton("L", ImVec2(0, 0))) {
                inDbgDrawMeshOutlines = !inDbgDrawMeshOutlines;
            }
            igSameLine(0, 8);
            if (igButton("O", ImVec2(0, 0))) {
                inDbgDrawMeshOrientation = !inDbgDrawMeshOrientation;
            }
        igEndChild();

        // Draw viewport itself
        ImVec2 currSize;
        igGetContentRegionAvail(&currSize);

        // We do not want the viewport to be NaN
        // That will crash the app
        if (currSize.x.isNaN || currSize.y.isNaN) {
            currSize = ImVec2(0, 0);
        }
        igSeparator();

        // Also viewport of 0 is too small, minimum 128.
        currSize = ImVec2(clamp(currSize.x, 128, float.max), clamp(currSize.y, 128, float.max));
        igBeginChild("##ViewportView", ImVec2(0, -32));
            
            igGetContentRegionAvail(&currSize);
            currSize = ImVec2(clamp(currSize.x, 128, float.max), clamp(currSize.y, 128, float.max));

            if (currSize != lastSize) {
                inSetViewport(cast(int)currSize.x, cast(int)currSize.y);
                
                // Redraw
                incUpdateActiveProject();
            }

            int width, height;
            inGetViewport(width, height);

            igImage(
                cast(void*)inGetRenderImage(), 
                ImVec2(width, height), 
                ImVec2(0, 1), 
                ImVec2(1, 0), 
                ImVec4(1, 1, 1, 1), ImVec4(0, 0, 0, 0)
            );

            lastSize = currSize;

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
        igEndChild();

        if (igBeginDragDropTarget()) {
            ImGuiPayload* payload = igAcceptDragDropPayload("__PARTS_DROP");
            if (payload !is null) {
                string[] files = *cast(string[]*)payload.Data;
                import std.path : baseName;
                foreach(file; files) {
                    string fname = file.baseName;
                    Part p = inCreateSimplePart(ShallowTexture(file), null, fname);
                    incAddChildWithHistory(p, incSelectedNode, fname);
                    p.updateBounds();
                }

                // We've added new stuff, rescan nodes
                incActivePuppet().rescanNodes();

                // Finish the file drag
                incFinishFileDrag();
            }

            igEndDragDropTarget();
        }

        igSeparator();

        igGetContentRegionAvail(&currSize);
        igBeginChild("##ViewportControls", ImVec2(0, currSize.y));
            igPushItemWidth(72);
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
                igSameLine(0, 8);
                igPushFont(incIconFont());
                    if (igButton("##2", ImVec2(0, 0))) {
                        incTargetPosition = vec2(0, 0);
                    }
                igPopFont();


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
