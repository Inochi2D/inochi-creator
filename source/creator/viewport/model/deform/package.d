/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.viewport.model.deform;
import creator.viewport.model.deform.mesh;
import creator.viewport.common.mesh;
import creator.viewport.common.mesheditor;
import creator.widgets.tooltip;
import creator.core.input;
import inochi2d.core.dbg;
import creator.core;
import creator;
import inochi2d;
import bindbc.imgui;
import i18n;
import std.stdio;

private {
    IncMeshEditor editor;
    Drawable selected = null;
}

void incViewportNodeDeformNotifyParamValueChanged() {
    if (Parameter param = incArmedParameter()) {
        if (!editor) {
            if (Drawable selectedDraw = cast(Drawable)incSelectedNode()) {
                editor = new IncMeshEditor(true);
                editor.setTarget(selectedDraw);
            } else {
                return;
            }
        } else {
            editor.resetMesh();
        }

        DeformationParameterBinding deform = cast(DeformationParameterBinding)param.getBinding(editor.getTarget(), "deform");
        if (deform) {
            editor.applyOffsets(deform.getValue(param.findClosestKeypoint()).vertexOffsets);
        }
    } else {
        editor = null;
    }
}

void incViewportModelDeformNodeSelectionChanged() {
    editor = null;
    incViewportNodeDeformNotifyParamValueChanged();
}

void incViewportModelDeformUpdate(ImGuiIO* io, Camera camera, Parameter param) {
    if (!editor) return;

    if (editor.update(io, camera)) {
        auto deform = cast(DeformationParameterBinding)param.getOrAddBinding(editor.getTarget(), "deform");
        deform.update(param.findClosestKeypoint(), editor.getOffsets());
    }
}

void incViewportModelDeformDraw(Camera camera, Parameter param) {
    if (editor)
        editor.draw(camera);
}

void incViewportModelDeformOverlay() {
    if (editor) {
        editor.viewportOverlay();
    }
}

void incViewportModelDeformToolSettings() {

}