/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.timeline;
import creator.panels;
import i18n;
import inochi2d;
import bindbc.imgui;
import creator.widgets;
import creator;
import inmath.noise;
import creator.ext.param;
import creator.ext;

private {

    float tlAnimTime_ = 0;
    
    Animation* currAnim_;
    float tlWidth_ = DEF_HEADER_WIDTH;
    float[] tlTrackHeights_;
}

void incAnimationSet(ref Animation anim) {
    currAnim_ = &anim;
    tlAnimTime_ = 0;
    
    tlTrackHeights_.length = anim.lanes.length;
    foreach(i, track; anim.lanes) {
        tlTrackHeights_[i] = MIN_TRACK_HEIGHT;
    }
}

Animation* incAnimationGet() {
    return currAnim_;
}

float incAnimationGetTimelineWidth() {
    return tlWidth_;
}

float[] incAnimationGetTrackHeights() {
    return tlTrackHeights_;
}

/**
    The timeline panel
*/
class TimelinePanel : Panel {
private:
    float scroll = 0;
    float zoom = 1;

    Animation* workingAnimation;
    bool playing;
    float widgetHeight;

    void drawHeaders() {

        float tlWidth = incAnimationGetTimelineWidth();

        // BG Color
        auto origBG = igGetStyle().Colors[ImGuiCol.ChildBg];
        igPushStyleColor(ImGuiCol.ChildBg, ImVec4(0, 0, 0, 0.25));
        if (igBeginChild("HEADERS_ROOT", ImVec2(tlWidth, widgetHeight), false, ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoScrollWithMouse)) {

            // Get scroll
            auto window = igGetCurrentWindow();
            scroll = clamp(scroll, 0, igGetScrollMaxY());
            igSetScrollY(scroll);
            

            // Draw headers
            igPushStyleColor(ImGuiCol.ChildBg, origBG);
                if (incAnimationGet()) {
                    foreach(i, ref lane; incAnimationGet().lanes) {
                        incAnimationLaneHeader(lane, tlWidth, incAnimationGetTrackHeights()[i]);
                    }
                }
            igPopStyleColor();


            float headerHeight = window.ClipRect.Min.y-window.ClipRect.Max.y;
            incHeaderResizer(tlWidth, headerHeight, false);
        }
        igEndChild();
        igPopStyleColor();
    }

    void drawTracks() {
        igSameLine(0, 0);
        igPushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0));
        igPushStyleColor(ImGuiCol.ChildBg, ImVec4(0, 0, 0, 0.033));
            if (igBeginChild("LANES_ROOT", ImVec2(0, widgetHeight), false, ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoScrollWithMouse)) {
                
                // Set scroll
                auto window = igGetCurrentWindow();
                igSetScrollY(scroll);
                
                if (incAnimationGet()) {
                    foreach(i, ref lane; incAnimationGet().lanes) {
                        incTimelineLane(lane, *incAnimationGet(), incAnimationGetTrackHeights[i], zoom, cast(int)i);
                    }
                }
            }
            igEndChild();
        igPopStyleColor();
        igPopStyleVar();
    }

protected:
    override
    void onBeginUpdate() {
        igPushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(0, 0));
        igPushStyleVar(ImGuiStyleVar.ChildBorderSize, 0);
        super.onBeginUpdate();
    }

    override
    void onEndUpdate() {
        super.onEndUpdate();
        igPopStyleVar(2);
    }

    override
    void onUpdate() {
        bool inAnimMode = incEditMode() == EditMode.AnimEdit;

        igPushID("TopBar");
            igBeginDisabled(!inAnimMode);
            if (incBeginInnerToolbar(24)) {
                
                if (incToolbarButton("", 32)) {
                    incActivePuppet().player.stopAll(true);
                    playing = false;
                }

                if (incToolbarButton(playing ? "" : "", 32)) {
                    if (!playing) incActivePuppet().player.play("TEST", true);
                    else incActivePuppet().player.pause("TEST");
                    playing = !playing;
                }

                if (incToolbarButton("DUMMY", 64)) {
                    import std.random : uniform;

                    AnimationLane[] newRandomLaneParam(Parameter param, InterpolateMode mode, int frames, int sep = 5) {
                        int iter = param.isVec2 + 1;
                        AnimationLane[] p;

                        foreach(i; 0..iter) {
                            p ~= AnimationLane(
                                param.uuid,
                                new AnimationParameterRef(param, i), 
                                [], 
                                mode
                            );

                            osseed(uniform(0, uint.max));
                            foreach(x; 1..(frames-1)/sep) {
                                p[i].frames ~= Keyframe(x*sep, (1+osnoise2(cast(float)x, 0))/2.0, 0);
                            }
                        }
                        return p;
                    }

                    Animation a = Animation(
                        0.100, false, 1, [], 100, 0, 0
                    );

                    size_t i = 0;
                    // foreach(ref param; incActivePuppet().parameters) {
                    //     if (auto group = cast(ExParameterGroup)param) {
                    //         foreach(ref child; group.children) {
                    //             a.lanes ~= newRandomLaneParam(child, InterpolateMode.Cubic, 100);
                    //         }
                    //     } else a.lanes ~= newRandomLaneParam(param, InterpolateMode.Cubic, 100);
                        
                    // }

                    ExPuppet expuppet = cast(ExPuppet)incActivePuppet();
                    
                    a.lanes ~= newRandomLaneParam(expuppet.findParameter("Head:: Roll"), InterpolateMode.Stepped, 100);
                    a.lanes ~= newRandomLaneParam(expuppet.findParameter("Head:: Yaw-Pitch"), InterpolateMode.Stepped, 100);
                    a.lanes ~= newRandomLaneParam(expuppet.findParameter("Body:: Roll"), InterpolateMode.Stepped, 100);
                    a.lanes ~= newRandomLaneParam(expuppet.findParameter("Arm:: Left:: Move"), InterpolateMode.Stepped, 100);
                    a.lanes ~= newRandomLaneParam(expuppet.findParameter("Arm:: Right:: Move"), InterpolateMode.Stepped, 100);
                    a.lanes ~= newRandomLaneParam(expuppet.findParameter("Body:: X:: Move"), InterpolateMode.Stepped, 100);

                    incActivePuppet().getAnimations()["TEST"] = a;
                    incAnimationSet(incActivePuppet().getAnimations()["TEST"]);

                    incActivePuppet().player.set("TEST", true);
                }
            }
            incEndInnerToolbar();
            igEndDisabled();
        igPopID();

        // Widget height is used in all cases
        widgetHeight = incAvailableSpace().y-24;

        // Don't render contents if not in animation edit mode
        if (inAnimMode) {
            if (igIsWindowHovered(ImGuiHoveredFlags.ChildWindows)) {

                if ((igGetIO().KeyMods & ImGuiModFlags.Ctrl) == ImGuiModFlags.Ctrl) {
                    
                    float delta = (igGetIO().MouseWheel*2*zoom)*deltaTime();
                    zoom = clamp(zoom+delta, TIMELINE_MIN_ZOOM, TIMELINE_MAX_ZOOM);
                } else {

                    float delta = (igGetIO().MouseWheel*1024)*deltaTime();
                    scroll -= delta;
                }
            }

            drawHeaders();
            drawTracks();
        } else {
            incDummy(ImVec2(0, widgetHeight-3));
        }

        igPushID("BottomBar");
            if (incBeginInnerToolbar(24, false, false)) {

                // Align text
                igSetCursorPosY(6);

                float t = incActivePuppet().player.getAnimTime();
                int s = cast(int)t;
                int ms = cast(int)((t-cast(float)s)*100);

                import std.format;
                incText("%ss %sms".format(s, ms));
            }
            incEndInnerToolbar();
        igPopID();

        if (!inAnimMode) {
            incLabelOver(_("Not in Animation Edit mode..."), ImVec2(0, 0), true);
            return;
        }
    }

public:
    this() {
        super("Timeline", _("Timeline"), false);
        this.flags |= ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoScrollWithMouse;
    }
}

/**
    Generate timeline panel
*/
mixin incPanel!TimelinePanel;