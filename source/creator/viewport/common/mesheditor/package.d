module creator.viewport.common.mesheditor;

/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors:
    - Luna Nielsen
    - Asahi Lina
*/
import i18n;
import creator.viewport;
public import creator.viewport.common.mesheditor.operations;
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


class IncMeshEditor {
private:
    IncMeshEditorOne[Node] editors;
    bool previewTriangulate = false;
    bool mirrorHoriz = false;
    bool mirrorVert = false;
    VertexToolMode toolMode = VertexToolMode.Points;

public:
    bool deformOnly;

    this(bool deformOnly) {
        this.deformOnly = deformOnly;
    }

    void setTarget(Node target) {
        if (target is null) {
        } else {
            addTarget(target);
        }
    }

    IncMeshEditorOne getEditorFor(Node drawing) {
        if (drawing in editors)
            return editors[drawing];
        return null;
    }

    void addTarget(Node target) {
        if (target in editors)
            return;
        IncMeshEditorOneDrawable subEditor = new IncMeshEditorOneDrawable(deformOnly);
        subEditor.setTarget(target);
        subEditor.mirrorHoriz = mirrorHoriz;
        subEditor.mirrorVert  = mirrorVert;
        subEditor.previewTriangulate = previewTriangulate;
        editors[target] = subEditor;
    }

    void setTargets(Node[] targets) {
        IncMeshEditorOne[Node] newEditors;
        foreach (t; targets) {
            if (t in editors) {
                newEditors[t] = editors[t];
            } else {
                Drawable drawable = cast(Drawable)t;
                IncMeshEditorOne subEditor = null;
                if (drawable) {
                    subEditor = new IncMeshEditorOneDrawable(deformOnly);
                    (cast(IncMeshEditorOneDrawable)subEditor).setTarget(drawable);
                } else {
                    subEditor = new IncMeshEditorOneNode(deformOnly);
                    (cast(IncMeshEditorOneNode)subEditor).setTarget(t);
                }
                subEditor.mirrorHoriz = mirrorHoriz;
                subEditor.mirrorVert  = mirrorVert;
                subEditor.previewTriangulate = previewTriangulate;
                newEditors[t] = subEditor;
            }
        }
        editors = newEditors;
    }

    void removeTarget(Node target) {
        if (target in editors)
            editors.remove(target);
    }

    Node[] getTargets() {
        return editors.keys();
    }

    void refreshMesh() {
        foreach (drawing, editor; editors) {
            editor.refreshMesh();
        }
    }

    void resetMesh() {
        foreach (drawing, editor; editors) {
            editor.resetMesh();
        }
    }

    void applyPreview() {
        foreach (drawing, editor; editors) {
            editor.applyPreview();
        }
    }

    void applyToTarget() {
        foreach (drawing, editor; editors) {
            editor.applyToTarget();
        }
    }

    bool update(ImGuiIO* io, Camera camera) {
        bool result = false;
        incActionPushGroup();
        int[] actions;
        foreach (drawing, editor; editors) {
            actions ~= editor.peek(io, camera);
        }
        int action = 0;
        if (editors.keys().length > 0)
            action = editors[editors.keys()[0]].unify(actions);
        foreach (drawing, editor; editors) {
            result = editor.update(io, camera, action) || result;
        }
        incActionPopGroup();
        return result;
    }


    void draw(Camera camera) {
        foreach (drawing, editor; editors) {
            editor.draw(camera);
        }
    }

    void setToolMode(VertexToolMode toolMode) {
        this.toolMode = toolMode;
        foreach (drawing, editor; editors) {
            editor.setToolMode(toolMode);
        }
    }

    VertexToolMode getToolMode() {
        return toolMode;
    }

    void viewportTools() {
        igSetWindowFontScale(1.30);
            igPushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(1, 1));
            igPushStyleVar(ImGuiStyleVar.FramePadding, ImVec2(8, 10));
                if (incButtonColored("", ImVec2(0, 0), getToolMode() == VertexToolMode.Points ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
                    setToolMode(VertexToolMode.Points);
                    foreach (e; editors)
                        e.viewportTools(VertexToolMode.Points);
                }
                incTooltip(_("Vertex Tool"));

                if (!deformOnly) {
                    if (incButtonColored("", ImVec2(0, 0), getToolMode() == VertexToolMode.Connect ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
                        setToolMode(VertexToolMode.Connect);
                        foreach (e; editors)
                            e.viewportTools(VertexToolMode.Connect);
                    }
                    incTooltip(_("Edge Tool"));
                }

                if (incButtonColored("", ImVec2(0, 0), getToolMode() == VertexToolMode.PathDeform ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
                    setToolMode(VertexToolMode.PathDeform);
                    foreach (e; editors)
                        e.viewportTools(VertexToolMode.PathDeform);
                }
                incTooltip(_("Path Deform Tool"));

                if (!deformOnly) {
                    if (incButtonColored("", ImVec2(0, 0), getToolMode() == VertexToolMode.Grid ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
                        setToolMode(VertexToolMode.Grid);
                        foreach (e; editors)
                            e.viewportTools(VertexToolMode.Grid);
                    }
                    incTooltip(_("Grid Vertex Tool"));
                }

            igPopStyleVar(2);
        igSetWindowFontScale(1);
    }

    void setMirrorHoriz(bool mirrorHoriz) {
        this.mirrorHoriz = mirrorHoriz;
        foreach (e; editors) {
            e.mirrorHoriz = mirrorHoriz;
        }
    }

    bool getMirrorHoriz() {
        return mirrorHoriz;
    }

    void setMirrorVert(bool mirrorVert) {
        this.mirrorVert = mirrorVert;
        foreach (e; editors) {
            e.mirrorVert = mirrorVert;
        }
    }

    bool getMirrorVert() {
        return mirrorVert;
    }

    void setPreviewTriangulate(bool previewTriangulate) {
        this.mirrorVert = mirrorVert;
        foreach (e; editors) {
            e.previewTriangulate = previewTriangulate;
        }
    }

    bool getPreviewTriangulate() {
        return previewTriangulate;
    }

    bool previewingTriangulation() {
        foreach (e; editors) {
            if (!e.previewingTriangulation())
                return false;
        }
        return true;
    }

}

