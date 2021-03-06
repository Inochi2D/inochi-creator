/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.view;
public import creator.view.rig;
public import creator.view.anim;
public import creator.view.test;
public import creator.view.startpage;


import gtk.Box;
class View(string name) : Box {
private:

public:

    /**
        Name of the view
    */
    enum Name = name;

    /**
        Title of the view
    */
    string Title;

    /**
        Base constructor for a view
    */
    this(string title) {
        Title = title;
        super(GtkOrientation.HORIZONTAL, 0);
        this.showAll();
    }

}

import gtk.Stack;
void addToStack(T)(ref Stack stack, T item) if (is(T : View!Args, Args...)) {
    stack.addTitled(item, item.Name, item.Title);
}