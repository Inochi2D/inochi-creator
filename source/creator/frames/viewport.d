module creator.frames.viewport;
import creator.core;
import creator.frames;
import creator;
import inochi2d;
import inochi2d.core.dbg;
import bindbc.imgui;

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
        wmclass.DockNodeFlagsOverrideSet = 
            ImGuiDockNodeFlags_NoTabBar;
        igSetNextWindowClass(&wmclass);
        igSetNextWindowDockID(incGetViewportDockSpace(), ImGuiCond_Always);
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
        if (igBeginChildStr("##ViewportMainControls", ImVec2(0, 32), false, 0)) {
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
        }

        // Draw viewport itself
        ImVec2 currSize;
        igGetContentRegionAvail(&currSize);
        currSize = ImVec2(clamp(currSize.x, 128, float.max), clamp(currSize.y, 128, float.max));
        if (igBeginChildStr("##ViewportView", ImVec2(0, currSize.y-24), false, 0)) {

            if (currSize != lastSize) {
                inSetViewport(cast(int)currSize.x, cast(int)currSize.y-32);
                
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
            igEndChild();

            if (igIsWindowHovered(ImGuiFocusedFlags_ChildWindows)) {

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
                zoom += (io.MouseWheel/50)*zoom;
                zoom = clamp(zoom, incVIEWPORT_ZOOM_MIN, incVIEWPORT_ZOOM_MAX);
                camera.scale = vec2(zoom);
                incTargetZoom = zoom;
            }
        }

        igGetContentRegionAvail(&currSize);
        if (igBeginChildStr("##ViewportControls", ImVec2(0, currSize.y), false, 0)) {
            igPushItemWidth(72);
                if (igSliderFloat("##Zoom", &zoom, incVIEWPORT_ZOOM_MIN, incVIEWPORT_ZOOM_MAX, "%.2f", 0)) {
                    camera.scale = vec2(zoom);
                    incTargetZoom = zoom;
                }
                if (zoom != 1) {
                    igSameLine(0, 8);
                    if (igButton("Reset", ImVec2(0, 0))) {
                        zoom = 1;
                    }
                }
                igSameLine(0, 8);
                igSeparatorEx(ImGuiSeparatorFlags_Vertical);

                igSameLine(0, 8);
                igText("x = %.2f y = %.2f", camera.position.x, camera.position.y);
                igSameLine(0, 8);
                if (igButton("Reset##2", ImVec2(0, 0))) {
                    camera.position = vec2(0, 0);
                    incTargetPosition = camera.position;
                }


            igPopItemWidth();
            igEndChild();
        }

        // Handle smooth move
        camera.scale = vec2(dampen(camera.scale.x, incTargetZoom, deltaTime, 1));
        camera.position = vec2(dampen(camera.position, incTargetPosition, deltaTime, 1));
    }

public:
    this() {
        super("Viewport");
        this.alwaysVisible = true;
        this.visible = true;
    }

}

mixin incFrame!ViewportFrame;
