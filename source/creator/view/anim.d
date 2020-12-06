/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.view.anim;
import creator.view;

class AnimView : View!("AnimView", "Animation") {
    this() {
        this.showAll();
    }
}