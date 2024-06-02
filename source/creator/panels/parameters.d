/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.parameters;
import creator.viewport.model.deform;
import creator.panels;
import creator.ext.param;
import creator.widgets;
import creator.windows;
import creator.core;
import creator.actions;
import creator.ext;
import creator.ext.param;
import creator.viewport.common.mesheditor;
import creator.viewport.common.mesh;
import creator.windows.flipconfig;
import creator.viewport.model.onionslice;
import creator.utils.transform;
import creator;
import std.string;
import inochi2d;
import i18n;
import std.uni : toLower;
import std.stdio;
import creator.utils;
import std.algorithm.searching : countUntil;
import std.algorithm.sorting : sort;
import std.algorithm.mutation : remove;

private {

    ParameterBinding[][Node] cParamBindingEntries;
    ParameterBinding[][Node] cParamBindingEntriesAll;
    Node[] cAllBoundNodes;
    ParameterBinding[BindTarget] cSelectedBindings;
    Node[] cCompatibleNodes;
    vec2u cParamPoint;
    vec2u cClipboardPoint;
    ParameterBinding[BindTarget] cClipboardBindings;
    Parameter cClipboardParameter = null;
    bool selectedOnly = false;

    void refreshBindingList(Parameter param, bool selectedOnly = false) {
        // Filter selection to remove anything that went away
        ParameterBinding[BindTarget] newSelectedBindings;

        auto selected = selectedOnly? incSelectedNodes() : [];
        cParamBindingEntriesAll.clear();
        foreach(ParameterBinding binding; param.bindings) {
            BindTarget target = binding.getTarget();
            if (target in cSelectedBindings) newSelectedBindings[target] = binding;
            if (!selectedOnly || selected.countUntil(target.node) >= 0)
                cParamBindingEntriesAll[binding.getNode()] ~= binding;
        }
        cAllBoundNodes = cParamBindingEntriesAll.keys.dup;
        cAllBoundNodes.sort!((x, y) => x.name < y.name);
        cSelectedBindings = newSelectedBindings;
        paramPointChanged(param);
    }

    void paramPointChanged(Parameter param) {
        cParamBindingEntries.clear();

        cParamPoint = param.findClosestKeypoint();
        foreach(ParameterBinding binding; param.bindings) {
            if (binding.isSet(cParamPoint)) {
                cParamBindingEntries[binding.getNode()] ~= binding;
            }
        }
    }

    void mirrorAll(Parameter param, uint axis) {
        auto action = new ParameterChangeBindingsAction("Mirror All", param, null);
        foreach(ParameterBinding binding; param.bindings) {
            uint xCount = param.axisPointCount(0);
            uint yCount = param.axisPointCount(1);
            foreach(x; 0..xCount) {
                foreach(y; 0..yCount) {
                    vec2u index = vec2u(x, y);
                    if (binding.isSet(index)) {
                        binding.scaleValueAt(index, axis, -1);
                    }
                }
            }
        }
        action.updateNewState();
        incActionPush(action);
    }

    void mirroredAutofill(Parameter param, uint axis, float min, float max) {
        incActionPushGroup();
        auto action = new ParameterChangeBindingsAction("Mirror Auto Fill", param, null);

        foreach(ParameterBinding binding; param.bindings) {

            Node target = binding.getTarget().node;
            auto pair = incGetFlipPairFor(target);
            auto targetBinding = incBindingGetPairFor(param, target, pair, binding.getName(), true);
            // Check if the binding was found or created
            if(targetBinding is null) continue;

            uint xCount = param.axisPointCount(0);
            uint yCount = param.axisPointCount(1);
            foreach(x; 0..xCount) {
                float offX = param.axisPoints[0][x];
                if (axis == 0 && (offX < min || offX > max)) continue;
                foreach(y; 0..yCount) {
                    float offY = param.axisPoints[1][y];
                    if (axis == 1 && (offY < min || offY > max)) continue;

                    vec2u index = vec2u(x, y);
                    if (!targetBinding.isSet(index)) incBindingAutoFlip(targetBinding, binding, index, axis);
                }
            }
        }
        action.updateNewState();
        incActionPush(action);
        incActionPopGroup();
    }

    void pasteParameter(Parameter param, uint axis) {
        if (cClipboardParameter is null)
            return;
        incActionPushGroup();
        auto action = new ParameterChangeBindingsAction("Paste", param, null);

        foreach(ParameterBinding srcBinding; cClipboardParameter.bindings) {

            Node target = srcBinding.getTarget().node;
            FlipPair pair = null;
            if (axis != 2)
                pair = incGetFlipPairFor(target);
            auto binding = incBindingGetPairFor(param, target, pair, srcBinding.getName(), true);
            // Check if the binding was found or created
            if(binding is null) continue;

            uint xCount = param.axisPointCount(0);
            uint yCount = param.axisPointCount(1);
            foreach(x; 0..xCount) {
                foreach(y; 0..yCount) {
                    vec2u index = vec2u(x, y);
                    incBindingAutoFlip(binding, srcBinding, index, axis, false);
                }
            }
        }
        action.updateNewState();
        incActionPush(action);
        incActionPopGroup();
        cClipboardParameter = null;
    }

    void fixScales(Parameter param) {
        auto action = new ParameterChangeBindingsAction("Fix Scale", param, null);
        foreach(ParameterBinding binding; param.bindings) {                        
            switch(binding.getName()) {
                case "transform.s.x":
                case "transform.s.y":
                if (ValueParameterBinding b = cast(ValueParameterBinding)binding) {
                    uint xCount = param.axisPointCount(0);
                    uint yCount = param.axisPointCount(1);
                    foreach(x; 0..xCount) {
                        foreach(y; 0..yCount) {
                            vec2u index = vec2u(x, y);
                            if (b.isSet(index)) {
                                b.values[x][y] += 1;
                            }
                        }
                    }
                    b.reInterpolate();
                }
                break;
                default: break;
            }
        }
        action.updateNewState();
        incActionPush(action);
    }

    Node[] getCompatibleNodes() {
        Node thisNode = null;

        foreach(binding; cSelectedBindings.byValue()) {
            if (thisNode is null) thisNode = binding.getNode();
            else if (!(binding.getNode() is thisNode)) return null;
        }
        if (thisNode is null) return null;

        Node[] compatible;
        nodeLoop: foreach(otherNode; cParamBindingEntriesAll.byKey()) {
            if (otherNode is thisNode) continue;

            foreach(binding; cSelectedBindings.byValue()) {
                if (!binding.isCompatibleWithNode(otherNode))
                    continue nodeLoop;
            }
            compatible ~= otherNode;
        }

        return compatible;
    }

    void copySelectionToNode(Parameter param, Node target) {
        Node src = cSelectedBindings.keys[0].node;

        foreach(binding; cSelectedBindings.byValue()) {
            assert(binding.getNode() is src, "selection mismatch");

            ParameterBinding b = param.getOrAddBinding(target, binding.getName());
            binding.copyKeypointToBinding(cParamPoint, b, cParamPoint);
        }
        target.notifyChange(target, NotifyReason.StructureChanged);

        refreshBindingList(param);
    }

    void swapSelectionWithNode(Parameter param, Node target) {
        Node src = cSelectedBindings.keys[0].node;

        foreach(binding; cSelectedBindings.byValue()) {
            assert(binding.getNode() is src, "selection mismatch");

            ParameterBinding b = param.getOrAddBinding(target, binding.getName());
            binding.swapKeypointWithBinding(cParamPoint, b, cParamPoint);
        }

        refreshBindingList(param);
    }

    void convertTo2D(Parameter param) {
        auto action = new GroupAction();

        auto newParam = new ExParameter(param.name, true);
        newParam.uuid = param.uuid;
        newParam.min  = vec2(param.min.x, param.min.x);
        newParam.max  = vec2(param.max.x, param.max.x);
        long findIndex(T)(T[] array, T target) {
            ptrdiff_t idx = array.countUntil(target);
            return idx;
        }
        foreach (key; param.axisPoints[0]) {
            if (key != 0 && key != 1) {
                newParam.insertAxisPoint(0, key);
            }
            foreach(binding; param.bindings) {
                ParameterBinding b = newParam.getOrAddBinding(binding.getTarget().node, binding.getName());
                auto srcKeyIndex  = param.findClosestKeypoint(param.unmapValue(vec2(key, 0)));
                auto destKeyIndex = newParam.findClosestKeypoint(newParam.unmapValue(vec2(key, newParam.min.y)));
                binding.copyKeypointToBinding(srcKeyIndex, b, destKeyIndex);
            }
        }
        auto index = incActivePuppet().parameters.countUntil(param);
        if (index >= 0) {
            action.addAction(new ParameterRemoveAction(param, &incActivePuppet().parameters));
            action.addAction(new ParameterAddAction(newParam, &incActivePuppet().parameters));
            incActivePuppet().parameters[index] = newParam;
            if (auto prevParam = cast(ExParameter)param) {
                auto parent = prevParam.getParent();
                prevParam.setParent(null);
                newParam.setParent(parent);
            }
        }
        incActionPush(action);
    }

    void pushColorScheme(vec3 color) {
        float h, s, v;
        igColorConvertRGBtoHSV(color.r, color.g, color.b, &h, &s, &v);

        float maxS = lerp(1, 0.60, v);

        vec3 c = color;
        igColorConvertHSVtoRGB(
            h, 
            clamp(lerp(s, s-0.20, v), 0, maxS), 
            clamp(v-0.15, 0.15, 0.90), 
            &c.vector[0], &c.vector[1], &c.vector[2]
        );
        igPushStyleColor(ImGuiCol.FrameBg, ImVec4(c.r, c.g, c.b, 1));


        maxS = lerp(1, 0.60, v);
        igColorConvertHSVtoRGB(
            h, 
            lerp(
                clamp(s-0.25, 0, maxS),
                clamp(s+0.25, 0, maxS),
                s
            ),
            v <= 0.55 ?
                clamp(v+0.25, 0.45, 0.95) :
                clamp(v-(0.25*(1+v)), 0.30, 1),
            &c.vector[0], &c.vector[1], &c.vector[2]
        );
        igPushStyleColor(ImGuiCol.TextDisabled, ImVec4(c.r, c.g, c.b, 1));
    }

    void popColorScheme() {
        igPopStyleColor(2);
    }

    ptrdiff_t findParamIndex(ref Parameter[] paramArr, Parameter param) {
        import std.algorithm.searching : countUntil;
        ptrdiff_t idx = paramArr.countUntil(param);
        return idx;
    }
    ParamDragDropData* dragDropData;

    bool removeParameter(Parameter param) {
        ExParameterGroup parent = null;
        ptrdiff_t idx = -1;

        mloop: foreach(i, iparam; incActivePuppet.parameters) {
            if (iparam.uuid == param.uuid) {
                idx = i;
                break mloop;
            }

            if (ExParameterGroup group = cast(ExParameterGroup)iparam) {
                foreach(x, ref xparam; group.children) {
                    if (xparam.uuid == param.uuid) {
                        idx = x;
                        parent = group;
                        break mloop;
                    }
                }
            }
        }

        if (idx < 0) return false;

        if (parent) {
            if (parent.children.length > 0) parent.children = parent.children.remove(idx);
            else parent.children.length = 0;
        }
        if (incActivePuppet().parameters.length > 1) incActivePuppet().parameters = incActivePuppet().parameters.remove(idx);
        else incActivePuppet().parameters.length = 0;

        return true;
    }

    void setTransparency(float alpha, float text) {
        ImGuiCol[] colIDs = [ImGuiCol.WindowBg, ImGuiCol.Text, ImGuiCol.FrameBg, ImGuiCol.Button, ImGuiCol.Border, ImGuiCol.PopupBg];
        foreach (id; colIDs) {
            ImVec4 style;
            style = *igGetStyleColorVec4(id);
            style.w = id == ImGuiCol.Text? text: alpha;
            igPushStyleColor(id, style);
        }
    }

    void resetTransparency() {
        igPopStyleColor(6);
    }

}

struct ParamDragDropData {
    Parameter param;
}


void incMoveParameter(Parameter from, ExParameterGroup to = null, int index = 0) {
    (cast(ExParameter)from).setParent(to);
}

ExParameterGroup incCreateParamGroup(int index = 0) {
    import std.array : insertInPlace;

    if (index < 0) index = 0;
    else if (index > incActivePuppet().parameters.length) index = cast(int)incActivePuppet().parameters.length-1;

    auto group = new ExParameterGroup(_("New Parameter Group"));
    (cast(ExPuppet)incActivePuppet()).addGroup(group);
    return group;
}


void incKeypointActions(Parameter param, ParameterBinding[] srcBindings, ParameterBinding[] targetBindings) {
    ParameterBinding[] bindings = (targetBindings !is null)? targetBindings: srcBindings;
    if (igMenuItem(__("Unset"), "", false, true)) {
        auto action = new ParameterChangeBindingsValueAction("unset", param, bindings, cParamPoint.x, cParamPoint.y);
        foreach(binding; bindings) {
            binding.unset(cParamPoint);
        }
        action.updateNewState();
        incActionPush(action);
        incViewportNodeDeformNotifyParamValueChanged();
    }
    if (igMenuItem(__("Set to current"), "", false, true)) {
        auto action = new ParameterChangeBindingsValueAction("setCurrent", param, bindings, cParamPoint.x, cParamPoint.y);
        foreach(binding; bindings) {
            binding.setCurrent(cParamPoint);
        }
        action.updateNewState();
        incActionPush(action);
        incViewportNodeDeformNotifyParamValueChanged();
    }
    if (igMenuItem(__("Reset"), "", false, true)) {
        auto action = new ParameterChangeBindingsValueAction("reset", param, bindings, cParamPoint.x, cParamPoint.y);
        foreach(binding; bindings) {
            binding.reset(cParamPoint);
        }
        action.updateNewState();
        incActionPush(action);
        incViewportNodeDeformNotifyParamValueChanged();
    }
    if (igMenuItem(__("Invert"), "", false, true)) {
        auto action = new ParameterChangeBindingsValueAction("invert", param, bindings, cParamPoint.x, cParamPoint.y);
        foreach(binding; bindings) {
            binding.scaleValueAt(cParamPoint, -1, -1);
        }
        action.updateNewState();
        incActionPush(action);
        incViewportNodeDeformNotifyParamValueChanged();
    }
    if (igBeginMenu(__("Mirror"), true)) {
        if (igMenuItem(__("Horizontally"), "", false, true)) {
            auto action = new ParameterChangeBindingsValueAction("mirror Horizontally", param, bindings, cParamPoint.x, cParamPoint.y);
            foreach(binding; bindings) {
                binding.scaleValueAt(cParamPoint, 0, -1);
            }
            action.updateNewState();
            incActionPush(action);
            incViewportNodeDeformNotifyParamValueChanged();
        }
        if (igMenuItem(__("Vertically"), "", false, true)) {
            auto action = new ParameterChangeBindingsValueAction("mirror Vertically", param, bindings, cParamPoint.x, cParamPoint.y);
            foreach(binding; bindings) {
                binding.scaleValueAt(cParamPoint, 1, -1);
            }
            action.updateNewState();
            incActionPush(action);
            incViewportNodeDeformNotifyParamValueChanged();
        }
        igEndMenu();
    }
    if (igMenuItem(__("Flip Deform"), "", false, true)) {

        auto action = new ParameterChangeBindingsValueAction("Flip Deform", param, bindings, cParamPoint.x, cParamPoint.y);
        foreach(binding; bindings) {
            auto deformBinding = cast(DeformationParameterBinding)binding;  
            if (deformBinding is null)
                continue;
            Drawable drawable = cast(Drawable)deformBinding.getTarget().node;
            auto mesh = new IncMesh(drawable.getMesh());
            if (deformBinding.getIsSet()[cParamPoint.x][cParamPoint.y]) {
                auto deform = deformBinding.getValue(cParamPoint);
                auto newDeform = mesh.deformByDeformationBinding(drawable, deform, true);
                if (newDeform)
                    deformBinding.setValue(cParamPoint, *newDeform);
            }
        }
        action.updateNewState();
        incActionPush(action);
        incViewportNodeDeformNotifyParamValueChanged();
    }

    if (param.isVec2) {
        if (igBeginMenu(__("Set from mirror"), true)) {
            if (igMenuItem(__("Horizontally"), "", false, true)) {
                incActionPushGroup();
                auto action = new ParameterChangeBindingsValueAction("set From Mirror (Horizontally)", param, bindings, cParamPoint.x, cParamPoint.y);
                foreach(binding; bindings) {
                    Node target = binding.getTarget().node;
                    auto pair = incGetFlipPairFor(target);
                    auto targetBinding = incBindingGetPairFor(param, target, pair, binding.getName(), targetBindings is null);
                    if (targetBindings !is null)
                        incBindingAutoFlip(binding, targetBinding, cParamPoint, 0);
                    else if(targetBinding !is null)
                        incBindingAutoFlip(targetBinding, binding, cParamPoint, 0);
                }
                action.updateNewState();
                incActionPush(action);
                incActionPopGroup();
                incViewportNodeDeformNotifyParamValueChanged();
            }
            if (igMenuItem(__("Vertically"), "", false, true)) {
                incActionPushGroup();
                auto action = new ParameterChangeBindingsValueAction("set From Mirror (Vertically)", param, bindings, cParamPoint.x, cParamPoint.y);
                foreach(binding; bindings) {
                    Node target = binding.getTarget().node;
                    auto pair = incGetFlipPairFor(target);
                    auto targetBinding = incBindingGetPairFor(param, target, pair, binding.getName(), targetBindings is null);
                    if (targetBindings !is null)
                        incBindingAutoFlip(binding, targetBinding, cParamPoint, 1);
                    else if(targetBinding !is null)
                        incBindingAutoFlip(targetBinding, binding, cParamPoint, 1);
                }
                action.updateNewState();
                incActionPush(action);
                incActionPopGroup();
                incViewportNodeDeformNotifyParamValueChanged();
            }
            if (igMenuItem(__("Diagonally"), "", false, true)) {
                incActionPushGroup();
                auto action = new ParameterChangeBindingsValueAction("set From Mirror (Diagonally)", param, bindings, cParamPoint.x, cParamPoint.y);
                foreach(binding; bindings) {
                    Node target = binding.getTarget().node;
                    auto pair = incGetFlipPairFor(target);
                    auto targetBinding = incBindingGetPairFor(param, target, pair, binding.getName(), targetBindings is null);
                    if (targetBindings !is null)
                        incBindingAutoFlip(binding, targetBinding, cParamPoint, -1);
                    else if(targetBinding !is null)
                        incBindingAutoFlip(targetBinding, binding, cParamPoint, -1);
                }
                action.updateNewState();
                incActionPush(action);
                incActionPopGroup();
                incViewportNodeDeformNotifyParamValueChanged();
            }
            igEndMenu();
        }
    } else {
        if (igMenuItem(__("Set from mirror"), "", false, true)) {
            incActionPushGroup();
            auto action = new ParameterChangeBindingsValueAction("set From Mirror", param, bindings, cParamPoint.x, cParamPoint.y);
            foreach(binding; bindings) {
                Node target = binding.getTarget().node;
                auto pair = incGetFlipPairFor(target);
                auto targetBinding = incBindingGetPairFor(param, target, pair, binding.getName(), targetBindings is null);
                if (targetBindings !is null)
                    incBindingAutoFlip(binding, targetBinding, cParamPoint, 0);
                else if(targetBinding !is null)
                    incBindingAutoFlip(targetBinding, binding, cParamPoint, 0);
            }
            action.updateNewState();
            incActionPush(action);
            incActionPopGroup();
            incViewportNodeDeformNotifyParamValueChanged();
        }
    }

    if (igMenuItem(__("Copy"), "", false, true)) {
        cClipboardPoint = cParamPoint;
        cClipboardBindings.clear();
        foreach(binding; bindings) {
            cClipboardBindings[binding.getTarget()] = binding;
        }
    }

    if (igMenuItem(__("Paste"), "", false,  true)) {

        // Find the bindings we should apply
        // This allows us to skip the application process if we can't apply anything.
        ParameterBinding[] bindingsToApply;
        foreach(ref binding; bindings) {
            if (binding.getTarget() in cClipboardBindings) bindingsToApply ~= binding;
        }

        // Whether there's only a single binding, if so, we should not push a group
        bool isSingle = (bindings.length == 1 && cClipboardBindings.length == 1) || bindingsToApply.length == 1;

        if (bindingsToApply.length > 0) {
            if (!isSingle) incActionPushGroup();
            foreach(binding; bindingsToApply) {
                auto action = new ParameterChangeBindingsValueAction("paste", param, bindings, cParamPoint.x, cParamPoint.y);
                ParameterBinding origBinding = cClipboardBindings[binding.getTarget()];
                origBinding.copyKeypointToBinding(cClipboardPoint, binding, cParamPoint);
                action.updateNewState();
                incActionPush(action);
            }
            if (!isSingle) incActionPopGroup();
        } else if (bindings.length == 1 && cClipboardBindings.length == 1) {
            ParameterBinding binding = bindings[0];
            ParameterBinding srcBinding = cClipboardBindings.values[0];
            if (is(typeof(binding) == typeof(srcBinding))) {
                auto action = new ParameterChangeBindingsValueAction("paste", param, bindings, cParamPoint.x, cParamPoint.y);
                if (auto deformParam = cast(DeformationParameterBinding)(binding)) {
                    auto deformBinding = cast(DeformationParameterBinding)binding;
                    auto srcDeformBinding = cast(DeformationParameterBinding)srcBinding;
                    Drawable drawable = cast(Drawable)deformBinding.getTarget().node;
                    Drawable srcDrawable = cast(Drawable)srcDeformBinding.getTarget().node;
                    auto mesh = new IncMesh(drawable.getMesh());
                    Deformation deform = srcDeformBinding.getValue(cClipboardPoint);
                    auto newDeform = mesh.deformByDeformationBinding(srcDrawable, deform, false);
                    if (newDeform)
                        deformBinding.setValue(cParamPoint, *newDeform);

                } else {
                    ValueParameterBinding valueBinding = cast(ValueParameterBinding)(binding);
                    ValueParameterBinding valueSrcBinding = cast(ValueParameterBinding)(srcBinding);
                    valueBinding.setValue(cParamPoint, valueSrcBinding.getValue(cClipboardPoint));
                }
                action.updateNewState();
                incActionPush(action);
            }
        }
    }

}

void incBindingMenuContents(Parameter param, ParameterBinding[BindTarget] cSelectedBindings) {
    if (igMenuItem(__("Remove"), "", false, true)) {
        auto action = new GroupAction();
        foreach(binding; cSelectedBindings.byValue()) {
            action.addAction(new ParameterBindingRemoveAction(param, binding));
            param.removeBinding(binding);
            binding.getTarget().node.notifyChange(binding.getTarget().node, NotifyReason.StructureChanged);
        }
        incActionPush(action);
        incViewportNodeDeformNotifyParamValueChanged();
    }

    incKeypointActions(param, null, cSelectedBindings.values);

    if (igBeginMenu(__("Interpolation Mode"), true)) {
        if (igMenuItem(__("Nearest"), "", false, true)) {
            foreach(binding; cSelectedBindings.values) {
                binding.interpolateMode = InterpolateMode.Nearest;
            }
            incViewportNodeDeformNotifyParamValueChanged();
        }
        if (igMenuItem(__("Linear"), "", false, true)) {
            foreach(binding; cSelectedBindings.values) {
                binding.interpolateMode = InterpolateMode.Linear;
            }
            incViewportNodeDeformNotifyParamValueChanged();
        }
        if (igMenuItem(__("Cubic"), "", false, true)) {
            foreach(binding; cSelectedBindings.values) {
                binding.interpolateMode = InterpolateMode.Cubic;
            }
            incViewportNodeDeformNotifyParamValueChanged();
        }
        igEndMenu();
    }

    bool haveCompatible = cCompatibleNodes.length > 0;
    if (igBeginMenu(__("Copy to"), haveCompatible)) {
        foreach(cNode; cCompatibleNodes) {
            if (igMenuItem(cNode.name.toStringz, "", false, true)) {
                copySelectionToNode(param, cNode);
            }
        }
        igEndMenu();
    }
    if (igBeginMenu(__("Swap with"), haveCompatible)) {
        foreach(cNode; cCompatibleNodes) {
            if (igMenuItem(cNode.name.toStringz, "", false, true)) {
                swapSelectionWithNode(param, cNode);
            }
        }
        igEndMenu();
    }

}

void incBindingList(Parameter param) {
    if (incBeginCategory(__("Bindings"),IncCategoryFlags.None, (float w, float h) {
        if (selectedOnly)
            igText("");
        else
            igTextDisabled("");
        if (igIsItemClicked()) {
            selectedOnly = !selectedOnly;
        }
        incTooltip(selectedOnly ? _("Show all nodes") : _("Show only selected nodes"));
        igSameLine();
    })) {
        refreshBindingList(param, selectedOnly);

        auto io = igGetIO();
        auto style = igGetStyle();
        ImS32 inactiveColor = igGetColorU32(style.Colors[ImGuiCol.TextDisabled]);

        igBeginChild("BindingList", ImVec2(0, 256), false);
            igPushStyleVar(ImGuiStyleVar.CellPadding, ImVec2(4, 1));
            igPushStyleVar(ImGuiStyleVar.IndentSpacing, 14);

            foreach(node; cAllBoundNodes) {
                ParameterBinding[] allBindings = cParamBindingEntriesAll[node];
                ParameterBinding[] *bindings = (node in cParamBindingEntries);

                // Figure out if node is selected ( == all bindings selected)
                bool nodeSelected = true;
                bool someSelected = false;
                foreach(binding; allBindings) {
                    if ((binding.getTarget() in cSelectedBindings) is null)
                        nodeSelected = false;
                    else
                        someSelected = true;
                }

                ImGuiTreeNodeFlags flags = ImGuiTreeNodeFlags.DefaultOpen | ImGuiTreeNodeFlags.OpenOnArrow;
                if (nodeSelected)
                    flags |= ImGuiTreeNodeFlags.Selected;

                if (bindings is null) igPushStyleColor(ImGuiCol.Text, inactiveColor);
                string nodeName = incTypeIdToIcon(node.typeId) ~ " " ~ node.name;
                if (igTreeNodeEx(cast(void*)node.uuid, flags, nodeName.toStringz)) {

                    if (bindings is null) igPopStyleColor();
                    if (igBeginPopup("###BindingPopup")) {
                        incBindingMenuContents(param, cSelectedBindings);
                        igEndPopup();
                    }
                    if (igIsItemClicked(ImGuiMouseButton.Right)) {
                        if (!someSelected) {
                            cSelectedBindings.clear();
                            foreach(binding; allBindings) {
                                cSelectedBindings[binding.getTarget()] = binding;
                            }
                        }
                        cCompatibleNodes = getCompatibleNodes();
                        igOpenPopup("###BindingPopup");
                    }

                    // Node selection logic
                    if (igIsItemClicked(ImGuiMouseButton.Left) && !igIsItemToggledOpen()) {
                        
                        // Select the node you've clicked in the bindings list
                        if (incNodeInSelection(node)) {
                            incFocusCamera(node);
                        } else incSelectNode(node);
                        
                        if (!io.KeyCtrl) {
                            cSelectedBindings.clear();
                            nodeSelected = false;
                        }
                        foreach(binding; allBindings) {
                            if (nodeSelected) cSelectedBindings.remove(binding.getTarget());
                            else cSelectedBindings[binding.getTarget()] = binding;
                        }
                    }

                    // Iterate over bindings
                    foreach(binding; allBindings) {
                        ImGuiTreeNodeFlags flags2 =
                            ImGuiTreeNodeFlags.DefaultOpen | ImGuiTreeNodeFlags.OpenOnArrow |
                            ImGuiTreeNodeFlags.Leaf | ImGuiTreeNodeFlags.NoTreePushOnOpen;

                        bool selected = cast(bool)(binding.getTarget() in cSelectedBindings);
                        if (selected) flags2 |= ImGuiTreeNodeFlags.Selected;

                        // Style as inactive if not set at this keypoint
                        if (!binding.isSet(cParamPoint))
                            igPushStyleColor(ImGuiCol.Text, inactiveColor);


                        // Binding entry
                        auto value = cast(ValueParameterBinding)binding;
                        string label;
                        if (value && binding.isSet(cParamPoint)) {
                            label = format("%s (%.02f)", binding.getName(), value.getValue(cParamPoint));
                        } else {
                            label = binding.getName();
                        }

                        // NOTE: This is a leaf node so it should NOT be popped.
                        const(char)* bid = binding.getName().toStringz;
                        igTreeNodeEx(bid, flags2, label.toStringz);
                            if (!binding.isSet(cParamPoint)) igPopStyleColor();

                            // Binding selection logic
                            if (igIsItemClicked(ImGuiMouseButton.Right)) {
                                if (!selected) {
                                    cSelectedBindings.clear();
                                    cSelectedBindings[binding.getTarget()] = binding;
                                }
                                cCompatibleNodes = getCompatibleNodes();
                                igOpenPopup("###BindingPopup");
                            }
                            if (igIsItemClicked(ImGuiMouseButton.Left)) {
                                if (!io.KeyCtrl) {
                                    cSelectedBindings.clear();
                                    selected = false;
                                }
                                if (selected) cSelectedBindings.remove(binding.getTarget());
                                else cSelectedBindings[binding.getTarget()] = binding;
                            }
                    }
                    
                    igTreePop();
                } else if (bindings is null) igPopStyleColor();
            }

            igPopStyleVar();
            igPopStyleVar();
        igEndChild();
    }
    incEndCategory();
}

/**
    Generates a parameter view
*/
void incParameterViewEditButtons(bool armedParam, bool horizontal)(size_t idx, Parameter param, ref Parameter[] paramArr, bool childVisible = true) {
    if (childVisible || armedParam) {
        if (incEditMode == EditMode.ModelEdit) {
            setTransparency(1.0, 1.0);
            if (igBeginPopup("###EditParam")) {
                if (igMenuItem(__("Edit Properties"), "", false, true)) {
                    incPushWindowList(new ParamPropWindow(param));
                }
                
                if (igMenuItem(__("Edit Axes Points"), "", false, true)) {
                    incPushWindowList(new ParamAxesWindow(param));
                }
                
                if (igMenuItem(__("Split"), "", false, true)) {
                    incPushWindowList(new ParamSplitWindow(idx, param));
                }

                if (!param.isVec2 && igMenuItem(__("To 2D"), "", false, true)) {
                    convertTo2D(param);
                }

                if (param.isVec2) {
                    if (igMenuItem(__("Flip X"), "", false, true)) {
                        auto action = new ParameterChangeBindingsAction("Flip X", param, null);
                        param.reverseAxis(0);
                        action.updateNewState();
                        incActionPush(action);
                    }
                    if (igMenuItem(__("Flip Y"), "", false, true)) {
                        auto action = new ParameterChangeBindingsAction("Flip Y", param, null);
                        param.reverseAxis(1);
                        action.updateNewState();
                        incActionPush(action);
                    }
                } else {
                    if (igMenuItem(__("Flip"), "", false, true)) {
                        auto action = new ParameterChangeBindingsAction("Flip", param, null);
                        param.reverseAxis(0);
                        action.updateNewState();
                        incActionPush(action);
                    }
                }
                if (igBeginMenu(__("Mirror"), true)) {
                    if (igMenuItem(__("Horizontally"), "", false, true)) {
                        mirrorAll(param, 0);
                        incViewportNodeDeformNotifyParamValueChanged();
                    }
                    if (igMenuItem(__("Vertically"), "", false, true)) {
                        mirrorAll(param, 1);
                        incViewportNodeDeformNotifyParamValueChanged();
                    }
                    igEndMenu();
                }
                if (igBeginMenu(__("Mirrored Autofill"), true)) {
                    if (igMenuItem("", "", false, true)) {
                        mirroredAutofill(param, 0, 0, 0.4999);
                        incViewportNodeDeformNotifyParamValueChanged();
                    }
                    if (igMenuItem("", "", false, true)) {
                        mirroredAutofill(param, 0, 0.5001, 1);
                        incViewportNodeDeformNotifyParamValueChanged();
                    }
                    if (param.isVec2) {
                        if (igMenuItem("", "", false, true)) {
                            mirroredAutofill(param, 1, 0.5001, 1);
                            incViewportNodeDeformNotifyParamValueChanged();
                        }
                        if (igMenuItem("", "", false, true)) {
                            mirroredAutofill(param, 1, 0, 0.4999);
                            incViewportNodeDeformNotifyParamValueChanged();
                        }
                    }
                    igEndMenu();
                }

                igNewLine();
                igSeparator();

                if (igMenuItem(__("Copy"), "", false, true)) {
                    cClipboardParameter = param.dup;
                }
                if (igMenuItem(__("Paste"), "", false, true)) {
                    pasteParameter(param, 2);
                    incViewportNodeDeformNotifyParamValueChanged();
                }
                if (igMenuItem(__("Paste and Horizontal Flip"), "", false, true)) {
                    pasteParameter(param, 0);
                    incViewportNodeDeformNotifyParamValueChanged();
                }

                if (igMenuItem(__("Duplicate"), "", false, true)) {
                    Parameter newParam = param.dup;
                    incActivePuppet().parameters ~= newParam;
                    if (auto exParam = cast(ExParameter)newParam) {
                        exParam.setParent((cast(ExParameter)param).getParent());
                    }
                    incActionPush(new ParameterAddAction(newParam, &paramArr));
                }

                if (igMenuItem(__("Delete"), "", false, true)) {
                    if (incArmedParameter() == param) {
                        incDisarmParameter();
                    }
                    incActionPush(new ParameterRemoveAction(param, &paramArr));
                    incActivePuppet().removeParameter(param);
                }

                igNewLine();
                igSeparator();

                // Sets the default value of the param
                if (igMenuItem(__("Set Starting Position"), "", false, true)) {
                    auto action = new ParameterValueChangeAction!vec2("axis points", param, &param.defaults);
                    param.defaults = param.value;
                    action.updateNewState();
                    incActionPush(action);
                }
                igEndPopup();
            }
            resetTransparency();
            
            if (igButton("", ImVec2(24, 24))) {
                igOpenPopup("###EditParam");
            }
            
            if (horizontal) {
                igSameLine();
            }
            
            bool isArmed = incArmedParameter() == param;
            if (incButtonColored(isArmed ? "" : "", ImVec2(24, 24), isArmed ? ImVec4(1f, 0f, 0f, 1f) : *igGetStyleColorVec4(ImGuiCol.Text))) {
                if (incArmedParameter() == param) {
                    incDisarmParameter();
                } else {
                    param.value = param.getClosestKeypointValue();
                    paramPointChanged(param);
                    incArmParameter(idx, param);
                }
            }

            // Arms the parameter for recording values.
            incTooltip(_("Arm Parameter"));
        }

        if (incEditMode == EditMode.AnimEdit) {
            if (horizontal) {
                igSameLine();
            }
            igBeginDisabled(incAnimationGet() is null);
                if (igButton("", ImVec2(24, 24))) {
                    if (param.isVec2) {
                        incAnimationKeyframeAdd(param, 0, param.value.vector[0]);
                        incAnimationKeyframeAdd(param, 1, param.value.vector[1]);
                    } else {
                        incAnimationKeyframeAdd(param, 0, param.value.vector[0]);
                    }
                }
                incTooltip(_("Add Keyframe"));
            igEndDisabled();
            
        }
    }
}

void incParameterView(bool armedParam=false, bool showCategory = true, bool fixedWidth = false)(size_t idx, Parameter param, string* grabParam, bool canGroup, ref Parameter[] paramArr, vec3 groupColor = vec3.init) {
    igPushID(cast(void*)param);
    scope(exit) igPopID();

    
    bool open = true;
    if (showCategory) {
        if (!groupColor.isFinite) open = incBeginCategory(param.name.toStringz);
        else open = incBeginCategory(param.name.toStringz, ImVec4(groupColor.r, groupColor.g, groupColor.b, 1));
    }

    if(igBeginDragDropSource(ImGuiDragDropFlags.SourceAllowNullID)) {
        if (!dragDropData) dragDropData = new ParamDragDropData;
        
        dragDropData.param = param;

        igSetDragDropPayload("_PARAMETER", cast(void*)&dragDropData, (&dragDropData).sizeof, ImGuiCond.Always);
        incText(dragDropData.param.name);
        igEndDragDropSource();
    }

    if (canGroup) {
        incBeginDragDropFake();
            auto peek = igAcceptDragDropPayload("_PARAMETER", ImGuiDragDropFlags.AcceptPeekOnly | ImGuiDragDropFlags.SourceAllowNullID);
            if(peek && peek.Data && (*cast(ParamDragDropData**)peek.Data).param != param) {
                if (igBeginDragDropTarget()) {
                    auto payload = igAcceptDragDropPayload("_PARAMETER");
                    
                    if (payload !is null) {
                        ParamDragDropData* payloadParam = *cast(ParamDragDropData**)payload.Data;

                        auto group = incCreateParamGroup(cast(int)idx);
                        incMoveParameter(param, group);
                        incMoveParameter(payloadParam.param, group);
                    }
                    igEndDragDropTarget();
                }
            }
        incEndDragDropFake();
    }

    if (open) {
        // Push color scheme
        if (groupColor.isFinite) pushColorScheme(groupColor);

        float reqSpace = param.isVec2 ? 144 : 52;

        // Parameter Control
        ImVec2 avail = incAvailableSpace();

        // We want to always show armed parameters but also make sure the child is begun.
        bool childVisible = true;
        float width = fixedWidth? 156: avail.x-24;
        float height = fixedWidth? (param.isVec2? 132: 52): reqSpace - 24;
        if (showCategory) {
            childVisible = igBeginChild("###PARAM", ImVec2(width, reqSpace));
        }
        if (childVisible || armedParam) {

            // Popup for rightclicking the controller
            if (igBeginPopup("###ControlPopup")) {
                if (incArmedParameter() == param) {
                    incKeypointActions(param, param.bindings, null);
                }
                igEndPopup();
            }

            if (param.isVec2) incText("%.2f %.2f".format(param.value.x, param.value.y));
            else incText("%.2f".format(param.value.x));

            if (incController("###CONTROLLER", param, ImVec2(width, height), incArmedParameter() == param, *grabParam)) {
                if (incArmedParameter() == param) {
                    auto onion = OnionSlice.singleton;
                    onion.capture(cParamPoint);

                    incViewportNodeDeformNotifyParamValueChanged();
                    paramPointChanged(param);
                }
                if (igIsMouseDown(ImGuiMouseButton.Left)) {
                    if (*grabParam == null)
                        *grabParam = param.name;
                } else {
                    *grabParam = "";
                }
            }
            if (igIsItemClicked(ImGuiMouseButton.Right)) {
                if (incArmedParameter() == param) incViewportNodeDeformNotifyParamValueChanged();
                refreshBindingList(param);
                igOpenPopup("###ControlPopup");
            }
        }
        if (showCategory) {
            igEndChild();
        }

            igSameLine(0, 0);

            // Parameter Setting Buttons
            if (showCategory) {
                childVisible = igBeginChild("###SETTING", ImVec2(24, reqSpace), false);
                incParameterViewEditButtons!(armedParam, false)(idx, param, paramArr, childVisible);
                igEndChild();
            }
        if (showCategory) {
            if (incArmedParameter() == param) {
                incBindingList(param);
            }
        }
        if (groupColor.isFinite) popColorScheme();
    }
    if (showCategory)
        incEndCategory();
}

bool incParameterGropuMenuContents(ExParameterGroup group) {
    bool result = false;
    if (igMenuItem(__("Rename"))) {
        incPushWindow(new RenameWindow(group.name));
    }

    if (igBeginMenu(__("Colors"))) {
        auto flags = ImGuiColorEditFlags.NoLabel | ImGuiColorEditFlags.NoTooltip;
        ImVec2 swatchSize = ImVec2(24, 24);

        // COLOR SWATCHES
        if (igColorButton("NONE", ImVec4(0, 0, 0, 0), flags | ImGuiColorEditFlags.AlphaPreview, swatchSize)) group.color = vec3(float.nan, float.nan, float.nan);
        igSameLine(0, 4);
        if (igColorButton("RED", ImVec4(1, 0, 0, 1), flags, swatchSize)) group.color = vec3(0.25, 0.15, 0.15);
        igSameLine(0, 4);
        if (igColorButton("GREEN", ImVec4(0, 1, 0, 1), flags, swatchSize)) group.color = vec3(0.15, 0.25, 0.15);
        igSameLine(0, 4);
        if (igColorButton("BLUE", ImVec4(0, 0, 1, 1), flags, swatchSize)) group.color = vec3(0.15, 0.15, 0.25);
        igSameLine(0, 4);
        if (igColorButton("PURPLE", ImVec4(1, 0, 1, 1), flags, swatchSize)) group.color = vec3(0.25, 0.15, 0.25);
        igSameLine(0, 4);
        if (igColorButton("CYAN", ImVec4(0, 1, 1, 1), flags, swatchSize)) group.color = vec3(0.15, 0.25, 0.25);
        igSameLine(0, 4);
        if (igColorButton("YELLOW", ImVec4(1, 1, 0, 1), flags, swatchSize)) group.color = vec3(0.25, 0.25, 0.15);
        igSameLine(0, 4);
        if (igColorButton("WHITE", ImVec4(1, 1, 1, 1), flags, swatchSize)) group.color = vec3(0.25, 0.25, 0.25);
        
        igSpacing();

        // CUSTOM COLOR PICKER
        // Allows user to select a custom color for parameter group.
        igColorPicker3(__("Custom Color"), &group.color.vector, ImGuiColorEditFlags.InputRGB | ImGuiColorEditFlags.DisplayHSV);
        igEndMenu();
    }

    if (igMenuItem(__("Delete"))) {
        foreach(child; group.children) {
            auto exChild = cast(ExParameter)child;
            exChild.setParent(null);
        }
        (cast(ExPuppet)incActivePuppet()).removeGroup(group);
        
        // End early.
        result = true;
    }
    return result;
}

void incParameterMenuContents(Parameter[] parameters) {
    if (igMenuItem(__("Add 1D Parameter (0..1)"), "", false, true)) {
        Parameter param = new ExParameter(
            "Param #%d\0".format(parameters.length),
            false
        );
        incActivePuppet().parameters ~= param;
        incActionPush(new ParameterAddAction(param, &incActivePuppet().parameters));
    }
    if (igMenuItem(__("Add 1D Parameter (-1..1)"), "", false, true)) {
        Parameter param = new ExParameter(
            "Param #%d\0".format(parameters.length),
            false
        );
        param.min.x = -1;
        param.max.x = 1;
        param.insertAxisPoint(0, 0.5);
        incActivePuppet().parameters ~= param;
        incActionPush(new ParameterAddAction(param, &incActivePuppet().parameters));
    }
    if (igMenuItem(__("Add 2D Parameter (0..1)"), "", false, true)) {
        Parameter param = new ExParameter(
            "Param #%d\0".format(parameters.length),
            true
        );
        incActivePuppet().parameters ~= param;
        incActionPush(new ParameterAddAction(param, &incActivePuppet().parameters));
    }
    if (igMenuItem(__("Add 2D Parameter (-1..+1)"), "", false, true)) {
        Parameter param = new ExParameter(
            "Param #%d\0".format(parameters.length),
            true
        );
        param.min = vec2(-1, -1);
        param.max = vec2(1, 1);
        param.insertAxisPoint(0, 0.5);
        param.insertAxisPoint(1, 0.5);
        incActivePuppet().parameters ~= param;
        incActionPush(new ParameterAddAction(param, &incActivePuppet().parameters));
    }
    if (igMenuItem(__("Add Mouth Shape"), "", false, true)) {
        Parameter param = new ExParameter(
            "Mouth #%d\0".format(parameters.length),
            true
        );
        param.min = vec2(-1, 0);
        param.max = vec2(1, 1);
        param.insertAxisPoint(0, 0.25);
        param.insertAxisPoint(0, 0.5);
        param.insertAxisPoint(0, 0.6);
        param.insertAxisPoint(1, 0.3);
        param.insertAxisPoint(1, 0.5);
        param.insertAxisPoint(1, 0.6);
        incActivePuppet().parameters ~= param;
        incActionPush(new ParameterAddAction(param, &incActivePuppet().parameters));
    }
}

/**
    The logger frame
*/
class ParametersPanel : Panel {
private:
    string filter;
    string grabParam = "";
protected:
    override
    void onUpdate() {
        if (incEditMode == EditMode.VertexEdit) {
            incLabelOver(_("In vertex edit mode..."), ImVec2(0, 0), true);
            return;
        }

        auto parameters = incActivePuppet().parameters;
        auto exPuppet = cast(ExPuppet)incActivePuppet();
        auto groups = (exPuppet !is null)? exPuppet.groups: [];

        if (igBeginPopup("###AddParameter")) {
            incParameterMenuContents(parameters);
            igEndPopup();
        }
        if (igBeginChild("###FILTER", ImVec2(0, 32))) {
            if (incInputText("Filter", filter)) {
                filter = filter.toLower;
            }
            incTooltip(_("Filter, search for specific parameters"));
        }
        igEndChild();

        if (igBeginChild("ParametersList", ImVec2(0, -36))) {
            
            // Always render the currently armed parameter on top
            if (incArmedParameter()) {
                incParameterView!true(incArmedParameterIdx(), incArmedParameter(), &grabParam, false, parameters);
            }

            // Render other parameters
            void displayParameters(Parameter[] targetParams, bool hideChildren) {
                foreach(i, ref param; targetParams) {
                    if (incArmedParameter() == param) continue;
                    if (hideChildren && (cast(ExParameter)param) && (cast(ExParameter)param).parent) continue;
                    import std.algorithm.searching : canFind;
                    ExParameterGroup group = cast(ExParameterGroup)param;
                    bool found = filter.length == 0 || param.indexableName.canFind(filter);
                    if (group) {
                        foreach (ix, ref child; group.children) {
                            if (incArmedParameter() == child) continue;
                            if (child.indexableName.canFind(filter))
                                found = true;
                        }
                    }
                    if (found) {
                        if (group) {
                            igPushID(group.uuid);

                                bool open;
                                if (group.color.isFinite) open = incBeginCategory(group.name.toStringz, ImVec4(group.color.r, group.color.g, group.color.b, 1));
                                else open = incBeginCategory(group.name.toStringz);
                                
                                if (igIsItemClicked(ImGuiMouseButton.Right)) {
                                    igOpenPopup("###CategorySettings");
                                }

                                // Popup
                                if (igBeginPopup("###CategorySettings")) {
                                    bool deleted = incParameterGropuMenuContents(group);
                                    igEndPopup();
                                    if (deleted) {
                                        incEndCategory();
                                        igPopID();
                                        continue;
                                    }
                                }

                                // Allow drag/drop in to the category
                                if (igBeginDragDropTarget()) {
                                    auto payload = igAcceptDragDropPayload("_PARAMETER");
                                    
                                    if (payload !is null) {
                                        ParamDragDropData* payloadParam = *cast(ParamDragDropData**)payload.Data;
                                        incMoveParameter(payloadParam.param, group);
                                    }
                                    igEndDragDropTarget();
                                }

                                // Render children if open
                                if (open) {
                                    foreach(ix, ref child; group.children) {

                                        // Skip armed param
                                        if (incArmedParameter() == child) continue;
                                        if (child.indexableName.canFind(filter)) {
                                            // Otherwise render it
                                            incParameterView(ix, child, &grabParam, false, group.children, group.color);
                                        }
                                    }
                                }
                                incEndCategory();
                            igPopID();
                        } else {
                            incParameterView(i, param, &grabParam, true, incActivePuppet().parameters);
                        }
                    }
                }
            }
            displayParameters(cast(Parameter[])groups, false);
            displayParameters(parameters, true);
        }
        igEndChild();
        
        // Allow drag/drop out of categories
        if (igBeginDragDropTarget()) {
            auto payload = igAcceptDragDropPayload("_PARAMETER");
            
            if (payload !is null) {
                ParamDragDropData* payloadParam = *cast(ParamDragDropData**)payload.Data;
                incMoveParameter(payloadParam.param, null);
            }
            igEndDragDropTarget();
        }

        // Right align add button
        ImVec2 avail = incAvailableSpace();
        incDummy(ImVec2(avail.x-32, 32));
        igSameLine(0, 0);

        // Add button
        if (igButton("", ImVec2(32, 32))) {
            igOpenPopup("###AddParameter");
        }
        incTooltip(_("Add Parameter"));
    }

public:
    this() {
        super("Parameters", _("Parameters"), false);
    }
}

vec2u incParamPoint() {
    return cParamPoint;
}

/**
    Generate logger frame
*/
mixin incPanel!ParametersPanel;
