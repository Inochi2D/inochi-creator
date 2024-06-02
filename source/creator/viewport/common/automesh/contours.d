module creator.viewport.common.automesh.contours;

import i18n;
import creator.viewport.common.automesh.automesh;
import creator.viewport.common.mesh;
import creator.widgets;
import inochi2d.core;
import inmath;
import dcv.core;
import dcv.imgproc;
import dcv.measure;
import mir.ndslice;
import mir.math.stat: mean;
import std.algorithm;
import std.algorithm.iteration: map, reduce;
import std.stdio;
import std.array;
import bindbc.imgui;

class ContourAutoMeshProcessor : AutoMeshProcessor {
    float SAMPLING_STEP = 32;
    const float SMALL_THRESHOLD = 256;
    float maskThreshold = 15;
    float MIN_DISTANCE = 16;
    float MAX_DISTANCE = -1;
    float[] SCALES = [1, 1.1, 0.9, 0.7, 0.4, 0.2, 0.1];
    string presetName;
public:
    override IncMesh autoMesh(Drawable target, IncMesh mesh, bool mirrorHoriz = false, float axisHoriz = 0, bool mirrorVert = false, float axisVert = 0) {
        if (MAX_DISTANCE < 0)
            MAX_DISTANCE = SAMPLING_STEP * 2;
        auto contoursToVec2s(ContourType)(ref ContourType contours) {
            vec2[] result;
            foreach (contour; contours) {
                if (contour.length < 10)
                    continue;

                foreach (idx; 1..contour.shape[0]) {
                    result ~= vec2(contour[idx, 1], contour[idx, 0]);
                }
            }
            return result;
        }

        auto calcMoment(vec2[] contour) {
            auto moment = contour.reduce!((a, b){return a+b;})();
            return moment / contour.length;
        }

        auto scaling(vec2[] contour, vec2 moment, float scale, int erode_dilate) {
            float cx = 0, cy = 0;
            return contour.map!((c) { return (c - moment)*scale + moment; })().array;
        }
        
        auto resampling(vec2[] contour, double rate, bool mirrorHoriz, float axisHoriz, bool mirrorVert, float axisVert) {
            vec2[] sampled;
            ulong base = 0;
            if (mirrorHoriz) {
                float minDistance = -1;
                foreach (i, vertex; contour) {
                    if (minDistance < 0 || vertex.x - axisHoriz < minDistance) {
                        base = i;
                        minDistance = vertex.x - axisHoriz;
                    }
                }
            }
            sampled ~= contour[base];
            float side = 0;
            foreach (idx; 1..contour.length) {
                vec2 prev = sampled[$-1];
                vec2 c    = contour[(idx + base)%$];
                if ((c-prev).lengthSquared > rate*rate) {
                    if (mirrorHoriz) {
                        if (side == 0) {
                            side = sign(c.x - axisHoriz);
                        } else if (sign(c.x - axisHoriz) != side) {
                            continue;
                        }
                    }
                    sampled ~= c;
                }
            }
            return sampled;
        }

        Part part = cast(Part)target;
        if (!part)
            return mesh;

        Texture texture = part.textures[0];
        if (!texture)
            return mesh;
        ubyte[] data = texture.getTextureData();
        auto img = new Image(texture.width, texture.height, ImageFormat.IF_RGB_ALPHA);
        copy(data, img.data);
        
        float step = 1;

        auto gray = img.sliced[0..$, 0..$, 3]; // Use transparent channel for boundary search
        auto imbin = gray;
        foreach (y; 0..imbin.shape[0]) {
            foreach (x; 0..imbin.shape[1]) {
                imbin[y, x] = imbin[y, x] < cast(ubyte)maskThreshold? 0: 255;
            }
        }
        auto labels = bwlabel(imbin);
        bool[] labelFound = [false];
        long maxLabel = 0;
        foreach (y; 0..labels.shape[0]) {
            foreach (x; 0..labels.shape[1]) {
                if (labels[y, x] > maxLabel) {
                    maxLabel = labels[y, x];
                    while (labelFound.length <= maxLabel)
                        labelFound ~= false;
                } 
                if (imbin[y, x] == 0) {
                    labelFound[labels[y, x]] = true;
                }
            }
        }
        mesh.clear();

        vec2 imgCenter = vec2(texture.width / 2, texture.height / 2);
        foreach (label, found; labelFound) {
            if (!found)
                continue;
            foreach (y; 0..imbin.shape[0]) {
                foreach (x; 0..imbin.shape[1]) {
                    imbin[y, x] = (labels[y, x] == label && imbin[y, x] == 0)? 255: 0;
                }
            }

            auto contours = findContours(imbin);
            auto contourVec = contoursToVec2s(contours);

            if (contourVec.length == 0)
                continue;

            float[] scales;
            // scaling for larger parts
            scales = SCALES;

            auto moment = calcMoment(contourVec);
            auto minSize = MIN_DISTANCE;

            foreach (double scale; scales) {
                double samplingRate = SAMPLING_STEP;
                samplingRate = min(MAX_DISTANCE / scale, scale > 0? samplingRate / scale / scale / step: 1); // heulistic sampling rate

                auto contour2 = resampling(contourVec, samplingRate, mirrorHoriz, imgCenter.x + axisHoriz, mirrorVert, imgCenter.y + axisVert);
                auto contour3 = scaling(contour2, moment, scale, 0);
                if (mirrorHoriz) {
                    auto flipped = contour3.map!((a) => vec2(imgCenter.x + axisHoriz - (a.x - imgCenter.x - axisHoriz), a.y));
                    foreach (f; flipped) {
                        auto scaledContourVec = scaling(contourVec, moment, scale, 0);
                        auto index = scaledContourVec.map!((a)=>(a - f).lengthSquared).minIndex();
                        contour3 ~= scaledContourVec[index];
                    }
                }

                foreach (vec2 c; contour3) {
                    if (mesh.vertices.length > 0) {
                        auto minDistance = mesh.vertices.map!((v) { return ((c-imgCenter) - v.position).length; } ).reduce!(min);
                        if (minDistance > minSize)
                            mesh.vertices ~= new MeshVertex(c - imgCenter, []);
                    } else 
                        mesh.vertices ~= new MeshVertex(c - imgCenter, []);
                }
            }

        }

        return mesh.autoTriangulate();
    };

    override void configure() {
        if (MAX_DISTANCE < 0)
            MAX_DISTANCE = SAMPLING_STEP * 2;
        if (!presetName) {
            presetName = "Normal parts";
        }

        incText(_("Presets"));
        igIndent();
        if(igBeginCombo(__("Presets"), __(presetName))) {
            if (igSelectable(__("Normal parts"))) {
                presetName = "Normal parts";
                SAMPLING_STEP = 50;
                maskThreshold = 15;
                MIN_DISTANCE = 16;
                MAX_DISTANCE = SAMPLING_STEP * 2;
                SCALES = [1, 1.1, 0.9, 0.7, 0.4, 0.2, 0.1, 0];
            }
            if (igSelectable(__("Detailed mesh"))) {
                presetName = "Detailed mesh";
                SAMPLING_STEP = 32;
                maskThreshold = 15;
                MIN_DISTANCE = 16;
                MAX_DISTANCE = SAMPLING_STEP * 2;
                SCALES = [1, 1.1, 0.9, 0.7, 0.4, 0.2, 0.1, 0];
            }
            if (igSelectable(__("Large parts"))) {
                presetName = "Large parts";
                SAMPLING_STEP = 80;
                maskThreshold = 15;
                MIN_DISTANCE = 24;
                MAX_DISTANCE = SAMPLING_STEP * 2;
                SCALES = [1, 1.1, 0.9, 0.7, 0.4, 0.2, 0.1, 0];
            }
            if (igSelectable(__("Small parts"))) {
                presetName = "Small parts";
                SAMPLING_STEP = 24;
                maskThreshold = 15;
                MIN_DISTANCE = 12;
                MAX_DISTANCE = SAMPLING_STEP * 2;
                SCALES = [1, 1.1, 0.6, 0.2];

            }
            if (igSelectable(__("Thin and minimum parts"))) {
                presetName = "Thin and minimum parts";
                SAMPLING_STEP = 12;
                maskThreshold = 1;
                MIN_DISTANCE = 4;
                MAX_DISTANCE = SAMPLING_STEP * 2;
                SCALES = [1];

            }
            if (igSelectable(__("Preserve edges"))) {
                presetName = "Preserve edges";
                SAMPLING_STEP = 24;
                maskThreshold = 15;
                MIN_DISTANCE = 8;
                MAX_DISTANCE = SAMPLING_STEP * 2;
                SCALES = [1, 1.2, 0.8];

            }
            igEndCombo();
        }
        igUnindent();

        igPushID("CONFIGURE_OPTIONS");
        if (incBeginCategory(__("Details"))) {

            if (igBeginChild("###CONTOUR_OPTIONS", ImVec2(0, 320))) {
                incText(_("Sampling rate"));
                igIndent();
                igPushID("SAMPLING_STEP");
                    igSetNextItemWidth(64);
                    if (incDragFloat(
                        "sampling_rate", &SAMPLING_STEP, 1,
                        1, 200, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
                    ) {
                        SAMPLING_STEP = SAMPLING_STEP;
                        if (MAX_DISTANCE < SAMPLING_STEP)
                            MAX_DISTANCE  = SAMPLING_STEP * 2;
                    }
                igPopID();
                igUnindent();

                incText(_("Mask threshold"));
                igIndent();
                igPushID("MASK_THRESHOLD");
                    igSetNextItemWidth(64);
                    if (incDragFloat(
                        "mask_threshold", &maskThreshold, 1,
                        1, 200, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
                    ) {
                        maskThreshold = maskThreshold;
                    }
                igPopID();
                igUnindent();

                incText(_("Distance between vertices"));
                igIndent();
                    incText(_("Minimum"));
                    igIndent();
                        igPushID("MIN_DISTANCE");
                            igSetNextItemWidth(64);
                            if (incDragFloat(
                                "min_distance", &MIN_DISTANCE, 1,
                                1, 200, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
                            ) {
                                MIN_DISTANCE = MIN_DISTANCE;
                            }

                        igPopID();
                    igUnindent();

                    incText(_("Maximum"));
                    igIndent();
                        igPushID("MAX_DISTANCE");
                            igSetNextItemWidth(64);
                            if (incDragFloat(
                                "min_distance", &MAX_DISTANCE, 1,
                                1, 200, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
                            ) {
                                MAX_DISTANCE = MAX_DISTANCE;
                            }
                        igPopID();
                    igUnindent();
                igUnindent();

                int deleteIndex = -1;
                incText("Scales");
                igIndent();
                    igPushID("SCALES");
                        if (igBeginChild("###AXIS_ADJ", ImVec2(0, 240))) {
                            if (SCALES.length > 0) {
                                int ix;
                                foreach(i, ref pt; SCALES) {
                                    ix++;

                                    // Do not allow existing points to cross over
                                    vec2 range = vec2(0, 2);

                                    igSetNextItemWidth(80);
                                    igPushID(cast(int)i);
                                        if (incDragFloat(
                                            "adj_offset", &SCALES[i], 0.01,
                                            range.x, range.y, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
                                        ) {
                                            // do something
                                        }
                                        igSameLine(0, 0);

                                        if (i == SCALES.length - 1) {
                                            incDummy(ImVec2(-52, 32));
                                            igSameLine(0, 0);
                                            if (igButton("", ImVec2(24, 24))) {
                                                deleteIndex = cast(int)i;
                                            }
                                            igSameLine(0, 0);
                                            if (igButton("", ImVec2(24, 24))) {
                                                SCALES ~= 1.0;
                                            }

                                        } else {
                                            incDummy(ImVec2(-28, 32));
                                            igSameLine(0, 0);
                                            if (igButton("", ImVec2(24, 24))) {
                                                deleteIndex = cast(int)i;
                                            }
                                        }
                                    igPopID();
                                }
                            } else {
                                incDummy(ImVec2(-28, 24));
                                igSameLine(0, 0);
                                if (igButton("", ImVec2(24, 24))) {
                                    SCALES ~= 1.0;
                                }
                            }
                        }
                        igEndChild();
                    igPopID();
                igUnindent();
                incTooltip(_("Specifying scaling factor to apply for contours. If multiple scales are specified, vertices are populated per scale factors."));
                if (deleteIndex != -1) {
                    SCALES = SCALES.remove(cast(uint)deleteIndex);
                }
            }
            igEndChild();
        }
        incEndCategory();
        igPopID();


    }

};