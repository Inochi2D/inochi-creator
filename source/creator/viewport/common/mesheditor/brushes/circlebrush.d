module creator.viewport.common.mesheditor.brushes.circlebrush;

import creator.viewport.common.mesheditor.brushes.base;
import creator.viewport;
import creator.widgets.drag;
import inochi2d;
import inochi2d.core.dbg;
import inmath;
import bindbc.imgui;

class CircleBrush : Brush {
    float radius;
    //float ratio;
    //float angle;
    
    this(float radius) {
        this.radius = radius;
    }
    
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
        vec3[] drawPoints;
        drawPoints ~= vec3(center, 0);
        inDbgSetBuffer(drawPoints);
        inDbgPointsSize(radius * incViewportZoom * 2 + 4);
        inDbgDrawPoints(vec4(0, 0, 0, 0.1), transform);
        inDbgPointsSize(2 * radius * incViewportZoom);
        inDbgDrawPoints(vec4(1, 1, 1, 0.3), transform);
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