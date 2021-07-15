/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.frames.logger;
import creator.frames;

/**
    The logger frame
*/
class LoggerFrame : Frame {
private:

protected:
    override
    void onUpdate() {

    }

public:
    this() {
        super("Logger", false);
    }
}

/**
    Generate logger frame
*/
mixin incFrame!LoggerFrame;


