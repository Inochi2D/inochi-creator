module creator.core.ui.window;
import creator.core.ui.backend;
import creator.core.ui.styling;
import nulib.string;
import i2d.imgui;
import sdl;
import creator.core.settings;
import creator.io.save;

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
    bool isCloseRequested;

    // Imgui State Info
    __gshared ImGuiContext* globalIgContext;
    __gshared nstring igConfigFile;

    // Style State
    __gshared VisualStyle activeStyle;
    __gshared VisualStyle darkStyle;
    __gshared VisualStyle lightStyle;

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

        // This is important to prevent thread leakage
        import creator.viewport.test : incViewportTestWithdraw;
        incViewportTestWithdraw();

        // Save settings
        igSaveIniSettingsToDisk(igGetIO().IniFilename);

        incGLBackendShutdown();
        ImGui_ImplShutdown();
        igDestroyContext(globalIgContext);
        this.globalIgContext = null;
        SDL_Quit();
    }

protected:

    /**
        Processes the events for the window.
    */
    void processEvent(const(SDL_Event)* event) { 
        version (UseUIScaling) {
            version (OSX) {
                
                // macOS handles the UI scaling automatically, as such we don't need to do as much cursed shit(TM) there.
                return ImGui_ImplProcessEvent(event);
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
                        return ImGui_ImplProcessEvent(event);
                }
            }
        } else {
            return ImGui_ImplProcessEvent(event);
        }
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

    /**
        The size of the window.
    */
    @property inrecti size() {
        int w, h;
        SDL_GetWindowSize(windowHandle, &w, &h);
        return inrecti(0, 0, w, h);
    }

    /**
        The current SDL flags for the window.
    */
    @property SDL_WindowFlags windowFlags() {
        return SDL_GetWindowFlags(windowHandle);
    }

    /**
        Whether window proceessing should happen.
    */
    @property bool shouldProcess() {
        return (SDL_GetWindowFlags(windowHandle) & SDL_WINDOW_MINIMIZED) == 0;
    }

    /**
        Whether wayland is used as the backing Window Manager subsystem.
    */
    static @property bool isWayland() {
        version(linux) {
            SDL_SysWMinfo info;
            SDL_GetWindowWMInfo(window, &info);
            return info.subsystem == SDL_SYSWM_TYPE.SDL_SYSWM_WAYLAND;
        } else return false;
    }

    /**
        Whether the window manager is a known tiling window manager.
    */
    static @property bool isTilingWM() {
        version(linux) {
            switch(environment.get("XDG_SESSION_DESKTOP")) {
                case "i3":

                // Items beyond this point are just guesstimations.
                case "awesome":
                case "bspwm":
                case "dwm":
                case "echinus":
                case "euclid-wm":
                case "herbstluftwm":
                case "leftwm":
                case "notion":
                case "qtile":
                case "ratpoison":
                case "snapwm":
                case "stumpwm":
                case "subtle":
                case "wingo":
                case "wmfs":
                case "xmonad":
                case "wayfire":
                case "river":
                case "labwc":
                case "hyprland":
                    return true;
                
                default:
                    return false;
            }
        }
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
        Redraws the window.
    */
    void redraw() {

        // Start the Dear ImGui frame
        incGLBackendNewFrame();
        ImGui_ImplSDL2_NewFrame();

        // Do our DPI pre-processing
        igNewFrame();
        incGLBackendBeginRender();

        version(linux) dpUpdate();

        // HACK: prevents the app freezing when files are drag and drop on the nagscreen.
        // freeze is caused by `igSetDragDropPayload()`, so we check if the modal is open.
        if (files.length > 0 && !incModalIsOpen()) {
            if (igBeginDragDropSource(ImGuiDragDropFlags.SourceExtern)) {
                igSetDragDropPayload("__PARTS_DROP", &files, files.sizeof);
                igBeginTooltip();
                foreach(file; files) {
                    import creator.widgets.label : incText;
                    incText(file);
                }
                igEndTooltip();
                igEndDragDropSource();
            }
        } else if (incModalIsOpen()) {
            // clean up the files array
            files.length = 0;
        }

        // Add docking space
        viewportDock = igDockSpaceOverViewport(null, ImGuiDockNodeFlags.NoDockingInCentralNode, null);
        if (!AppSettings.has("firstrun_complete")) {
            incSetDefaultLayout();
            AppSettings.set("firstrun_complete", true);
        }

        // HACK: ImGui Crashes if a popup is rendered on the first frame, let's avoid that.
        if (firstFrame) firstFrame = false;
        else {
            // imgui can not igOpenPopup two popups at the same time, that causes a freeze
            // so we sperate the popups rendering
            if (incModalIsOpen())
                incModalRender();
            else
                incRenderDialogs();
        }

        incStatusUpdate();
        incHandleDialogHandlers();

        // Rendering
        igRender();
        glViewport(0, 0, cast(int)(io.DisplaySize.x*incGetUIScale), cast(int)(io.DisplaySize.y*incGetUIScale));
        glClearColor(0.5, 0.5, 0.5, 1);
        glClear(GL_COLOR_BUFFER_BIT);
        incGLBackendRenderDrawData(igGetDrawData());

        if (io.ConfigFlags & ImGuiConfigFlags.ViewportsEnable) {
            SDL_Window* currentWindow = SDL_GL_GetCurrentWindow();
            SDL_GLContext currentCtx = SDL_GL_GetCurrentContext();
            igUpdatePlatformWindows();
            igRenderPlatformWindowsDefault();
            SDL_GL_MakeCurrent(currentWindow, currentCtx);
        }
        
        version(InBranding) {
            import creator.core.egg : incAdaUpdate;
            incAdaUpdate();
        }
    }

    /**
        Runs a single updat iteration.
    */
    void runOne(bool redraw) {
        SDL_Event event;

        while(SDL_PollEvent(&event)) {
            switch(event.type) {
                case SDL_QUIT:
                    incExitSaveAsk();
                    break;

                case SDL_DROPFILE:
                    files ~= cast(string)event.drop.file.fromStringz;
                    SDL_RaiseWindow(window);
                    break;
                
                default: 
                    this.processEvent(&event);
                    break;
            }
        }
        incTaskUpdate();

        if (redraw) this.redraw();

        incCleanupDialogs();
        SDL_GL_SwapWindow(window);
    }

    /**
        Applies the default UI layout
    */
    void applyDefaultLayout() {
        import creator.panels;
        
        igDockBuilderRemoveNodeChildNodes(viewportDock);
        ImGuiID 
            dockMainID, dockIDNodes, dockIDInspector, dockIDHistory, dockIDParams,
            dockIDToolSettings, dockIDLoggerAndTextureSlots, dockIDTimeline, dockIDAnimList;

        dockMainID = viewportDock;
        dockIDAnimList = igDockBuilderSplitNode(dockMainID, ImGuiDir.Left, 0.10f, null, &dockMainID);
        dockIDNodes = igDockBuilderSplitNode(dockMainID, ImGuiDir.Left, 0.10f, null, &dockMainID);
        dockIDInspector = igDockBuilderSplitNode(dockIDNodes, ImGuiDir.Down, 0.60f, null, &dockIDNodes);
        dockIDToolSettings = igDockBuilderSplitNode(dockMainID, ImGuiDir.Right, 0.10f, null, &dockMainID);
        dockIDHistory = igDockBuilderSplitNode(dockIDToolSettings, ImGuiDir.Down, 0.50f, null, &dockIDToolSettings);
        dockIDTimeline = igDockBuilderSplitNode(dockMainID, ImGuiDir.Down, 0.15f, null, &dockMainID);
        dockIDParams = igDockBuilderSplitNode(dockMainID, ImGuiDir.Left, 0.15f, null, &dockMainID);

        igDockBuilderDockWindow("###Nodes", dockIDNodes);
        igDockBuilderDockWindow("###Inspector", dockIDInspector);
        igDockBuilderDockWindow("###Tool Settings", dockIDToolSettings);
        igDockBuilderDockWindow("###History", dockIDHistory);
        igDockBuilderDockWindow("###Scene", dockIDHistory);
        debug(InExperimental) igDockBuilderDockWindow("###Tracking", dockIDHistory);
        igDockBuilderDockWindow("###Timeline", dockIDTimeline);
        igDockBuilderDockWindow("###Animation List", dockIDAnimList);
        igDockBuilderDockWindow("###Logger", dockIDTimeline);
        igDockBuilderDockWindow("###Parameters", dockIDParams);
        igDockBuilderDockWindow("###Texture Slots", dockIDLoggerAndTextureSlots);

        igDockBuilderFinish(viewportDock);
    }

    /**
        Closes the window and re-registers the context.
    */
    void close() {
        destroy(this);
    }
}