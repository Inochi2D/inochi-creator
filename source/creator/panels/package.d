/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels;
import creator.core;
import creator.core.settings;
import bindbc.imgui;
import std.string;
import i18n;

public import creator.panels.logger;

/**
    A Widget
*/
abstract class Panel {
private:
    string name_;
    string displayName_;
    bool defaultVisibility;
    const(char)* windowID;
    const(char)* displayNamePtr;

    bool drewContents;

protected:
    ImVec2 panelSpace;
    abstract void onUpdate();
    ImGuiWindowFlags flags;

    void onBeginUpdate() {
        drewContents = igBegin(windowID, &visible, flags);
        if (!drewContents) return;

        incDebugImGuiState("Panel::onBeginUpdate", 1);
        igGetContentRegionAvail(&panelSpace);
    }
    
    void onEndUpdate() {
        if (drewContents) incDebugImGuiState("Panel::onEndUpdate", -1);
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
    this(string name, string displayName, bool defaultVisibility) {
        this.name_ = name;
        this.displayName_ = displayName;
        this.visible = defaultVisibility;
        this.defaultVisibility = defaultVisibility;
    }

    /**
        Initializes the Panel
    */
    final void init_() {
        onInit();

        // Workaround for the fact that panels are initialized in shared static this
        this.displayName_ = _(this.displayName_);
        if (incSettingsCanGet(this.name_~".visible")) {
            visible = incSettingsGet!bool(this.name_~".visible");
        }

        windowID = "%s###%s".format(displayName_, name_).toStringz;
        displayNamePtr = displayName_.toStringz;
    }

    final string name() {
        return name_;
    }

    final string displayName() {
        return displayName_;
    }

    final const(char)* displayNameC() {
        return displayNamePtr;
    }

    /**
        Draws the panel
    */
    final void update() {
        this.onBeginUpdate();
            this.onUpdate();
        this.onEndUpdate();
    }

    final bool getDefaultVisibility() {
        return defaultVisibility;
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