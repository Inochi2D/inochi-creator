/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Grillo del Mal
*/
module creator.windows.trackbind;

import creator.windows;
import creator.widgets;
import creator.tracking;
import creator.tracking.expr;
import creator;
import i18n;
import inochi2d;
import std.format;

class TrackBindingWindow : Window {
private:
    Parameter param;
    uint axis;

    TrackingBinding binding;

    BindingType bindingType;
    string sourceName;
    SourceType sourceType;
    string expressionFormula;
    vec2 inRange = vec2(0, 1);
    vec2 outRange = vec2(0, 1);

    const(char)*[BindingType] bindingTypeComboText;
    const(char)*[SourceType] sourceTypeComboText;
    BindingType[] bindingTypeSort = [
            BindingType.RatioBinding,
            BindingType.ExpressionBinding,
            ];
    SourceType[] sourceTypeSort = [
            SourceType.Blendshape,
            SourceType.BonePosX,
            SourceType.BonePosY,
            SourceType.BonePosZ,
            SourceType.BoneRotRoll,
            SourceType.BoneRotPitch,
            SourceType.BoneRotYaw,
        ];

protected:
    override
    void onBeginUpdate() {
        igSetNextWindowSize(ImVec2(200*2, 140*2), ImGuiCond.Appearing);
        igSetNextWindowSizeConstraints(ImVec2(200*2, 140*2), ImVec2(200*2, 140*2));
        super.onBeginUpdate();
    }

    override
    void onUpdate() {
        igPushID(cast(void*)param);

        incText(_("Binding Type"));
        igIndent();
            if (igBeginCombo("###BindingType", bindingTypeComboText[bindingType])) {
                foreach(k; bindingTypeSort){
                    const(char)* name = bindingTypeComboText[k];
                    if (igSelectable(name, bindingType == k)) {
                        bindingType = k;
                    }
                }
                igEndCombo();
            }
        igUnindent();

        switch(bindingType) {
            case BindingType.RatioBinding:
                incText(_("Source name"));
                igIndent();
                    incInputText("###SourceName", 150, sourceName);
                igUnindent();

                incText(_("Source Type"));
                igIndent();
                    if (igBeginCombo("###SourceType", sourceTypeComboText[sourceType])) {
                        foreach(k; sourceTypeSort){
                            const(char)* name = sourceTypeComboText[k];
                            if (igSelectable(name, sourceType == k)) {
                                sourceType = k;
                                switch(sourceType) {
                                    case SourceType.Blendshape:
                                        inRange.x = 0;
                                        inRange.y = 1;
                                        break;

                                    case SourceType.BonePosX:
                                    case SourceType.BonePosY:
                                    case SourceType.BonePosZ:
                                        inRange.x = -1;
                                        inRange.y = 1;
                                        break;
                                    case SourceType.BoneRotPitch:
                                    case SourceType.BoneRotRoll:
                                    case SourceType.BoneRotYaw:
                                        inRange.x = -45;
                                        inRange.y = 45;
                                        break;
                                        
                                    default: assert(0);
                                }

                            }
                        }
                        igEndCombo();
                    }
                igUnindent();

                incText(_("Tracking In"));
                igIndent();
                    switch(sourceType) {
                        case SourceType.Blendshape:
                            igDragFloatRange2(
                                "###TrackingInBlendshape", 
                                &(inRange.vector[0]), &(inRange.vector[1]), 0.1f, 
                                -1, 1);
                            break;

                        case SourceType.BonePosX:
                        case SourceType.BonePosY:
                        case SourceType.BonePosZ:
                            igDragFloatRange2(
                                "###TrackingInBonePos", 
                                &(inRange.vector[0]), &(inRange.vector[1]), 1.0f, 
                                -float.max, float.max);
                            break;

                        case SourceType.BoneRotPitch:
                        case SourceType.BoneRotRoll:
                        case SourceType.BoneRotYaw:
                            igDragFloatRange2(
                                "###TrackingInBoneRot", 
                                &(inRange.vector[0]), &(inRange.vector[1]), 1.0f, 
                                -180, 180);
                            break;
                            
                        default: assert(0);
                    }
                igUnindent();

                incText(_("Tracking Out"));
                igIndent();
                    igDragFloatRange2(
                        "###TO", 
                        &(outRange.vector[0]), &(outRange.vector[1]), 1.0f, 
                        -float.max, float.max);
                igUnindent();
                break;

            case BindingType.ExpressionBinding:
                //Add expresion formula input
                incText(_("Expresion forumla"));
                igIndent();
                    incInputText(_("Expresion formula"), expressionFormula);
                igUnindent();
                break;

            default: assert(0);
        }

        if (igBeginChild("###SettingsBtns", ImVec2(0, 0))) {
            //if (igButton(__("Refresh Bindable"), ImVec2(0, 24))) {
                // TODO: Implement on tracking mode
                //this.currBindable = incViewportTestGetCurrBindable();
            //}

            igSameLine(0, 0);
            incDummy(ImVec2(-130, 0));
            igSameLine(0, 0);

            const(char)* cancelBtnTxt = this.binding !is null ? __("Remove") : __("Cancel");
            if (igButton(cancelBtnTxt, ImVec2(64, 24))) {
                if(this.binding !is null) {
                    incActiveProject().removeBinding(this.binding);
                }
                this.close();
            }

            igSameLine(0, 0);
            incDummy(ImVec2(-64, 0));
            igSameLine(0, 0);

            bool canSave = (
                bindingType == BindingType.RatioBinding && sourceName.length > 0
                ) || (
                bindingType == BindingType.ExpressionBinding && expressionFormula.length > 0
                );
            if (!canSave) igBeginDisabled();
                if (igButton(__("Save"), ImVec2(64, 24))) {
                    TrackingBinding saveBind = this.binding;
                    if(saveBind is null) {
                        saveBind = new TrackingBinding();
                        saveBind.param = param;
                        saveBind.axis = axis;
                        saveBind.name = param.isVec2 ? (
                            "%s (%s)".format(
                                param.name, axis == 0 ? "X" : "Y")
                            ) : param.name;
                        incActiveProject().addBinding(saveBind);
                    }

                    saveBind.type = this.bindingType;
                    saveBind.sourceName = this.sourceName;
                    saveBind.sourceType = this.sourceType;
                    if(this.bindingType == BindingType.ExpressionBinding) {
                        saveBind.expr = new Expression(
                            cast(int)saveBind.hashOf(), axis, 
                            expressionFormula);
                    }
                    saveBind.inRange = this.inRange;
                    saveBind.outRange = this.outRange;

                    saveBind.createSourceDisplayName();

                    this.close();
                }
            if (!canSave) igEndDisabled();
        }
        igEndChild();

        igPopID();
    }

public:
    this(ref Parameter param, uint axis = 0) {
        bindingTypeComboText = [
            BindingType.RatioBinding: __("Ratio Binding"),
            BindingType.ExpressionBinding: __("Expresion Binding"),
            //BindingType.External: __("External"),
        ];

        sourceTypeComboText = [
            SourceType.Blendshape: __("Blendshape"),
            SourceType.BonePosX: __("Bone Position (X)"),
            SourceType.BonePosY: __("Bone Position (Y)"),
            SourceType.BonePosZ: __("Bone Position (Z)"),
            SourceType.BoneRotRoll: __("Bone Rotation (Roll)"),
            SourceType.BoneRotPitch: __("Bone Rotation (Pitch)"),
            SourceType.BoneRotYaw: __("Bone Rotation (Yaw)"),
        ];

        this.param = param;
        this.axis = param.isVec2 ? axis : 0;

        binding = incActiveProject().findBindingByParam(this.param, this.axis);
        if(this.binding !is null) {
            this.bindingType = binding.type;
            this.sourceName = binding.sourceName;
            this.sourceType = binding.sourceType;
            this.expressionFormula = binding.expr !is null ? binding.expr.expression : "";
            this.inRange = binding.inRange;
            this.outRange = binding.outRange;
        }
        super(_("Set Tracking Binding - %s").format(
            param.isVec2 ? (
                "%s (%s)".format(
                    param.name, axis == 0 ? "X" : "Y")
                ) : param.name));
    }
}