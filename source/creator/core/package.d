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

    bool showStatsForNerds;
    bool dbgShowStyleEditor;
    bool dbgShowDebugger;

    bool isDarkMode = true;
}

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
    style.ChildBorderSize = 0;
    style.PopupBorderSize = 0;
    style.FrameBorderSize = 0;
    style.TabBorderSize = 0;

    style.WindowRounding = 6;
    style.ChildRounding = 6;
    style.FrameRounding = 6;
    style.PopupRounding = 6;
    style.ScrollbarRounding = 18;
    style.GrabRounding = 6;
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
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, 0);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GLcontextFlag.SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
    SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
    window = SDL_CreateWindow("Inochi Creator", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 1024, 1024, SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE);
    
    gl_context = SDL_GL_CreateContext(window);
    SDL_GL_MakeCurrent(window, gl_context);
    SDL_GL_SetSwapInterval(1);
    loadOpenGL();

    // Setup Inochi2D
    inInit(() { return igGetTime(); });

    incCreateContext();


    // Load image resources
    inLogo = new Texture(ShallowTexture(cast(ubyte[])import("logo.png")));

    // Load Settings
    showStatsForNerds = incSettingsCanGet("NerdStats") ? incSettingsGet!bool("NerdStats") : false;

    // Font loading
    incUseOpenDyslexic(incSettingsGet!bool("UseOpenDyslexic"));
}

void incCreateContext() {

    // Setup IMGUI
    igCreateContext(null);
    io = igGetIO();

    incSetDarkMode(incSettingsGet!bool("DarkMode", true));

    io.ConfigFlags |= ImGuiConfigFlags_DockingEnable;           // Enable Docking
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;       // Enable Keyboard Navigation
    io.ConfigWindowsResizeFromEdges = true;                     // Enable Edge resizing
    ImGui_ImplSDL2_InitForOpenGL(window, gl_context);
    ImGuiOpenGLBackend.init("#version 130\0".ptr);

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
        igStyleColorsDark(null);
        style.Colors[ImGuiCol_Border] = ImVec4(0, 0, 0, 0.5);
        style.FrameBorderSize = 0;
    }
    else {
        igStyleColorsLight(null);
        style.Colors[ImGuiCol_Border] = ImVec4(0.8, 0.8, 0.8, 0.5);
        style.Colors[ImGuiCol_BorderShadow] = ImVec4(0, 0, 0, 0.05);

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
    Begins the Inochi Creator rendering loop
*/
void incBeginLoop() {

    SDL_Event event;
    while(SDL_PollEvent(&event)) {
        ImGui_ImplSDL2_ProcessEvent(&event);
        if (event.type == SDL_QUIT)
            done = true;
        if (event.type == SDL_WINDOWEVENT && event.window.event == SDL_WINDOWEVENT_CLOSE && event.window.windowID == SDL_GetWindowID(window))
            done = true;
    }
    
    incFontsProcessChanges();

    mainFont = incFontsGet(0);
    iconFont = incFontsGet(1);
    biggerFont = incFontsGet(2);

    // Start the Dear ImGui frame
    ImGuiOpenGLBackend.new_frame();
    ImGui_ImplSDL2_NewFrame(window);
    igNewFrame();

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

/**
    Renders the main menu
*/
void incRenderMenu() {
    if(igBeginMainMenuBar()) {
        ImVec2 avail;
        igGetContentRegionAvail(&avail);
        igImage(cast(void*)inLogo.getTextureId, ImVec2(avail.y*2, avail.y*2), ImVec2(0, 0), ImVec2(1, 1), ImVec4(1, 1, 1, 1), ImVec4(0, 0, 0, 0));
        igSeparator();

        if (igBeginMenu("File", true)) {
            if (igBeginMenu("Open", true)) {
                igEndMenu();
            }
            
            if(igMenuItemBool("Save", "Ctrl+S", false, true)) {
            }
            
            if(igMenuItemBool("Save As...", "Ctrl+Shift+S", false, true)) {
            }

            if (igBeginMenu("Import", true)) {
                if(igMenuItemBool("Inochi Puppet", "", false, true)) {
                    const TFD_Filter[] filters = [
                        { ["*.inp"], "Inochi2D Puppet (*.inp)" }
                    ];

                    c_str filename = tinyfd_openFileDialog("Import...", "", filters, false);
                    if (filename !is null) {
                        string file = cast(string)filename.fromStringz;
                        incNewProject();
                        incActiveProject().puppet = inLoadPuppet(file);
                    }
                }
                igEndMenu();
            }
            if (igBeginMenu("Export", true)) {
                if(igMenuItemBool("Inochi Puppet", "", false, true)) {
                    const TFD_Filter[] filters = [
                        { ["*.inp"], "Inochi2D Puppet (*.inp)" }
                    ];

                    c_str filename = tinyfd_saveFileDialog("Export...", "", filters);
                    if (filename !is null) {
                        string file = cast(string)filename.fromStringz;
                        inWriteINPPuppet(incActivePuppet(), file);
                    }
                }
                igEndMenu();
            }

            if(igMenuItemBool("Quit", "Alt+F4", false, true)) incExit();
            igEndMenu();
        }
        
        if (igBeginMenu("Edit", true)) {
            if(igMenuItemBool("Undo", "Ctrl+Z", false, incActionCanUndo())) incActionUndo();
            if(igMenuItemBool("Redo", "Ctrl+Shift+Z", false, incActionCanRedo())) incActionRedo();
            
            igSeparator();
            if(igMenuItemBool("Cut", "Ctrl+X", false, false)) {}
            if(igMenuItemBool("Copy", "Ctrl+C", false, false)) {}
            if(igMenuItemBool("Paste", "Ctrl+V", false, false)) {}

            igSeparator();
            if(igMenuItemBool("Settings", "", false, true)) {
                if (!incIsSettingsOpen) incPushWindow(new SettingsWindow);
            }
            
            debug {
                igSpacing();
                igSpacing();

                igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "ImGui Debugging");

                igSeparator();
                if(igMenuItemBool("Style Editor", "", false, true)) dbgShowStyleEditor = !dbgShowStyleEditor;
                if(igMenuItemBool("ImGui Debugger", "", false, true)) dbgShowDebugger = !dbgShowDebugger;
            }
            igEndMenu();
        }

        if (igBeginMenu("View", true)) {
            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Frames");
            igSeparator();

            foreach(frame; incFrames) {

                // Skip frames that'll always be visible
                if (frame.alwaysVisible) continue;

                // Show menu item for frame
                if(igMenuItemBool(frame.name.ptr, null, frame.visible, true)) {
                    frame.visible = !frame.visible;
                    incSettingsSet(frame.name~".visible", frame.visible);
                }
            }

            // Spacing
            igSpacing();
            igSpacing();
            
            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Extras");
            igSeparator();

            if (igMenuItemBool("Show Stats for Nerds", "", showStatsForNerds, true)) {
                showStatsForNerds = !showStatsForNerds;
                incSettingsSet("NerdStats", showStatsForNerds);
            }

            igEndMenu();
        }

        if (igBeginMenu("Help", true)) {

            if(igMenuItemBool("Tutorial", "(TODO)", false, false)) { }
            igSeparator();
            
            if(igMenuItemBool("Online Documentation", "", false, true)) {
                openLink("https://github.com/Inochi2D/inochi-creator/wiki");
            }
            
            if(igMenuItemBool("Inochi2D Documentation", "", false, true)) {
                openLink("https://github.com/Inochi2D/inochi2d/wiki");
            }
            igSeparator();

            if(igMenuItemBool("About", "", false, true)) {
                incPushWindow(new AboutWindow);
            }
            igEndMenu();
        }

        if (showStatsForNerds) {
            igSeparator();
            igText("%.0fms %.1fFPS", 1000f/io.Framerate, io.Framerate);
        }

        igEndMainMenuBar();

        if (dbgShowStyleEditor) igShowStyleEditor(igGetStyle());
        if (dbgShowDebugger) igShowAboutWindow(&dbgShowDebugger);
    }
}

void incHandleShortcuts() {
    auto io = igGetIO();
    
    if (io.KeyCtrl && io.KeyShift && igIsKeyPressed(igGetKeyIndex(ImGuiKey_Z), false)) {
        incActionRedo();
    } else if (io.KeyCtrl && igIsKeyPressed(igGetKeyIndex(ImGuiKey_Z), false)) {
        incActionUndo();
    }
}

static this() {
    loadSDL();
    loadImGui();

    SDL_Init(SDL_INIT_EVERYTHING);
}