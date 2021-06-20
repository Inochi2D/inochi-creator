module creator.core;
import creator.core.font;
import creator.frames;
import creator.windows;
import creator.utils.link;
import creator;

import bindbc.sdl;
import bindbc.opengl;
import inochi2d;
import tinyfiledialogs;
import std.string;
import std.stdio;

public import bindbc.imgui;
public import creator.core.settings;
public import creator.core.actionstack;

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

    style.WindowRounding = 0;
    style.ChildRounding = 0;
    style.FrameRounding = 6;
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
    // Load GL 1
    loadOpenGL();

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, 0);
    version(OSX) {
		pragma(msg, "Building in macOS support mode...");

		// macOS only supports up to GL 4.1 with some extra stuff
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GLcontextFlag.SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GLprofile.SDL_GL_CONTEXT_PROFILE_CORE);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
	} else {

        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GLcontextFlag.SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
    }
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
    SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
    window = SDL_CreateWindow("Inochi Creator", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 1024, 1024, SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE);

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
    writefln("GLInfo:\n\t%s\n\t%s\n\t%s\n\t%s\n\tgls=%s",
        glGetString(GL_VERSION).fromStringz,
        glGetString(GL_VENDOR).fromStringz,
        glGetString(GL_RENDERER).fromStringz,
        glGetString(GL_SHADING_LANGUAGE_VERSION).fromStringz,
        support
    );

    // Setup Inochi2D
    inInit(() { return igGetTime(); });

    incCreateContext();


    // Load image resources
    inLogo = new Texture(ShallowTexture(cast(ubyte[])import("logo.png")));

    // Load Settings
    incShowStatsForNerds = incSettingsCanGet("NerdStats") ? incSettingsGet!bool("NerdStats") : false;

    import creator.widgets.titlebar : incSetUseNativeTitlebar, incGetUseNativeTitlebar;
    incSetUseNativeTitlebar(incSettingsGet("UseNativeTitleBar", false));
    
    // Font loading
    incUseOpenDyslexic(incSettingsGet!bool("UseOpenDyslexic"));
}

void incCreateContext() {

    // Setup IMGUI
    igCreateContext(null);
    io = igGetIO();

    incSetDarkMode(incSettingsGet!bool("DarkMode", true));

    io.ConfigFlags |= ImGuiConfigFlags.DockingEnable;           // Enable Docking
    //io.ConfigFlags |= ImGuiConfigFlags.ViewportsEnable;           // Enable Viewports (causes freezes)
    //io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;       // Enable Keyboard Navigation
    io.ConfigWindowsResizeFromEdges = true;                     // Enable Edge resizing
    ImGui_ImplSDL2_InitForOpenGL(window, gl_context);
    ImGuiOpenGLBackend.init("#version 330");

    incInitStyling();
}

void incRecreateContext() {
    ImGuiOpenGLBackend.shutdown();
    ImGui_ImplSDL2_Shutdown();
    igDestroyContext(null);
    
    incCreateContext();

    // Inochi2D's camera gets messed up by context
    // recreation, redo it
    inGetCamera().position = incTargetPosition;
    inGetCamera().scale = vec2(incTargetZoom);
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
        style.Colors[ImGuiCol.Header]                 = ImVec4(0.25f, 0.25f, 0.25f, 0.31f);
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

void incFinishFileDrag() {
    files.length = 0;
}

/**
    Begins the Inochi Creator rendering loop
*/
void incBeginLoop() {
    SDL_Event event;

    while(SDL_PollEvent(&event)) {
        switch(event.type) {
            case SDL_QUIT:
                done = true;
                break;

            case SDL_DROPFILE:
                files ~= cast(string)event.drop.file.fromStringz;
                SDL_RaiseWindow(window);
                break;
            
            default: 
                ImGui_ImplSDL2_ProcessEvent(&event);
                if (event.type == SDL_WINDOWEVENT && event.window.event == SDL_WINDOWEVENT_CLOSE && event.window.windowID == SDL_GetWindowID(window))
                    done = true;
                break;
        }
    }

    
    incFontsProcessChanges();

    mainFont = incFontsGet(0);
    iconFont = incFontsGet(1);
    biggerFont = incFontsGet(2);

    // Start the Dear ImGui frame
    ImGuiOpenGLBackend.new_frame();
    ImGui_ImplSDL2_NewFrame(window);
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
    ImGuiOpenGLBackend.render_draw_data(igGetDrawData());
    SDL_GL_SwapWindow(window);
    igUpdatePlatformWindows();
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

void incSetFontPair(string fontPair) {
    incFontsClear();
    switch(fontPair) {
        default:
        case "Kosugi Maru":
            incFontsLoad("Kosugi Maru", cast(ubyte[])import("KosugiMaru-Regular.ttf"));
            incFontsLoad(
                "MaterialIcons", 
                cast(ubyte[])import("MaterialIcons.ttf"), 
                16, 
                [cast(ImWchar)0xE000, cast(ImWchar)0xF23B].ptr, // Range aquired from CharMap
                false
            );
            incFontsLoad("Kosugi Maru", cast(ubyte[])import("KosugiMaru-Regular.ttf"), 18);
            break;
        case "OpenDyslexic":
            incFontsLoad("OpenDyslexic", cast(ubyte[])import("OpenDyslexic.otf"), 18);
            incFontsLoad(
                "MaterialIcons", 
                cast(ubyte[])import("MaterialIcons.ttf"), 
                18, 
                [cast(ImWchar)0xE000, cast(ImWchar)0xF23B].ptr, // Range aquired from CharMap
                false
            );
            incFontsLoad("OpenDyslexic", cast(ubyte[])import("OpenDyslexic.otf"), 24);
            break;
    }
}

void incUseOpenDyslexic(bool useOpenDyslexic) {
    incSetFontPair(useOpenDyslexic ? "OpenDyslexic" : "Kosugi Maru");
    incSettingsSet("UseOpenDyslexic", useOpenDyslexic);
}

void incHandleShortcuts() {
    auto io = igGetIO();
    
    if (io.KeyCtrl && io.KeyShift && igIsKeyPressed(igGetKeyIndex(ImGuiKey.Z), false)) {
        incActionRedo();
    } else if (io.KeyCtrl && igIsKeyPressed(igGetKeyIndex(ImGuiKey.Z), false)) {
        incActionUndo();
    }
}

static this() {
    loadSDL();
    loadImGui();

    SDL_Init(SDL_INIT_EVERYTHING);
}