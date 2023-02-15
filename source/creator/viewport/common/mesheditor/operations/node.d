/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors:
    - Luna Nielsen
    - Asahi Lina
*/
module creator.viewport.common.mesheditor.operations.node;

import i18n;
import creator.viewport;
import creator.viewport.common;
import creator.viewport.common.mesh;
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

class IncMeshEditorOneNode : IncMeshEditorOneImpl!Node {
protected:
    override
    void substituteMeshVertices(MeshVertex* meshVertex) {
        translation = meshVertex.position;
        target.setValue("transform.t.x", translation.x);
        target.setValue("transform.t.y", translation.y);
    }
private:
    vec2 translation;
    MeshEditorAction!GroupAction editorAction;
public:
    float selectRadius = 16f;
    this(bool deformOnly) {
        super(deformOnly);
        this.deformOnly = deformOnly;
    }

    override
    void setTarget(Node target) {
        super.setTarget(target);
        transform = target? target.transform.matrix : mat4.identity;
        refreshMesh();
    }

    override
    void resetMesh() {
        translation = vec2(target.getValue("transform.t.x"), target.getValue("transform.t.y"));
    }

    override
    void refreshMesh() {
        translation = vec2(target.getValue("transform.t.x"), target.getValue("transform.t.y"));
    }

    override void importMesh(ref MeshData data) {}

    override
    void applyOffsets(vec2[] offsets) {
        assert(deformOnly);
        translation = offsets[0];
    }

    override
    vec2[] getOffsets() {
        assert(deformOnly);
        return [translation];
    }

    override
    void applyToTarget() {
        auto action = new GroupAction();

        if (vertexMapDirty) {
            void alterDeform(ParameterBinding binding, float value) {
                auto deformBinding = cast(ValueParameterBinding)binding;
                if (!deformBinding)
                    return;
                foreach (uint x; 0..cast(uint)deformBinding.values.length) {
                    foreach (uint y; 0..cast(uint)deformBinding.values[x].length) {
                        auto deform = deformBinding.values[x][y];
                        if (deformBinding.isSet(vec2u(x, y))) {
                            deformBinding.values[x][y] = value;
                        }
                    }
                }
                deformBinding.reInterpolate();
            }

            foreach (param; incActivePuppet().parameters) {
                if (auto group = cast(ExParameterGroup)param) {
                    foreach(x, ref xparam; group.children) {
                        ParameterBinding binding = xparam.getBinding(target, "transform.t.x");
                        if (binding)
                            action.addAction(new ParameterChangeBindingsAction("Deformation of translation", xparam, null));
                        alterDeform(binding, translation.x);
                        binding = xparam.getBinding(target, "transform.t.y");
                        if (binding)
                            action.addAction(new ParameterChangeBindingsAction("Deformation of translation", xparam, null));
                        alterDeform(binding, translation.y);
                    }
                } else {
                    ParameterBinding binding = param.getBinding(target, "transform.t.x");
                    if (binding)
                        action.addAction(new ParameterChangeBindingsAction("Deformation of translation", param, null));
                    alterDeform(binding, translation.x);
                    binding = param.getBinding(target, "transform.t.y");
                    if (binding)
                        action.addAction(new ParameterChangeBindingsAction("Deformation of translation", param, null));
                    alterDeform(binding, translation.y);
                }
            }
            vertexMapDirty = false;
        }
        incActionPush(action);
    }

    override void applyPreview() { }

    Action getDeformActionImpl(bool reset = false)() {
        auto armedParam = incArmedParameter();
        vec2u index = armedParam.findClosestKeypoint();

        void registerBinding(string name, GroupAction groupAction) {
            ValueParameterBinding binding = cast(ValueParameterBinding)armedParam.getBinding(target, name);
            if (binding is null) {
                binding = cast(ValueParameterBinding)armedParam.createBinding(target, name);
                armedParam.addBinding(binding);
                groupAction.addAction(new ParameterBindingAddAction(armedParam, binding));

            }
            auto transAction = new ParameterBindingValueChangeAction!float(binding.getName(), binding, index.x, index.y);
            groupAction.addAction(transAction);
        }

        if (reset)
            pushDeformAction();
        if (editorAction is null) {
            GroupAction groupAction = new GroupAction();
            registerBinding("transform.t.x", groupAction);
            registerBinding("transform.t.y", groupAction);
            registerBinding("transform.r.z", groupAction);
            switch (toolMode) {
            case VertexToolMode.PathDeform:
                editorAction = new MeshEditorPathDeformAction!GroupAction(target, groupAction);
                break;
            default:
                editorAction = new MeshEditorAction!GroupAction(target, groupAction);
            }
        } else {
            if (reset) {
                editorAction.clear();
                editorAction.action.actions.length = 0;
                registerBinding("transform.t.x", editorAction.action);
                registerBinding("transform.t.y", editorAction.action);
                registerBinding("transform.r.z", editorAction.action);
            }
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
    void pushDeformAction() {
        if (editorAction !is null) {
            bool dirty = false;
            foreach (action; editorAction.action.actions) {
                auto changeAction = cast(ParameterBindingValueChangeAction!float)action;
                if (changeAction !is null) {
                    dirty = dirty || changeAction.dirty();
                    if (dirty)
                        break;
                }
            }
            if (dirty) {
                writefln("push: %s", target.name);
                editorAction.updateNewState();
                foreach (a; editorAction.action.actions) {
                    if (auto laction = cast(LazyBoundAction)a)
                        laction.updateNewState();
                }
                incActionPush(editorAction);
                editorAction = null;
            }
        }
    }

    override
    MeshVertex* getVertexFromPoint(vec2 mousePos) {
        if (abs(translation.distance(mousePos)) < selectRadius/incViewportZoom) return new MeshVertex(translation, []);
        return null;
    }

    override void removeVertexAt(vec2 vertex) {}
    override bool removeVertex(ImGuiIO* io, bool selectedOnly) { return false; }
    override bool addVertex(ImGuiIO* io) { return false; }
    override bool updateChanged(bool changed) { return changed; }
    override void removeMeshVertex(MeshVertex* v2) {}

    override
    bool isPointOver(vec2 mousePos) {
        if (abs(translation.distance(mousePos)) < selectRadius/incViewportZoom) return true;
        return false;
    }

    override
    MeshVertex*[] getInRect(vec2 min, vec2 max) { 
        if (min.x > max.x) swap(min.x, max.x);
        if (min.y > max.y) swap(min.y, max.y);

        if (min.x > translation.x) return [];
        if (min.y > translation.y) return [];
        if (max.x < translation.x) return [];
        if (max.y < translation.y) return [];
        return [new MeshVertex(translation)];
    }

    override
    void createPathTarget() {
        getPath().createTarget(target, mat4.identity);
    }

    override
    mat4 updatePathTarget() {
        return getPath().updateTarget(target);
    }

    override
    void resetPathTarget() {
        getPath().resetTarget(target);
    }

    override
    void remapPathTarget(ref CatmullSpline p, mat4 trans) {
        p.remapTarget(target, trans);
    }

    override
    bool hasAction() { return editorAction !is null; }

    override
    void updateAddVertexAction(MeshVertex* vertex) {
    }

    override
    void clearAction() {
        if (editorAction) {
            foreach (action; editorAction.action.actions) {
                auto changeAction = cast(ParameterBindingValueChangeAction!float)action;
                if (changeAction)
                    changeAction.clear();
            }

        }
    }

    override
    void markActionDirty() {
        foreach (action; editorAction.action.actions) {
            auto changeAction = cast(ParameterBindingValueChangeAction!float)action;
            if (changeAction)
                changeAction.markAsDirty();
        }
    }

    override
    void draw(Camera camera) {

        if (vtxAtMouse !is null && !isSelecting) {
            MeshVertex*[] one = [vtxAtMouse];
        }

        if (isSelecting) {
            vec3[] rectLines = incCreateRectBuffer(selectOrigin, mousePos);
            inDbgSetBuffer(rectLines);
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
