/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.paramsplit;
import creator.windows;
import creator.core;
import creator.widgets.dummy;
import creator.widgets.label;
import creator;
import std.string;
import creator.utils.link;
import inochi2d;
import i18n;
import std.array : insertInPlace;

struct ParamMapping {
    size_t idx;
    ParameterBinding[] bindings;
    Node node;
    bool take;
}

class ParamSplitWindow : Window {
private:
    size_t idx;
    Parameter param;
    ParamMapping[uint] mappings;

    void buildMapping() {
        foreach(i, ref binding; param.bindings) {
            if (binding.getNodeUUID() !in mappings) {
                mappings[binding.getNodeUUID()] = ParamMapping(
                    i,
                    [],
                    binding.getNode(),
                    false
                );
            }

            mappings[binding.getNodeUUID()].bindings ~= binding;
        }
    }

    void apply() {
        Parameter newParam = new Parameter(param.name~_(" (Split)"), param.isVec2);
        foreach(axis; 0..param.axisPoints.length) {
            newParam.axisPoints[axis] = param.axisPoints[axis].dup;
        }
        

        // TODO: remap
        ParameterBinding[] oldParamBindings;
        ParameterBinding[] newParamBindings;
        foreach(ref mappingNode; mappings) {
            if (!mappingNode.take) oldParamBindings ~= mappingNode.bindings;
            else newParamBindings ~= mappingNode.bindings;
        }

        if (newParamBindings.length > 0) {
            param.bindings = oldParamBindings;
            newParam.bindings = newParamBindings;
            incActivePuppet().parameters.insertInPlace(idx+1, newParam);
        }

        this.close();
    }

    void oldBindingsList() {

        foreach(k; 0..mappings.keys.length) {
            auto key = mappings.keys[k];
            auto mapping = &mappings[mappings.keys[k]];

            if (mapping.take) continue;

            igSelectable(mapping.node.name.toStringz);
            if(igBeginDragDropSource(ImGuiDragDropFlags.SourceAllowNullID)) {
                igSetDragDropPayload("__OLD_TO_NEW", cast(void*)&key, (&key).sizeof, ImGuiCond.Always);
                incText(mapping.node.name);
                igEndDragDropSource();
            }
        }
    }

    void newBindingsList() {
        
        foreach(k; 0..mappings.keys.length) {
            auto key = mappings.keys[k];
            auto mapping = &mappings[mappings.keys[k]];
            if (!mapping.take) continue;
            
            igSelectable(mapping.node.name.toStringz);
            if(igBeginDragDropSource(ImGuiDragDropFlags.SourceAllowNullID)) {
                igSetDragDropPayload("__NEW_TO_OLD", cast(void*)&key, (&key).sizeof, ImGuiCond.Always);
                incText(mapping.node.name);
                igEndDragDropSource();
            }
        }
    }

protected:

    override
    void onBeginUpdate() {
        float scale = incGetUIScale();
        igSetNextWindowSizeConstraints(ImVec2(640*scale, 480*scale), ImVec2(float.max, float.max));
        super.onBeginUpdate();
    }

    override
    void onUpdate() {
        float scale = incGetUIScale();
        ImVec2 space = incAvailableSpace();
        float gapspace = 8*scale;
        float childWidth = (space.x/2);
        float childHeight = space.y-(24*scale);

        igBeginGroup();
            if (igBeginChild("###OldParam", ImVec2(childWidth, childHeight))) {
                if (igBeginListBox("###ItemListOld", ImVec2(childWidth-gapspace, childHeight))) {
                    oldBindingsList();
                    igEndListBox();
                }
                
                if(igBeginDragDropTarget()) {
                    const(ImGuiPayload)* payload = igAcceptDragDropPayload("__NEW_TO_OLD");
                    if (payload !is null) {
                        uint mappingName = *cast(uint*)payload.Data;
                        
                        mappings[mappingName].take = false;

                        igEndDragDropTarget();
                        return;
                    }
                    igEndDragDropTarget();
                }
            }
            igEndChild();

            igSameLine(0, gapspace);

            if (igBeginChild("###NewParam", ImVec2(childWidth, childHeight))) {
                if (igBeginListBox("###ItemListNew", ImVec2(childWidth, childHeight))) {
                    newBindingsList();
                    igEndListBox();
                }
            }
            igEndChild();

            if(igBeginDragDropTarget()) {
                const(ImGuiPayload)* payload = igAcceptDragDropPayload("__OLD_TO_NEW");
                if (payload !is null) {
                    uint mappingName = *cast(uint*)payload.Data;
                    
                    mappings[mappingName].take = true;

                    igEndDragDropTarget();
                    return;
                }
                igEndDragDropTarget();
            }
        igEndGroup();

        igBeginGroup();
            incDummy(ImVec2(-64*scale, 24*scale));
            igSameLine(0, 0);
            if (igButton(__("Apply"), ImVec2(64*scale, 24*scale))) {
                this.apply();
            }
        igEndGroup();
    }

public:
    this(size_t idx, Parameter param) {
        this.idx = idx;
        this.param = param;
        this.buildMapping();
        super(_("Split Parameter"));
    }
}

