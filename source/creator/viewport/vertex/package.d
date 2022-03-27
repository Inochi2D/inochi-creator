/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.viewport.vertex;
import i18n;
import creator.viewport;
import creator.viewport.common.mesh;
import creator.viewport.common.mesheditor;
import creator.core.input;
import creator.widgets;
import creator;
import inochi2d;
import bindbc.imgui;
import std.stdio;
import bindbc.opengl;

private {
    IncMeshEditor editor;
    bool triangulate = false;
}

void incViewportVertexOverlay() {
    igPushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0));

        if (incButtonColored("", ImVec2(28, 28), editor.getToolMode() == VertexToolMode.Points ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
            editor.setToolMode(VertexToolMode.Points);
            editor.previewTriangulate = triangulate;
            editor.refreshMesh();
        }
        incTooltip(_("Vertex Tool"));

        igSameLine(0, 0);
        if (incButtonColored("", ImVec2(28, 28), editor.getToolMode() == VertexToolMode.Connect ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
            editor.setToolMode(VertexToolMode.Connect);
            editor.previewTriangulate = false;
            editor.refreshMesh();
        }
        incTooltip(_("Line Tool"));

    igPopStyleVar();

}

void incViewportVertexUpdate(ImGuiIO* io, Camera camera) {
    editor.update(io, camera);
}

void incViewportVertexDraw(Camera camera) {
    // Draw the part that is currently being edited
    auto target = editor.getTarget();
    if (target !is null) {
        if (Part part = cast(Part)target) {

            // Draw albedo texture at 0, 0
            inDrawTextureAtPosition(part.textures[0], vec2(0, 0));
        }
    }

    editor.draw(camera);
}

void incViewportVertexToolbar() { }

void incViewportVertexToolSettings() { }

void incViewportVertexPresent() {
    editor = new IncMeshEditor(false);
}

void incViewportVertexWithdraw() {
    editor = null;
}

Drawable incVertexEditGetTarget() {
    return editor.getTarget();
}

void incVertexEditSetTarget(Drawable target) {
    editor.setTarget(target);
}

void incVertexEditCopyMeshDataToTarget(MeshData data) {
    editor.importMesh(data);
}

/**
    Applies the mesh edits
*/
void incMeshEditApply() {
    editor.applyToTarget();
}

/**
    Resets the mesh edits
*/
void incMeshEditClear() {
    editor.mesh.clear();
}


/**
    Resets the mesh edits
*/
void incMeshEditReset() {
    editor.mesh.reset();
}

/**
    Flip vertically
*/
void incMeshFlipVert() {
    editor.mesh.flipVert();
}

/**
    Flip horizontally
*/
void incMeshFlipHorz() {
    editor.mesh.flipHorz();
}

void incMeshEditSetTriangulate(bool triangulate_) {
    triangulate = triangulate_;
    if (editor.getToolMode() == VertexToolMode.Points)
        editor.previewTriangulate = triangulate;
    editor.refreshMesh();
}

bool incMeshEditGetTriangulate() {
    return triangulate;
}

void incMeshEditApplyTriangulate() {
    if (!triangulate) return;
    triangulate = false;
    editor.applyPreview();
    editor.refreshMesh();
}

