/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.core;
import creator.core.font;
import creator.panels;
import creator.windows;
import creator.utils.link;
import creator;

import std.exception;

import bindbc.sdl;
import bindbc.opengl;
import inochi2d;
import tinyfiledialogs;
import std.string;
import std.stdio;

public import bindbc.imgui;
public import bindbc.imgui.ogl;
public import creator.core.settings;
public import creator.core.actionstack;
public import creator.core.taskstack;
public import creator.core.path;
public import creator.core.font;

private {
    SDL_GLContext gl_context;
    SDL_Window* window;
    ImGuiIO* io;
    bool done = false;
    ImGuiID viewportDock;

    Texture inLogo;

    ImFont* mainFont;
    ImFont* iconFont;
    ImFont* biggerFont;

    bool isDarkMode = true;
    string[] files;
}

bool incShowStatsForNerds;


/**
    Finalizes everything by freeing imgui resources, etc.
*/
void incFinalize() {
    igSaveIniSettingsToDisk(igGetIO().IniFilename);

    // Cleanup
    ImGuiOpenGLBackend.shutdown();
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
    
    import core.stdc.stdlib : exit;

    auto sdlSupport = loadSDL();
    enforce(sdlSupport != SDLSupport.noLibrary, "SDL2 library not found!");
    enforce(sdlSupport != SDLSupport.badLibrary, "Bad SDL2 library found!");
    
    auto imSupport = loadImGui();
    enforce(imSupport != ImGuiSupport.noLibrary, "cimgui library not found!");
    enforce(imSupport != ImGuiSupport.badLibrary, "Bad cimgui library found!");

    SDL_Init(SDL_INIT_EVERYTHING);

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, 0);
    version(OSX) {
		pragma(msg, "Building in macOS support mode...");

		// macOS only supports up to GL 4.1 with some extra stuff
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GLcontextFlag.SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GLprofile.SDL_GL_CONTEXT_PROFILE_CORE);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);
	} else {

        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GLcontextFlag.SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
    }
    debug SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GLcontextFlag.SDL_GL_CONTEXT_DEBUG_FLAG | SDL_GLcontextFlag.SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
    SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);

    SDL_WindowFlags flags = SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE;

    if (incSettingsGet!bool("WinMax", false)) {
        flags |= SDL_WINDOW_MAXIMIZED;
    }

    window = SDL_CreateWindow(
        "Inochi Creator", 
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        cast(uint)incSettingsGet!int("WinW", 1280), 
        cast(uint)incSettingsGet!int("WinH", 800), 
        flags
    );

    gl_context = SDL_GL_CreateContext(window);
    SDL_GL_MakeCurrent(window, gl_context);
    SDL_GL_SetSwapInterval(1);
    
    // Load GL 3
    GLSupport support = loadOpenGL();
    switch(support) {
        case GLSupport.noLibrary:
            throw new Exception("OpenGL library could not be loaded!");

        case GLSupport.noContext:
            throw new Exception("No valid OpenGL 4.2 context was found!");

        default: break;
    }

    import std.string : fromStringz;
    debug {
        writefln("GLInfo:\n\t%s\n\t%s\n\t%s\n\t%s\n\tgls=%s",
            glGetString(GL_VERSION).fromStringz,
            glGetString(GL_VENDOR).fromStringz,
            glGetString(GL_RENDERER).fromStringz,
            glGetString(GL_SHADING_LANGUAGE_VERSION).fromStringz,
            support
        );

        glEnable(GL_DEBUG_OUTPUT);
        version(Posix) {
            glDebugMessageCallback(&incDebugCallback, null);
        }
    }

    // Setup Inochi2D
    inInit(() { return igGetTime(); });

    incCreateContext();


    // Load image resources
    inLogo = new Texture(ShallowTexture(cast(ubyte[])import("logo.png")));

    // Load Settings
    incShowStatsForNerds = incSettingsCanGet("NerdStats") ? incSettingsGet!bool("NerdStats") : false;

    import creator.widgets.titlebar : incSetUseNativeTitlebar, incGetUseNativeTitlebar, incCanUseAppTitlebar;
    incCanUseAppTitlebar = SDL_SetWindowHitTest(incGetWindowPtr(), null, null) != -1;
    incSetUseNativeTitlebar(incSettingsGet("UseNativeTitleBar", false));
    
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

    io.ConfigFlags |= ImGuiConfigFlags.DockingEnable;           // Enable Docking
    io.ConfigFlags |= ImGuiConfigFlags.ViewportsEnable;         // Enable Viewports (causes freezes)
    //io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Navigation
    io.ConfigWindowsResizeFromEdges = true;                     // Enable Edge resizing
    ImGui_ImplSDL2_InitForOpenGL(window, gl_context);
    ImGuiOpenGLBackend.init(null);

    incInitStyling();
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
    }
    else {
        igStyleColorsLight(null);
        style.Colors[ImGuiCol.Border] = ImVec4(0.8, 0.8, 0.8, 0.5);
        style.Colors[ImGuiCol.BorderShadow] = ImVec4(0, 0, 0, 0.05);

        style.FrameBorderSize = 1;
    }

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

void incGetWindowSize(out int w, out int h) {
    SDL_GetWindowSize(window, &w, &h);
}

void incFinishFileDrag() {
    files.length = 0;
}

void incBeginLoopNoEv() {
    // Start the Dear ImGui frame
    ImGuiOpenGLBackend.new_frame();
    ImGui_ImplSDL2_NewFrame();

    int w, h;
    SDL_GetWindowSize(window, &w, &h);
    auto scale = incGetUIScale();
    auto io = igGetIO();
    io.DisplayFramebufferScale = ImVec2(scale, scale);
    io.DisplaySize = ImVec2(w/scale, h/scale);
    //io.MousePos = ImVec2(io.MousePos.x/scale, io.MousePos.y/scale);

    igNewFrame();

    if (files.length > 0) {
        if (igBeginDragDropSource(ImGuiDragDropFlags.SourceExtern)) {
            igSetDragDropPayload("__PARTS_DROP", &files, files.sizeof);
            igBeginTooltip();
            foreach(file; files) {
                igText(file.toStringz);
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
}

void incSetDefaultLayout() {
    import creator.panels;
    
    igDockBuilderRemoveNodeChildNodes(viewportDock);
    ImGuiID 
        dockMainID, dockIDNodes, dockIDInspector, dockIDHistory, dockIDParams,
        dockIDLoggerAndTextureSlots;

    dockMainID = viewportDock;
    dockIDNodes = igDockBuilderSplitNode(dockMainID, ImGuiDir.Left, 0.10f, null, &dockMainID);
    dockIDInspector = igDockBuilderSplitNode(dockIDNodes, ImGuiDir.Down, 0.60f, null, &dockIDNodes);
    dockIDHistory = igDockBuilderSplitNode(dockMainID, ImGuiDir.Right, 0.10f, null, &dockMainID);
    dockIDParams = igDockBuilderSplitNode(dockMainID, ImGuiDir.Left, 0.15f, null, &dockMainID);
    dockIDLoggerAndTextureSlots = igDockBuilderSplitNode(dockMainID, ImGuiDir.Down, 0.10f, null, &dockMainID);

    igDockBuilderDockWindow("###Nodes", dockIDNodes);
    igDockBuilderDockWindow("###Inspector", dockIDInspector);
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
                ImGui_ImplSDL2_ProcessEvent(&event);
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

    // Rendering
    igRender();
    glViewport(0, 0, cast(int)io.DisplaySize.x, cast(int)io.DisplaySize.y);
    glClearColor(0.5, 0.5, 0.5, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    auto io = igGetIO();
    auto draw = igGetDrawData();
    auto scale = incGetUIScale();
    //draw.FramebufferScale = ImVec2(io.DisplayFramebufferScale.x, io.DisplayFramebufferScale.y);
    //draw.DisplaySize = ImVec2(/draw.FramebufferScale.x, io.DisplaySize.y/draw.FramebufferScale.y);

    // ImDrawData_ScaleClipRects(draw, draw.FramebufferScale);
    // foreach(i; 0..draw.CmdListsCount) {
    //     ImDrawList* list = draw.CmdLists[i];
    //     foreach(vi; 0..list.VtxBuffer.Size) {
    //         ImDrawVert* v = &list.VtxBuffer.Data[vi];
    //         v.pos.x += draw.FramebufferScale.x;
    //         v.pos.y += draw.FramebufferScale.y;
    //     }
    // }

    //ImDrawData_ScaleClipRects(draw, draw.FramebufferScale);
    ImGuiOpenGLBackend.render_draw_data(draw);

    if (io.ConfigFlags & ImGuiConfigFlags.ViewportsEnable) {
        SDL_Window* currentWindow = SDL_GL_GetCurrentWindow();
        SDL_GLContext currentCtx = SDL_GL_GetCurrentContext();
        igUpdatePlatformWindows();


        // SDL_DisplayMode dm;
        // SDL_GetCurrentDisplayMode(0, &dm);
        // io.DisplaySize = ImVec2(dm.w/scale, dm.h/scale);

        igRenderPlatformWindowsDefault();
        SDL_GL_MakeCurrent(currentWindow, currentCtx);
    }

    SDL_GL_SwapWindow(window);
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

/**
    Bigger sized font
*/
ImFont* incBiggerFont() {
    return biggerFont;
}

/**
    Bigger sized font
*/
ImFont* incIconFont() {
    return iconFont;
}

/**
    Gets the Inochi2D Logo
*/
GLuint incGetLogo() {
    return inLogo.getTextureId;
}

void incHandleShortcuts() {
    auto io = igGetIO();
    
    if (io.KeyCtrl && io.KeyShift && igIsKeyPressed(igGetKeyIndex(ImGuiKey.Z), true)) {
        incActionRedo();
    } else if (io.KeyCtrl && igIsKeyPressed(igGetKeyIndex(ImGuiKey.Z), true)) {
        incActionUndo();
    }
}


debug {
    extern(C)
    void incDebugCallback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const(char)* message, void* userParam) nothrow {
        import core.stdc.stdio : fprintf, stderr;
        if (type == 0x8251) return;

        // HACK: I have no clue what causes this error
        // but everything seems to work nontheless
        // I'll just quietly ignore it.
        if (type == 0x824c) return; 

        fprintf(stderr, "GL CALLBACK: %s type = 0x%x, severity = 0x%x, message = %s\n",
           ( type == GL_DEBUG_TYPE_ERROR ? cast(char*)"** GL ERROR **" : cast(char*)"" ),
            type, severity, message );

    }
}