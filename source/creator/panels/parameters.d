/*
    Copyright © 2020, Inochi2D Project
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
import creator;
import std.string;
import inochi2d;
import i18n;
import std.uni : toLower;
import std.stdio;
import creator.utils;
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

    void refreshBindingList(Parameter param) {
        // Filter selection to remove anything that went away
        ParameterBinding[BindTarget] newSelectedBindings;

        cParamBindingEntriesAll.clear();
        foreach(ParameterBinding binding; param.bindings) {
            BindTarget target = binding.getTarget();
            if (target in cSelectedBindings) newSelectedBindings[target] = binding;
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
        auto action = new ParameterChangeBindingsAction("Mirror Auto Fill", param, null);
        foreach(ParameterBinding binding; param.bindings) {
            uint xCount = param.axisPointCount(0);
            uint yCount = param.axisPointCount(1);
            foreach(x; 0..xCount) {
                float offX = param.axisPoints[0][x];
                if (axis == 0 && (offX < min || offX > max)) continue;
                foreach(y; 0..yCount) {
                    float offY = param.axisPoints[1][x];
                    if (axis == 1 && (offY < min || offY > max)) continue;

                    vec2u index = vec2u(x, y);
                    if (!binding.isSet(index)) binding.extrapolateValueAt(index, axis);
                }
            }
        }
        action.updateNewState();
        incActionPush(action);
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

    void keypointActions(Parameter param, ParameterBinding[] bindings) {
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
        if (param.isVec2) {
            if (igBeginMenu(__("Set from mirror"), true)) {
                if (igMenuItem(__("Horizontally"), "", false, true)) {
                    auto action = new ParameterChangeBindingsValueAction("set From Mirror (Horizontally)", param, bindings, cParamPoint.x, cParamPoint.y);
                    foreach(binding; bindings) {
                        binding.extrapolateValueAt(cParamPoint, 0);
                    }
                    action.updateNewState();
                    incActionPush(action);
                    incViewportNodeDeformNotifyParamValueChanged();
                }
                if (igMenuItem(__("Vertically"), "", false, true)) {
                    auto action = new ParameterChangeBindingsValueAction("set From Mirror (Vertically)", param, bindings, cParamPoint.x, cParamPoint.y);
                    foreach(binding; bindings) {
                        binding.extrapolateValueAt(cParamPoint, 1);
                    }
                    action.updateNewState();
                    incActionPush(action);
                    incViewportNodeDeformNotifyParamValueChanged();
                }
                if (igMenuItem(__("Diagonally"), "", false, true)) {
                    auto action = new ParameterChangeBindingsValueAction("set From Mirror (Diagonally)", param, bindings, cParamPoint.x, cParamPoint.y);
                    foreach(binding; bindings) {
                        binding.extrapolateValueAt(cParamPoint, -1);
                    }
                    action.updateNewState();
                    incActionPush(action);
                    incViewportNodeDeformNotifyParamValueChanged();
                }
                igEndMenu();
            }
        } else {
            if (igMenuItem(__("Set from mirror"), "", false, true)) {
                auto action = new ParameterChangeBindingsValueAction("set From Mirror", param, bindings, cParamPoint.x, cParamPoint.y);
                foreach(binding; bindings) {
                    binding.extrapolateValueAt(cParamPoint, 0);
                }
                action.updateNewState();
                incActionPush(action);
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
            if (bindings.length == 1 && cClipboardBindings.length == 1 &&
                bindings[0].isCompatibleWithNode(cClipboardBindings.values[0].getNode())) {
                auto action = new ParameterChangeBindingsValueAction("set From Mirror", param, bindings,cParamPoint.x, cParamPoint.y);
                cClipboardBindings.values[0].copyKeypointToBinding(cClipboardPoint, bindings[0], cParamPoint);
                action.updateNewState();
                incActionPush(action);
            } else {
                foreach(binding; bindings) {
                    if (binding.getTarget() in cClipboardBindings) {
                        auto action = new ParameterChangeBindingsValueAction("set From Mirror", param, bindings, cParamPoint.x, cParamPoint.y);
                        ParameterBinding origBinding = cClipboardBindings[binding.getTarget()];
                        origBinding.copyKeypointToBinding(cClipboardPoint, binding, cParamPoint);
                    }
                }
            }
        }

    }

    void bindingList(Parameter param) {
        if (!igCollapsingHeader(__("Bindings"), ImGuiTreeNodeFlags.DefaultOpen)) return;

        refreshBindingList(param);

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
                        if (igMenuItem(__("Remove"), "", false, true)) {
                            auto action = new GroupAction();
                            foreach(binding; cSelectedBindings.byValue()) {
                                action.addAction(new ParameterBindingRemoveAction(param, binding));
                                param.removeBinding(binding);
                            }
                            incActionPush(action);
                            incViewportNodeDeformNotifyParamValueChanged();
                        }

                        keypointActions(param, cSelectedBindings.values);

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

    ptrdiff_t findParamIndex(ref Parameter[] paramArr, Parameter param) {
        import std.algorithm.searching : countUntil;
        ptrdiff_t idx = paramArr.countUntil(param);
        return idx;
    }
    ParamDragDropData* dragDropData;
}

struct ParamDragDropData {
    Parameter param;
    Parameter[]* paramArr;
}

/**
    Generates a parameter view
*/
void incParameterView(bool armedParam=false)(size_t idx, Parameter param, string* grabParam, bool canGroup, ref Parameter[] paramArr, vec3 groupColor = vec3.init) {
    igPushID(cast(void*)param);
    scope(exit) igPopID();

    
    bool open;
    if (!groupColor.isFinite) open = incBeginCategory(param.name.toStringz);
    else open = incBeginCategory(param.name.toStringz, ImVec4(groupColor.r, groupColor.g, groupColor.b, 1));
    if(igBeginDragDropSource(ImGuiDragDropFlags.SourceAllowNullID)) {
        if (!dragDropData) dragDropData = new ParamDragDropData;
        
        dragDropData.param = param;
        dragDropData.paramArr = &paramArr;

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
                        ptrdiff_t idx2 = (*payloadParam.paramArr).findParamIndex(payloadParam.param);
                        if (idx2 >= 0) {
                            paramArr[idx] = new ExParameterGroup(_("New Parameter Group"), [param, payloadParam.param]);
                            (*payloadParam.paramArr) = (*payloadParam.paramArr).remove(idx2);
                        }
                    }
                    igEndDragDropTarget();
                }
            }
        incEndDragDropFake();
    }

    if (open) {
        float reqSpace = param.isVec2 ? 144 : 52;

        // Parameter Control
        ImVec2 avail = incAvailableSpace();

        // We want to always show armed parameters but also make sure the child is begun.
        bool childVisible = igBeginChild("###PARAM", ImVec2(avail.x-24, reqSpace));
        if (childVisible || armedParam) {

            // Popup for rightclicking the controller
            if (igBeginPopup("###ControlPopup")) {
                if (incArmedParameter() == param) {
                    keypointActions(param, param.bindings);
                }
                igEndPopup();
            }

            if (param.isVec2) incText("%.2f %.2f".format(param.value.x, param.value.y));
            else incText("%.2f".format(param.value.x));

            if (incController("###CONTROLLER", param, ImVec2(avail.x-24, reqSpace-24), incArmedParameter() == param, *grabParam)) {
                if (incArmedParameter() == param) {
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
        igEndChild();


        if (incEditMode == EditMode.ModelEdit) {
            igSameLine(0, 0);

            // Parameter Setting Buttons
            childVisible = igBeginChild("###SETTING", ImVec2(24, reqSpace), false);
            if (childVisible || armedParam) {
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
                        if (igMenuItem(__(""), "", false, true)) {
                            mirroredAutofill(param, 0, 0, 0.4999);
                            incViewportNodeDeformNotifyParamValueChanged();
                        }
                        if (igMenuItem(__(""), "", false, true)) {
                            mirroredAutofill(param, 0, 0.5001, 1);
                            incViewportNodeDeformNotifyParamValueChanged();
                        }
                        if (param.isVec2) {
                            if (igMenuItem(__(""), "", false, true)) {
                                mirroredAutofill(param, 1, 0, 0.4999);
                                incViewportNodeDeformNotifyParamValueChanged();
                            }
                            if (igMenuItem(__(""), "", false, true)) {
                                mirroredAutofill(param, 1, 0.5001, 1);
                                incViewportNodeDeformNotifyParamValueChanged();
                            }
                        }
                        igEndMenu();
                    }

                    igNewLine();
                    igSeparator();

                    if (igMenuItem(__("Duplicate"), "", false, true)) {
                        Parameter newParam = param.dup;
                        incActivePuppet().parameters ~= newParam;
                        incActionPush(new ParameterAddAction(newParam));
                    }

                    if (igMenuItem(__("Delete"), "", false, true)) {
                        if (incArmedParameter() == param) {
                            incDisarmParameter();
                        }
                        incActivePuppet().removeParameter(param);
                        incActionPush(new ParameterRemoveAction(param));
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
                
                if (igButton("", ImVec2(24, 24))) {
                    igOpenPopup("###EditParam");
                }
                
                
                if (incButtonColored("", ImVec2(24, 24), incArmedParameter() == param ? ImVec4(1f, 0f, 0f, 1f) : *igGetStyleColorVec4(ImGuiCol.Text))) {
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
            igEndChild();
        }
        if (incArmedParameter() == param) {
            bindingList(param);
        }
    }
    incEndCategory();
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
        auto parameters = incActivePuppet().parameters;

        if (igBeginPopup("###AddParameter")) {
            if (igMenuItem(__("Add 1D Parameter (0..1)"), "", false, true)) {
                Parameter param = new Parameter(
                    "Param #%d\0".format(parameters.length),
                    false
                );
                incActivePuppet().parameters ~= param;
                incActionPush(new ParameterAddAction(param));
            }
            if (igMenuItem(__("Add 1D Parameter (-1..1)"), "", false, true)) {
                Parameter param = new Parameter(
                    "Param #%d\0".format(parameters.length),
                    false
                );
                param.min.x = -1;
                param.max.x = 1;
                param.insertAxisPoint(0, 0.5);
                incActivePuppet().parameters ~= param;
                incActionPush(new ParameterAddAction(param));
            }
            if (igMenuItem(__("Add 2D Parameter (0..1)"), "", false, true)) {
                Parameter param = new Parameter(
                    "Param #%d\0".format(parameters.length),
                    true
                );
                incActivePuppet().parameters ~= param;
                incActionPush(new ParameterAddAction(param));
            }
            if (igMenuItem(__("Add 2D Parameter (-1..+1)"), "", false, true)) {
                Parameter param = new Parameter(
                    "Param #%d\0".format(parameters.length),
                    true
                );
                param.min = vec2(-1, -1);
                param.max = vec2(1, 1);
                param.insertAxisPoint(0, 0.5);
                param.insertAxisPoint(1, 0.5);
                incActivePuppet().parameters ~= param;
                incActionPush(new ParameterAddAction(param));
            }
            if (igMenuItem(__("Add Mouth Shape"), "", false, true)) {
                Parameter param = new Parameter(
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
                incActionPush(new ParameterAddAction(param));
            }
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
            foreach(i, ref param; parameters) {
                if (incArmedParameter() == param) continue;
                import std.algorithm.searching : canFind;
                if (filter.length == 0 || param.indexableName.canFind(filter)) {
                    if (ExParameterGroup group = cast(ExParameterGroup)param) {
                        igPushID(group.uuid);

                            bool open;
                            if (group.color.isFinite) open = incBeginCategory(group.name.toStringz, ImVec4(group.color.r, group.color.g, group.color.b, 1));
                            else open = incBeginCategory(group.name.toStringz);
                            
                            if (igIsItemClicked(ImGuiMouseButton.Right)) {
                                igOpenPopup("###CategorySettings");
                            }

                            // Popup
                            if (igBeginPopup("###CategorySettings")) {
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
                                    if (i == 0) incActivePuppet().parameters = group.children ~ parameters[i+1..$];
                                    else if (i+1 == parameters.length) incActivePuppet().parameters = parameters[0..$-1] ~ group.children;
                                    else incActivePuppet().parameters = parameters[0..i] ~ group.children ~ parameters[i+1..$];
                                    igEndPopup();
                                    igPopID();
                                    continue;
                                }
                                igEndPopup();
                            }

                            // Allow drag/drop in to the category
                            if (igBeginDragDropTarget()) {
                                auto payload = igAcceptDragDropPayload("_PARAMETER");
                                
                                if (payload !is null) {
                                    ParamDragDropData* payloadParam = *cast(ParamDragDropData**)payload.Data;
                                    ptrdiff_t idx2 = (*payloadParam.paramArr).findParamIndex(payloadParam.param);
                                    if (idx2 >= 0) {
                                        (*payloadParam.paramArr) = (*payloadParam.paramArr).remove(idx2);
                                        group.children = payloadParam.param ~ group.children;
                                    }
                                }
                                igEndDragDropTarget();
                            }

                            // Render children if open
                            if (open) {
                                foreach(ix, ref child; group.children) {
                                    incParameterView(ix, child, &grabParam, false, group.children, group.color);
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
        igEndChild();
        
        // Allow drag/drop out of categories
        if (igBeginDragDropTarget()) {
            auto payload = igAcceptDragDropPayload("_PARAMETER");
            
            if (payload !is null) {
                ParamDragDropData* payloadParam = *cast(ParamDragDropData**)payload.Data;
                ptrdiff_t idx2 = (*payloadParam.paramArr).findParamIndex(payloadParam.param);
                if (idx2 >= 0) {
                    (*payloadParam.paramArr) = (*payloadParam.paramArr).remove(idx2);
                }

                incActivePuppet().parameters = payloadParam.param~parameters;
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

/**
    Generate logger frame
*/
mixin incPanel!ParametersPanel;
