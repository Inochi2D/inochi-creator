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
        
        int size = max(texture.width, texture.height);
        double imageScale = 1;

        float step = 1;
        if (size < SMALL_THRESHOLD) {
            step = SMALL_THRESHOLD / size * 2; // heulistic parameter adjustment. 
        }
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

            double[] scales;
            if (step == 1) {
                // scaling for larger parts
                scales = [1, 1.1, 0.9, 0.7, 0.4, 0.2, 0.1];
            } else {
                // special scaling for smaller parts
                scales = [1, 1.1, 0.8, 0.6, 0.2];
            }
            auto moment = calcMoment(contourVec);
            auto xlist = contourVec.map!((a)=>a.x);
            auto ylist = contourVec.map!((a)=>a.y);
            auto boundWidth  = xlist.reduce!(max) - xlist.reduce!(min);
            auto boundHeight = ylist.reduce!(max) - ylist.reduce!(min);
            auto minSize = min(boundWidth, boundHeight) * 0.05;
            minSize = min(minSize, MIN_DISTANCE);
            foreach (double scale; scales) {
                double samplingRate = SAMPLING_STEP;
                samplingRate = min(MAX_DISTANCE / scale, samplingRate / scale / scale / step); // heulistic sampling rate

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

        incText(_("Sampling rate"));
        igSameLine();
        igPushID("SAMPLING_STEP");
            igSetNextItemWidth(80);
            if (incDragFloat(
                "sampling_rate", &SAMPLING_STEP, 1,
                1, 200, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
            ) {
                SAMPLING_STEP = SAMPLING_STEP;
                if (MAX_DISTANCE < SAMPLING_STEP)
                    MAX_DISTANCE  = SAMPLING_STEP * 2;
            }
        igPopID();

        incText(_("Mask threshold"));
        igSameLine();
        igPushID("MASK_THRESHOLD");
            igSetNextItemWidth(80);
            if (incDragFloat(
                "mask_threshold", &maskThreshold, 1,
                1, 200, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
            ) {
                maskThreshold = maskThreshold;
            }
        igPopID();        

        incText(_("Distance between vertex"));
        igIndent();
            incText(_("Minimum"));
            igSameLine();
            igPushID("MIN_DISTANCE");
                igSetNextItemWidth(80);
                if (incDragFloat(
                    "min_distance", &MIN_DISTANCE, 1,
                    1, 200, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
                ) {
                    MIN_DISTANCE = MIN_DISTANCE;
                }
            igPopID();        

            incText(_("Maximum"));
            igSameLine();
            igPushID("MAX_DISTANCE");
                igSetNextItemWidth(80);
                if (incDragFloat(
                    "min_distance", &MAX_DISTANCE, 1,
                    1, 200, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
                ) {
                    MAX_DISTANCE = MAX_DISTANCE;
                }
            igPopID();
        igUnindent();
    }

};