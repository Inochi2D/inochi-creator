module creator.view;
public import creator.view.rig;
public import creator.view.anim;
public import creator.view.layout;


import gtk.Box;
class View(string name, string title) : Box {
private:

public:

    /**
        Name of the view
    */
    enum Name = name;

    /**
        Title of the view
    */
    enum Title = title;

    /**
        Base constructor for a view
    */
    this() {
        super(GtkOrientation.HORIZONTAL, 0);
        this.showAll();
    }

}

import gtk.Stack;
void addToStack(T)(ref Stack stack, T item) if (is(T : View!Args, Args...)) {
    stack.addTitled(item, item.Name, item.Title);
}