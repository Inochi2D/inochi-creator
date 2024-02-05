module creator.viewport.common.mesheditor.brushes.rectanglebrush;

import creator.viewport.common.mesheditor.brushes.base;
import creator.viewport;
import creator.viewport.common;
import creator.widgets.drag;
import inochi2d;
import inochi2d.core.dbg;
import inmath;
import bindbc.imgui;

class RectangleBrush : Brush {
    float width;
    float height;
    float innerRatio;
    string _name;
    
    this(string name, float width, float height, float innerRatio) {
        _name = name;
        this.width = max(1, width);
        this.height = max(1, height);
        this.innerRatio = max(0, min(innerRatio, 1));
    }

    override
    string name() {return _name;}
    
    override
    bool isInside(vec2 center, vec2 pos) {
        vec2 distance = (pos - center).abs;
        return distance.x <= width / 2 && distance.y <= height;
    }
    
    override
    float weightAt(vec2 center, vec2 pos) {
        vec2 distance = (pos - center).abs;
        float xratio = min(1, max(0, 1 - distance.x / width));
        float yratio = min(1, max(0, 1 - distance.y / height));
        return min(xratio, yratio);
    }

    override
    float[] weightsAt(vec2 center, vec2[] positions) {
        float[] result;
        foreach (p; positions) {
            result ~= weightAt(center, p);
        }
        return result;
    }
    
    override
    void draw(vec2 center, mat4 transform) {
        auto drawPoints = incCreateRectBuffer(vec2(center.x - width, center.y - height), vec2(center.x + width, center.y + height));
        inDbgSetBuffer(drawPoints);
        inDbgPointsSize(8);
        inDbgDrawLines(vec4(0, 0, 0, 1), transform);
        inDbgPointsSize(4);
        inDbgDrawLines(vec4(1, 0, 0, 1), transform);
    }

    override
    bool configure() {
        igBeginGroup();
            igPushID("BRUSH_WIDTH");
            igSetNextItemWidth(64);
            incDragFloat(
                "brush_width", &width, 1,
                1, 2000, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
            igPopID();

            igSameLine(0, 4);
    
            igPushID("BRUSH_HEIGHT");
            igSetNextItemWidth(64);
            incDragFloat(
                "brush_height", &height, 1,
                1, 2000, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
            igPopID();

            igSameLine(0, 4);

            igPushID("BRUSH_INNER_RATIO");
            igSetNextItemWidth(64);
            incDragFloat(
                "brush_inner_radtio", &innerRatio, 1,
                0, 1, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
            igPopID();
        igEndGroup();
        return false;
    }
}