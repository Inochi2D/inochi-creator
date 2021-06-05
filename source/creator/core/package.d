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

private {
    SDL_GLContext gl_context;
    SDL_Window* window;
    ImGuiIO* io;
    bool done = false;
    ImGuiID viewportDock;

    Texture inLogo;

    ImFont* mainFont;
    ImFont* biggerFont;

    bool showStatsForNerds;
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

    // Setup IMGUI
    igCreateContext(null);
    io = igGetIO();

    io.ConfigFlags |= ImGuiConfigFlags_DockingEnable;           // Enable Docking
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;       // Enable Keyboard Navigation
    io.ConfigWindowsResizeFromEdges = true;                     // Enable Edge resizing
    igStyleColorsDark(null);
    ImGui_ImplSDL2_InitForOpenGL(window, gl_context);
    ImGuiOpenGLBackend.init("#version 130\0".ptr);

    // Font loading
    mainFont = loadFont("Kosugi Maru", cast(ubyte[])import("KosugiMaru-Regular.ttf"));
    biggerFont = loadFont("Kosugi Maru", cast(ubyte[])import("KosugiMaru-Regular.ttf"), 18);

    // Setup Inochi2D
    inInit(() { return igGetTime(); });

    // Load image resources
    inLogo = new Texture(ShallowTexture(cast(ubyte[])import("logo.png")));

    // Load Settings
    showStatsForNerds = incSettingsCanGet("NerdStats") ? incSettingsGet!bool("NerdStats") : false;
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
    Gets the Inochi2D Logo
*/
GLuint incGetLogo() {
    return inLogo.getTextureId;
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
    }
}

static this() {
    loadSDL();
    loadImGui();

    SDL_Init(SDL_INIT_EVERYTHING);
}