/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.view.anim;
import creator.view;
import i18n;

class AnimView : View!("AnimView") {
    this() {
        super(_("Animation"));
        this.showAll();
    }
}