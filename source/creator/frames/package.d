module creator.frames;
import bindbc.imgui;
import std.string;

public import creator.frames.logger;

/**
    A Widget
*/
abstract class Frame {
private:
    string name_;

protected:
    abstract void onUpdate();

    void onBeginUpdate() {
        igBegin(name.ptr, &visible, ImGuiWindowFlags_None);
    }
    
    void onEndUpdate() {
        igEnd();
    }

public:

    /**
        Whether the frame is visible
    */
    bool visible = false;

    /**
        Whether the frame is always visible
    */
    bool alwaysVisible = false;

    /**
        Constructs a frame
    */
    this(string name) {
        this.name_ = name;
    }

    final string name() {
        return name_;
    }

    /**
        Draws the frame
    */
    final void update() {
        this.onBeginUpdate();
            this.onUpdate();
        this.onEndUpdate();
    }
}

/**
    Auto generate frame adder
*/
template incFrame(T) {
    static this() {
        incAddFrame(new T);
    }
}

/**
    Adds frame to frame list
*/
void incAddFrame(Frame frame) {
    incFrames ~= frame;
}

/**
    Draws frames
*/
void incUpdateFrames() {
    foreach(frame; incFrames) {
        if (!frame.visible && !frame.alwaysVisible) continue;

        frame.update();
    }
}

/**
    Frame list
*/
Frame[] incFrames;