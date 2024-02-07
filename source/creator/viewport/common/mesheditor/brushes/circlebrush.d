module creator.viewport.common.mesheditor.brushes.circlebrush;

import creator.viewport.common.mesheditor.brushes.base;
import creator.viewport;
import creator.viewport.common;
import creator.widgets.drag;
import inochi2d;
import inochi2d.core.dbg;
import inmath;
import bindbc.imgui;

class CircleBrush : Brush {
    string _name;
    float radius;
    
    this(string name, float radius) {
        _name = name;
        this.radius = radius;
    }

    override
    string name() { return _name; }
    
    override
    bool isInside(vec2 center, vec2 pos) {
        return (center.distance(pos) <= radius);
    }
    
    override
    float weightAt(vec2 center, vec2 pos) {
        float distance = 1 - abs(pos.distance(center)) / radius;
        return min(1, max(distance, 0));
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
        vec3[] drawPoints = incCreateCircleBuffer(center, vec2(radius, radius), 32);
        drawPoints ~= vec3(center.x - radius, center.y, 0);
        drawPoints ~= vec3(center.x + radius, center.y, 0);
        drawPoints ~= vec3(center.x, center.y - radius, 0);
        drawPoints ~= vec3(center.x, center.y + radius, 0);
        inDbgSetBuffer(drawPoints);
        inDbgPointsSize(8);
        inDbgDrawLines(vec4(0, 0, 0, 1), transform);
        inDbgPointsSize(4);
        inDbgDrawLines(vec4(1, 0, 0, 1), transform);
    }

    override
    bool configure() {
        igBeginGroup();
            igPushID("BRUSH_RADIUS");
            igSetNextItemWidth(64);
            incDragFloat(
                "brush_radius", &radius, 1,
                1, 2000, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
            igPopID();
    
        igEndGroup();
        return false;
    }
}