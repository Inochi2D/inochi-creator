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
import creator.viewport.common.mesheditor.tools.enums;
import creator.viewport.common.mesheditor.operations;
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
public:
    IncMesh mesh;

    this(bool deformOnly) {
        super(deformOnly);
    }

    ref IncMesh getMesh() {
        return mesh;
    }

    void setMesh(IncMesh mesh) {
        this.mesh = mesh;
    }
}

/**
 * MeshEditor of Drawable for vertex operation.
 */
class IncMeshEditorOneDrawableVertex : IncMeshEditorOneDrawable {
protected:
    override
    void substituteMeshVertices(MeshVertex* meshVertex) {
        mesh.vertices ~= meshVertex;
    }
    IncMesh previewMesh;
    MeshEditorAction!DeformationAction editorAction = null;

public:
    this() {
        super(false);
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
    void importMesh(ref MeshData data) {
        mesh.import_(data);
        mesh.refresh();
    }

    override
    void applyOffsets(vec2[] offsets) {
    }

    override
    vec2[] getOffsets() {
        return null;
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

        DeformationParameterBinding[] deformers;

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
                    } else {
                        deformBinding.values[x][y].vertexOffsets.length = data.vertices.length;
                    }
                    deformers ~= deformBinding;
                }
            }
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
        incActivePuppet().resetDrivers();
        vertexMapDirty = false;

        if (auto mgroup = cast(MeshGroup)target) {
            mgroup.clearCache();
        }
        target.rebuffer(data);

        // reInterpolate MUST be called after rebuffer is called.
        foreach (deformBinding; deformers) {
            deformBinding.reInterpolate();
        }

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
    ulong getVertexFromPoint(vec2 mousePos) {
        return mesh.getVertexFromPoint(mousePos);
    }

    override
    float[] getVerticesInBrush(vec2 mousePos, float radius) {
        return mesh.getVerticesInBrush(mousePos, radius);
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
            maybeSelectOne = ulong(-1);
            vtxAtMouse = ulong(-1);
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
        if (io.KeyCtrl) selectOne(mesh.vertices.length - 1);
        else selectOne(off);
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
    ulong[] getInRect(vec2 min, vec2 max) { 
        return mesh.getInRect(selectOrigin, mousePos);
    }
    override 
    MeshVertex*[] getVerticesByIndex(ulong[] indices, bool removeNull = false) {
        MeshVertex*[] result;
        foreach (idx; indices) {
            if (idx < mesh.vertices.length)
                result ~= mesh.vertices[idx];
            else if (!removeNull)
                result ~= null;
        }
        return result;
    }

    override
    void createPathTarget() {
        getPath().createTarget(mesh, mat4.identity); //transform.inverse() * target.transform.matrix);
    }

    override
    mat4 updatePathTarget() {
        return getPath().updateTarget(mesh, selected);
    }

    override
    void resetPathTarget() {
        getPath().resetTarget(mesh);
    }

    override
    void remapPathTarget(ref CatmullSpline p, mat4 trans) {
        p.remapTarget(mesh, mat4.identity);
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
            editorAction = tools[toolMode].editorAction(target, deformAction);

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

        if (vtxAtMouse != ulong(-1) && !isSelecting) {
            MeshVertex*[] one = getVerticesByIndex([vtxAtMouse], true);
            mesh.drawPointSubset(one, vec4(1, 1, 1, 0.3), trans, 15);
        }

        if (previewMesh) {
            previewMesh.drawLines(trans, vec4(0.7, 0.7, 0, 1));
            mesh.drawPoints(trans);
        } else {
            mesh.draw(trans);
        }

        if (selected.length) {
            if (isSelecting && !mutateSelection) {
                auto selectedVertices = getVerticesByIndex(selected, true);
                mesh.drawPointSubset(selectedVertices, vec4(0.6, 0, 0, 1), trans);
            }
            else {
                auto selectedVertices = getVerticesByIndex(selected, true);
                mesh.drawPointSubset(selectedVertices, vec4(1, 0, 0, 1), trans);
            }
        }

        if (mirrorSelected.length) {
            auto mirroredVertices = getVerticesByIndex(mirrorSelected, true);
            mesh.drawPointSubset(mirroredVertices, vec4(1, 0, 1, 1), trans);
        }

        if (isSelecting) {
            vec3[] rectLines = incCreateRectBuffer(selectOrigin, mousePos);
            inDbgSetBuffer(rectLines);
            if (!mutateSelection) inDbgDrawLines(vec4(1, 0, 0, 1), trans);
            else if(invertSelection) inDbgDrawLines(vec4(0, 1, 1, 0.8), trans);
            else inDbgDrawLines(vec4(0, 1, 0, 0.8), trans);

            if (newSelected.length) {
                if (mutateSelection && invertSelection) {
                    auto newSelectedVertices = getVerticesByIndex(newSelected, true);
                    mesh.drawPointSubset(newSelectedVertices, vec4(1, 0, 1, 1), trans);
                }
                else {
                    auto newSelectedVertices = getVerticesByIndex(newSelected, true);
                    mesh.drawPointSubset(newSelectedVertices, vec4(1, 0, 0, 1), trans);
                }
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

        if (toolMode in tools)
            tools[toolMode].draw(camera, this);
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
        if (getPath()) {
            if (getPath().target)
                getPath().target = doAdjust(getPath().target);
            auto path = getPath();
            setPath(doAdjust(path));
        }
        lastMousePos = (trans * vec4(lastMousePos, 0, 1)).xy;
        transform = this.target.transform.matrix;
        forceResetAction();
    }

}


/**
 * MeshEditor of Drawable for deformation operation.
 */
class IncMeshEditorOneDrawableDeform : IncMeshEditorOneDrawable {
protected:
    override
    void substituteMeshVertices(MeshVertex* meshVertex) {
    }
    MeshEditorAction!DeformationAction editorAction = null;
    void updateTarget() {
        auto drawable = cast(Drawable)target;
        transform = drawable.getDynamicMatrix();
        vertices.length = drawable.vertices.length;
        foreach (i, vert; drawable.vertices) {
            vertices[i] = drawable.vertices[i] + drawable.deformation[i]; // FIXME: should handle origin
        }
    }

    void importDeformation() {
        Drawable drawable = cast(Drawable)target;
        if (drawable is null)
            return;
        deformation = drawable.deformation.dup;
        auto param = incArmedParameter();
        auto binding = cast(DeformationParameterBinding)(param? param.getBinding(drawable, "deform"): null);
        if (binding is null) {
            deformation = drawable.deformation.dup;
            
        } else {
            auto deform = binding.getValue(param.findClosestKeypoint());
            if (drawable.deformation.length == deform.vertexOffsets.length) {
                deformation.length = drawable.deformation.length;
                foreach (i, d; drawable.deformation) {
                    deformation[i] = d - deform.vertexOffsets[i];
                }
            }
        }
            
    }

public:
    vec2[] deformation;
    vec2[] vertices;

    this() {
        super(true);
    }

    override
    void setTarget(Node target) {
        Drawable drawable = cast(Drawable)target;
        if (drawable is null)
            return;
        importDeformation();
        super.setTarget(target);
        updateTarget();
        mesh = new IncMesh(drawable.getMesh());
        refreshMesh();
    }

    override
    void resetMesh() {
        mesh.reset();
    }

    override
    void refreshMesh() {
        mesh.refresh();
        updateMirrorSelected();
    }

    override
    void importMesh(ref MeshData data) {
        mesh.import_(data);
        mesh.refresh();
    }

    override
    void applyOffsets(vec2[] offsets) {
        mesh.applyOffsets(offsets);
    }

    override
    vec2[] getOffsets() {
        return mesh.getOffsets();
    }

    override
    void applyToTarget() { }

    override
    void applyPreview() { }                      

    override
    void pushDeformAction() {
        if (editorAction && editorAction.action.dirty) {
            editorAction.updateNewState();
            incActionPush(editorAction);
            editorAction = null;
        }        
    }

    override
    ulong getVertexFromPoint(vec2 mousePos) {
        // return vertices position from mousePos
        foreach(i, ref vert; vertices) {
            if (abs(vert.distance(mousePos)) < mesh.selectRadius/incViewportZoom) {
                return i;
            }
        }
        return -1;
    }

    override
    float[] getVerticesInBrush(vec2 mousePos, float radius) {
        float[] indices;
        foreach(idx, ref vert; vertices) {
            float distance = 1 - abs(vert.distance(mousePos)) / radius;
            indices ~= max(distance, 0);
        }
        return indices;
    }

    override
    void removeVertexAt(vec2 vertex) { }

    override
    bool removeVertex(ImGuiIO* io, bool selectedOnly) { return false; }

    override
    bool addVertex(ImGuiIO* io) { return false; }

    override
    bool updateChanged(bool changed) { return changed; }

    override
    void removeMeshVertex(MeshVertex* v2) { }

    override
    bool isPointOver(vec2 mousePos) {
        foreach(vert; vertices) {
            if (abs(vert.distance(mousePos)) < mesh.selectRadius/incViewportZoom) return true;
        }
        return false;
    }

    override
    ulong[] getInRect(vec2 min, vec2 max) {
        if (min.x > max.x) swap(min.x, max.x);
        if (min.y > max.y) swap(min.y, max.y);

        ulong[] matching;
        foreach(idx, vertex; vertices) {
            if (min.x > vertex.x) continue;
            if (min.y > vertex.y) continue;
            if (max.x < vertex.x) continue;
            if (max.y < vertex.y) continue;
            matching ~= idx;
        }

        return matching;        
    }

    override 
    MeshVertex*[] getVerticesByIndex(ulong[] indices, bool removeNull = false) {
        MeshVertex*[] result;
        foreach (idx; indices) {
            if (idx < mesh.vertices.length)
                result ~= mesh.vertices[idx];
            else if (!removeNull)
                result ~= null;
        }
        return result;
    }

    override
    void createPathTarget() {
        getPath().createTarget(mesh, mat4.identity, vertices); //transform.inverse() * target.transform.matrix);
    }

    override
    mat4 updatePathTarget() {
        return getPath().updateTarget(mesh, selected, mat4.identity(), deformation);
    }

    override
    void resetPathTarget() {
        getPath().resetTarget(mesh);
    }

    override
    void remapPathTarget(ref CatmullSpline p, mat4 trans) {
        p.remapTarget(mesh, trans, vertices); //mat4.identity);
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
            editorAction = tools[toolMode].editorAction(target, deformAction);

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
        auto drawable = cast(Drawable)target;
        updateTarget();
        auto trans = transform;

        MeshVertex*[] _getVerticesByIndex(ulong[] indices) {
            MeshVertex*[] result;
            foreach (idx; indices) {
                if (idx < vertices.length)
                    result ~= new MeshVertex(vertices[idx]);
            }
            return result;
        }

        drawable.drawMeshLines();
        vec3[] points;
        points.length = vertices.length;
        foreach (i; 0..vertices.length) {
            points[i] = vec3(vertices[i], 0);
        }
        if (points.length > 0) {
            inDbgSetBuffer(points);
            inDbgPointsSize(10);
            inDbgDrawPoints(vec4(0, 0, 0, 1), trans);
            inDbgPointsSize(6);
            inDbgDrawPoints(vec4(1, 1, 1, 1), trans);
        }

        if (vtxAtMouse != ulong(-1) && !isSelecting) {
            MeshVertex*[] one = _getVerticesByIndex([vtxAtMouse]);
            mesh.drawPointSubset(one, vec4(1, 1, 1, 0.3), trans, 15);
        }

        if (selected.length) {
            if (isSelecting && !mutateSelection) {
                auto selectedVertices = _getVerticesByIndex(selected);
                mesh.drawPointSubset(selectedVertices, vec4(0.6, 0, 0, 1), trans);
            }
            else {
                auto selectedVertices = _getVerticesByIndex(selected);
                mesh.drawPointSubset(selectedVertices, vec4(1, 0, 0, 1), trans);
            }
        }

        if (mirrorSelected.length) {
            auto mirrorSelectedVertices = _getVerticesByIndex(mirrorSelected);
            mesh.drawPointSubset(mirrorSelectedVertices, vec4(1, 0, 1, 1), trans);
        }

        if (isSelecting) {
            vec3[] rectLines = incCreateRectBuffer(selectOrigin, mousePos);
            inDbgSetBuffer(rectLines);
            if (!mutateSelection) inDbgDrawLines(vec4(1, 0, 0, 1), trans);
            else if(invertSelection) inDbgDrawLines(vec4(0, 1, 1, 0.8), trans);
            else inDbgDrawLines(vec4(0, 1, 0, 0.8), trans);

            if (newSelected.length) {
                auto newSelectedVertices = _getVerticesByIndex(newSelected);
                if (mutateSelection && invertSelection)
                    mesh.drawPointSubset(newSelectedVertices, vec4(1, 0, 1, 1), trans);
                else
                    mesh.drawPointSubset(newSelectedVertices, vec4(1, 0, 0, 1), trans);
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

        if (toolMode in tools)
            tools[toolMode].draw(camera, this);
    }

    override
    void adjustPathTransform() {
        auto drawable = cast(Drawable)target;

        mat4 trans = (target? drawable.getDynamicMatrix(): transform).inverse * transform;
        importDeformation();
        ref CatmullSpline doAdjust(ref CatmullSpline p) {
            p.update();

            remapPathTarget(p, trans);
            return p;
        }
        if (getPath()) {
            if (getPath().target)
                getPath().target = doAdjust(getPath().target);
            auto path = getPath();
            setPath(doAdjust(path));
        }
        lastMousePos = (trans * vec4(lastMousePos, 0, 1)).xy;
        updateTarget();

        forceResetAction();
    }

}