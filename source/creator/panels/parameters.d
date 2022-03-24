/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.parameters;
import creator.panels;
import creator.widgets;
import creator.windows;
import creator;
import std.string;
import inochi2d;
import i18n;
import std.uni : toLower;

private {
    ParameterBinding[][Node] cParamBindingEntries;
    ParameterBinding[][Node] cParamBindingEntriesAll;
    vec2u cParamPoint;
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
                        if (cParamBindingEntries.length > 0) {
                            if (igBeginMenu(__("Unlink"), true)) {
                                foreach(node, bindingList; cParamBindingEntries) {
                                    if (igBeginMenu(node.name.toStringz, true)) {
                                        foreach(ParameterBinding binding; bindingList) {
                                            if (auto dparam = cast(DeformationParameterBinding)binding) {
                                                if (igMenuItem(_("deform (%s)".format(node.name)).toStringz, "", false, true)) {
                                                    dparam.unset(cParamPoint);
                                                }
                                            } else if (auto vparam = cast(ValueParameterBinding)binding) {
                                                if (igMenuItem(vparam.getName().toStringz, "", false, true)) {
                                                    vparam.unset(cParamPoint);
                                                }
                                            }
                                            
                                            // Remove unused bindings.
                                            if (binding.getSetCount() == 0) {
                                                param.removeBinding(binding);
                                            }
                                        }
                                        igEndMenu();
                                    }
                                }
                                igEndMenu();
                            }
                        }

                        if (cParamBindingEntriesAll.length > 0) {
                            if (igBeginMenu(__("Unlink All"), true)) {
                                foreach(node, bindingList; cParamBindingEntriesAll) {
                                    if (igBeginMenu(node.name.toStringz, true)) {
                                        foreach(ParameterBinding binding; bindingList) {
                                            if (auto dparam = cast(DeformationParameterBinding)binding) {
                                                if (igMenuItem(_("deform (%s)".format(node.name)).toStringz, "", false, true)) {
                                                    param.removeBinding(dparam);
                                                }
                                            } else if (auto vparam = cast(ValueParameterBinding)binding) {
                                                if (igMenuItem(vparam.getName().toStringz, "", false, true)) {
                                                    param.removeBinding(vparam);
                                                }
                                            }
                                        }
                                        igEndMenu();
                                    }
                                }
                                igEndMenu();
                            }
                        }
                    }

                    igEndPopup();
                }

                if (param.isVec2) igText("%.2f %.2f", param.value.x, param.value.y);
                else igText("%.2f", param.value.x);

                incController("###CONTROLLER", param, ImVec2(avail.x-18, reqSpace-24), incArmedParameter() == param);
                if (igIsItemClicked(ImGuiMouseButton.Right)) {
                    cParamBindingEntries.clear();
                    cParamBindingEntriesAll.clear();

                    cParamPoint = param.getClosestBreakpoint();
                    foreach(ParameterBinding binding; param.bindings) {
                        cParamBindingEntriesAll[binding.getNode()] ~= binding;
                        if (binding.getIsSet()[cParamPoint.x][cParamPoint.y]) {
                            cParamBindingEntries[binding.getNode()] ~= binding;
                        }
                    }
                    igOpenPopup("###ControlPopup");
                }
                igEndChild();
            }

            igSameLine(0, 0);

            if (incEditMode == EditMode.ModelEdit) {
                // Parameter Setting Buttons
                if(igBeginChild("###SETTING", ImVec2(avail.x-24, reqSpace))) {
                    if (igBeginPopup("###EditParam")) {
                        if (igMenuItem(__("Edit Properties"), "", false, true)) {
                            incPushWindowList(new ParamPropWindow(param));
                        }
                        
                        if (igMenuItem(__("Edit Axes Points"), "", false, true)) {
                            incPushWindowList(new ParamAxesWindow(param));
                        }

                        igNewLine();
                        igSeparator();

                        if (igMenuItem(__("Delete"), "", false, true)) {
                            incActivePuppet().removeParameter(param);
                        }
                        igEndPopup();
                    }
                    
                    if (igButton("", ImVec2(24, 24))) {
                        igOpenPopup("###EditParam");
                    }
                    
                    
                    if (incButtonColored("", ImVec2(24, 24), incArmedParameter() == param ? ImVec4(1f, 0f, 0f, 1f) : *igGetStyleColorVec4(ImGuiCol.Text))) {
                        if (incArmedParameter() == param) incDisarmParameter();
                        else incArmParameter(param);
                    }

                    // Arms the parameter for recording values.
                    incTooltip(_("Arm Parameter"));
                    igEndChild();
                }
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
            if (igMenuItem(__("Add 1D Parameter"), "", false, true)) {
                incActivePuppet().parameters ~= new Parameter(
                    "Param #%d\0".format(parameters.length),
                    false
                );
            }
            if (igMenuItem(__("Add 2D Parameter"), "", false, true)) {
                incActivePuppet().parameters ~= new Parameter(
                    "Param #%d\0".format(parameters.length),
                    true
                );
            }
            igEndPopup();
        }
        if (igBeginChild("###FILTER", ImVec2(0, 32))) {
            if (incInputText("Filter", filter)) {
                filter = filter.toLower;
            }
            incTooltip("Filter, search for specific parameters");
            igEndChild();
        }


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
            igEndChild();
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


