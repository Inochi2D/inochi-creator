/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.view.rig;
import creator.view;
import i18n;
import creator.widgets.viewport;
import core.project;
import core.imgui_surface;

class RigView : View!("RigView") {
    this() {
        super(_("Rigging"));
        
        this.packStart(new ImGuiSurface(), true, true, 0);

        this.showAll();
    }
}