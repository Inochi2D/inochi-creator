/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.core;
import creator.core.dpi;
import creator.core.input;
import creator.core.egg;
import creator.panels;
import creator.windows;
import creator.utils.link;
import creator;
import creator.widgets.dialog;
import creator.widgets.modal;
import creator.io.autosave;
import creator.io.save;

import std.exception;

import bindbc.sdl;
import bindbc.opengl;
import inochi2d;
import std.string;
import std.stdio;
import std.conv;
import std.range : repeat;

public import i2d.imgui;
public import i2d.imgui.ogl;
public import creator.core.settings;
public import creator.core.actionstack;
public import creator.core.tasks;
public import creator.core.path;
public import creator.core.font;
public import creator.core.dpi;
import i18n;

version(OSX) {
    enum const(char)*[] SDL_VERSIONS = ["libSDL2.dylib", "libSDL2-2.0.dylib", "libSDL2-2.0.0.dylib"];
} else version(Windows) {
    enum const(char)*[] SDL_VERSIONS = ["SDL2.dll"];
} else {
    enum const(char)*[] SDL_VERSIONS = [
        "libSDL2-2.0.so.0",
        "libSDL2-2.0.so",
        "libSDL2.so",
        "/usr/local/lib/libSDL2-2.0.so.0",
        "/usr/local/lib/libSDL2-2.0.so",
        "/usr/local/lib/libSDL2.so",
    ];
}

version(linux) {
    import dportals;
}

private {
    SDL_GLContext gl_context;
    SDL_Window* window;
    ImGuiIO* io;
    bool done = false;
    ImGuiID viewportDock;
    bool firstFrame = true;

    version (InBranding) {
        Texture incLogoI2D;
        Texture incLogo;
        Texture incAda;
    }
    Texture incGrid;

    ImFont* mainFont;

    bool isDarkMode = true;
    string[] files;
    bool isWayland;
    bool isTilingWM;

    
    ImVec4[ImGuiCol.COUNT] incDarkModeColors;
    ImVec4[ImGuiCol.COUNT] incLightModeColors;

    SDL_Window* tryCreateWindow(string title, SDL_WindowFlags flags) {
        auto w = SDL_CreateWindow(
            title.toStringz, 
            SDL_WINDOWPOS_UNDEFINED,
            SDL_WINDOWPOS_UNDEFINED,
            cast(uint)incSettingsGet!int("WinW", 1280), 
            cast(uint)incSettingsGet!int("WinH", 800), 
            flags
        );
        if (w) SDL_SetWindowMinimumSize(window, 960, 720);
        return w;
    }

}

bool incShowStatsForNerds;
bool incShouldPostProcess = false;

bool incIsWayland() {
    return isWayland;
}

bool incIsTilingWM() {
    return isTilingWM;
}

/**
    Finalizes everything by freeing imgui resources, etc.
*/
void incFinalize() {

    // This is important to prevent thread leakage
    import creator.viewport.test : incViewportTestWithdraw;
    incViewportTestWithdraw();

    // Save settings
    igSaveIniSettingsToDisk(igGetIO().IniFilename);

    // Cleanup
    incGLBackendShutdown();
    ImGui_ImplSDL2_Shutdown();
    igDestroyContext(null);

    SDL_GL_DeleteContext(gl_context);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

/**
    Gets dockspace of the viewport
*/
ImGuiID incGetViewportDockSpace() {
    return viewportDock;
}

/**
    Opens Window
*/
void incOpenWindow() {
    import std.process : environment;
    import std.string : fromStringz;

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
            isTilingWM = true;
            break;
        
        default:
            isTilingWM = false;
            break;
    }


    // Load SDL2 in the order required for Steam
    foreach(ver; SDL_VERSIONS) {
        auto sdlSupport = loadSDL(ver);

        if (sdlSupport != SDLSupport.noLibrary && 
            sdlSupport != SDLSupport.badLibrary) break;
    }

    // Whomp whomp
    enforce(sdlSupport != SDLSupport.noLibrary, "SDL2 library not found!");
    enforce(sdlSupport != SDLSupport.badLibrary, "Bad SDL2 library found!");
    
    version(BindImGui_Dynamic) {
        auto imSupport = loadImGui();
        enforce(imSupport != ImGuiSupport.noLibrary, "cimgui library not found!");
    
        // HACK: For some reason this check fails on some macOS and Linux installations
        version(Windows) enforce(imSupport != ImGuiSupport.badLibrary, "Bad cimgui library found!");
    }

    
    int code = SDL_Init(SDL_INIT_EVERYTHING & ~SDL_INIT_AUDIO);
    enforce(
        code == 0,
        "Error initializing SDL2! %s".format(SDL_GetError().fromStringz)
    );

    SDL_WindowFlags flags = SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI;

    if (incSettingsGet!bool("WinMax", false)) {
        flags |= SDL_WINDOW_MAXIMIZED;
    }

    // Don't make KDE freak out when Inochi Creator opens
    if (!incSettingsGet!bool("DisableCompositor")) SDL_SetHint(SDL_HINT_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR, "0");
    SDL_SetHint(SDL_HINT_IME_SHOW_UI, "1");

    version(InBranding) {
        debug string WIN_TITLE = "Inochi Creator "~_("(Debug Mode)");
        else string WIN_TITLE = "Inochi Creator "~INC_VERSION;
    } else string WIN_TITLE = "Inochi Creator "~_("(Unsupported)");
    
    window = tryCreateWindow(WIN_TITLE, flags);
    
    // On Linux we want to check whether the window was created under wayland or x11
    version(linux) {
        SDL_SysWMinfo info;
        SDL_GetWindowWMInfo(window, &info);
        isWayland = info.subsystem == SDL_SYSWM_TYPE.SDL_SYSWM_WAYLAND;
    }

    GLSupport support;
    gl_context = SDL_GL_CreateContext(window);
    if (!gl_context) {
        SDL_DestroyWindow(window);

        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GLprofile.SDL_GL_CONTEXT_PROFILE_CORE);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);
        window = tryCreateWindow(WIN_TITLE, flags);
        gl_context = SDL_GL_CreateContext(window);
    }
    enforce(gl_context !is null, "Failed to create GL 3.2 or 3.1 core context!");
    SDL_GL_SetSwapInterval(1);

    // Load GL 3
    support = loadOpenGL();
    switch(support) {
        case GLSupport.noLibrary:
            throw new Exception("OpenGL library could not be loaded!");

        case GLSupport.noContext:
            throw new Exception("No valid OpenGL context was found!");

        default: break;
    }


    import std.string : fromStringz;
    version(Windows) {
        
        // Windows is heck when it comes to /SUBSYSTEM:windows
    } else {
    }

    // Setup Inochi2D
    inInit(() { return igGetTime(); });
    
    version(InBranding) incInitAda();
    incCreateContext();

    ShallowTexture tex;
    version (InBranding) {

        // Load image resources
        tex = ShallowTexture(cast(ubyte[])import("logo.png"));
        inTexPremultiply(tex.data);
        incLogoI2D = new Texture(tex);

        // Load image resources
        tex = ShallowTexture(cast(ubyte[])import("icon.png"));
        inTexPremultiply(tex.data);
        incLogo = new Texture(tex);

        // Set X11 window icon
        version(linux) {
            if (!isWayland) {
                SDL_SetWindowIcon(window, SDL_CreateRGBSurfaceWithFormatFrom(tex.data.ptr, tex.width, tex.height, 32, 4*tex.width,  SDL_PIXELFORMAT_RGBA32));
            }
        }

        tex = ShallowTexture(cast(ubyte[])import("ui/ui-ada.png"));
        inTexPremultiply(tex.data);
        incAda = new Texture(tex);
    }

    // Grid texture
    tex = ShallowTexture(cast(ubyte[])import("ui/grid.png"));
    inTexPremultiply(tex.data);
    incGrid = new Texture(tex);
    incGrid.setFiltering(Filtering.Point);
    incGrid.setWrapping(Wrapping.Repeat);

    // Load Settings
    incShowStatsForNerds = incSettingsCanGet("NerdStats") ? incSettingsGet!bool("NerdStats") : false;

    version(linux) {
        dpInit();
    }
}

void incCreateContext() {

    // Setup IMGUI
    auto ctx = igCreateContext(null);
    io = igGetIO();

    import std.file : exists;
    if (!exists(incGetAppImguiConfigFile())) {
        // TODO: Setup a base config
    }


    // Copy string out of GC memory to make sure it doesn't get yeeted before imgui exits.
    import core.stdc.stdlib : malloc;
    import core.stdc.string : memcpy;
    io.IniFilename = cast(char*)malloc(incGetAppImguiConfigFile().length+1);
    memcpy(cast(void*)io.IniFilename, toStringz(incGetAppImguiConfigFile), incGetAppImguiConfigFile().length+1);
    igLoadIniSettingsFromDisk(io.IniFilename);

    incSetDarkMode(incSettingsGet!bool("DarkMode", true));

    io.ConfigFlags |= ImGuiConfigFlags.DockingEnable;                               // Enable Docking
    io.ConfigWindowsResizeFromEdges = true;                                         // Enable Edge resizing
    version (OSX) io.ConfigMacOSXBehaviors = true;                                  // macOS Behaviours on macOS

    // Force C locale due to imgui removing support for setting decimal separator.
    import i18n.culture : i18nSetLocale;
    i18nSetLocale("C");

    // NOTE: Viewports break DPI scaling system, as such if Viewports is enabled
    // we will be disable DPI scaling.
    version(NoUIScaling) {
        if (!incIsTilingWM) io.ConfigFlags |= ImGuiConfigFlags.ViewportsEnable;         // Enable Viewports (causes freezes)
    } else {
        incInitDPIScaling();
    }

    //io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;                         // Enable Keyboard Navigation
    ImGui_ImplSDL2_InitForOpenGL(window, gl_context);
    incGLBackendInit(null);

    // Setup font handling
    incInitFonts();

    incInitStyling();
    incInitDialogs();
    incResetClearColor();
}

/**
    Gets whether a frame should be processed
*/
bool incShouldProcess() {
    return (SDL_GetWindowFlags(window) & SDL_WINDOW_MINIMIZED) == 0;
}

/**
    Gets SDL Window Pointer
*/
SDL_Window* incGetWindowPtr() {
    return window;
}

void incFinishFileDrag() {
    files.length = 0;
}

void incBeginLoopNoEv() {
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
    if (!incSettingsCanGet("firstrun_complete")) {
        incSetDefaultLayout();
        incSettingsSet("firstrun_complete", true);
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
}

void incSetDefaultLayout() {
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
    Begins the Inochi Creator rendering loop
*/
void incBeginLoop() {
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
                incGLBackendProcessEvent(&event);
                break;
        }
    }

    incTaskUpdate();

    // Begin loop post-event
    incBeginLoopNoEv();
}

/**
    Ends the Inochi Creator rendering loop
*/
void incEndLoop() {
    // incGLBackendEndRender();

    incCleanupDialogs();

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

    SDL_GL_SwapWindow(window);
}

/**
    Prints ImGui debug info
*/
void incDebugImGuiState(string msg, int indent = 0) {
    debug(imgui) {
        static int currentIndent = 0;

        string flag = "  ";
        if (indent > 0) {
            currentIndent += indent;
            flag = ">>";
        } else if (indent < 0) {
            flag = "<<";
        }

        //auto g = igGetCurrentContext();
        auto win = igGetCurrentWindow();
        writefln(
            "%s%s%s [%s]", ' '.repeat(currentIndent * 2), flag, msg,
            to!string(win.Name)
        );

        if (indent < 0) {
            currentIndent += indent;
            if (currentIndent < 0) {
                debug writeln("ERROR: dedented too far!");
                currentIndent = 0;
            }
        }
    }
}

/**
    Resets the clear color
*/
void incResetClearColor() {
    inSetClearColor(0, 0, 0, 0);
}

/**
    Gets whether Inochi Creator has requested the app to close
*/
bool incIsCloseRequested() {
    return done;
}

/**
    Exit Inochi Creator
*/
void incExit() {
    done = true;

    int w, h;
    SDL_WindowFlags flags;
    flags = SDL_GetWindowFlags(window);
    SDL_GetWindowSize(window, &w, &h);
    incSettingsSet("WinW", w);
    incSettingsSet("WinH", h);
    incSettingsSet!bool("WinMax", (flags & SDL_WINDOW_MAXIMIZED) > 0);
    incReleaseLockfile();
}

/**
    check project has changes
*/
bool incIsProjectModified() {
    // TODO: we need more detailed check, maybe history action stack or tracking all changes
    // currently just assume user history action stack should record all changes
    // if not record, it is action stack bug
    return !incIsActionStackEmpty();
}

/**
    Main font
*/
ImFont* incMainFont() {
    return mainFont;
}

version (InBranding) {
    /**
        Gets the Inochi2D Logo
    */
    Texture incGetLogo() {
        return incLogo;
    }

    /**
        Gets the Ada texture
    */
    Texture incGetAda() {
        return incAda;
    }

    Texture incGetLogoI2D() {
        return incLogoI2D;
    }
}

/**
    Gets the grid texture
*/
Texture incGetGrid() {
    return incGrid;
}

void incHandleShortcuts() {
    auto io = igGetIO();
    
    if (incShortcut("Ctrl+Shift+Z", true)) {
        incActionRedo();
    } else if (incShortcut("Ctrl+Z", true)) {
        incActionUndo();
    }
}

void incSetWindowTitle(string subtitle) {
    if (subtitle.length > 0) SDL_SetWindowTitle(window, ("Inochi Creator - "~subtitle).toStringz);
    else SDL_SetWindowTitle(window, "Inochi Creator");
}