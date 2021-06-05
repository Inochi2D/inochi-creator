module creator.frames.parameters;
import creator.frames;

/**
    The logger frame
*/
class ParametersFrame : Frame {
private:

protected:
    override
    void onUpdate() {

    }

public:
    this() {
        super("Parameters");
        this.visible = true;
    }
}

/**
    Generate logger frame
*/
mixin incFrame!ParametersFrame;


