/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.core;
import creator.core.dpi;
import creator.core.input;
import creator.panels;
import creator.windows;
import creator.utils.link;
import creator;
import creator.widgets.dialog;
import creator.backend.gl;

import std.exception;

import bindbc.sdl;
import bindbc.opengl;
import inochi2d;
import tinyfiledialogs;
import std.string;
import std.stdio;
import std.conv;
import std.range : repeat;

public import bindbc.imgui;
public import bindbc.imgui.ogl;
public import creator.core.settings;
public import creator.core.actionstack;
public import creator.core.tasks;
public import creator.core.path;
public import creator.core.font;
public import creator.core.dpi;
import i18n;

private {
    SDL_GLContext gl_context;
    SDL_Window* window;
    ImGuiIO* io;
    bool done = false;
    ImGuiID viewportDock;

    version (InBranding) {
        Texture incLogo;
        Texture incAda;
    }
    Texture incGrid;

    ImFont* mainFont;

    bool isDarkMode = true;
    string[] files;
    bool isWayland;
    bool isTilingWM;
}

bool incShowStatsForNerds;

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
    Initialize styling
*/
void incInitStyling() {
    auto style = igGetStyle();
    //style.WindowBorderSize = 0;
    style.ChildBorderSize = 1;
    style.PopupBorderSize = 1;
    style.FrameBorderSize = 1;
    style.TabBorderSize = 1;

    style.WindowRounding = 4;
    style.ChildRounding = 0;
    style.FrameRounding = 3;
    style.PopupRounding = 6;
    style.ScrollbarRounding = 18;
    style.GrabRounding = 3;
    style.LogSliderDeadzone = 6;
    style.TabRounding = 6;

    style.IndentSpacing = 10;
    style.ItemSpacing.y = 3;
    style.FramePadding.y = 4;

    style.GrabMinSize = 13;
    style.ScrollbarSize = 14;
    style.ChildBorderSize = 1;
}


/**
    Opens Window
*/
void incOpenWindow() {
    import std.process : environment;
    isWayland = environment.get("XDG_SESSION_TYPE") == "wayland";
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

    auto sdlSupport = loadSDL();
    enforce(sdlSupport != SDLSupport.noLibrary, "SDL2 library not found!");
    enforce(sdlSupport != SDLSupport.badLibrary, "Bad SDL2 library found!");
    
    version(BindImGui_Dynamic)
    {
        auto imSupport = loadImGui();
        enforce(imSupport != ImGuiSupport.noLibrary, "cimgui library not found!");
    
        // HACK: For some reason this check fails on some macOS and Linux installations
        version(Windows) enforce(imSupport != ImGuiSupport.badLibrary, "Bad cimgui library found!");
    }

    SDL_Init(SDL_INIT_EVERYTHING);

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GLprofile.SDL_GL_CONTEXT_PROFILE_CORE);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);

    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
    SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, 8);

    SDL_WindowFlags flags = SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE;

    if (incSettingsGet!bool("WinMax", false)) {
        flags |= SDL_WINDOW_MAXIMIZED;
    }

    // Don't make KDE freak out when Inochi Creator opens
    if (!incSettingsGet!bool("DisableCompositor")) SDL_SetHint(SDL_HINT_VIDEO_X11_NET_WM_BYPASS_COMPOSITOR, "0");

    version(InGallium) {
        import std.process : environment;
        if (incSettingsGet!bool("SoftwareRenderer")) {

            // For Mesa builds, use llvmpipe gallium driver
            environment["GALLIUM_DRIVER"] = "llvmpipe";
        } else {

            // For Mesa builds, use zink gallium driver
            environment["GALLIUM_DRIVER"] = "zink";
        }
    }


    version(InBranding) {
        debug string WIN_TITLE = "Inochi Creator "~_("(Debug Mode)");
        else string WIN_TITLE = "Inochi Creator "~INC_VERSION;
    } else string WIN_TITLE = "Inochi Creator "~_("(Unsupported)");
    
    window = SDL_CreateWindow(
        WIN_TITLE.toStringz, 
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        cast(uint)incSettingsGet!int("WinW", 1280), 
        cast(uint)incSettingsGet!int("WinH", 800), 
        flags
    );
    SDL_SetWindowMinimumSize(window, 960, 720);
    
    GLSupport support;

    // Gallium Support
    version(InGallium) {

        bool incInitGalliumCtx() {
            if (gl_context !is null) SDL_GL_DeleteContext(gl_context);
            gl_context = SDL_GL_CreateContext(window);
            SDL_GL_SetSwapInterval(1);
            support = loadOpenGL();
            return support != GLSupport.noLibrary && support != GLSupport.noContext;
        }
        
        if (!incInitGalliumCtx() && !incSettingsGet!bool("SoftwareRenderer")) {
            debug writeln("Attempting Gallium software rendering...");

            environment["GALLIUM_DRIVER"] = "llvmpipe";
            if (!incInitGalliumCtx()) {
                incSettingsSet("SoftwareRenderer", true);
                throw new Exception("Could not create Gallium Zink nor llvmpipe GL 3.2 instance!");
            }
        }

    } else {

        gl_context = SDL_GL_CreateContext(window);
        SDL_GL_SetSwapInterval(1);

        // Load GL 3
        support = loadOpenGL();
        switch(support) {
            case GLSupport.noLibrary:
                throw new Exception("OpenGL library could not be loaded!");

            case GLSupport.noContext:
                throw new Exception("No valid OpenGL 4.2 context was found!");

            default: break;
        }
    }


    import std.string : fromStringz;
    version(Windows) {
        
        // Windows is heck when it comes to /SUBSYSTEM:windows
    } else {
        debug {
            writefln("GLInfo:\n\t%s\n\t%s\n\t%s\n\t%s\n\tgls=%s",
                glGetString(GL_VERSION).fromStringz,
                glGetString(GL_VENDOR).fromStringz,
                glGetString(GL_RENDERER).fromStringz,
                glGetString(GL_SHADING_LANGUAGE_VERSION).fromStringz,
                support
            );
        }
    }

    // Setup Inochi2D
    inInit(() { return igGetTime(); });

    incCreateContext();

    ShallowTexture tex;
    version (InBranding) {
        // Load image resources
        tex = ShallowTexture(cast(ubyte[])import("logo.png"));
        inTexPremultiply(tex.data);
        incLogo = new Texture(tex);

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
}

void incCreateContext() {

    // Setup IMGUI
    igCreateContext(null);
    io = igGetIO();
    
    // Setup font handling
    incInitFonts();

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

    incInitStyling();
    incInitDialogs();
}

void incSetDarkMode(bool darkMode) {
    auto style = igGetStyle();

    if (darkMode) {
        style.Colors[ImGuiCol.Text]                   = ImVec4(1.00f, 1.00f, 1.00f, 1.00f);
        style.Colors[ImGuiCol.TextDisabled]           = ImVec4(0.50f, 0.50f, 0.50f, 1.00f);
        style.Colors[ImGuiCol.WindowBg]               = ImVec4(0.17f, 0.17f, 0.17f, 1.00f);
        style.Colors[ImGuiCol.ChildBg]                = ImVec4(0.00f, 0.00f, 0.00f, 0.00f);
        style.Colors[ImGuiCol.PopupBg]                = ImVec4(0.08f, 0.08f, 0.08f, 0.94f);
        style.Colors[ImGuiCol.Border]                 = ImVec4(0.00f, 0.00f, 0.00f, 0.16f);
        style.Colors[ImGuiCol.BorderShadow]           = ImVec4(0.00f, 0.00f, 0.00f, 0.16f);
        style.Colors[ImGuiCol.FrameBg]                = ImVec4(0.12f, 0.12f, 0.12f, 1.00f);
        style.Colors[ImGuiCol.FrameBgHovered]         = ImVec4(0.15f, 0.15f, 0.15f, 0.40f);
        style.Colors[ImGuiCol.FrameBgActive]          = ImVec4(0.22f, 0.22f, 0.22f, 0.67f);
        style.Colors[ImGuiCol.TitleBg]                = ImVec4(0.04f, 0.04f, 0.04f, 1.00f);
        style.Colors[ImGuiCol.TitleBgActive]          = ImVec4(0.00f, 0.00f, 0.00f, 1.00f);
        style.Colors[ImGuiCol.TitleBgCollapsed]       = ImVec4(0.00f, 0.00f, 0.00f, 0.51f);
        style.Colors[ImGuiCol.MenuBarBg]              = ImVec4(0.05f, 0.05f, 0.05f, 1.00f);
        style.Colors[ImGuiCol.ScrollbarBg]            = ImVec4(0.02f, 0.02f, 0.02f, 0.53f);
        style.Colors[ImGuiCol.ScrollbarGrab]          = ImVec4(0.31f, 0.31f, 0.31f, 1.00f);
        style.Colors[ImGuiCol.ScrollbarGrabHovered]   = ImVec4(0.41f, 0.41f, 0.41f, 1.00f);
        style.Colors[ImGuiCol.ScrollbarGrabActive]    = ImVec4(0.51f, 0.51f, 0.51f, 1.00f);
        style.Colors[ImGuiCol.CheckMark]              = ImVec4(0.76f, 0.76f, 0.76f, 1.00f);
        style.Colors[ImGuiCol.SliderGrab]             = ImVec4(0.25f, 0.25f, 0.25f, 1.00f);
        style.Colors[ImGuiCol.SliderGrabActive]       = ImVec4(0.60f, 0.60f, 0.60f, 1.00f);
        style.Colors[ImGuiCol.Button]                 = ImVec4(0.39f, 0.39f, 0.39f, 0.40f);
        style.Colors[ImGuiCol.ButtonHovered]          = ImVec4(0.44f, 0.44f, 0.44f, 1.00f);
        style.Colors[ImGuiCol.ButtonActive]           = ImVec4(0.50f, 0.50f, 0.50f, 1.00f);
        style.Colors[ImGuiCol.Header]                 = ImVec4(0.25f, 0.25f, 0.25f, 1.00f);
        style.Colors[ImGuiCol.HeaderHovered]          = ImVec4(0.28f, 0.28f, 0.28f, 0.80f);
        style.Colors[ImGuiCol.HeaderActive]           = ImVec4(0.44f, 0.44f, 0.44f, 1.00f);
        style.Colors[ImGuiCol.Separator]              = ImVec4(0.00f, 0.00f, 0.00f, 1.00f);
        style.Colors[ImGuiCol.SeparatorHovered]       = ImVec4(0.29f, 0.29f, 0.29f, 0.78f);
        style.Colors[ImGuiCol.SeparatorActive]        = ImVec4(0.47f, 0.47f, 0.47f, 1.00f);
        style.Colors[ImGuiCol.ResizeGrip]             = ImVec4(0.35f, 0.35f, 0.35f, 0.00f);
        style.Colors[ImGuiCol.ResizeGripHovered]      = ImVec4(0.40f, 0.40f, 0.40f, 0.00f);
        style.Colors[ImGuiCol.ResizeGripActive]       = ImVec4(0.55f, 0.55f, 0.56f, 0.00f);
        style.Colors[ImGuiCol.Tab]                    = ImVec4(0.00f, 0.00f, 0.00f, 1.00f);
        style.Colors[ImGuiCol.TabHovered]             = ImVec4(0.34f, 0.34f, 0.34f, 0.80f);
        style.Colors[ImGuiCol.TabActive]              = ImVec4(0.25f, 0.25f, 0.25f, 1.00f);
        style.Colors[ImGuiCol.TabUnfocused]           = ImVec4(0.14f, 0.14f, 0.14f, 0.97f);
        style.Colors[ImGuiCol.TabUnfocusedActive]     = ImVec4(0.17f, 0.17f, 0.17f, 1.00f);
        style.Colors[ImGuiCol.DockingPreview]         = ImVec4(0.62f, 0.68f, 0.75f, 0.70f);
        style.Colors[ImGuiCol.DockingEmptyBg]         = ImVec4(0.20f, 0.20f, 0.20f, 1.00f);
        style.Colors[ImGuiCol.PlotLines]              = ImVec4(0.61f, 0.61f, 0.61f, 1.00f);
        style.Colors[ImGuiCol.PlotLinesHovered]       = ImVec4(1.00f, 0.43f, 0.35f, 1.00f);
        style.Colors[ImGuiCol.PlotHistogram]          = ImVec4(0.90f, 0.70f, 0.00f, 1.00f);
        style.Colors[ImGuiCol.PlotHistogramHovered]   = ImVec4(1.00f, 0.60f, 0.00f, 1.00f);
        style.Colors[ImGuiCol.TableHeaderBg]          = ImVec4(0.19f, 0.19f, 0.20f, 1.00f);
        style.Colors[ImGuiCol.TableBorderStrong]      = ImVec4(0.31f, 0.31f, 0.35f, 1.00f);
        style.Colors[ImGuiCol.TableBorderLight]       = ImVec4(0.23f, 0.23f, 0.25f, 1.00f);
        style.Colors[ImGuiCol.TableRowBg]             = ImVec4(0.00f, 0.00f, 0.00f, 0.00f);
        style.Colors[ImGuiCol.TableRowBgAlt]          = ImVec4(1.00f, 1.00f, 1.00f, 0.06f);
        style.Colors[ImGuiCol.TextSelectedBg]         = ImVec4(0.26f, 0.59f, 0.98f, 0.35f);
        style.Colors[ImGuiCol.DragDropTarget]         = ImVec4(1.00f, 1.00f, 0.00f, 0.90f);
        style.Colors[ImGuiCol.NavHighlight]           = ImVec4(0.32f, 0.32f, 0.32f, 1.00f);
        style.Colors[ImGuiCol.NavWindowingHighlight]  = ImVec4(1.00f, 1.00f, 1.00f, 0.70f);
        style.Colors[ImGuiCol.NavWindowingDimBg]      = ImVec4(0.80f, 0.80f, 0.80f, 0.20f);
        style.Colors[ImGuiCol.ModalWindowDimBg]       = ImVec4(0.80f, 0.80f, 0.80f, 0.35f);

        style.FrameBorderSize = 1;
        style.TabBorderSize = 1;
    } else {
        igStyleColorsLight(null);
        style.Colors[ImGuiCol.Border] = ImVec4(0.8, 0.8, 0.8, 0.5);
        style.Colors[ImGuiCol.BorderShadow] = ImVec4(0, 0, 0, 0.05);
        style.Colors[ImGuiCol.TitleBg] = ImVec4(0.902, 0.902, 0.902, 1);
        style.Colors[ImGuiCol.TitleBgActive] = ImVec4(0.98, 0.98, 0.98, 1);
        
        style.Colors[ImGuiCol.Separator] = ImVec4(0.86, 0.86, 0.86, 1);
        
        style.Colors[ImGuiCol.ScrollbarGrab] = ImVec4(0.68, 0.68, 0.68, 1);
        style.Colors[ImGuiCol.ScrollbarGrabActive] = ImVec4(0.68, 0.68, 0.68, 1);
        style.Colors[ImGuiCol.ScrollbarGrabHovered] = ImVec4(0.64, 0.64, 0.64, 1);

        style.Colors[ImGuiCol.FrameBg] = ImVec4(1, 1, 1, 1);
        style.Colors[ImGuiCol.FrameBgHovered] = ImVec4(0.78, 0.88, 1, 1);
        style.Colors[ImGuiCol.FrameBgActive] = ImVec4(0.76, 0.86, 1, 1);

        style.Colors[ImGuiCol.Button] = ImVec4(0.98, 0.98, 0.98, 1);
        style.Colors[ImGuiCol.ButtonHovered] = ImVec4(1, 1, 1, 1);
        style.Colors[ImGuiCol.ButtonActive] = ImVec4(0.8, 0.8, 0.8, 1);
        style.Colors[ImGuiCol.CheckMark] = ImVec4(0, 0, 0, 1);

        style.Colors[ImGuiCol.Tab] = ImVec4(0.98, 0.98, 0.98, 1);
        style.Colors[ImGuiCol.TabHovered] = ImVec4(1, 1, 1, 1);
        style.Colors[ImGuiCol.TabActive] = ImVec4(0.8, 0.8, 0.8, 1);
        style.Colors[ImGuiCol.TabUnfocused] = ImVec4(0.92, 0.92, 0.92, 1);
        style.Colors[ImGuiCol.TabUnfocusedActive] = ImVec4(0.88, 0.88, 0.88, 1);

        style.Colors[ImGuiCol.MenuBarBg] = ImVec4(0.863, 0.863, 0.863, 1);  
        style.Colors[ImGuiCol.PopupBg] = ImVec4(0.941, 0.941, 0.941, 1);  
        style.Colors[ImGuiCol.Header] = ImVec4(0.990, 0.990, 0.990, 1);  
        style.Colors[ImGuiCol.HeaderHovered] = ImVec4(1, 1, 1, 1);  


        style.FrameBorderSize = 1;
    } 


    // Don't draw the silly roll menu
    style.WindowMenuButtonPosition = ImGuiDir.None;

    // Set Dark mode setting
    incSettingsSet("DarkMode", darkMode);
    isDarkMode = darkMode;
}

bool incGetDarkMode() {
    return isDarkMode;
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



    if (files.length > 0) {
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
    }

    // Add docking space
    viewportDock = igDockSpaceOverViewport(null, cast(ImGuiDockNodeFlags)0, null);
    if (!incSettingsCanGet("firstrun_complete")) {
        incSetDefaultLayout();
        incSettingsSet("firstrun_complete", true);
    }

    incRenderDialogs();
    incStatusUpdate();
}

void incSetDefaultLayout() {
    import creator.panels;
    
    igDockBuilderRemoveNodeChildNodes(viewportDock);
    ImGuiID 
        dockMainID, dockIDNodes, dockIDInspector, dockIDHistory, dockIDParams,
        dockIDToolSettings, dockIDLoggerAndTextureSlots;

    dockMainID = viewportDock;
    dockIDNodes = igDockBuilderSplitNode(dockMainID, ImGuiDir.Left, 0.10f, null, &dockMainID);
    dockIDInspector = igDockBuilderSplitNode(dockIDNodes, ImGuiDir.Down, 0.60f, null, &dockIDNodes);
    dockIDToolSettings = igDockBuilderSplitNode(dockMainID, ImGuiDir.Right, 0.10f, null, &dockMainID);
    dockIDHistory = igDockBuilderSplitNode(dockIDToolSettings, ImGuiDir.Down, 0.50f, null, &dockIDToolSettings);
    dockIDParams = igDockBuilderSplitNode(dockMainID, ImGuiDir.Left, 0.15f, null, &dockMainID);
    dockIDLoggerAndTextureSlots = igDockBuilderSplitNode(dockMainID, ImGuiDir.Down, 0.15f, null, &dockMainID);

    igDockBuilderDockWindow("###Nodes", dockIDNodes);
    igDockBuilderDockWindow("###Inspector", dockIDInspector);
    igDockBuilderDockWindow("###Tool Settings", dockIDToolSettings);
    igDockBuilderDockWindow("###History", dockIDHistory);
    igDockBuilderDockWindow("###Tracking", dockIDHistory);
    igDockBuilderDockWindow("###Parameters", dockIDParams);
    igDockBuilderDockWindow("###Texture Slots", dockIDLoggerAndTextureSlots);
    igDockBuilderDockWindow("###Logger", dockIDLoggerAndTextureSlots);

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
                incExit();
                break;

            case SDL_DROPFILE:
                files ~= cast(string)event.drop.file.fromStringz;
                SDL_RaiseWindow(window);
                break;
            
            default: 
                incGLBackendProcessEvent(&event);
                if (
                    event.type == SDL_WINDOWEVENT && 
                    event.window.event == SDL_WINDOWEVENT_CLOSE && 
                    event.window.windowID == SDL_GetWindowID(window)
                ) incExit();
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
        import creator.core.egg;
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