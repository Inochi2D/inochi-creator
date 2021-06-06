module creator.windows;
import creator.core;
import bindbc.imgui;
import std.string;
import std.conv;

public import creator.windows.about;
public import creator.windows.settings;
public import creator.windows.texviewer;
public import creator.windows.notice;

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

    void onClose() { }

public:

    /**
        Constructs a frame
    */
    this(string name) {
        this.name_ = name;
        this.restore();
    }

    final void close() {
        this.visible = false;
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
            ImGuiWindowFlags_NoScrollWithMouse |
            ImGuiWindowFlags_NoScrollbar;
        disabled = true;
    }

    void restore() {
        disabled = false;
        this.flags = ImGuiWindowFlags_NoDocking | ImGuiWindowFlags_NoCollapse;
    }
}

private {
    Window[] windowStack;
    Window[] windowList;
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
    Pushes window to stack
*/
void incPushWindowList(Window window) {
    windowList ~= window;
}

/**
    Pop window from Window List
*/
void incPopWindowList(Window window) {
    import std.algorithm.searching : countUntil;
    import std.algorithm.mutation : remove;

    ptrdiff_t i = windowList.countUntil(window);
    if (i != -1) {
        if (windowList.length == 1) windowList.length = 0;
        else windowList = windowList.remove(i);
    }
}

/**
    Pops a window
*/
void incPopWindow() {
    windowStack[$-1].onClose();
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
    
    Window[] closedWindows;
    foreach(window; windowList) {
        window.update(id++);
        closedWindows ~= window;
    }

    foreach(window; closedWindows) {
        if (!window.visible) incPopWindowList(window);
    }
}

/**
    Gets top window
*/
Window incGetTopWindow() {
    return windowStack.length > 0 ? windowStack[$-1] : null;
}