/*
    Copyright © 2020-2023, Inochi2D Project
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
import creator.core.actionstack;
import creator.widgets;
import creator;
import inochi2d;
import bindbc.imgui;
import std.stdio;
import std.string;
import bindbc.opengl;

private {
    IncMeshEditor editor;
    AutoMeshProcessor[] autoMeshProcessors = [
        new ContourAutoMeshProcessor(),
        new GridAutoMeshProcessor()
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
            if (igButton("")) {
                foreach (d; incSelectedNodes) {
                    auto meshEditor = cast(IncMeshEditorOneDrawable)editor.getEditorFor(d);
                    if (meshEditor)
                        meshEditor.getMesh().flipHorz();
                }
            }
            incTooltip(_("Flip Horizontally"));

            igSameLine(0, 0);

            if (igButton("")) {
                foreach (d; incSelectedNodes) {
                    auto meshEditor = cast(IncMeshEditorOneDrawable)editor.getEditorFor(d);
                    if (meshEditor)
                        meshEditor.getMesh().flipVert();
                }
            }
            incTooltip(_("Flip Vertically"));
        igEndGroup();

        igSameLine(0, 4);

        igBeginGroup();
            if (incButtonColored("", ImVec2(0, 0), editor.getMirrorHoriz() ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
                editor.setMirrorHoriz(!editor.getMirrorHoriz());
                editor.refreshMesh();
            }
            incTooltip(_("Mirror Horizontally"));

            igSameLine(0, 0);

            if (incButtonColored("", ImVec2(0, 0), editor.getMirrorVert() ? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
                editor.setMirrorVert(!editor.getMirrorVert());
                editor.refreshMesh();
            }
            incTooltip(_("Mirror Vertically"));
        igEndGroup();

        igSameLine(0, 4);

        igBeginGroup();
            if (incButtonColored("", ImVec2(0, 0),
                editor.getPreviewTriangulate() ? ImVec4(1, 1, 0, 1) : ImVec4.init)) {
                editor.setPreviewTriangulate(!editor.getPreviewTriangulate());
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
                foreach (drawable; editor.getTargets()) {
                    auto e = cast(IncMeshEditorOneDrawable)editor.getEditorFor(drawable);
                    if (e !is null)
                        e.setMesh(activeProcessor.autoMesh(cast(Drawable)drawable, e.getMesh(), e.mirrorHoriz, 0, e.mirrorVert, 0));
                }
                editor.refreshMesh();
            }
            if (incBeginDropdownMenu("AUTOMESH_SETTINGS")) {
                if (!activeProcessor)
                    activeProcessor = autoMeshProcessors[0];
                
                igBeginGroup();
                foreach (processor; autoMeshProcessors) {
                    if (incButtonColored(processor.icon().toStringz, ImVec2(0, 0), (processor == activeProcessor)? ImVec4.init : ImVec4(0.6, 0.6, 0.6, 1))) {
                        activeProcessor = processor;
                    }
                    igSameLine(0, 2);
                }
                igEndGroup();

                activeProcessor.configure();

                // Button which bakes some auto generated content
                // In this case, a mesh is baked from the triangulation.
                if (igButton(__("Bake"),ImVec2(incAvailableSpace().x, 0))) {
                    foreach (drawable; editor.getTargets()) {
                        auto e = cast(IncMeshEditorOneDrawable)editor.getEditorFor(drawable);
                        if (e !is null)
                            e.setMesh(activeProcessor.autoMesh(cast(Drawable)drawable, e.getMesh(), e.mirrorHoriz, 0, e.mirrorVert, 0));
                    }
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
    auto target = editor.getTargets();
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
            incActionPopStack();
            incSetEditMode(EditMode.ModelEdit);
            foreach (d; target) {
                incAddSelectNode(d);
            }
            incFocusCamera(target[0]);  /// FIX ME!
        }
        incTooltip(_("Cancel"));
    igPopStyleVar();
}

void incViewportVertexUpdate(ImGuiIO* io, Camera camera) {
    editor.update(io, camera);
}

void incViewportVertexDraw(Camera camera) {
    // Draw the part that is currently being edited
    auto targets = editor.getTargets();
    if (targets.length > 0) {
        foreach (target; targets) {
            if (Part part = cast(Part)target) {
                // Draw albedo texture at 0, 0
                auto origin = vec2(0, 0);
                if (part.textures[0] !is null) {
                    inDrawTextureAtPosition(part.textures[0], origin);
                } else {
                    mat4 transform = part.transform.matrix.inverse;
                    part.setOneTimeTransform(&transform);
                    part.drawOne();
                    part.setOneTimeTransform(null);
                }
            } else if (MeshGroup mgroup = cast(MeshGroup)target) {
                mat4 transform = mgroup.transform.matrix.inverse;
                mgroup.setOneTimeTransform(&transform);
                Node[] subParts;
                void findSubDrawable(Node n) {
                    if (auto m = cast(MeshGroup)n) {
                        foreach (child; n.children)
                            findSubDrawable(child);
                    } else if (auto c = cast(Composite)n) {
                        if (c.propagateMeshGroup) {
                            subParts ~= c;
                        }
                    } else if (auto d = cast(Drawable)n) {
                        subParts ~= d;
                        foreach (child; n.children)
                            findSubDrawable(child);
                    }
                }
                findSubDrawable(mgroup);
                import std.algorithm.sorting;
                import std.algorithm.mutation : SwapStrategy;
                import std.math : cmp;
                sort!((a, b) => cmp(
                    a.zSort, 
                    b.zSort) > 0, SwapStrategy.stable)(subParts);

                foreach (part; subParts) {
                    part.drawOne();
                }
                mgroup.setOneTimeTransform(null);
            }
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

/*
Drawable incVertexEditGetTarget() {
    return editor.getTarget();
}
*/

void incVertexEditStartEditing(Drawable target) {
    incSetEditMode(EditMode.VertexEdit);
    incSelectNode(target);
    incVertexEditSetTarget(target);
    incFocusCamera(target, vec2(0, 0));
}

void incVertexEditSetTarget(Drawable target) {
    editor.setTarget(target);
}

void incVertexEditCopyMeshDataToTarget(Drawable target, Drawable drawable, ref MeshData data) {
    if (editor.getEditorFor(target)) {
        editor.getEditorFor(target).importMesh(data);
    } else {
        editor.addTarget(target);
        assert(editor.getEditorFor(target));
        editor.getEditorFor(target).importMesh(data);
    }
}

bool incMeshEditGetIsApplySafe() {
    /* Disabled temporary
    Drawable target = cast(Drawable)editor.getTarget();
    return !(
        editor.mesh.getVertexCount() != target.getMesh().vertices.length &&
        incActivePuppet().getIsNodeBound(target)
    );
    */
    return true;
}

/**
    Applies the mesh edits
*/
void incMeshEditApply() {
    auto target = editor.getTargets();
    
    // Automatically apply triangulation
    if (editor.previewingTriangulation()) {
        editor.applyPreview();
        editor.refreshMesh();
    }

    foreach (d; target) {
        if (Drawable drawable = cast(Drawable)d) {
            auto meshEditor = cast(IncMeshEditorOneDrawable)editor.getEditorFor(drawable);
            if (meshEditor !is null && (meshEditor.getMesh().getTriCount() < 1)) {
                incDialog(__("Error"), _("Cannot apply invalid mesh\nAt least 3 vertices forming a triangle is needed."));
                return;
            }
        }
    }

    incActionPopStack();
    // Apply to target
    editor.applyToTarget();

    // Switch mode
    incSetEditMode(EditMode.ModelEdit);
    foreach (d; target) {
        if (Drawable drawable = cast(Drawable)d)
            incAddSelectNode(drawable);
    }
    incFocusCamera(target[0]); /// FIX ME
}

/**
    Resets the mesh edits
*/
void incMeshEditClear() {
    foreach (d; editor.getTargets()) {
        auto meshEditor = cast(IncMeshEditorOneDrawable)editor.getEditorFor(d);
        if (meshEditor !is null)
            meshEditor.getMesh().clear();
    }
}


/**
    Resets the mesh edits
*/
void incMeshEditReset() {
    foreach (d; editor.getTargets()) {
        auto meshEditor = cast(IncMeshEditorOneDrawable)editor.getEditorFor(d);
        if (meshEditor !is null)
            meshEditor.getMesh().reset();
    }
}
