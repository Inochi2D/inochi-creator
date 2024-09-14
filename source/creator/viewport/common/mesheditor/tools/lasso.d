/*
    Copyright © 2020-2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Lin, Yong Xiang <r888800009@gmail.com>
*/

module creator.viewport.common.mesheditor.tools.lasso;
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

        auto implDrawable = cast(IncMeshEditorOneDrawable)impl;
        auto mesh = implDrawable.getMesh();
        if (mesh is null)
            return;

        foreach (index, meshVertex; mesh.vertices) {
            if (pointInPolygon(vec3(meshVertex.position.x, meshVertex.position.y, 0), lassoPoints))
                impl.toggleSelect(index);
        }

        lassoPoints.length = 0;
    }

    /**
        check lines are crossing on x axis
        Note: p1, p2 vec3 just for x, y (z is not used)
    */
    pragma(inline, true)
    bool isCrossingXaxis(float y, vec3 p1, vec3 p2) {
        if (p1.y > p2.y)
            swap(p1, p2);
        return p1.y <= y && y <= p2.y && p1.y != p2.y;
    }

    pragma(inline, true)
    float getCrossX(float y, vec3 p1, vec3 p2) {
        return p1.x + (y - p1.y) / (p2.y - p1.y) * (p2.x - p1.x);
    }

    bool pointInPolygon(vec3 p, vec3[] poly) {
        debug assert(poly.length % 2 == 0);
        // ray-casting algorithm
        bool inside = false;
        for (size_t i = 0; i < poly.length; i += 2) {
            vec3 p1 = poly[i];
            vec3 p2 = poly[i + 1];
            if (isCrossingXaxis(p.y, p1, p2)) {
                // check point is on the left side of the line
                float crossX = getCrossX(p.y, p1, p2);
                if (p.x < crossX)
                    inside = !inside;
            }
        }
        return inside;
    }

    override
    bool update(ImGuiIO* io, IncMeshEditorOne impl, int action, out bool changed) {
        super.update(io, impl, action, changed);
        incStatusTooltip(_("Add Lasso Point"), _("Left Mouse"));
        incStatusTooltip(_("Delete Last Point"), _("Right Mouse"));
        incStatusTooltip(_("Clear"), _("ESC"));

        if (igIsMouseClicked(ImGuiMouseButton.Left)) {


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
        return p1.distance(p2) < 20;
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

        inDbgSetBuffer(lassoPoints);
        inDbgPointsSize(10);
        inDbgDrawPoints(vec4(0, 0, 0, 1), transform);
        inDbgPointsSize(6);
        inDbgDrawPoints(vec4(0.5, 0.5, 0.5, 1), transform);

        // find closest point
        vec3 mousePos = vec3(impl.mousePos.x, impl.mousePos.y, 0);
        size_t p = isClosestToStart(mousePos);
        if (p != -1) {
            inDbgSetBuffer([lassoPoints[p]]);
            inDbgPointsSize(10);
            inDbgDrawPoints(vec4(1, 0, 0, 1), transform);
        }

        inDbgSetBuffer(lassoPoints ~ [lassoPoints[$ - 1], vec3(impl.mousePos.x, impl.mousePos.y, 0)]);
        inDbgLineWidth(3);
        inDbgDrawLines(vec4(.0, .0, .0, 1), transform);
        inDbgLineWidth(1);
        inDbgDrawLines(vec4(1, 1, 1, 1), transform);
    }
}

class ToolInfoImpl(T: LassoTool) : ToolInfoBase!(T) {
    override
    bool viewportTools(bool deformOnly, VertexToolMode toolMode, IncMeshEditorOne[Node] editors) {
        // idk why lasso selection can't get the deformed mesh vertex, so disable it
        if (deformOnly)
            return false;

        return super.viewportTools(deformOnly, toolMode, editors);
    }
    override VertexToolMode mode() { return VertexToolMode.LassoSelection; }

    // material symbols "\ueb03" lasso_select not working
    // using material icons (deprecated) highlight_alt instead
    override string icon() { return "\uef52"; }
    override string description() { return _("Lasso Selection"); }
}