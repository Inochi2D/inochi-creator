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
import inochi2d.core.animation.player;

private {
    float tlWidth_ = DEF_HEADER_WIDTH;
    float[] tlTrackHeights_;
}

void incAnimationTimelineUpdate(ref Animation anim) {
    tlTrackHeights_.length = anim.lanes.length;
    foreach(i, track; anim.lanes) {
        tlTrackHeights_[i] = MIN_TRACK_HEIGHT;
    }
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
                    foreach(i; 0..incAnimationGet().animation().lanes.length) {
                        AnimationLane* lane = &incAnimationGet().animation().lanes[i];

                        igPushID(cast(int)i);
                            if (igBeginPopup("###OPTIONS")) {
                                if (igBeginMenu(__("Interpolation"))) {
                                    if (igMenuItem(__("Nearest"), null, lane.interpolation == InterpolateMode.Nearest)) {
                                        lane.interpolation = InterpolateMode.Nearest;
                                    }
                                    if (igMenuItem(__("Stepped"), null, lane.interpolation == InterpolateMode.Stepped)) {
                                        lane.interpolation = InterpolateMode.Stepped;
                                    }
                                    if (igMenuItem(__("Linear"), null, lane.interpolation == InterpolateMode.Linear)) {
                                        lane.interpolation = InterpolateMode.Linear;
                                    }
                                    if (igMenuItem(__("Cubic"), null, lane.interpolation == InterpolateMode.Cubic)) {
                                        lane.interpolation = InterpolateMode.Cubic;
                                    }
                                    igEndMenu();
                                }

                                if (igMenuItem(__("Delete"))) {
                                    import std.algorithm.mutation : remove;
                                    incAnimationGet().animation().lanes = 
                                        incAnimationGet().animation().lanes.remove(i);

                                    // Whew, end early
                                    igEndPopup();
                                    igPopID();
                                    igPopStyleColor();
                                    igEndChild();
                                    igPopStyleColor();
                                    return;
                                }
                                igEndPopup();
                            }
                            incAnimationLaneHeader(*lane, tlWidth, incAnimationGetTrackHeights()[i]);
                            igOpenPopupOnItemClick("###OPTIONS", ImGuiPopupFlags.MouseButtonRight);
                        igPopID();
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
                    incBeginTimelinePlayhead(*incAnimationGet().animation, zoom);
                        foreach(i, ref lane; incAnimationGet().animation().lanes) {
                            float frame;
                            float offset;
                            incTimelineLane(lane, *incAnimationGet().animation, incAnimationGetTrackHeights[i], zoom, cast(int)i, &frame, &offset);

                            if (frame > -1) {
                                int xframe = cast(int)round(frame);
                                if (igIsMouseDown(ImGuiMouseButton.Left)) {
                                    incAnimationGet().seek(xframe);
                                }

                                if (igIsMouseDoubleClicked(ImGuiMouseButton.Left)) {
                                    auto param = lane.paramRef.targetParam;
                                    auto axis = lane.paramRef.targetAxis;
                                    auto value = param.unmapAxis(axis, offset);

                                    if (!incAnimationKeyframeRemove(param, axis)) incAnimationKeyframeAdd(param, axis, value);
                                }
                            }
                        }
                    incEndTimelinePlayhead(*incAnimationGet().animation, zoom, incAnimationGet().hframe);
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

        AnimationPlaybackRef anim = incAnimationGet();

        igPushID("TopBar");
            igBeginDisabled(!inAnimMode);
            if (incBeginInnerToolbar(24)) {
                
                
                igBeginDisabled(!anim);
                    auto player = incAnimationPlayerGet();
                    if (incToolbarButton(player.snapToFramerate ? "" : "", 32)) {
                        player.snapToFramerate = !player.snapToFramerate;
                    }
                    incTooltip(_("Lock playback to animation framerate"));

                    if (incToolbarButton("", 32)) {
                        anim.stop(igIsKeyDown(ImGuiKey.LeftShift) || igIsKeyDown(ImGuiKey.RightShift));
                    }

                    if (incToolbarButton(anim && !(!anim.playing || anim.paused) ? "" : "", 32)) {
                        if (!anim.playing || anim.paused) anim.play(true);
                        else anim.pause();
                    }
                igEndDisabled();
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

                int s, ms;
                if (anim) {
                    s = anim.seconds;
                    ms = anim.miliseconds;
                }

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