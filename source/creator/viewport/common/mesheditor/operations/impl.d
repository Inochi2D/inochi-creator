module creator.viewport.common.mesheditor.operations.impl;

import creator.viewport.common.mesheditor.tools;
import creator.viewport.common.mesheditor.operations.base;
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


class IncMeshEditorOneImpl(T) : IncMeshEditorOne {
protected:
    T target;

    Tool[VertexToolMode] tools;

public:
    this(bool deformOnly) {
        super(deformOnly);
        ToolInfo[] infoList = incGetToolInfo();
        foreach (info; infoList) {
            tools[info.mode()] = info.newTool();
        }
    }

    override
    Node getTarget() {
        return target;
    }

    override
    void setTarget(Node target) {
        this.target = cast(T)(target);
    }

    override
    CatmullSpline getPath() {
        auto pathTool = cast(PathDeformTool)(tools[VertexToolMode.PathDeform]);
        return pathTool.path;
    }

    override
    void setPath(CatmullSpline path) {
        auto pathTool = cast(PathDeformTool)(tools[VertexToolMode.PathDeform]);
        pathTool.setPath(path);
    }

    override int peek(ImGuiIO* io, Camera camera) {
        if (toolMode in tools) {
            return tools[toolMode].peek(io, this);
        }
        assert(0);
    }

    override int unify(int[] actions) {
        if (toolMode in tools) {
            return tools[toolMode].unify(actions);
        }
        assert(0);
    }

    override
    bool update(ImGuiIO* io, Camera camera, int actions) {
        bool changed = false;
        if (toolMode in tools) {
            tools[toolMode].update(io, this, actions, changed);
        } else {
            assert(0);
        }

        if (isSelecting) {
            newSelected = getInRect(selectOrigin, mousePos);
            mutateSelection = io.KeyShift;
            invertSelection = io.KeyCtrl;
        }

        return updateChanged(changed);
    }

    override
    void setToolMode(VertexToolMode toolMode) {
        if (toolMode in tools) {
            this.toolMode = toolMode;
            tools[toolMode].setToolMode(toolMode, this);
        }
    }

    override
    Tool getTool() { return tools[toolMode]; }

}