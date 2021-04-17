module core.imgui_surface;
import core.glsurface;
import core.rinit;
import core.itime;
import gtk.GLArea;
import gtk.EventBox;
import gtk.Widget;
import bindbc.opengl;
import std.stdio;
import safew;
import gtk.Widget;
import gdk.FrameClock;
import gdk.GLContext;

import core.project;

import gtk.Application;
import gtk.ApplicationWindow;
import gdk.GLContext;
import gtk.Widget;
import gdk.Event;
import bindbc.sdl,
       bindbc.sdl.dynload,
       bindbc.imgui.dynload,
       bindbc.imgui.bind.imgui,
       bindbc.opengl;

import std.functional;

import bindbc.imgui.ImGuiOpenGLBackend;

class ImGuiSurface : GLSurface {
private:
    // ImGui test state
    bool show_demo_window = true;
    bool show_another_window = false;
    ImVec4 clear_color = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);

    // Main loop
    bool done = false;

public:

    this() {
    }

    override void initialize() {
            igCreateContext(null);
            ImGuiIO* io = igGetIO();
            //io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls
            //io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls
            io.ConfigFlags |= ImGuiConfigFlags_DockingEnable;           // Enable Docking
            io.ConfigFlags |= ImGuiConfigFlags_ViewportsEnable;         // Enable Multi-Viewport / Platform Windows

            // Setup Dear ImGui style
            igStyleColorsDark(null);
            //igStyleColorsClassic();

            // Setup Platform/Renderer backends
            //ImGui_ImplSDL2_InitForOpenGL(window, gl_context);
            imgui_gtk_init(this);
            bindbc.imgui.ImGuiOpenGLBackend.init("#version 130");
    }
    
    override void update(double delta_time) {
        ImGuiIO* io = igGetIO();

        // Start the Dear ImGui frame
        bindbc.imgui.ImGuiOpenGLBackend.new_frame();
        imgui_gtk_new_frame(cast(GLSurface)this);
        igNewFrame();

        igDockSpaceOverViewport(null, cast(ImGuiDockNodeFlags)0, null);

        // 1. Show the big demo window (Most of the sample code is in igShowDemoWindow()! You can browse its code to learn more about Dear ImGui!).
        if (show_demo_window)
            igShowDemoWindow(&show_demo_window);

        // 2. Show a simple window that we create ourselves. We use a Begin/End pair to created a named window.
        {
            static float f = 0.0f;
            static int counter = 0;

            igBegin("Hello, world!", null, cast(ImGuiWindowFlags)0);                          // Create a window called "Hello, world!" and append into it.

            igCheckbox("Left Mouse Down", &io.MouseDown[0]);
            igCheckbox("Right Mouse Down", &io.MouseDown[2]);
            igInputFloat2("Mouse Position", cast(float[2]*)&io.MousePos, null, 0);

            igText("This is some useful text.");               // Display some text (you can use a format strings too)
            igCheckbox("Demo Window", &show_demo_window);      // Edit bools storing our window open/close state
            igCheckbox("Another Window", &show_another_window);

            igSliderFloat("float", &f, 0.0f, 1.0f, null, 0);            // Edit 1 float using a slider from 0.0f to 1.0f
            //igColorEdit3("clear color", cast(float*)&clear_color.x); // Edit 3 floats representing a color

            if (igButton("Button", ImVec2(0,0)))                            // Buttons return true when clicked (most widgets return true when edited/activated)
                counter++;
            igSameLine(0,0);
            igText("counter = %d", counter);

            igText("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / igGetIO().Framerate, igGetIO().Framerate);
            igEnd();
        }

        // 3. Show another simple window.
        if (show_another_window)
        {
            igBegin("Another Window", &show_another_window, 0);   // Pass a pointer to our bool variable (the window will have a closing button that will clear the bool when clicked)
            igText("Hello from another window!");
            if (igButton("Close Me", ImVec2(0,0)))
                show_another_window = false;
            igEnd();
        }
        
        igRender();

        // Rendering
        //igUpdatePlatformWindows();
    }

    override void draw(double deltaTime) {
        // hacky hack hack hack
        this.getViewport().setCanFocus(true);
        this.getViewport().grabFocus();

        //this.getViewport().add


        ImGuiIO* io = igGetIO();
        
        this.getViewport().makeCurrent();
        glClearColor(0, 0, 0, 0);
        glViewport(0, 0, cast(int)io.DisplaySize.x, cast(int)io.DisplaySize.y);

        auto drawData = igGetDrawData();
        if (drawData != null)
            bindbc.imgui.ImGuiOpenGLBackend.render_draw_data(drawData);
    }
}







class ImGuiManagedSurface : GLSurface {
private:
public:

    this() {
    }

    override void initialize() {
    }
    
    override void update(double delta_time) {
    }

    override void draw(double deltaTime) {
    }
}









































import core.stdc.float_;
import gdk.Cursor;
import gdk.Device;
import gdk.Keymap;
import gdk.Keysyms;
import gdk.Window;
import glib.TimeVal;
import gtk.Clipboard;
import gtk.Widget;
import std.conv;

GdkAtom MakeAtom(int u)
{
    return cast(GdkAtom)(cast(void*)(cast(long)(u)));
}

const GdkAtom cGdkSelectionClipboard = MakeAtom(69); // not a joke, this really is 69. This was very annoying to figure out how to do.

const int cEventMask = GdkEventMask.STRUCTURE_MASK |
      GdkEventMask.FOCUS_CHANGE_MASK |
      GdkEventMask.EXPOSURE_MASK |
      GdkEventMask.PROPERTY_CHANGE_MASK |
      GdkEventMask.ENTER_NOTIFY_MASK |
      GdkEventMask.LEAVE_NOTIFY_MASK |
      GdkEventMask.KEY_PRESS_MASK |
      GdkEventMask.KEY_RELEASE_MASK |
      GdkEventMask.BUTTON_PRESS_MASK |
      GdkEventMask.BUTTON_RELEASE_MASK |
      GdkEventMask.POINTER_MOTION_MASK |
      GdkEventMask.SMOOTH_SCROLL_MASK |
      GdkEventMask.SCROLL_MASK;

      
struct gdk_key_to_imgui_key_map
{
    this(ImGuiKey_ a, uint b) {
		this.imgui = a;
		this.gdk = b;
	}

    ImGuiKey_ imgui;
    uint gdk;
}

shared immutable gdk_key_to_imgui_key_map[] gdk_key_to_imgui_key;
//shared immutable string[string] cTypeMap;

shared static this()
{
    gdk_key_to_imgui_key =
            [
                gdk_key_to_imgui_key_map(ImGuiKey_Tab, GdkKeysyms.GDK_Tab),
                gdk_key_to_imgui_key_map(ImGuiKey_Tab, GdkKeysyms.GDK_ISO_Left_Tab),
                gdk_key_to_imgui_key_map(ImGuiKey_LeftArrow, GdkKeysyms.GDK_Left),
                gdk_key_to_imgui_key_map(ImGuiKey_RightArrow, GdkKeysyms.GDK_Right),
                gdk_key_to_imgui_key_map(ImGuiKey_UpArrow, GdkKeysyms.GDK_Up),
                gdk_key_to_imgui_key_map(ImGuiKey_DownArrow, GdkKeysyms.GDK_Down),
                gdk_key_to_imgui_key_map(ImGuiKey_PageUp, GdkKeysyms.GDK_Page_Up),
                gdk_key_to_imgui_key_map(ImGuiKey_PageDown, GdkKeysyms.GDK_Page_Down),
                gdk_key_to_imgui_key_map(ImGuiKey_Home, GdkKeysyms.GDK_Home),
                gdk_key_to_imgui_key_map(ImGuiKey_End, GdkKeysyms.GDK_End),
                gdk_key_to_imgui_key_map(ImGuiKey_Delete, GdkKeysyms.GDK_Delete),
                gdk_key_to_imgui_key_map(ImGuiKey_Backspace, GdkKeysyms.GDK_BackSpace),
                gdk_key_to_imgui_key_map(ImGuiKey_Enter, GdkKeysyms.GDK_Return),
                gdk_key_to_imgui_key_map(ImGuiKey_Escape, GdkKeysyms.GDK_Escape),
                gdk_key_to_imgui_key_map(ImGuiKey_A, GdkKeysyms.GDK_a),
                gdk_key_to_imgui_key_map(ImGuiKey_C, GdkKeysyms.GDK_c),
                gdk_key_to_imgui_key_map(ImGuiKey_V, GdkKeysyms.GDK_v),
                gdk_key_to_imgui_key_map(ImGuiKey_X, GdkKeysyms.GDK_x),
                gdk_key_to_imgui_key_map(ImGuiKey_Y, GdkKeysyms.GDK_y),
                gdk_key_to_imgui_key_map(ImGuiKey_Z, GdkKeysyms.GDK_z),
            ];
}

// Data
static Uint64           g_Time = 0;
static bool[5]          g_MousePressed = [ false, false, false, false, false ];
static ImVec2           g_MousePosition = ImVec2(-FLT_MAX, -FLT_MAX);
static float            g_MouseWheel = 0.0f;
static Cursor[ImGuiMouseCursor_COUNT] g_MouseCursors = [];
static GLSurface[] g_Surfaces;
static Clipboard g_Clipboard;

static const (char)* imgui_gtk_get_clipboard_text(void* user_data)
{
    static string last_clipboard;
    last_clipboard = g_Clipboard.waitForText();
    return last_clipboard.ptr;
}

static void imgui_gtk_set_clipboard_text(void* user_data, const (char)* text)
{
    string clip = to!string(text);
    g_Clipboard.setText(clip, clip.sizeof);
}


bool imgui_gtk_handle_event(Event event, Widget widget)
{
    ImGuiIO* io = igGetIO();

    switch (event.type)
    {
    case GdkEventType.MOTION_NOTIFY:
    {
        g_MousePosition = ImVec2(event.motion().x, event.motion().y);
        break;
    }
    case GdkEventType.BUTTON_PRESS:
    case GdkEventType.BUTTON_RELEASE:
    {
        g_MousePressed[event.button().button - 1] = event.type == GdkEventType.BUTTON_PRESS;
        break;
    }
    case GdkEventType.SCROLL:
    {
        g_MouseWheel = -event.scroll().y;
        break;
    }
    case GdkEventType.KEY_PRESS:
    case GdkEventType.KEY_RELEASE:
    {
        GdkEventKey* e = event.key();

        foreach (key; gdk_key_to_imgui_key)
        {
            if (e.keyval == key.gdk)
                io.KeysDown[key.imgui] = event.type == GdkEventType.KEY_PRESS;
        }

        if (e.keyval >= ImGuiKey_COUNT && e.keyval < io.KeysDown.sizeof)
            io.KeysDown[e.keyval] = event.type == GdkEventType.KEY_PRESS;

        if (event.type == GdkEventType.KEY_PRESS && (0 != Keymap.keyvalToUnicode(e.keyval)))
        {
            //import std.utf;
            //import glib.Unicode;
            //
            //char[32] buffer;
            //int charactersWritten = Unicode.unicharToUtf8(cast(dchar)Keymap.keyvalToUnicode(e.keyval), cast(char[])buffer);
            //string utf8String = to!string(buffer.ptr);
            //ImGuiIO_AddInputCharactersUTF8(&io, utf8String.ptr);
        }

        struct mods_map{
            this(bool* a, GdkModifierType b, GdkKeysyms[3] c) {
                this.var = a;
                this.modifier = b;
                this.keyvals = c;
            }

            bool* var;
            GdkModifierType modifier;
            GdkKeysyms[3] keyvals;
        } 
        
        mods_map[] mods = [
            mods_map(&io.KeyCtrl, GdkModifierType.CONTROL_MASK, [ GdkKeysyms.GDK_Control_L, GdkKeysyms.GDK_Control_R, cast(GdkKeysyms)0 ]),
            mods_map(&io.KeyShift, GdkModifierType.SHIFT_MASK, [ GdkKeysyms.GDK_Shift_L, GdkKeysyms.GDK_Shift_R, cast(GdkKeysyms)0 ]),
            mods_map(&io.KeyAlt, GdkModifierType.MOD1_MASK, [ GdkKeysyms.GDK_Alt_L, GdkKeysyms.GDK_Alt_R, cast(GdkKeysyms)0 ]),
            mods_map(&io.KeySuper, GdkModifierType.SUPER_MASK, [ GdkKeysyms.GDK_Super_L, GdkKeysyms.GDK_Super_R, cast(GdkKeysyms)0 ],)
        ];
        

        foreach (mod; mods)
        {
            *mod.var = (mod.modifier & e.state) > 0;

            bool match = false;
            for (int j = 0; mod.keyvals[j] != 0; j++)
                if (e.keyval == mod.keyvals[j])
                    match = true;

            if (match)
                *mod.var = event.type == GdkEventType.KEY_PRESS;
        }
        break;
    }
    default:
        break;
    }

    //gtk_gl_area_queue_render(GTK_GL_AREA(g_GtkGlArea));
    //gtk_widget_queue_draw(g_GtkGlArea);

    return true;
}

import gdk.Atom;

bool imgui_gtk_init(ImGuiSurface surface)
{
    g_Surfaces.length += 1;
    g_Surfaces[g_Surfaces.length - 1] = surface;

    //if (g_Surfaces.length > 1)
    //{
    //    return;
    //}

    surface.getViewport().setCanFocus(true);
    surface.getViewport().grabFocus();
    surface.getViewport().addEvents(cEventMask);
    surface.getViewport().addOnEvent(toDelegate(&imgui_gtk_handle_event));

    ImGuiIO* io = igGetIO();

    io.BackendFlags |= ImGuiBackendFlags_HasMouseCursors;       // We can honor GetMouseCursor() values (optional)
    io.BackendFlags |= ImGuiBackendFlags_PlatformHasViewports;  // We can create multi-viewports on the Platform side (optional)

    for (int i = 0; i < ImGuiKey_COUNT; i++)
    {
        io.KeyMap[i] = i;
    }

    //io.SetClipboardTextFn = imgui_gtk_set_clipboard_text;
    //io.GetClipboardTextFn = imgui_gtk_get_clipboard_text;
    //io.ClipboardUserData = null;
    //g_Clipboard = surface.getViewport().getClipboard(cGdkSelectionClipboard);

    auto display = surface.getViewport().getDisplay();
    g_MouseCursors[ImGuiMouseCursor_Arrow] = new Cursor(display, "default");
    g_MouseCursors[ImGuiMouseCursor_TextInput] = new Cursor(display, "text");
    g_MouseCursors[ImGuiMouseCursor_ResizeAll] = new Cursor(display, "all-scroll");
    g_MouseCursors[ImGuiMouseCursor_ResizeNS] = new Cursor(display, "ns-resize");
    g_MouseCursors[ImGuiMouseCursor_ResizeEW] = new Cursor(display, "ew-resize");
    g_MouseCursors[ImGuiMouseCursor_ResizeNESW] = new Cursor(display, "nesw-resize");
    g_MouseCursors[ImGuiMouseCursor_ResizeNWSE] = new Cursor(display, "nwse-resize");
    g_MouseCursors[ImGuiMouseCursor_Hand] = new Cursor(display, "pointer");
    
    imgui_gtk_update_monitors();
    imgui_gtk_init_platform_interface(surface);

    return true;
}

static void imgui_gtk_update_mouse_cursor(Window window)
{
    const ImGuiIO* io = igGetIO();
    if (io.ConfigFlags & ImGuiConfigFlags_NoMouseCursorChange)
        return;

    ImGuiMouseCursor imgui_cursor = igGetMouseCursor();
    if (imgui_cursor != ImGuiMouseCursor_None && !io.MouseDrawCursor)
        window.setCursor(g_MouseCursors[imgui_cursor]);
}

void imgui_gtk_new_frame(GLSurface surface)
{
    ImGuiIO* io = igGetIO();

    // Setup display size (every frame to accommodate for window resizing)
    GtkAllocation allocation;
    surface.getViewport().getAllocation(allocation);
    
    io.DisplaySize = ImVec2(cast(float)allocation.width, cast(float)allocation.height);
    const int scale_factor = surface.getViewport().getScaleFactor();
    io.DisplayFramebufferScale = ImVec2(scale_factor, scale_factor);

    // Setup time step
    const long current_time = TimeVal.getMonotonicTime();
    io.DeltaTime = g_Time > 0 ? (cast(float)(current_time - g_Time) / 1_000_000.0f) : cast(float)(1.0f/60.0f);
    g_Time = current_time;

    // Setup inputs
    if (surface.getViewport().hasFocus())
    {
        io.MousePos = g_MousePosition;   // Mouse position in screen coordinates (set to -1,-1 if no mouse / on another screen, etc.)
    }
    else
    {
        io.MousePos = ImVec2(-FLT_MAX, -FLT_MAX);
    }
    
    Window window = surface.getViewport().getWindow();


    GdkModifierType modifiers;
    window.getDisplay().getDeviceManager().getClientPointer().getState(window, null, modifiers);

    io.MouseDown[0] = g_MousePressed[0]; // left
    io.MouseDown[1] = g_MousePressed[1]; // right
    io.MouseDown[2] = g_MousePressed[2]; // middle
    //g_MousePressed[0] = false;
    //g_MousePressed[1] = false;
    //g_MousePressed[2] = false;

    io.MouseWheel = g_MouseWheel;
    g_MouseWheel = 0.0f;

    imgui_gtk_update_mouse_cursor(window);
    imgui_gtk_update_monitors();
}




static void imgui_gtk_update_monitors()
{
    import gdk.Display;
    import gdk.DisplayManager;
    import gdk.MonitorG;
    import gdk.Screen;

    ImGuiPlatformIO* platform_io = igGetPlatformIO();

    ImVector!ImGuiPlatformMonitor tempVecDoNotInteract;
    tempVecDoNotInteract.Size = platform_io.Monitors.Size;
    tempVecDoNotInteract.Capacity = platform_io.Monitors.Capacity;
    tempVecDoNotInteract.Data = platform_io.Monitors.Data;

    tempVecDoNotInteract.resize(0);
    Screen screen = Screen.getDefault();
    for (int i = 0; i < Screen.getDefault().getNMonitors(); ++i)
    {
        ImGuiPlatformMonitor monitor;        
        
        GdkRectangle rect;
        screen.getMonitorGeometry(i, rect);
        monitor.MainPos = monitor.WorkPos = ImVec2(cast(float)rect.x, cast(float)rect.y);
        monitor.MainSize = monitor.WorkSize = ImVec2(cast(float)rect.width, cast(float)rect.height);

        monitor.DpiScale = screen.getMonitorScaleFactor(i);
        tempVecDoNotInteract.push_back(&monitor);
    }

    platform_io.Monitors.Size = tempVecDoNotInteract.Size;
    platform_io.Monitors.Capacity = tempVecDoNotInteract.Capacity;
    platform_io.Monitors.Data = tempVecDoNotInteract.Data;
}










import gtk.Window : GtkImGuiWindow = Window;


extern (C)
{
    // Helper structure we store in the void* RenderUserData field of each ImGuiViewport to easily retrieve our backend data.
    struct ImGuiViewportDataGtk
    {
        ImGuiSurface mainSurface;
        ImGuiManagedSurface surface;
        GtkImGuiWindow gtkWindow;
        bool isMinimized = false;
        bool isOwned = true;
    //    SDL_Window*     Window;
    //    Uint32          WindowID;
    //    bool            WindowOwned;
    //    SDL_GLContext   GLContext;
    //
    //    ImGuiViewportDataGtk() { Window = NULL; WindowID = 0; WindowOwned = false; GLContext = NULL; }
    ////    ~ImGuiViewportDataGtk() { IM_ASSERT(Window == NULL && GLContext == NULL); }
    }

    static void imgui_gtk_create_window(ImGuiViewport* viewport)
    {
        ImGuiViewportDataGtk* data = new ImGuiViewportDataGtk;
        viewport.PlatformUserData = data;
        viewport.PlatformHandle = data;

        ImGuiViewport* main_viewport = igGetMainViewport();
        ImGuiViewportDataGtk* main_viewport_data = cast(ImGuiViewportDataGtk*)main_viewport.PlatformUserData;
    //
    //    // Share GL resources with main context
    //    bool use_opengl = (main_viewport_data.GLContext != NULL);
    //    SDL_GLContext backup_context = NULL;
    //    if (use_opengl)
    //    {
    //        backup_context = SDL_GL_GetCurrentContext();
    //        SDL_GL_SetAttribute(SDL_GL_SHARE_WITH_CURRENT_CONTEXT, 1);
    //        SDL_GL_MakeCurrent(main_viewport_data.Window, main_viewport_data.GLContext);
    //    }

        data.gtkWindow = new GtkImGuiWindow("imgui window");
        data.gtkWindow.move(cast(double)viewport.Pos.x, cast(double)viewport.Pos.y);
        data.gtkWindow.setDecorated(false);
        data.gtkWindow.setDefaultSize(cast(int)viewport.Size.x, cast(int)viewport.Size.y);
        data.surface = new ImGuiManagedSurface();
        data.gtkWindow.add(data.surface);
        
        //window.setSizeRe(cast(int)viewport.Size.x, cast(int)viewport.Size.y);

    //    Uint32 sdl_flags = 0;
    //    sdl_flags |= use_opengl ? SDL_WINDOW_OPENGL : (g_UseVulkan ? SDL_WINDOW_VULKAN : 0);
    //    sdl_flags |= SDL_GetWindowFlags(g_Window) & SDL_WINDOW_ALLOW_HIGHDPI;
    //    sdl_flags |= SDL_WINDOW_HIDDEN;
    //    sdl_flags |= (viewport.Flags & ImGuiViewportFlags_NoDecoration) ? SDL_WINDOW_BORDERLESS : 0;
    //    sdl_flags |= (viewport.Flags & ImGuiViewportFlags_NoDecoration) ? 0 : SDL_WINDOW_RESIZABLE;
    //#if !defined(_WIN32)
    //    // See SDL hack in ImGui_ImplSDL2_ShowWindow().
    //    sdl_flags |= (viewport.Flags & ImGuiViewportFlags_NoTaskBarIcon) ? SDL_WINDOW_SKIP_TASKBAR : 0;
    //#endif
    //#if SDL_HAS_ALWAYS_ON_TOP
    //    sdl_flags |= (viewport.Flags & ImGuiViewportFlags_TopMost) ? SDL_WINDOW_ALWAYS_ON_TOP : 0;
    //#endif
    //    data.Window = SDL_CreateWindow("No Title Yet", (int)viewport.Pos.x, (int)viewport.Pos.y, (int)viewport.Size.x, (int)viewport.Size.y, sdl_flags);
    //    data.WindowOwned = true;
    //    if (use_opengl)
    //    {
    //        data.GLContext = SDL_GL_CreateContext(data.Window);
    //        SDL_GL_SetSwapInterval(0);
    //    }
    //    if (use_opengl && backup_context)
    //        SDL_GL_MakeCurrent(data.Window, backup_context);
    //
        viewport.PlatformHandle = cast(void*)&data.gtkWindow;
    //#if defined(_WIN32)
    //    SDL_SysWMinfo info;
    //    SDL_VERSION(&info.version);
    //    if (SDL_GetWindowWMInfo(data.Window, &info))
    //        viewport.PlatformHandleRaw = info.info.win.window;
    //#endif
    }

    static void imgui_gtk_destroy_window(ImGuiViewport* viewport)
    {
        if (ImGuiViewportDataGtk* data = cast(ImGuiViewportDataGtk*)viewport.PlatformUserData)
        {
            data.surface.destroy();
            data.gtkWindow.destroy();
        }

        viewport.PlatformUserData = viewport.PlatformHandle = null;
    }

    static void imgui_gtk_show_window(ImGuiViewport* viewport)
    {
        ImGuiViewportDataGtk* data = cast(ImGuiViewportDataGtk*)viewport.PlatformUserData;
        data.gtkWindow.showAll();
    }

    static ImVec2 imgui_gtk_get_window_pos(ImGuiViewport* viewport)
    {
        writeln("ID: ", viewport.ID);
        writeln("Flags: ", viewport.Flags);
        writeln("Pos: ", viewport.Pos);
        writeln("Size: ", viewport.Size);
        writeln("WorkPos: ", viewport.WorkPos);
        writeln("WorkSize: ", viewport.WorkSize);
        writeln("DpiScale: ", viewport.DpiScale);
        writeln("ParentViewportId: ", viewport.ParentViewportId);
        writeln("DrawData: ", viewport.DrawData);
        writeln("RendererUserData: ", viewport.RendererUserData);
        writeln("PlatformUserData: ", viewport.PlatformUserData);
        writeln("PlatformHandle: ", viewport.PlatformHandle);
        writeln("PlatformHandleRaw: ", viewport.PlatformHandleRaw);
        writeln("PlatformRequestMove: ", viewport.PlatformRequestMove);
        writeln("PlatformRequestResize: ", viewport.PlatformRequestResize);
        writeln("PlatformRequestClose: ", viewport.PlatformRequestClose);

        void* test = viewport.PlatformUserData;
        ImGuiViewportDataGtk* data = cast(ImGuiViewportDataGtk*)test;
        if (data.isOwned == false) 
            return ImVec2(0.0f, 0.0f);

        int x = 0;
        int y = 0;
        data.gtkWindow.getPosition(x, y);
        return ImVec2(cast(float)x, cast(float)y);
    }

    static void imgui_gtk_set_window_pos(ImGuiViewport* viewport, ImVec2 pos)
    {
        ImGuiViewportDataGtk* data = cast(ImGuiViewportDataGtk*)viewport.PlatformUserData;
        data.gtkWindow.move(pos.x, pos.y);
    }

    static ImVec2 imgui_gtk_get_window_size(ImGuiViewport* viewport)
    {
        ImGuiViewportDataGtk* data = cast(ImGuiViewportDataGtk*)viewport.PlatformUserData;
        int x = 0;
        int y = 0;
        data.gtkWindow.getSize(x, y);
        return ImVec2(cast(float)x, cast(float)y);
    }

    static void imgui_gtk_set_window_size(ImGuiViewport* viewport, ImVec2 size)
    {
    //    ImGuiViewportDataGtk* data = cast(ImGuiViewportDataGtk*)viewport.PlatformUserData;
    //    SDL_SetWindowSize(data.Window, (int)size.x, (int)size.y);
    }

    static void imgui_gtk_set_window_title(ImGuiViewport* viewport, const char* title)
    {
        ImGuiViewportDataGtk* data = cast(ImGuiViewportDataGtk*)viewport.PlatformUserData;
        data.gtkWindow.setTitle(to!string(title));
    }

    ////#if SDL_HAS_WINDOW_ALPHA
    //static void imgui_gtk_set_window_alpha(ImGuiViewport* viewport, float alpha)
    //{
    ////    ImGuiViewportDataGtk* data = cast(ImGuiViewportDataGtk*)viewport.PlatformUserData;
    ////    SDL_SetWindowOpacity(data.Window, alpha);
    //}
    ////#endif

    static void imgui_gtk_set_window_focus(ImGuiViewport* viewport)
    {
        ImGuiViewportDataGtk* data = cast(ImGuiViewportDataGtk*)viewport.PlatformUserData;
        data.gtkWindow.present();
    }

    static bool imgui_gtk_get_window_focus(ImGuiViewport* viewport)
    {
        ImGuiViewportDataGtk* data = cast(ImGuiViewportDataGtk*)viewport.PlatformUserData;
        return data.gtkWindow.isActive();
    }

    static bool imgui_gtk_get_window_minimized(ImGuiViewport* viewport)
    {
        ImGuiViewportDataGtk* data = cast(ImGuiViewportDataGtk*)viewport.PlatformUserData;
        return data.isMinimized;
    }

    static void imgui_gtk_render_window(ImGuiViewport* viewport, void*)
    {
        ImGuiViewportDataGtk* data = cast(ImGuiViewportDataGtk*)viewport.PlatformUserData;
        data.surface.getViewport().makeCurrent();
    }

    static void imgui_gtk_swap_buffers(ImGuiViewport* viewport, void*)
    {
    //    ImGuiViewportDataGtk* data = cast(ImGuiViewportDataGtk*)viewport.PlatformUserData;
    //    if (data.GLContext)
    //    {
    //        SDL_GL_MakeCurrent(data.Window, data.GLContext);
    //        SDL_GL_SwapWindow(data.Window);
    //    }
    }
}

static void imgui_gtk_init_platform_interface(ImGuiSurface surface)
{
    // Register platform interface (will be coupled with a renderer interface)
    ImGuiPlatformIO* platform_io = igGetPlatformIO();
    platform_io.Platform_CreateWindow = &imgui_gtk_create_window;
    platform_io.Platform_DestroyWindow = &imgui_gtk_destroy_window;
    platform_io.Platform_ShowWindow = &imgui_gtk_show_window;
    platform_io.Platform_SetWindowPos = &imgui_gtk_set_window_pos;
    platform_io.Platform_GetWindowPos = &imgui_gtk_get_window_pos;
    platform_io.Platform_SetWindowSize = &imgui_gtk_set_window_size;
    platform_io.Platform_GetWindowSize = &imgui_gtk_get_window_size;
    platform_io.Platform_SetWindowFocus = &imgui_gtk_set_window_focus;
    platform_io.Platform_GetWindowFocus = &imgui_gtk_get_window_focus;
    platform_io.Platform_GetWindowMinimized = &imgui_gtk_get_window_minimized;
    platform_io.Platform_SetWindowTitle = &imgui_gtk_set_window_title;
    platform_io.Platform_RenderWindow = &imgui_gtk_render_window;
    platform_io.Platform_SwapBuffers = &imgui_gtk_swap_buffers;
//#if SDL_HAS_WINDOW_ALPHA
//    platform_io.Platform_SetWindowAlpha = imgui_gtk_SetWindowAlpha;
//#endif
//#if SDL_HAS_VULKAN
//    platform_io.Platform_CreateVkSurface = imgui_gtk_CreateVkSurface;
//#endif
//
//    // SDL2 by default doesn't pass mouse clicks to the application when the click focused a window. This is getting in the way of our interactions and we disable that behavior.
//#if SDL_HAS_MOUSE_FOCUS_CLICKTHROUGH
//    SDL_SetHint(SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH, "1");
//#endif
//
    // Register main window handle (which is owned by the main application, not by us)
    // This is mostly for simplicity and consistency, so that our code (e.g. mouse handling etc.) can use same logic for main and secondary viewports.
    ImGuiViewport* main_viewport = igGetMainViewport();
    ImGuiViewportDataGtk* data = cast(ImGuiViewportDataGtk*)igMemAlloc(ImGuiViewportDataGtk.sizeof);
    data.mainSurface = surface;
    data.isOwned = false;
    main_viewport.PlatformUserData = cast(void*)data;
    main_viewport.PlatformHandle = cast(void*)data;
}

static void imgui_gtk_ShutdownPlatformInterface()
{
}










/*


import gdk.Keysyms; //keys enums are defined here
import gdk.Cursor;
import gtk.Clipboard;


static Cursor[ImGuiMouseCursor_COUNT] gMouseCursors;

void imgui_gtkd_init(Widget widget) {
    // Setup back-end capabilities flags
    ImGuiIO* io = igGetIO();
    io.BackendFlags |= ImGuiBackendFlags_HasMouseCursors;       // We can honor GetMouseCursor() values (optional)
    //io.BackendFlags |= ImGuiBackendFlags_HasSetMousePos;        // We can honor io.WantSetMousePos requests (optional, rarely used)
    io.BackendPlatformName = "imgui_impl_gtkd";
	
    // Keyboard mapping. ImGui will use those indices to peek into the io.KeysDown[] array.
    
    // Need to default to -1 to let ImGui know these are currently unmapped.
    for (int i = 0; i < ImGuiKey_COUNT; ++i)
        io.KeyMap[i] = -1;

    io.KeyMap[ImGuiKey_Tab] = to_sdl(GdkKeysyms.GDK_Tab);
    io.KeyMap[ImGuiKey_LeftArrow] = to_sdl(GdkKeysyms.GDK_Left);
    io.KeyMap[ImGuiKey_RightArrow] = to_sdl(GdkKeysyms.GDK_Right);
    io.KeyMap[ImGuiKey_UpArrow] = to_sdl(GdkKeysyms.GDK_Up);
    io.KeyMap[ImGuiKey_DownArrow] = to_sdl(GdkKeysyms.GDK_Down);
    io.KeyMap[ImGuiKey_PageUp] = to_sdl(GdkKeysyms.GDK_Page_Up);
    io.KeyMap[ImGuiKey_PageDown] = to_sdl(GdkKeysyms.GDK_Page_Down);
    io.KeyMap[ImGuiKey_Home] = to_sdl(GdkKeysyms.GDK_Home);
    io.KeyMap[ImGuiKey_End] = to_sdl(GdkKeysyms.GDK_End);
    io.KeyMap[ImGuiKey_Insert] = to_sdl(GdkKeysyms.GDK_Insert);
    io.KeyMap[ImGuiKey_Delete] = to_sdl(GdkKeysyms.GDK_Delete);
    io.KeyMap[ImGuiKey_Backspace] = to_sdl(GdkKeysyms.GDK_BackSpace);
    io.KeyMap[ImGuiKey_Space] = to_sdl(GdkKeysyms.GDK_space);
    io.KeyMap[ImGuiKey_Enter] = to_sdl(GdkKeysyms.GDK_Return);
    io.KeyMap[ImGuiKey_Escape] = to_sdl(GdkKeysyms.GDK_Escape);
    io.KeyMap[ImGuiKey_KeyPadEnter] = to_sdl(GdkKeysyms.GDK_KP_Enter);
    io.KeyMap[ImGuiKey_A] = to_sdl(GdkKeysyms.GDK_A);
    io.KeyMap[ImGuiKey_C] = to_sdl(GdkKeysyms.GDK_C);
    io.KeyMap[ImGuiKey_V] = to_sdl(GdkKeysyms.GDK_V);
    io.KeyMap[ImGuiKey_X] = to_sdl(GdkKeysyms.GDK_X);
    io.KeyMap[ImGuiKey_Y] = to_sdl(GdkKeysyms.GDK_Y);
    io.KeyMap[ImGuiKey_Z] = to_sdl(GdkKeysyms.GDK_Z);

    for (int i = 0; i < ImGuiKey_COUNT; ++i)
    {
        int key = io.KeyMap[i];
        writeln(key);
    }

    auto display = widget.getDisplay();

    //Clipboard.get().setText()
	
    //io.SetClipboardTextFn = ImGui_ImplSFML_SetClipboardText;
    //io.GetClipboardTextFn = ImGui_ImplSFML_GetClipboardText;
    //io.ClipboardUserData = NULL;

    gMouseCursors[ImGuiMouseCursor_Arrow] = new Cursor(display, "default");
    gMouseCursors[ImGuiMouseCursor_TextInput] = new Cursor(display, "text");
    gMouseCursors[ImGuiMouseCursor_ResizeAll] = new Cursor(display, "all-scroll");
    gMouseCursors[ImGuiMouseCursor_ResizeNS] = new Cursor(display, "ns-resize");
    gMouseCursors[ImGuiMouseCursor_ResizeEW] = new Cursor(display, "ew-resize");
    gMouseCursors[ImGuiMouseCursor_ResizeNESW] = new Cursor(display, "nesw-resize");
    gMouseCursors[ImGuiMouseCursor_ResizeNWSE] = new Cursor(display, "nwse-resize");
    gMouseCursors[ImGuiMouseCursor_Hand] = new Cursor(display, "pointer");
}

void imgui_gtkd_new_frame(GLSurface widget, float delta_time) {
    ImGuiIO* io = igGetIO();

//    IM_ASSERT(io.Fonts.IsBuilt() && "Font atlas not built! It is generally built by the renderer back-end. Missing call to renderer _NewFrame() function? e.g. ImGui_ImplOpenGL3_NewFrame().");

    // Setup display size (every frame to accommodate for window resizing)
    GtkAllocation allocation;
    widget.getViewport().getAllocation(allocation);
    
    io.DisplaySize = ImVec2(cast(float)allocation.width, cast(float)allocation.height);
    if (io.DisplaySize.x > 0 && io.DisplaySize.y > 0)
        io.DisplayFramebufferScale = ImVec2(1, 1);
	
    // Setup time step (we don't use SDL_GetTicks() because it is using millisecond resolution)
    //io.DeltaTime = delta_time;
    io.DeltaTime = 0.016f;
}




bool imgui_gtkd_handle_events(Event event, Widget widget) {
    ImGuiIO* io = igGetIO();
    switch (event.type)
    {       
        // a special code to indicate a null event.
        case GdkEventType.NOTHING:
        {
            break;
        }
        // the window manager has requested that the toplevel window be
        // hidden or destroyed, usually when the user clicks on a special icon in the
        // title bar.
        case GdkEventType.DELETE:
        {
            break;
        }
        // the window has been destroyed.
        case GdkEventType.DESTROY:
        {
            break;
        }
        // all or part of the window has become visible and needs to be redrawn.
        case GdkEventType.EXPOSE:
        {
            break;
        }
        // the pointer (usually a mouse) has moved.
        case GdkEventType.MOTION_NOTIFY:
        {
			io.MousePos.x = event.motion().x;
			io.MousePos.y = event.motion().y;
            break;
        }
        case GdkEventType.BUTTON_PRESS: // a mouse button has been pressed.
        case GdkEventType.BUTTON_RELEASE: // a mouse button has been released.
        {
            auto button = event.button();
            const auto pressed = button.type == GdkEventType.BUTTON_PRESS;

            if      (button.button == 1) io.MouseDown[0] = pressed; // left
            else if (button.button == 3) io.MouseDown[1] = pressed; // right
            else if (button.button == 2) io.MouseDown[2] = pressed; // middle
            break;
        }
        case GdkEventType.DOUBLE_BUTTON_PRESS: // alias for %GDK_2BUTTON_PRESS, added in 3.6.
        case GdkEventType.TRIPLE_BUTTON_PRESS: // alias for %GDK_3BUTTON_PRESS, added in 3.6.
        {
            break;
        }
        // a key has been pressed/released.
        case GdkEventType.KEY_PRESS:
        case GdkEventType.KEY_RELEASE:
        {
            auto key = to_sdl(cast(GdkKeysyms)event.key.keyval);
            
            //IM_ASSERT(key >= 0 && key < IM_ARRAYSIZE(io.KeysDown));
            io.KeysDown[key] = (event.key.type == GdkEventType.KEY_PRESS);
            io.KeyShift = ((event.key.state & GdkModifierType.SHIFT_MASK) != 0);
            io.KeyCtrl = ((event.key.state & GdkModifierType.CONTROL_MASK) != 0);
            io.KeyAlt = ((event.key.state & GdkModifierType.HYPER_MASK) != 0);
            io.KeySuper = ((event.key.state & GdkModifierType.META_MASK) != 0);
            return true;
        }       
        // the pointer has entered the window.
        case GdkEventType.ENTER_NOTIFY:
        {
            break;
        }       
        // the pointer has left the window.
        case GdkEventType.LEAVE_NOTIFY:
        {
            break;
        }       
        // the keyboard focus has entered or left the window.
        case GdkEventType.FOCUS_CHANGE:
        {
            break;
        }       
        // the size, position or stacking order of the window has changed. Note that GTK+ discards these events for %GDK_WINDOW_CHILD windows.
        case GdkEventType.CONFIGURE:
        {
            break;
        }       
        // the window has been mapped.
        case GdkEventType.MAP:
        {
            break;
        }       
        // the window has been unmapped.
        case GdkEventType.UNMAP:
        {
            break;
        }       
        // a property on the window has been changed or deleted.
        case GdkEventType.PROPERTY_NOTIFY:
        {
            break;
        }       
        // the application has lost ownership of a selection.
        case GdkEventType.SELECTION_CLEAR:
        {
            break;
        }       
        // another application has requested a selection.
        case GdkEventType.SELECTION_REQUEST:
        {
            break;
        }       
        // a selection has been received.
        case GdkEventType.SELECTION_NOTIFY:
        {
            break;
        }       
        // an input device has moved into contact with a sensing surface (e.g. a touchscreen or graphics tablet).
        case GdkEventType.PROXIMITY_IN:
        {
            break;
        }       
        // an input device has moved out of contact with a sensing surface.
        case GdkEventType.PROXIMITY_OUT:
        {
            break;
        }       
        // the mouse has entered the window while a drag is in progress.
        case GdkEventType.DRAG_ENTER:
        {
            break;
        }       
        // the mouse has left the window while a drag is in progress.
        case GdkEventType.DRAG_LEAVE:
        {
            break;
        }       
        // the mouse has moved in the window while a drag is in progress.
        case GdkEventType.DRAG_MOTION:
        {
            break;
        }       
        // the status of the drag operation initiated by the window has changed.
        case GdkEventType.DRAG_STATUS:
        {
            break;
        }       
        // a drop operation onto the window has started.
        case GdkEventType.DROP_START:
        {
            break;
        }       
        // the drop operation initiated by the window has completed.
        case GdkEventType.DROP_FINISHED:
        {
            break;
        }       
        // a message has been received from another application.
        case GdkEventType.CLIENT_EVENT:
        {
            break;
        }       
        // the window visibility status has changed.
        case GdkEventType.VISIBILITY_NOTIFY:
        {
            break;
        }       
        // the scroll wheel was turned
        case GdkEventType.SCROLL:
        {
            io.MouseWheel += event.scroll().y;
            io.MouseWheelH += event.scroll().x;
            break;
        }       
        // the state of a window has changed. See #GdkWindowState for the possible window states
        case GdkEventType.WINDOW_STATE:
        {
            break;
        }       
        // a setting has been modified.
        case GdkEventType.SETTING:
        {
            break;
        }       
        // the owner of a selection has changed. This event type was added in 2.6
        case GdkEventType.OWNER_CHANGE:
        {
            break;
        }       
        // a pointer or keyboard grab was broken. This event type was added in 2.8.
        case GdkEventType.GRAB_BROKEN:
        {
            break;
        }       
        // the content of the window has been changed. This event type was added in 2.14.
        case GdkEventType.DAMAGE:
        {
            break;
        }       
        // A new touch event sequence has just started. This event type was added in 3.4.
        case GdkEventType.TOUCH_BEGIN:
        {
            break;
        }       
        // A touch event sequence has been updated. This event type was added in 3.4.
        case GdkEventType.TOUCH_UPDATE:
        {
            break;
        }       
        // A touch event sequence has finished. This event type was added in 3.4.
        case GdkEventType.TOUCH_END:
        {
            break;
        }       
        // A touch event sequence has been canceled. This event type was added in 3.4.
        case GdkEventType.TOUCH_CANCEL:
        {
            break;
        }       
        // A touchpad swipe gesture event, the current state is determined by its phase field. This event type was added in 3.18.
        case GdkEventType.TOUCHPAD_SWIPE:
        {
            break;
        }       
        // A touchpad pinch gesture event, the current state is determined by its phase field. This event type was added in 3.18.
        case GdkEventType.TOUCHPAD_PINCH:
        {
            break;
        }       
        // A tablet pad button press event. This event type was added in 3.22.
        case GdkEventType.PAD_BUTTON_PRESS:
        {
            break;
        }       
        // A tablet pad button release event. This event type was added in 3.22.
        case GdkEventType.PAD_BUTTON_RELEASE:
        {
            break;
        }       
        // A tablet pad axis event from a "ring". This event type was
        case GdkEventType.PAD_RING:
        {
            break;
        }       
        // A tablet pad axis event from a "strip". This event type was added in 3.22.
        case GdkEventType.PAD_STRIP:
        {
            break;
        }       
        // A tablet pad group mode change. This event type was added in 3.22.
        case GdkEventType.PAD_GROUP_MODE:
        {
            break;
        }       
        // marks the end of the GdkEventType enumeration. Added in 2.18
        case GdkEventType.EVENT_LAST:
        {
            break;
        }
        default:
        {
            break;
        }
    }

    return false;
}

*/