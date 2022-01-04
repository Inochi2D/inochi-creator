/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels;
import creator.core.settings;
import bindbc.imgui;
import std.string;

public import creator.panels.logger;

/**
    A Widget
*/
abstract class Panel {
private:
    string name_;
protected:
    ImVec2 panelSpace;
    abstract void onUpdate();
    ImGuiWindowFlags flags;

    void onBeginUpdate() {
        igBegin(name.ptr, &visible, flags);
        igGetContentRegionAvail(&panelSpace);
    }
    
    void onEndUpdate() {
        igEnd();
    }

    void onInit() { }

public:

    /**
        Whether the panel is visible
    */
    bool visible;

    /**
        Whether the panel is always visible
    */
    bool alwaysVisible = false;

    /**
        Constructs a panel
    */
    this(string name, bool defaultVisibility) {
        this.name_ = name;
        this.visible = defaultVisibility;
    }

    /**
        Initializes the Panel
    */
    final void init_() {
        onInit();
        if (incSettingsCanGet(this.name_~".visible")) {
            visible = incSettingsGet!bool(this.name_~".visible");
        }
    }

    final string name() {
        return name_;
    }

    /**
        Draws the panel
    */
    final void update() {
        this.onBeginUpdate();
            this.onUpdate();
        this.onEndUpdate();
    }
}

/**
    Auto generate panel adder
*/
template incPanel(T) {
    static this() {
        incAddPanel(new T);
    }
}

/**
    Adds panel to panel list
*/
void incAddPanel(Panel panel) {
    incPanels ~= panel;
}

/**
    Draws panels
*/
void incUpdatePanels() {
    foreach(panel; incPanels) {
        if (!panel.visible && !panel.alwaysVisible) continue;

        panel.update();
    }
}

/**
    Draws panels
*/
void incInitPanels() {
    foreach(panel; incPanels) {
        panel.init_();
    }
}

/**
    Panel list
*/
Panel[] incPanels;