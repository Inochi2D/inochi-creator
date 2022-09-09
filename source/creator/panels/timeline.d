/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.timeline;
import creator.panels;
import i18n;
import inochi2d;

/**
    The logger frame
*/
class TimelinePanel : Panel {
private:
    Animation* workingAnimation;

protected:
    override
    void onUpdate() {
        
    }

public:
    this() {
        super("Timeline", _("Timeline"), false);
    }
}

/**
    Generate logger frame
*/
mixin incPanel!TimelinePanel;


