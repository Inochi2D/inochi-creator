/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.viewport.model.deform;
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

private {
    IncMeshEditor editor;
    Drawable selected = null;
}

void incViewportNodeDeformNotifyParamValueChanged() {
    if (Parameter param = incArmedParameter()) {
        auto drawables = incSelectedNodes();

        if (!editor) {
            if (drawables && drawables.length > 0) {
                editor = new IncMeshEditor(true);
                editor.setTargets(drawables);
            } else
                return;
        } else {
            editor.setTargets(drawables);
            editor.resetMesh();
        }

        foreach (node; editor.getTargets()) {
            auto e = editor.getEditorFor(node);
            DeformationParameterBinding deform = null;
            if (auto drawable = cast(Drawable)node)
                deform = cast(DeformationParameterBinding)param.getBinding(drawable, "deform");
            if (e !is null) {
                if (deform !is null) {
                    auto binding = deform.getValue(param.findClosestKeypoint());
                    e.applyOffsets(binding.vertexOffsets);
                }
                e.adjustPathTransform();
            }
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
        foreach (d; incSelectedNodes()) {
            if (Drawable drawable = cast(Drawable)d) {
                auto deform = cast(DeformationParameterBinding)param.getOrAddBinding(drawable, "deform");
                deform.update(param.findClosestKeypoint(), editor.getEditorFor(drawable).getOffsets());
            }
        }
    }
}

void incViewportModelDeformDraw(Camera camera, Parameter param) {
    if (editor)
        editor.draw(camera);
}

void incViewportModelDeformTools() {
    if (editor) {
        editor.viewportTools();
    }
}

void incViewportModelDeformOptions() {
    if (editor) {
        editor.displayToolOptions();
    }
}

void incViewportModelDeformToolSettings() {

}

IncMeshEditor incViewportModelDeformGetEditor() {
    return editor;
}