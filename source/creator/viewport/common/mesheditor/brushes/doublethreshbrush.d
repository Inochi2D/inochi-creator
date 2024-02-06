module creator.viewport.common.mesheditor.brushes.doublethreshbrush;

import creator.viewport.common.mesheditor.brushes.base;
import creator.viewport;
import creator.viewport.common;
import creator.widgets.drag;
import inochi2d;
import inochi2d.core.dbg;
import inmath;
import bindbc.imgui;

class DoubleThreshBrush : Brush {
    float radius;
    float innerRadius;
    string _name;
    
    this(string name, float radius, float innerRadius) {
        _name = name;
        this.radius = max(1, radius);
        this.innerRadius = min(innerRadius, radius);
    }

    override
    string name() {return _name;}
    
    override
    bool isInside(vec2 center, vec2 pos) {
        return (center.distance(pos) <= radius);
    }
    
    override
    float weightAt(vec2 center, vec2 pos) {
        float distance = abs(pos.distance(center));
        if (distance <= innerRadius)
            return 1;
        if (radius > innerRadius)
            return min(1, max(1 - (distance - innerRadius) / (radius - innerRadius), 0));
        return 0;
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
        vec3[] drawPoints = incCreateCircleBuffer(center, vec2(radius, radius), 32) ~
                            incCreateCircleBuffer(center, vec2(innerRadius, innerRadius), 32);
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

            igSameLine(0, 4);
    
            igPushID("BRUSH_INNER_RADIUS");
            igSetNextItemWidth(64);
            incDragFloat(
                "brush_inner_radius", &innerRadius, 1,
                1, 2000, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
            igPopID();
        igEndGroup();
        return false;
    }
}