/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.viewport.test;
import creator.core;
import creator;
import inochi2d;
import bindbc.imgui;
import ft;

enum TrackingMode {
    None,
    VMC,
    VTS,
    OSF,
    Dummy
}

enum TrackingBindingMode {
    BonePosX,
    BonePosY,
    BonePosZ,
    BoneRotX,
    BoneRotY,
    BoneRotZ,
    Bone,
    Blendshape
}

struct TrackingBinding {
    TrackingBindingMode mode;
    string key;

    bool inverse;

    Parameter param;
    int axis;
}

private {
    TrackingMode trackingMode;
    Adaptor adaptor;
    string[string] options;

    TrackingBinding[] bindings;

    void applyToAxis(Parameter param, int axis, float val, bool inverse) {
        if (axis == 0) param.value.x = clamp(inverse ? val*-1 : val, 0, 1);
        if (axis == 1) param.value.y = clamp(inverse ? val*-1 : val, 0, 1);
    }

    void applyBindings() {
        if (!adaptor || !adaptor.isRunning) return;

        auto bones = adaptor.getBones;
        auto blendshapes = adaptor.getBlendshapes;

        foreach(binding; bindings) {
            switch(binding.mode) {
                case TrackingBindingMode.BonePosX:
                    if (binding.key in bones) {
                        applyToAxis(binding.param, binding.axis, bones[binding.key].position.x, binding.inverse);
                    }
                    break;

                case TrackingBindingMode.BonePosY:
                    if (binding.key in bones) {
                        applyToAxis(binding.param, binding.axis, bones[binding.key].position.y, binding.inverse);
                    }
                    break;

                case TrackingBindingMode.BonePosZ:
                    if (binding.key in bones) {
                        applyToAxis(binding.param, binding.axis, bones[binding.key].position.z, binding.inverse);
                    }
                    break;

                case TrackingBindingMode.BoneRotX:
                    if (binding.key in bones) {
                        applyToAxis(binding.param, binding.axis, bones[binding.key].rotation.x, binding.inverse);
                    }
                    break;

                case TrackingBindingMode.BoneRotY:
                    if (binding.key in bones) {
                        applyToAxis(binding.param, binding.axis, bones[binding.key].rotation.y, binding.inverse);
                    }
                    break;

                case TrackingBindingMode.BoneRotZ:
                    if (binding.key in bones) {
                        applyToAxis(binding.param, binding.axis, bones[binding.key].rotation.z, binding.inverse);
                    }
                    break;

                case TrackingBindingMode.Blendshape:
                    if (binding.key in blendshapes) {
                        applyToAxis(binding.param, binding.axis, blendshapes[binding.key], binding.inverse);
                    }
                    break;
                default: assert(0);
            }
        }
    }
}

void incTestSetTrackingMode(TrackingMode mode) {
    trackingMode = mode;
    incSettingsSet("tracking_mode", mode);

    // Stop old adaptor before switching
    if (adaptor && adaptor.isRunning) adaptor.stop();
    
    switch(trackingMode) {
        case TrackingMode.VMC:
            adaptor = new VMCAdaptor();
            break;
        case TrackingMode.VTS:
            adaptor = new VTSAdaptor();
            break;
        default: 
            adaptor = null;
            break;
    }
}

bool incTestHasAdaptor() {
    return adaptor !is null;
}

void incTestRestartTracker() {
    if (adaptor) {
        try {
            if (adaptor.isRunning) adaptor.stop();
            adaptor.start(options);
        } catch(Exception ex) {
            if (adaptor.isRunning) adaptor.stop();
            adaptor = null;
        }
    }
}

void incTestSetAdaptorOption(string name, string value) {
    options[name] = value;
}

ref string[string] incTestGetAdaptorOptions() {
    return options;
}

TrackingMode incTestGetTrackingMode() {
    return trackingMode;
}

TrackingBinding[] incTestGetTrackingBindings() {
    return bindings;
}

void incTestAddTrackingBinding(TrackingBinding binding) {
    bindings ~= binding;
}

void incTestRemoveTrackingBinding(TrackingBinding binding) {
    import std.algorithm.mutation : remove;
    import std.algorithm.searching : countUntil;

    ptrdiff_t idx = bindings.countUntil(binding);
    if (idx >= 0) {
        bindings = bindings.remove(idx);
    }
}

TrackingBindingMode[string] incViewportTestGetCurrBindable() {
    TrackingBindingMode[string] modes;
    if (adaptor && adaptor.isRunning) {
        foreach(shape, _; adaptor.getBlendshapes) {
            modes[shape] = TrackingBindingMode.Blendshape;
        }

        foreach(bone, _; adaptor.getBones) {
            modes[bone] = TrackingBindingMode.Bone;
        }
    }
    return modes;
}

// No overlay in deform mode
void incViewportTestOverlay() { }

void incViewportTestUpdate(ImGuiIO* io, Camera camera) {
    if (adaptor && adaptor.isRunning) {
        adaptor.poll();
    }
}

void incViewportTestDraw(Camera camera) {
    applyBindings();

    incActivePuppet.update();
    incActivePuppet.draw();
}

void incViewportTestToolbar() {

}



void incViewportTestPresent() {
    import std.conv : text;

    incTestSetTrackingMode(incSettingsGet("tracking_mode", TrackingMode.None));
    incTestSetAdaptorOption("address", incSettingsGet("vmc_bind_ip", "0.0.0.0"));
    incTestSetAdaptorOption("port", incSettingsGet("vmc_bind_port", 39540).text);
    incTestSetAdaptorOption("phoneIP", incSettingsGet("vts_phone_ip", "0.0.0.0"));
    incTestSetAdaptorOption("appName", "inochi-creator");
    incTestRestartTracker();
}

void incViewportTestWithdraw() {
    adaptor.stop();
}