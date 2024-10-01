module creator.viewport.common.mesheditor.tools.select;

import creator.viewport.common.mesheditor.tools.enums;
import creator.viewport.common.mesheditor.tools.base;
import creator.viewport.common.mesheditor.operations;
import i18n;
import creator.viewport;
import creator.viewport.common;
import creator.viewport.common.mesh;
import creator.viewport.common.spline;
import creator.core.input;
import creator.core.actionstack;
import creator.actions;
import creator.ext;
import creator.widgets;
import creator;
import inochi2d;
import inochi2d.core.dbg;
import bindbc.opengl;
import bindbc.imgui;
import std.algorithm.mutation;
import std.algorithm.searching;
import std.stdio;

class NodeSelect : Tool, Draggable {
    bool isDragging = false;

    enum SelectActionID {
        None = 0,
        SelectArea = 1,
        ToggleSelect,
        SelectOne,
        MaybeSelectOne,
        SelectMaybeSelectOne,
        StartDrag,
        End
    }

    override
    void setToolMode(VertexToolMode toolMode, IncMeshEditorOne impl) {
        assert(!impl.deformOnly || toolMode != VertexToolMode.Connect);
        isDragging = false;
        impl.isSelecting = false;
        incViewportSetAlwaysUpdate(false);
    }

    vec3 calculateMousePosIntersection(IncMeshEditorOne impl, vec2 mousePos) {
        vec3 translation = vec3(impl.transform[0][3], impl.transform[1][3], impl.transform[2][3]);
        mat4 RS = impl.transform;
        RS[0][3] = RS[1][3] = RS[2][3] = 0;
        float sx = vec3(RS[0][0], RS[1][0], RS[2][0]).length(); 
        float sy = vec3(RS[0][1], RS[1][1], RS[2][1]).length(); 
        float sz = vec3(RS[0][2], RS[1][2], RS[2][2]).length();
        mat4 R = mat4(sx, 0, 0, 0, 
                      0, sy, 0, 0, 
                      0, 0, sz, 0, 
                      0, 0, 0, 1);
        mat4 S = RS * R.inverse;

        // Assume that normal vector n of the mesh plane is defined as n = (0, 0, 1)
        vec3 n = vec3(0.0, 0.0, 1.0);
        float D_0 = 0.0;

        // plane is represented as Ax + By + Cz + D = 0
        // calculate transformed normal vector n' and D' 
        mat3 RS3 = mat3(RS);
        vec3 n_prime = (mat3(S) * mat3(R)).inverse.transposed * n;
        float D_prime = D_0 - dot(n_prime, translation);

        // calculated transformed A', B', C', D'
        // assume mouse position is on the line define by fixed point (x, y, 0) and unit vector (0, 0, 1)
        vec3 point = vec3(mousePos.x, mousePos.y, 0);
        vec3 direction = vec3(0.0, 0.0, 1.0);

        // calculated the intersection of line and plane.
        float numerator = -(dot(n_prime.xy, point.xy) + D_prime);
        float denominator = n_prime.z;

        vec3 projectionMousePos;
        if (denominator != 0.0) {
            float t_intersection = numerator / denominator;
            projectionMousePos = point + t_intersection * direction;
        } else {
            projectionMousePos.x = float.nan;
            projectionMousePos.y = float.nan;
        }
        impl.mousePos = projectionMousePos.xy;
        return projectionMousePos;
    }

    override 
    int peek(ImGuiIO* io, IncMeshEditorOne impl) {
        impl.lastMousePos = impl.mousePos;

        impl.mousePos = incInputGetMousePosition();
        if (impl.deformOnly) {
            /* impl.mousePos must be calculated as point C, but above code return point D.
             * calculate the intersection point of plane and line DC first, and then calculate position in mesh coordinate.
             * z      C (mesh plane)
             * ^     /|
             *      / |
             *     /  |
             *    /|  |
             *   / |  |
             * x/__|__|_______> y (Screen)
             *    B   D
             */

            vec4 pIn = vec4(calculateMousePosIntersection(impl, -impl.mousePos), 1);
            mat4 tr = impl.transform.inverse();
            vec4 pOut = tr * pIn;
            impl.mousePos = pOut.xy;
        } else {
            impl.mousePos = -impl.mousePos;
        }

        impl.vtxAtMouse = impl.getVertexFromPoint(impl.mousePos);

        return 0;
    }

    override 
    int unify(int[] actions) {
        return 0;
    }

    override 
    bool update(ImGuiIO* io, IncMeshEditorOne impl, int action, out bool changed) {
        return false;
    }

    override 
    bool onDragStart(vec2 mousePos, IncMeshEditorOne impl) {
        if (!impl.isSelecting) {
            isDragging = true;
            impl.getDeformAction();
            return true;
        }
        return false;
    }

    override 
    bool onDragEnd(vec2 mousePos, IncMeshEditorOne impl) {
        isDragging = false;
        if (impl.isSelecting) {
            if (impl.mutateSelection) {
                if (!impl.invertSelection) {
                    foreach(v; impl.newSelected) {
                        auto idx = impl.selected.countUntil(v);
                        if (idx == -1) impl.selected ~= v;
                    }
                } else {
                    foreach(v; impl.newSelected) {
                        auto idx = impl.selected.countUntil(v);
                        if (idx != -1) impl.selected = impl.selected.remove(idx);
                    }
                }
                impl.updateMirrorSelected();
                impl.newSelected.length = 0;
            } else {
                impl.selected = impl.newSelected;
                impl.newSelected = [];
                impl.updateMirrorSelected();
            }
            impl.isSelecting = false;
        }
        impl.pushDeformAction();
        return true;
    }

    override 
    bool onDragUpdate(vec2 mousePos, IncMeshEditorOne impl) {
        if (isDragging) {
            foreach(select; impl.selected) {
                impl.foreachMirror((uint axis) {
                    MeshVertex *v = impl.getVerticesByIndex([impl.mirrorVertex(axis, select)])[0];
                    if (v is null) return;
                    impl.updateAddVertexAction(v);
                    impl.markActionDirty();
                    v.position += impl.mirror(axis, mousePos - impl.lastMousePos);
                });
            }
            if (impl.selected.length > 0)
                impl.maybeSelectOne = ulong(-1);
            impl.refreshMesh();
            return true;
        }

        return false;
    }

    override
    void draw(Camera camera, IncMeshEditorOne impl) {
    }
}