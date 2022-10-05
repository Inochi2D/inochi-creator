/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.imgexport;
import creator.windows;
import creator.widgets;
import creator.core;
import creator.core.i18n;
import creator;
import std.string;
import creator.utils.link;
import creator.ext;
import creator.io;
import i18n;
import inmath;
import inochi2d;

/**
    Settings window
*/
class ImageExportWindow : Window {
private:
    string outFile;
    ExCamera selectedCamera;
    ExCamera[] cameras;
    bool transparency;
    bool postprocessing;

    void export_() {
        Camera cam = selectedCamera.getCamera();
        vec2 vp = selectedCamera.getViewport();

        Camera oc;
        float or, og, ob, oa;
        int ow, oh;
        inGetViewport(ow, oh);
        oc = inGetCamera();

        // Set state for dumping viewport
        inSetCamera(cam);
        inSetViewport(cast(int)vp.x, cast(int)vp.y);
        if (transparency) {
            inGetClearColor(or, og, ob, oa);
            inSetClearColor(0, 0, 0, 0);
        }

        // Render viewport
        inBeginScene();
            incActivePuppet().draw();
        inEndScene();
        if (postprocessing) inPostProcessScene();

        // Dump to file
        ubyte[] data = new ubyte[inViewportDataLength()];
        inDumpViewport(data);
        incExportImage(outFile, data, cast(int)vp.x, cast(int)vp.y);

        // Reset state
        if (transparency) inSetClearColor(or, og, ob, oa);
        inSetViewport(ow, oh);
        inSetCamera(oc);
    }

protected:
    override
    void onBeginUpdate() {
        flags |= ImGuiWindowFlags.NoSavedSettings;
        
        ImVec2 wpos = ImVec2(
            igGetMainViewport().Pos.x+(igGetMainViewport().Size.x/2),
            igGetMainViewport().Pos.y+(igGetMainViewport().Size.y/2),
        );

        ImVec2 uiSize = ImVec2(
            512, 
            256
        );

        igSetNextWindowPos(wpos, ImGuiCond.Appearing, ImVec2(0.5, 0.5));
        igSetNextWindowSize(uiSize, ImGuiCond.Appearing);
        igSetNextWindowSizeConstraints(uiSize, ImVec2(float.max, float.max));
        super.onBeginUpdate();
    }

    override
    void onUpdate() {

        // Contents
        if (igBeginChild("ExportContent", ImVec2(0, -28), true)) {
            incText(_("Export Settings"));

            igSpacing();

            if (incBeginCategory(__("Camera"))) {
                if (igBeginCombo("###CAMERA", selectedCamera.name.toStringz)) {

                    foreach(ref camera; cameras) {
                        if (igMenuItem(camera.cName)) {
                            selectedCamera = camera;
                        }
                    }

                    igEndCombo();
                }

                igSpacing();
                igCheckbox(__("Allow Transparency"), &transparency);
                igCheckbox(__("Use Post Processing"), &postprocessing);
            }
            incEndCategory();
        }
        igEndChild();

        // Bottom buttons
        if (igBeginChild("ExportButtons", ImVec2(0, 0), false, ImGuiWindowFlags.NoScrollbar)) {
            incDummy(ImVec2(-64, 0));
            igSameLine(0, 0);

            if (igButton(__("Save"), ImVec2(64, 24))) {
                this.export_();
                this.close();
            }
        }
        igEndChild();
    }

public:
    this(string outFile) {
        super(_("Export Image..."));

        this.outFile = outFile;

        // Search for cameras
        cameras = incActivePuppet().findNodesType!ExCamera(incActivePuppet().root);
        if (cameras.length == 0) {
            incDialog("Error", "No cameras to export from in Scene, please add a Camera.");
            this.close();
            return;
        }

        selectedCamera = cameras[0];
    }
}