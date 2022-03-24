/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.viewport.model.deform;
import creator.widgets.tooltip;
import creator.core.input;
import inochi2d.core.dbg;
import creator.core;
import creator;
import inochi2d;
import bindbc.imgui;
import i18n;
import std.stdio;

private {
    vec2 lastMousePos;
    vec2 currMousePos;
    Drawable selected;

    ushort[] selectedIndices;
    vec2[] deformOffsets;

    /**
        Draws the points of the mesh
    */
    void drawMeshPoints() {
        if (deformOffsets.length == 0) return;

        auto trans = selected.transform.matrix();
        vec3[] points;
        vec3[] selPoints;
        vec2[] origVerts = selected.vertices;
        foreach(i, point; deformOffsets) {
            import std.algorithm.searching : canFind;
            if (selectedIndices.canFind(i)) selPoints ~= vec3(origVerts[i]+point, 0);
            else points ~= vec3(origVerts[i]+point, 0);
        }

        if (points.length > 0) {
            inDbgSetBuffer(points);
            inDbgPointsSize(8);
            inDbgDrawPoints(vec4(0, 0, 0, 1), trans);
            inDbgPointsSize(4);
            inDbgDrawPoints(vec4(1, 1, 1, 1), trans);
        }

        if (selPoints.length > 0) {
            inDbgSetBuffer(selPoints);
            inDbgPointsSize(8);
            inDbgDrawPoints(vec4(0, 0, 0, 1), trans);
            inDbgPointsSize(4);
            inDbgDrawPoints(vec4(1, 0, 0, 1), trans);
        }
    }

    void dragSelectedPoints(vec2 delta) {
        foreach(indice; selectedIndices) {
            deformOffsets[indice] += delta;
        }
    }

    vec2 pointMapToSelected(vec2 p) {
        mat4 tr = mat4.translation(p.x, p.y, 0)*selected.transform.matrix().inverse();
        return vec2(tr.matrix[0][3]*-1, tr.matrix[1][3]*-1);
    }

    vec2 pointRelToSelected(vec2 p) {
        mat4 tr = selected.transform.matrix()*mat4.translation(p.x, p.y, 0);
        return vec2(tr.matrix[0][3]*-1, tr.matrix[1][3]*-1);
    }

    bool deselectPoint(vec2 position) {
        import std.algorithm.mutation : remove;
        vec2[] origin = selected.vertices;
        foreach(i; 0..deformOffsets.length) {
            vec2 actualPoint = pointRelToSelected(origin[i]+deformOffsets[i]);

            if (actualPoint.distance(position) < 8f) {
                selectedIndices = selectedIndices.remove(i);
                return true;
            }
        }
        return false;
    }

    bool selectPoint(vec2 position) {
        vec2[] origin = selected.vertices;
        foreach(i, p; deformOffsets) {
            vec2 actualPoint = pointRelToSelected(origin[i]+p);

            if (actualPoint.distance(position) < 8f) {
                selectedIndices = [cast(ushort)i];
                return true;
            }
        }
        return false;
    }

    void addSelectPoint(vec2 position) {
        import std.algorithm.searching : canFind;
        import std.algorithm.mutation : remove;

        vec2[] origin = selected.vertices;
        foreach(i; 0..deformOffsets.length) {
            vec2 actualPoint = pointRelToSelected(origin[i]+deformOffsets[i]);

            if (actualPoint.distance(position) < 8f) {
                if (selectedIndices.canFind(i)) selectedIndices = selectedIndices.remove(i);
                else selectedIndices ~= cast(ushort)i;
                return;
            }
        }
    }

    void clearSelection() {
        selectedIndices.length = 0;
    }
}

void incViewportNodeDeformNotifyParamValueChanged() {
    deformOffsets.length = 0;
    if (selected is null) return;

    if (Parameter param = incArmedParameter()) {
        DeformationParameterBinding deform = cast(DeformationParameterBinding)param.getBinding(selected, "deform");
        if (deform) {
            writeln("RELOAD");
            deformOffsets = deform.getValue(param.getClosestBreakpoint()).vertexOffsets;
        } else {
            writeln("RESET");

            deformOffsets.length = selected.vertices.length;
            foreach(i; 0..deformOffsets.length) {
                deformOffsets[i] = vec2(0);
            }
        }
    }
}

void incViewportModelDeformNodeSelect(Node node) {
    if (Drawable selectedDraw = cast(Drawable)incSelectedNode()) {
        selectedIndices.length = 0;
        selected = selectedDraw;
        import std.stdio : writeln;
        writeln("NEW SELECT");
        incViewportNodeDeformNotifyParamValueChanged();
    }
}

void incViewportModelDeformUpdate(ImGuiIO* io, Camera camera, Parameter param) {
    if (Drawable selectedDraw = cast(Drawable)incSelectedNode()) {
        DeformationParameterBinding deform = cast(DeformationParameterBinding)param.getBinding(selected, "deform");
        lastMousePos = currMousePos;
        currMousePos = incInputGetMousePosition();
        if (incInputIsMouseClicked(ImGuiMouseButton.Left)) {
            if (io.KeyCtrl) {
                addSelectPoint(currMousePos);
            } else {
                selectPoint(currMousePos);
            }
        }
        if (incInputIsDragRequested(ImGuiMouseButton.Left)) {
            vec2 deltaMousePos = lastMousePos-currMousePos;
            dragSelectedPoints(deltaMousePos);
            writeln("SET @ ", param.getClosestBreakpoint());
            if (deform) {
                deform.update(deformOffsets);
            } else {
                deform = new DeformationParameterBinding(param, selectedDraw, "deform");
                deform.update(deformOffsets);
                param.bindings ~= deform;

            }
        }
    }
}

void incViewportModelDeformDraw(Camera camera, Parameter param) {
    if (Drawable selectedDraw = cast(Drawable)incSelectedNode()) {
        selectedDraw.drawMeshLines();
        drawMeshPoints();
    }
}