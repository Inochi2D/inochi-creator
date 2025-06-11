module creator.core.ui.window;
import creator.core.ui.backend;
import nulib.string;
import i2d.imgui;
import sdl;

/**
    High level wrapper for the application window, handling events
    for the underlying imgui instance.
*/
class AppWindow {
private:
@nogc:
    SDL_Window* windowHandle;
    SDL_WindowID windowId;
    SDL_GLContext glctx;
    ulong time;

    // Imgui State Info
    __gshared ImGuiContext* globalIgContext;
    __gshared nstring igConfigFile;

    //
    //      HELPERS
    //

    static BackendData* getBackendData() {
        return ImGui_CreatorGetBackendData();
    }

    //
    //      WINDOW AND CONTEXT CREATION.
    //

    SDL_Window* createWindow(string title, uint w, uint h) {
        nstring _title = title;
        SDL_WindowFlags flags = 
            SDL_WindowFlags.SDL_WINDOW_OPENGL | 
            SDL_WindowFlags.SDL_WINDOW_RESIZABLE | 
            SDL_WindowFlags.SDL_WINDOW_ALLOW_HIGHDPI;

        auto whndl = SDL_CreateWindow(_title.ptr, w, h, flags);
        SDL_SetWindowMinimumSize(whndl, 960, 720);
        return whndl;
    }

    SDL_GLContext createContext(SDL_Window* handle) {
        import bindbc.opengl;

        SDL_GL_SetAttribute(SDL_GLAttr.SDL_GL_CONTEXT_PROFILE_MASK, SDL_GLProfile.SDL_GL_CONTEXT_PROFILE_CORE);
        SDL_GL_SetAttribute(SDL_GLAttr.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GLAttr.SDL_GL_CONTEXT_MINOR_VERSION, 1);

        SDL_GL_SetAttribute(SDL_GLAttr.SDL_GL_DOUBLEBUFFER, 1);
        SDL_GL_SetAttribute(SDL_GLAttr.SDL_GL_DEPTH_SIZE, 24);
        SDL_GL_SetAttribute(SDL_GLAttr.SDL_GL_STENCIL_SIZE, 8);
        SDL_GL_SetAttribute(SDL_GLAttr.SDL_GL_RED_SIZE, 8);
        SDL_GL_SetAttribute(SDL_GLAttr.SDL_GL_GREEN_SIZE, 8);
        SDL_GL_SetAttribute(SDL_GLAttr.SDL_GL_BLUE_SIZE, 8);
        SDL_GL_SetAttribute(SDL_GLAttr.SDL_GL_ALPHA_SIZE, 8);

        auto ctx = SDL_GL_CreateContext(handle);
        SDL_GL_MakeCurrent(handle, ctx);

        if (openGLContextVersion() == GLSupport.noContext) {
            loadOpenGL();
        }

        debug {
            import std.stdio : writefln;
            import std.string : fromStringz;
            writefln("GLInfo:\n\t%s\n\t%s\n\t%s\n\t%s\n\tgls=%s",
                glGetString(GL_VERSION).fromStringz,
                glGetString(GL_VENDOR).fromStringz,
                glGetString(GL_RENDERER).fromStringz,
                glGetString(GL_SHADING_LANGUAGE_VERSION).fromStringz,
                openGLContextVersion()
            );
        }
        return ctx;
    }


    //
    //      INITIALIZATION AND CLEANUP
    //

    bool isInitialized() {
        return SDL_WasInit(0) != 0;
    }

    void initializeSubsystems() {
        settings = new AppSettings();
    }

    void initializeSDL() {
        SDL_Init(SDL_INIT_EVENTS | SDL_INIT_VIDEO);

        // Setup DPI Awareness.
        version(Windows) {
            import creator.core.ui.win32 : uiSetWin32DPIAwareness;
            uiSetWin32DPIAwareness();
        }
    }

    void initializeImGui(AppWindow appWindow) {
        igInitialize();

        // TODO: Add new font atlas implementation using hairetsu.
        this.globalIgContext = igCreateContext(null);

        // Load config
        auto io = igGetIO();
        io.IniFilename = igConfigFile.ptr;
        igLoadIniSettingsFromDisk(io.IniFilename);

        io.ConfigFlags |= ImGuiConfigFlags.DockingEnable;
        io.ConfigWindowsResizeFromEdges = true;
        version(OSX) io.ConfigMacOSXBehaviors = true;

        // Finally setup the UI library.
        ImGui_ImplInit(appWindow);
        incGLBackendInit(null);
    }

    void shutdown() {
        ImGui_ImplShutdown();
        igShutdown();
        this.globalIgContext = null;
        SDL_Quit();
    }

public:

    /**
        Global UI Scale
    */
    __gshared float uiScale = 1.0f;

    /**
        The main window of the application.

        Once the main window closes, the application will exit.
    */
    static @property AppWindow mainWindow() { return this.getBackendData().mainWindow; }

    /**
        Handle to the SDL Window that backs the AppWindow.
    */
    @property SDL_Window* handle() { return this.windowHandle; }

    /**
        Handle to the SDL Window that backs the AppWindow's current IME.
    */
    @property SDL_Window* imeHandle() { return this.getBackendData().imeWindowHandle; }
    @property void imeHandle(SDL_Window* handle) { this.getBackendData().imeWindowHandle = handle; }

    /**
        The ID of the AppWindow.
    */
    @property SDL_WindowID id() { return this.windowId; }

    /**
        The OpenGL Context of the window.
    */
    @property SDL_GLContext glContext() { return this.glctx; }

    /**
        The text in the clipboard.
    */
    @property string clipboardText() { return this.getBackendData().clipboardData[]; }
    @property void clipboardText(const(char)* text) { this.getBackendData().clipboardData = text; }
    @property void clipboardText(string text) { this.getBackendData().clipboardData = text; }

    /**
        Whether the application is still running.
    */
    static @property bool isRunning() {
        return (AppWindow.getBackendData() !is null);
    }

    /*
        Destructor
    */
    ~this() {
        if (this == mainWindow) {
            this.shutdown();
        } else {
            if (windowHandle) SDL_DestroyWindow(windowHandle);
            if (imeWindowHandle) SDL_DestroyWindow(imeWindowHandle);
        }
    }

    /**
        Creates a new window, if this is the first window created,
        the window will be set as the main window.
    */
    this(string title, uint w, uint h) {
        if (!isInitialized()) {
            this.initializeSubsystems();
            this.initializeSDL();
            this.windowHandle = this.createWindow(title, w, h);
            this.glctx = this.createContext(this.windowHandle);
            this.initializeImGui(windowHandle);
        } else {
            this.windowHandle = this.createWindow(title, w, h);
            this.glctx = this.createContext(this.windowHandle);
        }
    }

    /**
        Processes the events for the window.
    */
    void processEvent(const(SDL_Event)* event) { 
        version (UseUIScaling) {
            version (OSX) {
                
                // macOS handles the UI scaling automatically, as such we don't need to do as much cursed shit(TM) there.
                return ImGui_Implcreator.core.ui_ProcessEvent(event);
            } else {
                switch(event.type) {

                    // For UI Scaling we want to send in our own scaled UI inputs
                    case SDL_EventType.SDL_MOUSEMOTION:
                        float uiScale = incGetUIScale();
                        ImGuiIO_AddMousePosEvent(
                            igGetIO(), 
                            cast(float)event.motion.x/uiScale, 
                            cast(float)event.motion.y/uiScale
                        );
                        return true;
                    
                    default:
                        return ImGui_Implcreator.core.ui_ProcessEvent(event);
                }
            }
        } else {
            return ImGui_Implcreator.core.ui_ProcessEvent(event);
        }
    }

    /**
        Closes the window and re-registers the context.
    */
    void close() {
        destroy(this);
    }
}