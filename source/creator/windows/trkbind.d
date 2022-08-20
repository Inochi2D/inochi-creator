/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.trkbind;
import creator.viewport.test;
import creator.windows;
import creator.widgets;
import creator.core;
import creator;
import std.string;
import creator.utils.link;
import i18n;
import inochi2d;

class TrackingBindingWindow : Window {
private:
    TrackingBinding binding;
    const(char)* paramComboName = "";
    const(char)* trackingComboName = "";
    const(char)* bindingBoneInputName = "";
    const(char)* bindingAxisName = "";
    TrackingBindingMode[string] currBindable;

    void boneElementSelectable(const(char)* name, TrackingBindingMode mode) {

        if (igSelectable(name, binding.mode == mode)) {
            binding.mode = mode;
            bindingBoneInputName = name;
        }
    }

protected:
    override
    void onBeginUpdate() {
        flags |= ImGuiWindowFlags.NoResize;
        igSetNextWindowSize(ImVec2(384, 192), ImGuiCond.Appearing);
        igSetNextWindowSizeConstraints(ImVec2(384, 192), ImVec2(float.max, float.max));
        super.onBeginUpdate();
    }

    override
    void onUpdate() {
        if (igBeginChild("###MainSettings", ImVec2(0, -28))) {
            if (igBeginCombo(__("Parameter"), paramComboName)) {
                foreach(i, param; incActivePuppet().parameters) {
                    igPushID(cast(int)i);
                        bool isSelected = binding.param == param;
                        if (igSelectable(param.name.toStringz, isSelected)) {
                            binding.param = param;
                            paramComboName = param.name.toStringz;
                        }
                    igPopID();
                }
                igEndCombo();
            }

            if (binding.param) {
                if (igBeginCombo(__("Bind To"), trackingComboName)) {
                    foreach(name, mode; currBindable) {
                        igPushID(name.ptr);
                            bool isSelected = binding.key == name;
                            if (igSelectable(name.toStringz, isSelected)) {
                                binding.key = name;
                                trackingComboName = name.toStringz;

                                if (mode == TrackingBindingMode.Blendshape) {
                                    binding.mode = mode;
                                } else {
                                    binding.mode = TrackingBindingMode.Bone;
                                }
                            }
                        igPopID();
                    }
                    igEndCombo();
                }

                if (binding.key in currBindable && currBindable[binding.key] == TrackingBindingMode.Bone) {
                    
                    if (igBeginCombo(__("Bone Input"), bindingBoneInputName)) {
                        boneElementSelectable(__("Position (X)"), TrackingBindingMode.BonePosX);
                        boneElementSelectable(__("Position (Y)"), TrackingBindingMode.BonePosY);
                        boneElementSelectable(__("Position (Z)"), TrackingBindingMode.BonePosZ);
                        boneElementSelectable(__("Rotation (X)"), TrackingBindingMode.BoneRotX);
                        boneElementSelectable(__("Rotation (Y)"), TrackingBindingMode.BoneRotY);
                        boneElementSelectable(__("Rotation (Z)"), TrackingBindingMode.BoneRotZ);
                        igEndCombo();
                    }
                }

                if (binding.param.isVec2) {
                    if (igBeginCombo(__("Binding Axis"), bindingAxisName)) {
                        if (igSelectable("X", binding.axis == 0)) {
                            binding.axis = 0;
                            bindingAxisName = "X";
                        }

                        if (igSelectable("Y", binding.axis == 1)) {
                            binding.axis = 1;
                            bindingAxisName = "Y";
                        }
                        igEndCombo();
                    }
                } else {
                    binding.axis = 0;
                }

                igCheckbox(__("Invert"), &binding.inverse);
            }
            igEndChild();

            if (igBeginChild("###SettingsBtns", ImVec2(0, 0))) {
                if (igButton(__("Refresh Bindable"), ImVec2(0, 24))) {
                    this.currBindable = incViewportTestGetCurrBindable();
                }

                igSameLine(0, 0);
                incDummy(ImVec2(-64, 0));
                igSameLine(0, 0);

                bool canSave = binding.key.length > 0 && binding.mode != TrackingBindingMode.Bone;

                if (!canSave) igBeginDisabled();
                    // Settings are autosaved, but in case the user
                    // feels more safe with a save button then we have
                    // it here.
                    if (igButton(__("Save"), ImVec2(64, 24))) {
                        incTestAddTrackingBinding(binding);
                        this.close();
                    }
                if (!canSave) igEndDisabled();
            }
        }
        igEndChild();
    }

public:
    this(TrackingBindingMode[string] bindable) {
        this.currBindable = bindable;

        // Title for the parameter properties window.
        super(_("Bind Tracking to Parameter"));
    }
}