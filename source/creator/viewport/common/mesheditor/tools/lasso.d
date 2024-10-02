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

/**
    the PolyLassoTool allow to draw a polygon and undo the last point
    the RegualarLassoTool just click and drag to draw a lasso selection
*/
enum LassoType {
    PolyLasso = 0,
    RegularLasso = 1,
}

private {
    const(char)* getLassoIcon(LassoType type) {
        final switch(type) {
            case LassoType.PolyLasso:
                return "\ue922";
            case LassoType.RegularLasso:
                return "\ue155";
        }
    }

    string getLassoHint(LassoType lassoType) {
        switch (lassoType) {
            case LassoType.PolyLasso: return _("Poly Lasso Selection Mode");
            case LassoType.RegularLasso: return _("Regular Lasso Selection Mode");
            default:
                throw new Exception("Invalid LassoType");
        }
    }

    LassoType getNextLassoType(LassoType lassoType) {
        switch (lassoType) {
            case LassoType.PolyLasso: return LassoType.RegularLasso;
            case LassoType.RegularLasso: return LassoType.PolyLasso;
            default:
                throw new Exception("Invalid LassoType");
        }
    }
}

class LassoIO {
    bool addSelect = false;
    bool removeSelect = false;
    bool undo = false;
    bool cleanup = false;

    void update() {
        addSelect = igIsKeyDown(ImGuiKey.ModShift);
        removeSelect = igIsKeyDown(ImGuiKey.ModCtrl);
        undo = igIsMouseClicked(ImGuiMouseButton.Right);
        cleanup = igIsKeyPressed(ImGuiKey.Escape);
    }
}

class LassoTool : NodeSelect {
private:
    vec3[] lassoPoints;
    size_t[] rollbackCheckpoints;

public:
    LassoType lassoType = LassoType.RegularLasso;

    void setNextMode() {
        lassoType = getNextLassoType(lassoType);
        cleanup();
    }

    void cleanup() {
        lassoPoints.length = 0;
        rollbackCheckpoints.length = 0;
    }

    /**
        Rollback the previous checkpoint
    */
    bool rollbackOnce() {
        if (rollbackCheckpoints.length == 0)
            return false;
        
        lassoPoints.length = rollbackCheckpoints[$ - 1];
        rollbackCheckpoints.length -= 1;
        return true;
    }

    void commitCheckpoint() {
        rollbackCheckpoints ~= lassoPoints.length;
    }

    void doSelection(IncMeshEditorOne impl, LassoIO lassoIO) {
        bool addSelect = lassoIO.addSelect;
        bool removeSelect = lassoIO.removeSelect;

        // lassoPoints is stored the edge so multiply by 2
        if (lassoPoints.length < 2 * 2)
            return;

        // get the vertices
        vec2[] vertices;
        if (auto tmpImpl = cast(IncMeshEditorOneDrawableDeform)impl) {
            // We need to use Drawable because it has been Deformed
            auto drawable = cast(Drawable)tmpImpl.getTarget();
            vertices.length = drawable.vertices().length;
            foreach (index, vec; drawable.vertices())
                vertices[index] = vec + drawable.deformation[index];
        } else if (auto tmpImpl = cast(IncMeshEditorOneDrawable)impl) {
            // We can't use Drawable because the Drawable hasn't been updated yet
            // For edit mode we are not affected by binding so can use mesh vertices directly
            auto mesh = tmpImpl.getMesh();
            if (mesh is null)
                return;

            vertices.length = mesh.vertices.length;
            foreach (index, meshVertex; mesh.vertices)
                vertices[index] = meshVertex.position;
        } else {
            throw new Exception("Invalid IncMeshEditorOne type");
        }

        // check if the point is inside the lasso polygon
        if (!addSelect && !removeSelect)
            impl.deselectAll();

        foreach (index, vec; vertices) {
            if (pointInPolygon(vec3(vec.x, vec.y, 0), lassoPoints)) {
                if (addSelect && removeSelect) impl.toggleSelect(index); 
                else if(!addSelect && removeSelect) impl.deselect(index);
                else impl.select(index);
            }
                
        }

        cleanup();
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

    /**
        if trigger the doSelection, return true
    */
    bool doSelectionTrigger(IncMeshEditorOne impl, LassoIO lassoIO) {
        if (lassoPoints.length > 2) {
            // force close the polygon prevent issue
            lassoPoints[$ - 1] = lassoPoints[0];
            doSelection(impl, lassoIO);
            return true;
        }

        return false;
    }

    override
    bool update(ImGuiIO* io, IncMeshEditorOne impl, int action, out bool changed) {
        super.update(io, impl, action, changed);
        LassoIO lassoIO = new LassoIO;
        lassoIO.update();

        incStatusTooltip(_("Add Lasso Point"), _("Left Mouse"));
        incStatusTooltip(_("Additive Selection"), _("Shift"));
        if (lassoIO.addSelect) incStatusTooltip(_("Inverse Selection"), _("Ctrl"));
        else incStatusTooltip(_("Remove Selection"), _("Ctrl"));
        incStatusTooltip(_("Delete Last Lasso Point"), _("Right Mouse"));
        incStatusTooltip(_("Clear All Lasso Points"), _("ESC"));

        if (igIsMouseClicked(ImGuiMouseButton.Left))
            commitCheckpoint();

        if (igIsMouseClicked(ImGuiMouseButton.Left) ||
            (igIsMouseDown(ImGuiMouseButton.Left) && lassoPoints.length > 0 &&
            lassoPoints[$ - 1].xy.distance(impl.mousePos) > 14/incViewportZoom)) {

            if (lassoPoints.length > 1)
                lassoPoints ~= lassoPoints[$ - 1];
            lassoPoints ~= vec3(impl.mousePos.x, impl.mousePos.y, 0);

            if (isClosestToStart(vec3(impl.mousePos.x, impl.mousePos.y, 0)) == 0)
                doSelectionTrigger(impl, lassoIO);
        }

        if (igIsMouseReleased(ImGuiMouseButton.Left) && lassoType == LassoType.RegularLasso)
            doSelectionTrigger(impl, lassoIO);

        if (lassoIO.undo)
            rollbackOnce();

        if (lassoIO.cleanup)
            cleanup();

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

            // find closest point
            vec3 mousePos = vec3(impl.mousePos.x, impl.mousePos.y, 0);
            size_t p = isClosestToStart(mousePos);
            if (p != -1) {
                inDbgSetBuffer([mirroredPoints[p]]);
                inDbgPointsSize(10);
                inDbgDrawPoints(vec4(1, 0, 0, 1), transform);
            } else if (lassoType == LassoType.PolyLasso) {
                // draw the first point to hint the user to close the polygon
                inDbgSetBuffer([mirroredPoints[0]]);
                inDbgPointsSize(7);
                inDbgDrawPoints(vec4(0.6, 0.6, 0.6, 0.6), transform);
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

    override
    bool displayToolOptions(bool deformOnly, VertexToolMode toolMode, IncMeshEditorOne[Node] editors) { 
        auto lassoTool = cast(LassoTool)(editors.length == 0 ? null: editors.values()[0].getTool());
        igBeginGroup();
            auto current_icon = getLassoIcon(lassoTool.lassoType);
            if (incButtonColored(current_icon, ImVec2(0, 0), ImVec4.init)) {
                foreach (e; editors) {
                    auto lt = cast(LassoTool)(e.getTool());
                    if (lt !is null)
                        lt.setNextMode();
                }
            }
            incTooltip(getLassoHint(lassoTool.lassoType));
        igEndGroup();


        return false;
    }
}