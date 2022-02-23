/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.logger;
import creator.panels;
import i18n;

/**
    The logger frame
*/
class LoggerPanel : Panel {
private:

protected:
    override
    void onUpdate() {

    }

public:
    this() {
        super("Logger", _("Logger"), false);
    }
}

/**
    Generate logger frame
*/
mixin incPanel!LoggerPanel;


