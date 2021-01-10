/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.view.startpage;
import creator.view;
import i18n;
import creator.widgets.viewport;
import core.project;

class StartPage : View!("StartPage") {
    this() {
        super(_("Inochi Creator"));


        this.showAll();
    }
}