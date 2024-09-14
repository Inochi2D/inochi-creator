/*
    Copyright © 2020-2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Lin, Yong Xiang <r888800009@gmail.com>
*/
module creator.viewport.common.mesheditor.tools.lasso;
import creator.viewport;
import creator.viewport.common.mesh;
import creator.viewport.common.mesheditor.tools.enums;
import creator.viewport.common.mesheditor.tools.base;
import creator.viewport.common.mesheditor.tools.select;
import creator.viewport.common.mesheditor.operations;
import creator.widgets;
import i18n;
import bindbc.imgui;
import inochi2d;
import inochi2d.core.dbg;
import std.algorithm.mutation : swap;

class LassoTool : NodeSelect {
private:
    vec3[] lassoPoints;

public:
    void doSelection(IncMeshEditorOne impl) {
        // lassoPoints is stored the edge so multiply by 2
        if (lassoPoints.length < 2 * 2)
            return;

        // get the vertices
        vec2[] vertices;
        if (auto tmpImpl = cast(IncMeshEditorOneDrawableDeform)impl) {
            auto drawable = cast(Drawable)tmpImpl.getTarget();
            vertices.length = drawable.vertices().length;
            foreach (index, vec; drawable.vertices())
                vertices[index] = vec + drawable.deformation[index];
        } else if (auto tmpImpl = cast(IncMeshEditorOneDrawable)impl) {
            auto drawable = cast(Drawable)tmpImpl.getTarget();
            vertices = drawable.vertices;
        } else {
            throw new Exception("Invalid IncMeshEditorOne type");
        }

        // check if the point is inside the lasso polygon
        foreach (index, vec; vertices) {
            if (pointInPolygon(vec3(vec.x, vec.y, 0), lassoPoints))
                impl.toggleSelect(index);
        }

        lassoPoints.length = 0;
    }

    /**
        check lines are crossing on x axis
    */
    pragma(inline, true)
    bool isCrossingXaxis(float y, vec2 p1, vec2 p2) {
        if (p1.y > p2.y)
            swap(p1, p2);
        return p1.y <= y && y <= p2.y && p1.y != p2.y;
    }

    /**
        Gets the point on the X axis that y crosses p1 and p2
    */
    pragma(inline, true)
    float getCrossX(float y, vec2 p1, vec2 p2) {
        return p1.x + (y - p1.y) / (p2.y - p1.y) * (p2.x - p1.x);
    }

    /**
        Gets whether the crossing direction is "up" or "down"
    */
    pragma(inline, true)
    bool getCrossDir(vec2 p1, vec2 p2) {
        return p1.y < p2.y ? true : false;
    }

    vec3[] mirrorLassoPoints(IncMeshEditorOne impl, uint axis, vec3[] points) {
        vec3[] mirroredPoints;
        foreach (point; points) {
            vec2 v2 = impl.mirrorDelta(axis, point.xy);
            mirroredPoints ~= vec3(v2.x, v2.y, 0);
        }
        return mirroredPoints;
    }

    bool pointInPolygon(vec3 p, vec3[] poly) {
        debug assert(poly.length % 2 == 0);
        
        // Sunday's algorithm
        ptrdiff_t crossings = 0;
        for (size_t i = 0; i < poly.length; i += 2) {
            vec2 p1 = poly[i].xy;
            vec2 p2 = poly[i + 1].xy;
            if (isCrossingXaxis(p.y, p1, p2)) {

                // check point is on the left side of the line
                float crossX = getCrossX(p.y, p1, p2);
                
                // Check direction of line
                bool dir = getCrossDir(p1, p2);

                if (p.x < crossX) {
                    if (dir)    crossings++;
                    else        crossings--;
                }
            }
        }
        return crossings != 0;
    }

    override
    bool update(ImGuiIO* io, IncMeshEditorOne impl, int action, out bool changed) {
        super.update(io, impl, action, changed);
        incStatusTooltip(_("Add Lasso Point"), _("Left Mouse"));
        incStatusTooltip(_("Delete Last Point"), _("Right Mouse"));
        incStatusTooltip(_("Clear"), _("ESC"));

        if (igIsMouseClicked(ImGuiMouseButton.Left) ||
            (igIsMouseDown(ImGuiMouseButton.Left) && lassoPoints.length > 0 &&
            lassoPoints[$ - 1].xy.distance(impl.mousePos) > 14/incViewportZoom)) {

            if (lassoPoints.length > 1)
                lassoPoints ~= lassoPoints[$ - 1];
            lassoPoints ~= vec3(impl.mousePos.x, impl.mousePos.y, 0);

            size_t p = isClosestToStart(vec3(impl.mousePos.x, impl.mousePos.y, 0));
            if (p == 0 && lassoPoints.length > 2) {
                // force close the polygon prevent issue
                lassoPoints[$ - 1] = lassoPoints[0];
                doSelection(impl);
            }
        }

        if (igIsMouseClicked(ImGuiMouseButton.Right)) {
            if (lassoPoints.length >= 2) {
                lassoPoints.length -= 2;
            } else {
                lassoPoints.length = 0;
            }
        }

        if (igIsKeyPressed(ImGuiKey.Escape)) {
            lassoPoints.length = 0;
        }

        return true;
    }

    bool isCloses(vec3 p1, vec3 p2) {
        return p1.distance(p2) < 14/incViewportZoom;
    }

    size_t findClosest(vec3 target) {
        foreach (i, p; lassoPoints) {
            if (!isCloses(p, target))
                continue;
            return i;
        }
        return -1;
    }

    size_t isClosestToStart(vec3 target) {
        if (lassoPoints.length == 0)
            return -1;
        return isCloses(lassoPoints[0], target) ? 0 : -1;
    }

    override
    void draw(Camera camera, IncMeshEditorOne impl) {
        super.draw(camera, impl);

        if (lassoPoints.length == 0) {
            return;
        }

        mat4 transform = mat4.identity;
        if (impl.deformOnly)
            transform = impl.transform;

        impl.foreachMirror((uint axis) {
            vec3[] mirroredPoints = mirrorLassoPoints(impl, axis, lassoPoints);

            inDbgSetBuffer(mirroredPoints);
            inDbgPointsSize(10);
            inDbgDrawPoints(vec4(0, 0, 0, 1), transform);
            inDbgPointsSize(6);
            inDbgDrawPoints(vec4(0.5, 0.5, 0.5, 1), transform);

            // find closest point
            vec3 mousePos = vec3(impl.mousePos.x, impl.mousePos.y, 0);
            size_t p = isClosestToStart(mousePos);
            if (p != -1) {
                inDbgSetBuffer([mirroredPoints[p]]);
                inDbgPointsSize(10);
                inDbgDrawPoints(vec4(1, 0, 0, 1), transform);
            }

            inDbgSetBuffer(mirroredPoints ~ mirrorLassoPoints(impl, axis, [lassoPoints[$ - 1], vec3(impl.mousePos.x, impl.mousePos.y, 0)]));
            inDbgLineWidth(3);
            inDbgDrawLines(vec4(.0, .0, .0, 1), transform);
            inDbgLineWidth(1);
            inDbgDrawLines(vec4(1, 1, 1, 1), transform);
        });
    }
}

class LassoToolInfo : ToolInfoBase!LassoTool {
    override
    bool viewportTools(bool deformOnly, VertexToolMode toolMode, IncMeshEditorOne[Node] editors) {
        return super.viewportTools(deformOnly, toolMode, editors);
    }
    override VertexToolMode mode() { return VertexToolMode.LassoSelection; }

    // material symbols "\ueb03" lasso_select not working
    // using material icons (deprecated) highlight_alt instead
    override string icon() { return "\uef52"; }
    override string description() { return _("Lasso Selection"); }
}