module creator.core.ui.widgets.window;
import creator.core.ui.widgets.widget;
import inmath;
import i2d.imgui;
import std.string;
import std.conv;
import i18n;

/**
    A window
*/
abstract
class Window : Container {
public:

    /**
        Minimum size of the window.
    */
    vec2i minimumSize = vec2u(0, 0);

    /**
        Maximum size of the window.
    */
    vec2i maximumSize = vec2u(int.max, int.max);

    /**
        Title of the window.
    */
    final @property string title() { return name; }
    @property void title(string value) { this.name = value; }

    /**
        Creates a new window.
    */
    this(string name, bool randomize = true) {
        super(name, randomize);
    }
    
    /**
        Closes the window.
    */
    abstract void close();
}

/**
    A workspace is a container for ImGui Windows.
*/
class ImWorkspace : Widget {
private:
    ImWindow[] windows_;

protected:

    /**
        The task bar to draw for the workspace.
    */
    ImWindow taskbar;
    
    /**
        The status bar to draw for the workspace.
    */
    ImWindow statusbar;

    /**
        Called once a frame to update the widget.
    */
    override
    void onUpdate(float delta) {
        foreach(window; windows_) {
            window.update();
        }
    }
    
    /**
        Called when the widget needs to refresh all of its 
        information.
    */
    override
    void onRefresh() {
        foreach(window; windows_) {
            window.refresh();
        }
    }

public:

    /**
        The open windows.
    */
    @property ImWindow[] windows() {
        return this.windows_[0..$];
    }

    /**
        Gets the top window being managed.
    */
    @property Window topWindow() {
        return windows_.length > 0 ? windows_[$-1] : null;
    }

    /**
        Constructor
    */
    this() { super("workspace", false); }
}

/**
    ImGui Window
*/
class ImWindow : Window {
private:
    bool disabled_;
    bool visible_ = true;
    bool didDrawWindow;
    ImGuiWindowFlags flags;

protected:

    /**
        Called once a frame to update the widget.
    */
    override
    void onUpdate(float delta) {
        if (!disabled_ && !visible_) return;

        ImVec2 minSize = ImVec2(minimumSize.x, minimumSize.y);
        ImVec2 maxSize = ImVec2(maximumSize.x, maximumSize.y);

        igPushItemFlag(ImGuiItemFlags.Disabled, disabled);
            igSetNextWindowSizeConstraints(minSize, maxSize);
            if (alwaysOnTop) igSetNextWindowFocus();
            didDrawWindow = igBegin(imName.ptr, &visible, flags);
                foreach(child; children_) {
                    child.update();
                }
            igEnd();
        igPopItemFlag();

        // Make window visible again.
        if (disabled_ && !visible_)
            visible_ = true;
    }

    /**
        Called when the window is being closed.
    */
    void onClose() {
        wm.remove(this);
    }

public:

    /**
        Whether the window should always be rendered on top.
    */
    bool alwaysOnTop;

    /**
        The position of the window
    */
    final @property vec2 position() {
        ImVec2 pos;
        igGetWindowPos(&pos);
        return vec2(pos.x, pos.y);
    }

    /**
        Whether the window is visible.
    */
    final @property bool visible() { return visible_; }

    /**
        Whether the window is disabled.
    */
    final @property bool disabled() { return disabled_; }

    /**
        Enables interaction with the window.
    */
    final
    void enable() {
        disabled = false;
        this.flags = ImGuiWindowFlags.NoDocking | ImGuiWindowFlags.NoCollapse | ImGuiWindowFlags.NoSavedSettings;
    }

    /**
        Disables interaction with the window.
    */
    final
    void disable() {
        this.flags = ImGuiWindowFlags.NoDocking | 
            ImGuiWindowFlags.NoCollapse | 
            ImGuiWindowFlags.NoNav | 
            ImGuiWindowFlags.NoMove |
            ImGuiWindowFlags.NoScrollWithMouse |
            ImGuiWindowFlags.NoScrollbar;
        disabled = true;
    }

    /**
        Creates a new window.
    */
    this(string name, bool randomize = false) {
        super(name, randomize);
    }
}

/**
    A container which manages window instances.
*/
final
class ImWindowManager {
private:
    ImWindow[] windows_;
    ImWindow[] modals_;

public:

    /**
        Update windows
    */
    void update() {
        foreach(window; windowStack) {
            window.update();
            if (!window.visible) incPopWindow();
        }
        
        Window[] closedWindows;
        foreach(window; windowList) {
            window.update();
            if (!window.visible) closedWindows ~= window;
        }

        foreach(window; closedWindows) {
            incPopWindowList(window);
        }
    }
}