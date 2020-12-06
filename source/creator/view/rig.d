/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.view.rig;
import creator.view;

class RigView : View!("RigView", "Rigging") {
    this() {
        import gtk.Label;
        this.add(new Label("Rigging view"));

        this.showAll();
    }
}