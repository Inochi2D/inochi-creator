module creator.frames;
import creator.core.settings;
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
    ImVec2 frameSpace;
    abstract void onUpdate();

    void onBeginUpdate() {
        igBegin(name.ptr, &visible, ImGuiWindowFlags_None);
        igGetContentRegionAvail(&frameSpace);
    }
    
    void onEndUpdate() {
        igEnd();
    }

    void onInit() { }

public:

    /**
        Whether the frame is visible
    */
    bool visible;

    /**
        Whether the frame is always visible
    */
    bool alwaysVisible = false;

    /**
        Constructs a frame
    */
    this(string name, bool defaultVisibility) {
        this.name_ = name;
        this.visible = defaultVisibility;
    }

    /**
        Initializes the Frame
    */
    final void init_() {
        onInit();
        if (incSettingsCanGet(this.name_~".visible")) {
            visible = incSettingsGet!bool(this.name_~".visible");
        }
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
    Draws frames
*/
void incInitFrames() {
    foreach(frame; incFrames) {
        frame.init_();
    }
}

/**
    Frame list
*/
Frame[] incFrames;