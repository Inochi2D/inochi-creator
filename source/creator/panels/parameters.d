/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.parameters;
import creator.viewport.model.deform;
import creator.panels;
import creator.widgets;
import creator.windows;
import creator.core;
import creator;
import std.string;
import inochi2d;
import i18n;
import std.uni : toLower;
import std.stdio;
import creator.utils;

private {
    ParameterBinding[][Node] cParamBindingEntries;
    ParameterBinding[][Node] cParamBindingEntriesAll;
    ParameterBinding[BindTarget] cSelectedBindings;
    Node[] cCompatibleNodes;
    vec2u cParamPoint;

    void refreshBindingList(Parameter param) {
        // Filter selection to remove anything that went away
        ParameterBinding[BindTarget] newSelectedBindings;

        cParamBindingEntriesAll.clear();
        foreach(ParameterBinding binding; param.bindings) {
            BindTarget target = binding.getTarget();
            if (target in cSelectedBindings) newSelectedBindings[target] = binding;
            cParamBindingEntriesAll[binding.getNode()] ~= binding;
        }
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
    }

    void mirroredAutofill(Parameter param, uint axis, float min, float max) {
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
    }

    void fixScales(Parameter param) {
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
            foreach(binding; bindings) {
                binding.unset(cParamPoint);
            }
            incViewportNodeDeformNotifyParamValueChanged();
        }
        if (igMenuItem(__("Set to current"), "", false, true)) {
            foreach(binding; bindings) {
                binding.setCurrent(cParamPoint);
            }
            incViewportNodeDeformNotifyParamValueChanged();
        }
        if (igMenuItem(__("Reset"), "", false, true)) {
            foreach(binding; bindings) {
                binding.reset(cParamPoint);
            }
            incViewportNodeDeformNotifyParamValueChanged();
        }
        if (igMenuItem(__("Invert"), "", false, true)) {
            foreach(binding; bindings) {
                binding.scaleValueAt(cParamPoint, -1, -1);
            }
            incViewportNodeDeformNotifyParamValueChanged();
        }
        if (param.isVec2) {
            if (igBeginMenu(__("Mirror"), true)) {
                if (igMenuItem(__("Horizontally"), "", false, true)) {
                    foreach(binding; bindings) {
                        binding.scaleValueAt(cParamPoint, 0, -1);
                    }
                    incViewportNodeDeformNotifyParamValueChanged();
                }
                if (igMenuItem(__("Vertically"), "", false, true)) {
                    foreach(binding; bindings) {
                        binding.scaleValueAt(cParamPoint, 1, -1);
                    }
                    incViewportNodeDeformNotifyParamValueChanged();
                }
                igEndMenu();
            }
        }
        if (param.isVec2) {
            if (igBeginMenu(__("Set from mirror"), true)) {
                if (igMenuItem(__("Horizontally"), "", false, true)) {
                    foreach(binding; bindings) {
                        binding.extrapolateValueAt(cParamPoint, 0);
                    }
                    incViewportNodeDeformNotifyParamValueChanged();
                }
                if (igMenuItem(__("Vertically"), "", false, true)) {
                    foreach(binding; bindings) {
                        binding.extrapolateValueAt(cParamPoint, 1);
                    }
                    incViewportNodeDeformNotifyParamValueChanged();
                }
                if (igMenuItem(__("Diagonally"), "", false, true)) {
                    foreach(binding; bindings) {
                        binding.extrapolateValueAt(cParamPoint, -1);
                    }
                    incViewportNodeDeformNotifyParamValueChanged();
                }
                igEndMenu();
            }
        } else {
            if (igMenuItem(__("Set from mirror"), "", false, true)) {
                foreach(binding; bindings) {
                    binding.extrapolateValueAt(cParamPoint, 0);
                }
                incViewportNodeDeformNotifyParamValueChanged();
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

            foreach(node, allBindings; cParamBindingEntriesAll) {
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
                string nodeName = incTypeIdToIconConcat(node.typeId) ~ " " ~ node.name;
                if (igTreeNodeEx(cast(void*)node.uuid, flags, nodeName.toStringz)) {
                    if (bindings is null) igPopStyleColor();
                    if (igBeginPopup("###BindingPopup")) {
                        if (igMenuItem(__("Remove"), "", false, true)) {
                            foreach(binding; cSelectedBindings.byValue()) {
                                param.removeBinding(binding);
                            }
                            incViewportNodeDeformNotifyParamValueChanged();
                        }

                        keypointActions(param, cSelectedBindings.values);

                        bool haveCompatible = cCompatibleNodes.length > 0;
                        if (igBeginMenu(__("Copy to"), haveCompatible)) {
                            foreach(node; cCompatibleNodes) {
                                if (igMenuItem(node.name.toStringz, "", false, true)) {
                                    copySelectionToNode(param, node);
                                }
                            }
                            igEndMenu();
                        }
                        if (igBeginMenu(__("Swap with"), haveCompatible)) {
                            foreach(node; cCompatibleNodes) {
                                if (igMenuItem(node.name.toStringz, "", false, true)) {
                                    swapSelectionWithNode(param, node);
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
                    foreach(binding; allBindings) {
                        ImGuiTreeNodeFlags flags =
                            ImGuiTreeNodeFlags.DefaultOpen | ImGuiTreeNodeFlags.OpenOnArrow |
                            ImGuiTreeNodeFlags.Leaf | ImGuiTreeNodeFlags.NoTreePushOnOpen;

                        bool selected = cast(bool)(binding.getTarget() in cSelectedBindings);
                        if (selected) flags |= ImGuiTreeNodeFlags.Selected;

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
                        igTreeNodeEx("binding", flags, label.toStringz);
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

}

/**
    Generates a parameter view
*/
void incParameterView(Parameter param) {
    if (!igCollapsingHeader(param.name.toStringz, ImGuiTreeNodeFlags.DefaultOpen)) return;
    igIndent();
        igPushID(cast(void*)param);

            float reqSpace = param.isVec2 ? 144 : 52;

            // Parameter Control
            ImVec2 avail = incAvailableSpace();
            if (igBeginChild("###PARAM", ImVec2(avail.x-24, reqSpace))) {
                // Popup for rightclicking the controller
                if (igBeginPopup("###ControlPopup")) {
                    if (incArmedParameter() == param) {
                        keypointActions(param, param.bindings);
                    }
                    igEndPopup();
                }

                if (param.isVec2) igText("%.2f %.2f", param.value.x, param.value.y);
                else igText("%.2f", param.value.x);

                if (incController("###CONTROLLER", param, ImVec2(avail.x-18, reqSpace-24), incArmedParameter() == param)) {
                    if (incArmedParameter() == param) {
                        incViewportNodeDeformNotifyParamValueChanged();
                        paramPointChanged(param);
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
                if(igBeginChild("###SETTING", ImVec2(avail.x-24, reqSpace))) {
                    if (igBeginPopup("###EditParam")) {
                        if (igMenuItem(__("Edit Properties"), "", false, true)) {
                            incPushWindowList(new ParamPropWindow(param));
                        }
                        
                        if (igMenuItem(__("Edit Axes Points"), "", false, true)) {
                            incPushWindowList(new ParamAxesWindow(param));
                        }

                        if (param.isVec2) {
                            if (igMenuItem(__("Flip X"), "", false, true)) {
                                param.reverseAxis(0);
                            }
                            if (igMenuItem(__("Flip Y"), "", false, true)) {
                                param.reverseAxis(1);
                            }
                        } else {
                            if (igMenuItem(__("Flip"), "", false, true)) {
                                param.reverseAxis(0);
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

                        if (igMenuItem(__("Delete"), "", false, true)) {
                            if (incArmedParameter() == param) {
                                incDisarmParameter();
                            }
                            incActivePuppet().removeParameter(param);
                        }

                        igNewLine();
                        igSeparator();

                        if (igMenuItem(__("Fix Scales"), "", false, true)) {
                            fixScales(param);
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
                            incArmParameter(param);
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
        igPopID();
    igUnindent();
}

/**
    The logger frame
*/
class ParametersPanel : Panel {
private:
    string filter;
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
            }
            if (igMenuItem(__("Add 2D Parameter (0..1)"), "", false, true)) {
                Parameter param = new Parameter(
                    "Param #%d\0".format(parameters.length),
                    true
                );
                incActivePuppet().parameters ~= param;
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
            }
            igEndPopup();
        }
        if (igBeginChild("###FILTER", ImVec2(0, 32))) {
            if (incInputText("Filter", filter)) {
                filter = filter.toLower;
            }
            incTooltip("Filter, search for specific parameters");
        }
        igEndChild();

        if (igBeginChild("ParametersList", ImVec2(0, -36))) {
            
            // Always render the currently armed parameter on top
            if (incArmedParameter()) {
                incParameterView(incArmedParameter());
            }

            // Render other parameters
            foreach(ref param; parameters) {
                if (incArmedParameter() == param) continue;
                import std.algorithm.searching : canFind;
                if (filter.length == 0 || param.indexableName.canFind(filter)) {
                    incParameterView(param);
                }
            }
        }
        igEndChild();

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


