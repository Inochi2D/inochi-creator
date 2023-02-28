/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.videoexport;
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
import creator.io.videoexport;
import inochi2d.core.animation.player;

private {
    float acc = 0;
    float forcedTimestep = 1;

    double exportDeltaTime() {
        return acc += forcedTimestep;
    }

    void incEndExportVideo() {
        inSetTimingFunc(() { return igGetTime(); });
        incActivePuppet().resetDrivers();
    }

    void incBeginExportVideo(float timestep) {
        forcedTimestep = timestep;
        inSetTimingFunc(&exportDeltaTime);
    }
}

/**
    Video export window
*/
class VideoExportWindow : Window {
private:
    string outFile;
    ExCamera selectedCamera;
    ExCamera[] cameras;
    Animation[string] animations;
    bool transparency;
    bool postprocessing;
    VideoEncodingContext vctx;
    VideoCodec codec;
    string animToExport;
    bool done = false;

    AnimationPlayer player;
    AnimationPlaybackRef playback;
    int framerate = -1;
    float lengthFactor = 1;
    float frametime = 0;


    void exportFrame() {
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
        inUpdate();
        inBeginScene();
            incActivePuppet().update();
            player.update(frametime);
            incActivePuppet().draw();
        inEndScene();
        if (postprocessing) inPostProcessScene();

        // Dump to file
        ubyte[] data = new ubyte[inViewportDataLength()];
        inDumpViewport(data);
        vctx.encodeFrame(data);

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
            720, 
            420
        );

        igSetNextWindowPos(wpos, ImGuiCond.Appearing, ImVec2(0.5, 0.5));
        igSetNextWindowSize(uiSize, ImGuiCond.Appearing);
        igSetNextWindowSizeConstraints(uiSize, ImVec2(float.max, float.max));
        super.onBeginUpdate();
    }

    override
    void onUpdate() {
        if (incDialogButtonSelected("ENCODE_ERROR") == DialogButtons.OK) {
            this.close();
        }

        if (vctx && !done) {
            this.exportFrame();
            if (vctx.progress >= 1) {
                incEndExportVideo();
                done = true;
            }

            if (!vctx.checkState) {
                incDialog("ENCODE_ERROR", __("Error"), "FFMPEG Encoding Error:\n"~vctx.errors());
                vctx.end();
                vctx = null;
            }
        }

        igBeginDisabled(vctx !is null);
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
                
                if (incBeginCategory(__("Output"))) {
                    igText(__("Animation"));
                    if (igBeginCombo("###Animation", animToExport.toStringz)) {
                        foreach(name, anim; incActivePuppet().getAnimations) {
                            if (igMenuItem(name.toStringz)) {
                                animToExport = name;
                            }
                        }
                        
                        igEndCombo();
                    }

                    igDragInt(__("Framerate"), &framerate, 1, -1, 240);
                    if (framerate < 1) {
                        igSameLine(0, 4);
                        igText(__("[AUTO]"));
                    }
                    incTooltip(_("Framerate of the video file"));

                    igCheckbox(__("Lock to Animation Framerate"), &player.snapToFramerate);

                    igText(__("Codec"));
                    igIndent();
                        if (igBeginCombo("###Codec", codec.name.toStringz)) {
                            foreach(cdc; incVideoCodecs()) {
                                if (igMenuItem(cdc.name.toStringz)) {
                                    codec = cdc;
                                }
                            }
                            
                            igEndCombo();
                        }

                    igUnindent();
                    incEndCategory();
                }
            }
            igEndChild();
        igEndDisabled();

        // Bottom buttons
        if (igBeginChild("ExportButtons", ImVec2(0, 0), false, ImGuiWindowFlags.NoScrollbar)) {
            igProgressBar(vctx ? vctx.progress() : 0, ImVec2(-68, 24));
            igSameLine(0, 4);

            if (!vctx) {
                if (igButton(__("Export"), ImVec2(64, 24))) {
                    playback = player.createOrGet(animToExport);


                    frametime = playback.animation.timestep;
                    if (framerate >= 1 && framerate != playback.fps) {
                        lengthFactor = framerate/playback.fps;
                        frametime = 1.0/framerate;
                    }

                    VideoExportSettings settings;
                    settings.frames = cast(int)(playback.animation.length*lengthFactor);
                    settings.framerate = framerate < 1 ? playback.fps : framerate;
                    settings.codec = codec.tag;
                    settings.width = selectedCamera.getViewport().x;
                    settings.height = selectedCamera.getViewport().y;
                    settings.file = outFile;
                    settings.transparency = transparency;
                    done = false;

                    vctx = new VideoEncodingContext(settings);
                    incBeginExportVideo(frametime);
                    playback.play(false, true);
                    player.prerenderAll();
                    incActivePuppet().resetDrivers();
                }
            } else {
                if (!done) {
                    if (igButton(__("Cancel"), ImVec2(64, 24))) {
                        vctx.end();
                        incEndExportVideo();
                        this.close();
                    }
                } else {
                    if (igButton(__("Close"), ImVec2(64, 24))) {
                        this.close();
                    }
                }
            }
        }
        igEndChild();
    }

public:
    this(string outFile) {
        super(_("Export Video..."));

        if (!incVideoCanExport()) {
            incDialog("NO_EXPORT", __("Error"), _("FFMPEG was not found, please install FFMPEG to export video."));
            this.close();
            return;
        }

        this.outFile = outFile;

        // Search for cameras
        cameras = incActivePuppet().findNodesType!ExCamera(incActivePuppet().root);
        if (cameras.length == 0) {
            incDialog("NO_CAMERA", __("Error"), _("No cameras to export from in Scene, please add a Camera."));
            this.close();
            return;
        }

        // Search for animations
        animations = incActivePuppet().getAnimations();
        if (animations.length == 0) {
            incDialog("NO_ANIMS", __("Error"), _("No animations are defined for this model, please add an animation."));
            this.close();
            return;
        }

        codec = incVideoCodecs()[0];
        animToExport = animations.keys[0];
        selectedCamera = cameras[0];
        player = new AnimationPlayer(incActivePuppet());
    }
}