/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets.header;
import gtk.StackSwitcher;
import gtk.Button;
import gtk.Stack;
import gtk.HeaderBar;


/**
    The Headerbar on top of the window
*/
class InochiHeader : HeaderBar {
private:
    StackSwitcher viewSwitcher;

public:
    
    /**
        Constructs a Inochi Creator header
    */
    this() {
        this.setShowCloseButton(true);
        this.setTitle("Inochi Creator");
        this.setSubtitle("No project loaded");
    }

    /**
        Unload views from header
    */
    void unloadViews() {
        viewSwitcher = null;
        this.setCustomTitle(null);

        // Remove all children
        this.removeAll();

        // Re-add close button
        this.setShowCloseButton(true);
    }

    /**
        Set views for header
    */
    void setViews(Stack stack) {
        viewSwitcher = new StackSwitcher();
        viewSwitcher.setStack(stack);
        this.packEnd(viewSwitcher);
    }
}