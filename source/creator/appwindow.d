/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.appwindow;
public import gtk.Widget;
import gtk.MainWindow;
import gtk.HeaderBar;
import gtk.Stack;

import creator.viewport;
import creator.view;



class InochiHeader : HeaderBar {
    import gtk.StackSwitcher;
    import gtk.Button;
    
    this(Stack stack) {
        this.setShowCloseButton(true);

        StackSwitcher switcher = new StackSwitcher();
        switcher.setStack(stack);
        this.setCustomTitle(switcher);
    }
}

class InochiWindow : MainWindow {
private:
    InochiHeader header;
    Stack views;

public:
    this() {
        super("Inochi2D Creator");

        // Open a reasonable window size
        this.setDefaultSize(640, 480);

        // Prepare the views
        views = new Stack();
        views.addToStack(new LayoutView);
        views.addToStack(new RigView);
        views.addToStack(new AnimView);

        // Makes so the views show
        this.add(views);

        // Set a headerbar
        header = new InochiHeader(views);
        this.setTitlebar(header);

        // Show all the content in the window.
        this.showAll();
    }
}
