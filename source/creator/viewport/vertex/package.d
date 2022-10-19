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
import creator.viewport.common.automesh;
import creator.core.input;
import creator.widgets;
import creator;
import inochi2d;
import bindbc.imgui;
import std.stdio;
import bindbc.opengl;

private {
    IncMeshEditor editor;
    AutoMeshProcessor[] autoMeshProcessors = [
        new ContourAutoMeshProcessor()
    ];
    AutoMeshProcessor activeProcessor = null;
}

void incViewportVertexInspector(Drawable node) {

    

}

void incViewportVertexTools() {
    editor.viewportTools();
}

void incViewportVertexOptions() {
    igPushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0));
    igPushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(4, 4));
        igBeginGroup();
            if (igButton("")) editor.mesh.flipHorz();
            incTooltip(_("Flip Horizontally"));

            igSameLine(0, 0);

            if (igButton("")) editor.mesh.flipVert();
            incTooltip(_("Flip Vertically"));
        igEndGroup();

        igSameLine(0, 4);

        igBeginGroup();
            if (incButtonColored("", ImVec2(0, 0), editor.mirrorHoriz ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
                editor.mirrorHoriz = !editor.mirrorHoriz;
                editor.refreshMesh();
            }
            incTooltip(_("Mirror Horizontally"));

            igSameLine(0, 0);

            if (incButtonColored("", ImVec2(0, 0), editor.mirrorVert ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
                editor.mirrorVert = !editor.mirrorVert;
                editor.refreshMesh();
            }
            incTooltip(_("Mirror Vertically"));
        igEndGroup();

        igSameLine(0, 4);

        igBeginGroup();
            if (incButtonColored("", ImVec2(0, 0),
                editor.previewTriangulate ? ImVec4(1, 1, 0, 1) : ImVec4.init)) {
                editor.previewTriangulate = !editor.previewTriangulate;
                editor.refreshMesh();
            }
            incTooltip(_("Triangulate vertices"));

            if (incBeginDropdownMenu("TRIANGULATE_SETTINGS")) {
                incDummyLabel("TODO: Options Here", ImVec2(0, 192));

                // Button which bakes some auto generated content
                // In this case, a mesh is baked from the triangulation.
                if (incButtonColored(__("Bake"), ImVec2(incAvailableSpace().x, 0),
                    editor.previewingTriangulation() ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
                    if (editor.previewingTriangulation()) {
                        editor.applyPreview();
                        editor.refreshMesh();
                    }
                }
                incTooltip(_("Bakes the triangulation, applying it to the mesh."));
                
                incEndDropdownMenu();
            }
            incTooltip(_("Triangulation Options"));

        igEndGroup();

        igSameLine(0, 4);

        igBeginGroup();
            if (igButton("")) {
                if (!activeProcessor)
                    activeProcessor = autoMeshProcessors[0];
                editor.mesh = activeProcessor.autoMesh(editor.getTarget(), editor.getMesh(), editor.mirrorHoriz, 0, editor.mirrorVert, 0);
                editor.refreshMesh();
            }
            if (incBeginDropdownMenu("AUTOMESH_SETTINGS")) {
                if (!activeProcessor)
                    activeProcessor = autoMeshProcessors[0];
                activeProcessor.configure();

                // Button which bakes some auto generated content
                // In this case, a mesh is baked from the triangulation.
                if (igButton(__("Bake"),ImVec2(incAvailableSpace().x, 0))) {
                    editor.mesh = activeProcessor.autoMesh(editor.getTarget(), editor.getMesh(), editor.mirrorHoriz, 0, editor.mirrorVert, 0);
                    editor.refreshMesh();
                }
                incTooltip(_("Bakes the auto mesh."));
                
                incEndDropdownMenu();
            }
            incTooltip(_("Auto Meshing Options"));
        igEndGroup();

    igPopStyleVar(2);
}

void incViewportVertexConfirmBar() {
    Drawable target = editor.getTarget();
    igPushStyleVar(ImGuiStyleVar.FramePadding, ImVec2(16, 4));
        if (igButton(__(" Apply"), ImVec2(0, 26))) {
            if (incMeshEditGetIsApplySafe()) {
                incMeshEditApply();
            } else {
                incDialog(
                    "CONFIRM_VERTEX_APPLY", 
                    __("Are you sure?"), 
                    _("The layout of the mesh has changed, all deformations to this mesh will be deleted if you continue."),
                    DialogLevel.Warning,
                    DialogButtons.Yes | DialogButtons.No
                );
            }
        }

        // In case of a warning popup preventing application.
        if (incDialogButtonSelected("CONFIRM_VERTEX_APPLY") == DialogButtons.Yes) {
            incMeshEditApply();
        }
        incTooltip(_("Apply"));
        
        igSameLine(0, 0);

        if (igButton(__(" Cancel"), ImVec2(0, 26))) {
            if (igGetIO().KeyShift) {
                incMeshEditReset();
            } else {
                incMeshEditClear();
            }

            incSetEditMode(EditMode.ModelEdit);
            incSelectNode(target);
            incFocusCamera(target);
        }
        incTooltip(_("Cancel"));
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

void incVertexEditStartEditing(Drawable target) {
    incSetEditMode(EditMode.VertexEdit);
    incSelectNode(target);
    incVertexEditSetTarget(target);
    incFocusCamera(target, vec2(0, 0));
}

void incVertexEditSetTarget(Drawable target) {
    editor.setTarget(target);
}

void incVertexEditCopyMeshDataToTarget(MeshData data) {
    editor.importMesh(data);
}

bool incMeshEditGetIsApplySafe() {
    Drawable target = cast(Drawable)editor.getTarget();
    return !(
        editor.mesh.getVertexCount() != target.getMesh().vertices.length &&
        incActivePuppet().getIsNodeBound(target)
    );
}

/**
    Applies the mesh edits
*/
void incMeshEditApply() {
    Node target = editor.getTarget();
    
    // Automatically apply triangulation
    if (editor.previewingTriangulation()) {
        editor.applyPreview();
        editor.refreshMesh();
    }

    if (editor.mesh.getVertexCount() < 3 || editor.mesh.getEdgeCount() < 3) {
        incDialog(__("Error"), _("Cannot apply invalid mesh\nAt least 3 vertices forming a triangle is needed."));
        return;
    }

    // Apply to target
    editor.applyToTarget();

    // Switch mode
    incSetEditMode(EditMode.ModelEdit);
    incSelectNode(target);
    incFocusCamera(target);
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
