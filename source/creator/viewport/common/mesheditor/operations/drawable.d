/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors:
    - Luna Nielsen
    - Asahi Lina
*/
module creator.viewport.common.mesheditor.operations.drawable;

import i18n;
import creator.viewport;
import creator.viewport.common;
import creator.viewport.common.mesh;
import creator.viewport.common.mesheditor.base;
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

class IncMeshEditorOneDrawable : IncMeshEditorOneImpl!Drawable {
protected:
    override
    void substituteMeshVertices(MeshVertex* meshVertex) {
        mesh.vertices ~= meshVertex;
    }
    IncMesh previewMesh;
    MeshEditorAction!DeformationAction editorAction = null;

public:
    IncMesh mesh;

    this(bool deformOnly) {
        super(deformOnly);
        this.deformOnly = deformOnly;
    }

    override
    void setTarget(Node target) {
        Drawable drawable = cast(Drawable)target;
        if (drawable is null)
            return;
        super.setTarget(target);
        transform = target ? target.transform.matrix : mat4.identity;
        mesh = new IncMesh(drawable.getMesh());
        refreshMesh();
    }

    ref IncMesh getMesh() {
        return mesh;
    }

    override
    void resetMesh() {
        mesh.reset();
    }

    override
    void refreshMesh() {
        mesh.refresh();
        if (previewingTriangulation()) {
            previewMesh = mesh.autoTriangulate();
        } else {
            previewMesh = null;
        }
        updateMirrorSelected();
    }

    override
    void importMesh(MeshData data) {
        mesh.import_(data);
        mesh.refresh();
    }

    override
    void applyOffsets(vec2[] offsets) {
        assert(deformOnly);

        mesh.applyOffsets(offsets);
    }

    override
    vec2[] getOffsets() {
        assert(deformOnly);

        return mesh.getOffsets();
    }

    override
    void applyToTarget() {
        // Apply the model
        auto action = new DrawableChangeAction(target.name, target);

        // Export mesh
        MeshData data = mesh.export_();
        data.fixWinding();

        // Fix UVs
        foreach(i; 0..data.uvs.length) {
            if (Part part = cast(Part)target) {

                // Texture 0 is always albedo texture
                auto tex = part.textures[0];

                // By dividing by width and height we should get the values in UV coordinate space.
                data.uvs[i].x /= cast(float)tex.width;
                data.uvs[i].y /= cast(float)tex.height;
                data.uvs[i] += vec2(0.5, 0.5);
            }
        }

        if (data.vertices.length != target.vertices.length)
            vertexMapDirty = true;

        if (vertexMapDirty) {
            void alterDeform(ParameterBinding binding) {
                auto deformBinding = cast(DeformationParameterBinding)binding;
                if (!deformBinding)
                    return;
                foreach (uint x; 0..cast(uint)deformBinding.values.length) {
                    foreach (uint y; 0..cast(uint)deformBinding.values[x].length) {
                        auto deform = deformBinding.values[x][y];
                        if (deformBinding.isSet(vec2u(x, y))) {
                            auto newDeform = mesh.deformByDeformationBinding(deformBinding, vec2u(x, y), false);
                            if (newDeform) 
                                deformBinding.values[x][y] = *newDeform;
                        }
                    }
                }
                deformBinding.reInterpolate();
            }

            foreach (param; incActivePuppet().parameters) {
                if (auto group = cast(ExParameterGroup)param) {
                    foreach(x, ref xparam; group.children) {
                        ParameterBinding binding = xparam.getBinding(target, "deform");
                        if (binding)
                            action.addAction(new ParameterChangeBindingsAction("Deformation recalculation on mesh update", xparam, null));
                        alterDeform(binding);
                    }
                } else {
                    ParameterBinding binding = param.getBinding(target, "deform");
                    if (binding)
                        action.addAction(new ParameterChangeBindingsAction("Deformation recalculation on mesh update", param, null));
                    alterDeform(binding);
                }
            }
            vertexMapDirty = false;
        }

        target.rebuffer(data);

        action.updateNewState();
        incActionPush(action);
    }

    override
    void applyPreview() {
        mesh = previewMesh;
        previewMesh = null;
        previewTriangulate = false;
    }

    override
    void pushDeformAction() {
        if (editorAction && editorAction.action.dirty) {
            editorAction.updateNewState();
            incActionPush(editorAction);
            editorAction = null;
        }        
    }

    override
    MeshVertex* getVertexFromPoint(vec2 mousePos) {
        return mesh.getVertexFromPoint(mousePos);
    }

    override
    void removeVertexAt(vec2 vertex) {
        mesh.removeVertexAt(vertex);
    }

    override
    bool removeVertex(ImGuiIO* io, bool selectedOnly) {
        // In the case that it is, double clicking would remove an item
        if (!selectedOnly || isSelected(vtxAtMouse)) {
            foreachMirror((uint axis) {
                removeVertexAt(mirror(axis, mousePos));
            });
            refreshMesh();
            vertexMapDirty = true;
            selected.length = 0;
            updateMirrorSelected();
            maybeSelectOne = null;
            vtxAtMouse = null;
            return true;
        }
        return false;
    }

    override
    bool addVertex(ImGuiIO* io) {
        ulong off = mesh.vertices.length;
        if (isOnMirror(mousePos, meshEditAOE)) {
            placeOnMirror(mousePos, meshEditAOE);
        } else {
            foreachMirror((uint axis) {
                substituteMeshVertices(new MeshVertex(mirror(axis, mousePos)));
            });
        }
        refreshMesh();
        vertexMapDirty = true;
        if (io.KeyCtrl) selectOne(mesh.vertices[$-1]);
        else selectOne(mesh.vertices[off]);
        return true;
    }

    override
    bool updateChanged(bool changed) {
        if (changed)
            mesh.changed = true;

        if (mesh.changed) {
            if (previewingTriangulation())
                previewMesh = mesh.autoTriangulate();
            mesh.changed = false;
        }
        return changed;
    }

    override
    void removeMeshVertex(MeshVertex* v2) {
        mesh.remove(v2);
    }

    override
    bool isPointOver(vec2 mousePos) {
        return mesh.isPointOverVertex(mousePos);
    }

    override
    MeshVertex*[] getInRect(vec2 min, vec2 max) { 
        return mesh.getInRect(selectOrigin, mousePos);
    }

    override
    void createPathTarget() {
        path.createTarget(mesh, mat4.identity); //transform.inverse() * target.transform.matrix);
    }

    override
    mat4 updatePathTarget() {
        return path.updateTarget(mesh);
    }

    override
    void resetPathTarget() {
        path.resetTarget(mesh);
    }

    override
    void remapPathTarget(ref CatmullSpline p, mat4 trans) {
        p.remapTarget(mesh);
    }

    override
    bool hasAction() { return editorAction !is null; }

    override
    void updateAddVertexAction(MeshVertex* vertex) {
        if (editorAction) {
            editorAction.action.addVertex(vertex);
        }
    }

    override
    void clearAction() {
        if (editorAction)
            editorAction.action.clear();
    }

    override
    void markActionDirty() {
        if (editorAction)
            editorAction.action.markAsDirty();
    }

    Action getDeformActionImpl(bool reset = false)() {
        if (reset)
            pushDeformAction();
        if (editorAction is null || !editorAction.action.isApplyable()) {
            auto deformAction = new DeformationAction(target.name, target);
            switch (toolMode) {
            case VertexToolMode.PathDeform:
                editorAction = new MeshEditorPathDeformAction!DeformationAction(target, deformAction);
                break;
            default:
                editorAction = new MeshEditorAction!DeformationAction(target, deformAction);
            }

        } else {
            if (reset)
                editorAction.clear();
        }
        return editorAction;
    }

    override
    Action getDeformAction() {
        return getDeformActionImpl!false();
    }

    override
    Action getCleanDeformAction() {
        return getDeformActionImpl!true();
    }

    override
    void forceResetAction() {
        editorAction = null;
    }

    override
    void draw(Camera camera) {
        mat4 trans = mat4.identity;
        if (deformOnly) trans = target.transform.matrix();

        if (vtxAtMouse !is null && !isSelecting) {
            MeshVertex*[] one = [vtxAtMouse];
            mesh.drawPointSubset(one, vec4(1, 1, 1, 0.3), trans, 15);
        }

        if (previewMesh) {
            previewMesh.drawLines(trans, vec4(0.7, 0.7, 0, 1));
            mesh.drawPoints(trans);
        } else {
            mesh.draw(trans);
        }

        if (selected.length) {
            if (isSelecting && !mutateSelection)
                mesh.drawPointSubset(selected, vec4(0.6, 0, 0, 1), trans);
            else
                mesh.drawPointSubset(selected, vec4(1, 0, 0, 1), trans);
        }

        if (mirrorSelected.length)
            mesh.drawPointSubset(mirrorSelected, vec4(1, 0, 1, 1), trans);

        if (isSelecting) {
            vec3[] rectLines = incCreateRectBuffer(selectOrigin, mousePos);
            inDbgSetBuffer(rectLines);
            if (!mutateSelection) inDbgDrawLines(vec4(1, 0, 0, 1), trans);
            else if(invertSelection) inDbgDrawLines(vec4(0, 1, 1, 0.8), trans);
            else inDbgDrawLines(vec4(0, 1, 0, 0.8), trans);

            if (newSelected.length) {
                if (mutateSelection && invertSelection)
                    mesh.drawPointSubset(newSelected, vec4(1, 0, 1, 1), trans);
                else
                    mesh.drawPointSubset(newSelected, vec4(1, 0, 0, 1), trans);
            }
        }

        vec2 camSize = camera.getRealSize();
        vec2 camPosition = camera.position;
        vec3[] axisLines;
        if (mirrorHoriz) {
            axisLines ~= incCreateLineBuffer(
                vec2(mirrorOrigin.x, -camSize.y - camPosition.y),
                vec2(mirrorOrigin.x, camSize.y - camPosition.y)
            );
        }
        if (mirrorVert) {
            axisLines ~= incCreateLineBuffer(
                vec2(-camSize.x - camPosition.x, mirrorOrigin.y),
                vec2(camSize.x - camPosition.x, mirrorOrigin.y)
            );
        }

        if (axisLines.length > 0) {
            inDbgSetBuffer(axisLines);
            inDbgDrawLines(vec4(0.8, 0, 0.8, 1), trans);
        }

        if (path && path.target && deforming) {
            path.draw(transform, vec4(0, 0.6, 0.6, 1));
            path.target.draw(transform, vec4(0, 1, 0, 1));
        } else if (path) {
            if (path.target) path.target.draw(transform, vec4(0, 0.6, 0, 1));
            path.draw(transform, vec4(0, 1, 1, 1));
        }
    }

    override
    void adjustPathTransform() {
        mat4 trans = (target? target.transform.matrix: transform).inverse * transform;
        ref CatmullSpline doAdjust(ref CatmullSpline p) {
            for (int i; i < p.points.length; i++) {
                p.points[i].position = (trans * vec4(p.points[i].position, 0, 1)).xy;
            }
            p.update();
            remapPathTarget(p, mat4.identity);
            return p;
        }
        if (path) {
            if (path.target)
                path.target = doAdjust(path.target);
            path = doAdjust(path);
        }
        lastMousePos = (trans * vec4(lastMousePos, 0, 1)).xy;
        transform = this.target.transform.matrix;
        forceResetAction();
    }

}