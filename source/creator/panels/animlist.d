/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.animlist;
import creator.panels;
import creator : EditMode;
import i18n;

/**
    The logger frame
*/
class AnimListPanel : Panel {
private:

protected:
    override
    void onUpdate() {

    }

public:
    this() {
        super("Animation List", _("Animation List"), false);
        activeModes = EditMode.AnimEdit;
    }
}

/**
    Generate logger frame
*/
mixin incPanel!AnimListPanel;


