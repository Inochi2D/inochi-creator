module creator.windows;
import creator.core;
import bindbc.imgui;
import std.string;
import std.conv;

public import creator.windows.about;

/**
    A Widget
*/
abstract class Window {
private:
    string name_;
    bool visible = true;
    bool disabled;

protected:
    ImGuiWindowFlags flags;

    abstract void onUpdate();

    void onBeginUpdate(int id) {
        igBegin((name~"##"~id.text).toStringz, &visible, flags);
    }
    
    void onEndUpdate() {
        igEnd();
    }

public:

    /**
        Constructs a frame
    */
    this(string name) {
        this.name_ = name;
        this.restore();
    }

    final string name() {
        return name_;
    }

    /**
        Draws the frame
    */
    final void update(int id) {
        igPushItemFlag(ImGuiItemFlags_Disabled, disabled);
            this.onBeginUpdate(id);
                this.onUpdate();
            this.onEndUpdate();
        igPopItemFlag();

        if (disabled && !visible) visible = true;
    }

    ImVec2 getPosition() {
        ImVec2 pos;
        igGetWindowPos(&pos);
        return pos;
    }

    void disable() {
        this.flags = ImGuiWindowFlags_NoDocking | 
            ImGuiWindowFlags_NoCollapse | 
            ImGuiWindowFlags_NoNav | 
            ImGuiWindowFlags_NoMove |
            ImGuiWindowFlags_NoResize |
            ImGuiWindowFlags_NoScrollWithMouse |
            ImGuiWindowFlags_NoScrollbar;
        disabled = true;
    }

    void restore() {
        disabled = false;
        this.flags = ImGuiWindowFlags_NoDocking | ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize;
    }
}

private {
    Window[] windowStack;
}

/**
    Pushes window to stack
*/
void incPushWindow(Window window) {
    if (windowStack.length > 0) {
        windowStack[$-1].disable();
    }

    windowStack ~= window;
}

/**
    Pops a window
*/
void incPopWindow() {
    windowStack.length--;
    if (windowStack.length > 0) windowStack[$-1].restore();
}

/**
    Update windows
*/
void incUpdateWindows() {
    int id = 0;
    foreach(window; windowStack) {
        window.update(id++);
        if (!window.visible) incPopWindow();
    }
}

/**
    Gets top window
*/
Window incGetTopWindow() {
    return windowStack.length > 0 ? windowStack[$-1] : null;
}