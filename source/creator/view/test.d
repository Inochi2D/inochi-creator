/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.view.test;
import creator.view;
import core.imgui_surface;
import i18n;

class TestView : View!("TestView") {
    this() {
        super(_("Test"));
        
        this.packStart(new ImGuiSurface(), true, true, 0);

        this.showAll();
    }
}