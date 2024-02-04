module creator.viewport.common.mesheditor.tools.base;

import i18n;
import creator.viewport;
import creator.viewport.common;
import creator.viewport.common.mesh;
import creator.viewport.common.mesheditor.tools.enums;
import creator.viewport.common.mesheditor.operations;
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
import std.string: toStringz;

interface Tool {
    int peek(ImGuiIO* io, IncMeshEditorOne impl);
    int unify(int[] actions);
    bool update(ImGuiIO* io, IncMeshEditorOne impl, int action, out bool changed);
    void setToolMode(VertexToolMode toolMode, IncMeshEditorOne impl);
    void draw(Camera camera, IncMeshEditorOne impl);
}


interface Draggable {
    bool onDragStart(vec2 mousePos, IncMeshEditorOne impl);
    bool onDragUpdate(vec2 mousePos, IncMeshEditorOne impl);
    bool onDragEnd(vec2 mousePos, IncMeshEditorOne impl);
}


interface ToolInfo {
    bool viewportTools(bool deformOnly, VertexToolMode toolMode, IncMeshEditorOne[Node] editors);
    bool displayToolOptions(bool deformOnly, VertexToolMode toolMode, IncMeshEditorOne[Node] editors);
    string icon();
    string description();
    VertexToolMode mode();
    Tool newTool();
}

class ToolInfoBase(T) : ToolInfo {
    override
    bool viewportTools(bool deformOnly, VertexToolMode toolMode, IncMeshEditorOne[Node] editors) {
        bool result = false;
        if (incButtonColored(icon.toStringz, ImVec2(0, 0), toolMode == mode ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
            result = true;
            foreach (e; editors) {
                e.setToolMode(toolMode);
                e.viewportTools(mode);
            }
        }
        incTooltip(description);
        return result;
    }
    override
    bool displayToolOptions(bool deformOnly, VertexToolMode toolMode, IncMeshEditorOne[Node] editors) { 
        return false;
    }
    abstract VertexToolMode mode();
    abstract string icon();
    abstract string description();
    override
    Tool newTool() { return new T; }
}
