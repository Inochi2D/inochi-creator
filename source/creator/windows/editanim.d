/*
    Copyright © 2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.editanim;
import creator.widgets;
import creator.windows;
import creator.core;
import creator;
import std.string;
import creator.utils.link;
import inochi2d;
import i18n;
import std.stdio;

class EditAnimationWindow : Window {
private:
    bool isNew;
    string originalName;

    string name;
    Animation newAnim;

    size_t frameRateOption = 1;
    const(char)*[] fpsOptions;
    float[]      fpsOptionsFR;
    float framerate = 60;

    void apply() {

        if (name.strip().length == 0) {
            incDialog(
                "ERR_NAME_INVALID", 
                __("Invalid Name"), 
                _("Name can not be empty!")
            );
            return;
        }

        foreach(anim; incActivePuppet().getAnimations().keys) {
            if ((isNew && anim == name) || (!isNew && originalName != name && anim == name)) {
                incDialog(
                    "ERR_NAME_TAKEN", 
                    __("Invalid Name"), 
                    _("%s is already taken! Please chose another animation name.").format(name)
                );
                return;
            }
        }

        // Set framerate
        if (frameRateOption+1 == fpsOptions.length) newAnim.timestep = 1.0/framerate;
        else newAnim.timestep = 1.0/fpsOptionsFR[frameRateOption];
    

        if (!isNew && originalName != name) {
            incActivePuppet().getAnimations().remove(originalName);
        }
        incActivePuppet().getAnimations()[name] = newAnim;
        incAnimationChange(name);
        this.close();
    }

protected:
    override
    void onBeginUpdate() {
        enum WIDTH = 480;
        enum HEIGHT = 320;
        igSetNextWindowSize(ImVec2(WIDTH, HEIGHT), ImGuiCond.Appearing);
        igSetNextWindowSizeConstraints(ImVec2(WIDTH, HEIGHT), ImVec2(float.max, HEIGHT));
        super.onBeginUpdate();
    }

    override
    void onUpdate() {

        // Textbox
        ImVec2 avail = incAvailableSpace();
        igIndent(16);
            avail = incAvailableSpace();
            if (incInputText("NAME", avail.x-16, name, ImGuiInputTextFlags.EnterReturnsTrue)) {
                this.apply();
            }
        igUnindent(16);


        incBeginCategory(__("Options"), IncCategoryFlags.NoCollapse);
            igCheckbox(__("Additive"), &newAnim.additive);
            igInputFloat(__("Weight"), &newAnim.animationWeight);
            
            if (igDragInt(__("Frames"), &newAnim.length, 1, 1, int.max)) {
                newAnim.leadOut = newAnim.length;
            }
            igDragInt(__("Lead In"), &newAnim.leadIn, 1, 0, newAnim.length);
            igDragInt(__("Lead Out"), &newAnim.leadOut, 1, 0, newAnim.length);


            if (igBeginCombo(__("Framerate"), fpsOptions[frameRateOption])) {
                foreach(i; 0..fpsOptions.length) {
                    if (igSelectable(fpsOptions[i], i == frameRateOption))
                        frameRateOption = i;
                }

                igEndCombo();
            }

            // Custom FPS
            float timestep = 1.0/fpsOptionsFR[frameRateOption];
            if (frameRateOption+1 == fpsOptions.length) {
                igInputFloat(__("Custom Framerate"), &framerate);
                timestep = 1.0/framerate;
            }

            float time = timestep*newAnim.length;
            float s = cast(int)time;
            float ms = cast(int)((time - cast(float)s) * 1000);
            incText(_("%ss %sms").format(s, ms));
            
        incEndCategory();

        // Done button
        string btnName = isNew ? _("Create") : _("Save");

        float doneLength = clamp(incMeasureString(btnName).x, 64, float.max);
        avail = incAvailableSpace();
        incDummy(ImVec2(0, -24));
        incDummy(ImVec2(avail.x-(doneLength+8), 20));
        igSameLine(0, 0);
        if (igButton(btnName.toStringz, ImVec2(doneLength+8, 20))) {
            this.apply();
        }
    }

    final
    void setupFPS() {
        fpsOptions = [
            __("120 FPS"),
            __("60 FPS"),
            __("30 FPS"),
            __("25 FPS"),
            __("Custom Framrate")
        ];

        fpsOptionsFR = [
            120,
            60,
            30,
            25,
            60
        ];
    }

public:
    this() {
        super(_("New Animation..."));
        isNew = true;
        
        newAnim.animationWeight = 1;
        newAnim.additive = false;
        
        newAnim.leadIn = 0;
        newAnim.leadOut = 0;
        newAnim.length = 100;
        setupFPS();
    }

    this(Animation anim, string name) {
        super(_("Edit %s...").format(name));
        isNew = false;

        // Set up name stuff
        this.originalName = name.dup;
        this.name = cast(string)(name.dup~"\0");
        this.name = this.name[0..$-1];

        newAnim = anim;
        setupFPS();
    }
}