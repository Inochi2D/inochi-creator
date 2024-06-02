module creator.viewport.common.automesh.grid;

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

class GridAutoMeshProcessor : AutoMeshProcessor {
    float[] scaleX = [-0.1, 0.0, 0.5, 1.0, 1.1];
    float[] scaleY = [-0.1, 0.0, 0.5, 1.0, 1.1];
    float maskThreshold = 15;
    float xSegments = 2, ySegments = 2;
    float margin = 0.1;
public:
    override
    IncMesh autoMesh(Drawable target, IncMesh mesh, bool mirrorHoriz = false, float axisHoriz = 0, bool mirrorVert = false, float axisVert = 0) {
        Part part = cast(Part)target;
        if (!part)
            return mesh;

        Texture texture = part.textures[0];
        if (!texture)
            return mesh;
        ubyte[] data = texture.getTextureData();
        auto img = new Image(texture.width, texture.height, ImageFormat.IF_RGB_ALPHA);
        copy(data, img.data);
        
        auto gray = img.sliced[0..$, 0..$, 3]; // Use transparent channel for boundary search
        auto imbin = gray;
        foreach (y; 0..imbin.shape[0]) {
            foreach (x; 0..imbin.shape[1]) {
                imbin[y, x] = imbin[y, x] < cast(ubyte)maskThreshold? 0: 255;
            }
        }
        vec2 imgCenter = vec2(texture.width / 2, texture.height / 2);
        mesh.clear();

        float minX = texture.width();
        float minY = texture.height();
        float maxX = 0;
        float maxY = 0;
        foreach (y; 0..imbin.shape[0]) {
            foreach (x; 0..imbin.shape[1]) {
                if (imbin[y, x] > 0) {
                    minX = min(x, minX);
                    minY = min(y, minY);
                    maxX = max(x, maxX);
                    maxY = max(y, maxY);
                }
            }
        }

        MeshData meshData;
        
        mesh.axes = [[], []];
        scaleY.sort!((a, b)=> a<b);
        foreach (y; scaleY) {
            mesh.axes[0] ~= (minY * y + maxY * (1 - y)) - imgCenter.y;
        }
        scaleX.sort!((a, b)=> a<b);
        foreach (x; scaleX) {
            mesh.axes[1] ~= (minX * x + maxX * (1 - x)) - imgCenter.x;
        }
        meshData.gridAxes = mesh.axes[];
        meshData.regenerateGrid();
        mesh.copyFromMeshData(meshData);

        return mesh;
    }

    override
    void configure() {
        void editScale(ref float[] scales) {
            int deleteIndex = -1;
            if (igBeginChild("###AXIS_ADJ", ImVec2(0, 240))) {
                if (scales.length > 0) {
                    int ix;
                    foreach(i, ref pt; scales) {
                        ix++;

                        // Do not allow existing points to cross over
                        vec2 range = vec2(0, 2);

                        igSetNextItemWidth(80);
                        igPushID(cast(int)i);
                            if (incDragFloat(
                                "adj_offset", &scales[i], 0.01,
                                range.x, range.y, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
                            ) {
                                // do something
                            }
                            igSameLine(0, 0);

                            if (i == scales.length - 1) {
                                incDummy(ImVec2(-52, 32));
                                igSameLine(0, 0);
                                if (igButton("", ImVec2(24, 24))) {
                                    deleteIndex = cast(int)i;
                                }
                                igSameLine(0, 0);
                                if (igButton("", ImVec2(24, 24))) {
                                    scales ~= 1.0;
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
                        scales ~= 1.0;
                    }
                }
            }
            igEndChild();
            if (deleteIndex != -1) {
                scales = scales.remove(cast(uint)deleteIndex);
            }
        }

        void divideAxes() {
            scaleY.length = 0;
            scaleX.length = 0;
            if (margin != 0) {
                scaleY ~= -margin;
                scaleX ~= -margin;
            }
            foreach (y; 0..(ySegments+1)) {
                scaleY ~= y / ySegments;
            }
            foreach (x; 0..(xSegments+1)) {                
                scaleX ~= x / xSegments;
            }
            if (margin != 0) {
                scaleY ~= 1 + margin;
                scaleX ~= 1 + margin;
            }
        }

        igPushID("CONFIGURE_OPTIONS");

            if (incBeginCategory(__("Auto Segmentation"))) {
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

                incText(_("X Segments"));
                igIndent();
                    igPushID("XSEGMENTS");
                        igSetNextItemWidth(64);
                        if (incDragFloat(
                            "x_segments", &xSegments, 1,
                            2, 20, "%.0f", ImGuiSliderFlags.NoRoundToFormat)
                        ) {
                            divideAxes();
                        }
                    igPopID();
                igUnindent();

                incText(_("Y Segments"));
                igIndent();
                    igPushID("YSEGMENTS");
                        igSetNextItemWidth(64);
                        if (incDragFloat(
                            "y_segments", &ySegments, 1,
                            2, 20, "%.0f", ImGuiSliderFlags.NoRoundToFormat)
                        ) {
                            divideAxes();
                        }
                    igPopID();
                igUnindent();

                incText(_("Margin"));
                igIndent();
                    igPushID("MARGIN");
                        igSetNextItemWidth(64);
                        if (incDragFloat(
                            "margin", &margin, 0.1,
                            0, 1, "%.2f", ImGuiSliderFlags.NoRoundToFormat)
                        ) {
                            divideAxes();
                        }
                    igPopID();
                igUnindent();
            }
            incEndCategory();

            if (incBeginCategory(__("X Scale"))) {
                editScale(scaleX);
            }
            incEndCategory();
            if (incBeginCategory(__("Y Scale"))) {
                editScale(scaleY);
            }
            incEndCategory();
        igPopID();

    }

    override
    string icon() {
        return "";
    }
};