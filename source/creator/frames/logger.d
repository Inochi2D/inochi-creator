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


