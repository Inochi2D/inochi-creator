module creator.core;
import creator.core.font;
import creator.frames;
import creator;

import bindbc.sdl;
import bindbc.imgui;
import bindbc.opengl;
import inochi2d;
import tinyfiledialogs;
import std.string;
import std.stdio;

private {
    SDL_GLContext gl_context;
    SDL_Window* window;
    ImGuiIO* io;
    bool done = false;
    ImGuiID viewportDock;
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
    loadFont("Kosugi Maru", cast(ubyte[])import("KosugiMaru-Regular.ttf"));

    // Setup Inochi2D
    inInit(() { return igGetTime(); });

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
    Renders the main menu
*/
void incRenderMenu() {
    if(igBeginMainMenuBar()) {
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
            igText("Frames");
            igSeparator();

            foreach(frame; incFrames) {

                // Skip frames that'll always be visible
                if (frame.alwaysVisible) continue;

                // Show menu item for frame
                if(igMenuItemBool(frame.name.ptr, null, frame.visible, true)) frame.visible = !frame.visible;
            }
            igEndMenu();
        }

        igSeparator();
        igText("%.0fms %.1fFPS", 1000f/io.Framerate, io.Framerate);

        igEndMainMenuBar();
    }
}

static this() {
    loadSDL();
    loadImGui();

    SDL_Init(SDL_INIT_EVERYTHING);
}