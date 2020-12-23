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
            //io.ConfigFlags |= ImGuiConfigFlags_ViewportsEnable;         // Enable Multi-Viewport / Platform Windows

            // Setup Dear ImGui style
            igStyleColorsDark(null);
            //igStyleColorsClassic();

            // Setup Platform/Renderer backends
            //ImGui_ImplSDL2_InitForOpenGL(window, gl_context);
            imgui_gtk_init(cast(GLSurface)this);
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


        ImGuiIO* io = igGetIO();
        glClearColor(0, 0, 0, 0);
        glViewport(0, 0, cast(int)io.DisplaySize.x, cast(int)io.DisplaySize.y);
        bindbc.imgui.ImGuiOpenGLBackend.render_draw_data(igGetDrawData());
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

bool imgui_gtk_init(GLSurface surface)
{
    surface.getViewport().setCanFocus(true);
    surface.getViewport().grabFocus();
    surface.getViewport().addEvents(cEventMask);
    surface.getViewport().addOnEvent(toDelegate(&imgui_gtk_handle_event));

    ImGuiIO* io = igGetIO();
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
}




















































/*



import bindbc.sdl;

GdkKeysyms to_gdk(SDL_Scancode key)
{
    switch (key)
    {
    default:
    case SDL_SCANCODE_UNKNOWN: return cast(GdkKeysyms)0;  // 0,
    case SDL_SCANCODE_RETURN: return GdkKeysyms.GDK_Return;  // '\r',
    case SDL_SCANCODE_ESCAPE: return GdkKeysyms.GDK_Escape;  // '\033',
    case SDL_SCANCODE_BACKSPACE: return GdkKeysyms.GDK_BackSpace;  // '\b',
    case SDL_SCANCODE_TAB: return GdkKeysyms.GDK_Tab;  // '\t',
    case SDL_SCANCODE_SPACE: return GdkKeysyms.GDK_space;  // ' ',
//    case SDL_SCANCODE_: return GdkKeysyms.GDK_exclam;  // '!',
//    case SDL_SCANCODE_: return GdkKeysyms.GDK_quotedbl;  // '"',
//    case SDL_SCANCODE_HASH: return GdkKeysyms.GDK_numbersign;  // '#',
//    case SDL_SCANCODE_PERCENT: return GdkKeysyms.GDK_percent;  // '%',
//    case SDL_SCANCODE_DOLLAR: return GdkKeysyms.GDK_dollar;  // '$',
//    case SDL_SCANCODE_AMPERSAND: return GdkKeysyms.GDK_ampersand;  // '&',
    case SDL_SCANCODE_APOSTROPHE: return GdkKeysyms.GDK_quoteright;  // '\'',
//    case SDL_SCANCODE_LEFTPAREN: return GdkKeysyms.GDK_parenleft;  // '(',
//    case SDL_SCANCODE_RIGHTPAREN: return GdkKeysyms.GDK_parenright;  // ')',
//    case SDL_SCANCODE_ASTERISK: return GdkKeysyms.GDK_asterisk;  // '*',
//    case SDL_SCANCODE_PLUS: return GdkKeysyms.GDK_plus;  // '+',
    case SDL_SCANCODE_COMMA: return GdkKeysyms.GDK_comma;  // ',',
    case SDL_SCANCODE_MINUS: return GdkKeysyms.GDK_minus;  // '-',
    case SDL_SCANCODE_PERIOD: return GdkKeysyms.GDK_period;  // '.',
    case SDL_SCANCODE_SLASH: return GdkKeysyms.GDK_slash;  // '/',
    case SDL_SCANCODE_0: return GdkKeysyms.GDK_0;  // '0',
    case SDL_SCANCODE_1: return GdkKeysyms.GDK_1;  // '1',
    case SDL_SCANCODE_2: return GdkKeysyms.GDK_2;  // '2',
    case SDL_SCANCODE_3: return GdkKeysyms.GDK_3;  // '3',
    case SDL_SCANCODE_4: return GdkKeysyms.GDK_4;  // '4',
    case SDL_SCANCODE_5: return GdkKeysyms.GDK_5;  // '5',
    case SDL_SCANCODE_6: return GdkKeysyms.GDK_6;  // '6',
    case SDL_SCANCODE_7: return GdkKeysyms.GDK_7;  // '7',
    case SDL_SCANCODE_8: return GdkKeysyms.GDK_8;  // '8',
    case SDL_SCANCODE_9: return GdkKeysyms.GDK_9;  // '9',
//    case SDL_SCANCODE_COLON: return GdkKeysyms.GDK_colon;  // ':',
    case SDL_SCANCODE_SEMICOLON: return GdkKeysyms.GDK_semicolon;  // ';',
//    case SDL_SCANCODE_LESS: return GdkKeysyms.GDK_less;  // '<',
    case SDL_SCANCODE_EQUALS: return GdkKeysyms.GDK_equal;  //  '=',
//    case SDL_SCANCODE_GREATER: return GdkKeysyms.GDK_greater;  // '>',
//    case SDL_SCANCODE_QUESTION: return GdkKeysyms.GDK_question;  // '?',
//    case SDL_SCANCODE_: return GdkKeysyms.GDK_at;  // '@',

    case SDL_SCANCODE_LEFTBRACKET: return GdkKeysyms.GDK_bracketleft;  // '[',
    case SDL_SCANCODE_BACKSLASH: return GdkKeysyms.GDK_backslash;  // '\\',
    case SDL_SCANCODE_RIGHTBRACKET: return GdkKeysyms.GDK_bracketright;  // ']',
//    case SDL_SCANCODE_CARET: return GdkKeysyms.GDK_caret;  // '^',
//    case SDL_SCANCODE_UNDERSCORE: return GdkKeysyms.GDK_underscore;  // '_',
    case SDL_SCANCODE_GRAVE: return GdkKeysyms.GDK_quoteleft;  // '`',
    case SDL_SCANCODE_A: return GdkKeysyms.GDK_A;  // 'A',
    case SDL_SCANCODE_B: return GdkKeysyms.GDK_B;  // 'B',
    case SDL_SCANCODE_C: return GdkKeysyms.GDK_C;  // 'C',
    case SDL_SCANCODE_D: return GdkKeysyms.GDK_D;  // 'D',
    case SDL_SCANCODE_E: return GdkKeysyms.GDK_E;  // 'E',
    case SDL_SCANCODE_F: return GdkKeysyms.GDK_F;  // 'F',
    case SDL_SCANCODE_G: return GdkKeysyms.GDK_G;  // 'G',
    case SDL_SCANCODE_H: return GdkKeysyms.GDK_H;  // 'H',
    case SDL_SCANCODE_I: return GdkKeysyms.GDK_I;  // 'I',
    case SDL_SCANCODE_J: return GdkKeysyms.GDK_J;  // 'J',
    case SDL_SCANCODE_K: return GdkKeysyms.GDK_K;  // 'K',
    case SDL_SCANCODE_L: return GdkKeysyms.GDK_L;  // 'L',
    case SDL_SCANCODE_M: return GdkKeysyms.GDK_M;  // 'M',
    case SDL_SCANCODE_N: return GdkKeysyms.GDK_N;  // 'N',
    case SDL_SCANCODE_O: return GdkKeysyms.GDK_O;  // 'O',
    case SDL_SCANCODE_P: return GdkKeysyms.GDK_P;  // 'P',
    case SDL_SCANCODE_Q: return GdkKeysyms.GDK_Q;  // 'Q',
    case SDL_SCANCODE_R: return GdkKeysyms.GDK_R;  // 'R',
    case SDL_SCANCODE_S: return GdkKeysyms.GDK_S;  // 'S',
    case SDL_SCANCODE_T: return GdkKeysyms.GDK_T;  // 'T',
    case SDL_SCANCODE_U: return GdkKeysyms.GDK_U;  // 'U',
    case SDL_SCANCODE_V: return GdkKeysyms.GDK_V;  // 'V',
    case SDL_SCANCODE_W: return GdkKeysyms.GDK_W;  // 'W',
    case SDL_SCANCODE_X: return GdkKeysyms.GDK_X;  // 'X',
    case SDL_SCANCODE_Y: return GdkKeysyms.GDK_Y;  // 'Y',
    case SDL_SCANCODE_Z: return GdkKeysyms.GDK_Z;  // 'Z',

    case SDL_SCANCODE_CAPSLOCK: return GdkKeysyms.GDK_Caps_Lock;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_CAPSLOCK),

    case SDL_SCANCODE_F1: return GdkKeysyms.GDK_F1;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F1),
    case SDL_SCANCODE_F2: return GdkKeysyms.GDK_F2;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F2),
    case SDL_SCANCODE_F3: return GdkKeysyms.GDK_F3;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F3),
    case SDL_SCANCODE_F4: return GdkKeysyms.GDK_F4;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F4),
    case SDL_SCANCODE_F5: return GdkKeysyms.GDK_F5;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F5),
    case SDL_SCANCODE_F6: return GdkKeysyms.GDK_F6;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F6),
    case SDL_SCANCODE_F7: return GdkKeysyms.GDK_F7;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F7),
    case SDL_SCANCODE_F8: return GdkKeysyms.GDK_F8;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F8),
    case SDL_SCANCODE_F9: return GdkKeysyms.GDK_F9;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F9),
    case SDL_SCANCODE_F10: return GdkKeysyms.GDK_F10;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F10),
    case SDL_SCANCODE_F11: return GdkKeysyms.GDK_F11;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F11),
    case SDL_SCANCODE_F12: return GdkKeysyms.GDK_F12;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F12),

    case SDL_SCANCODE_PRINTSCREEN: return GdkKeysyms.GDK_3270_PrintScreen;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_PRINTSCREEN),
    case SDL_SCANCODE_SCROLLLOCK: return GdkKeysyms.GDK_Scroll_Lock;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_SCROLLLOCK),
    case SDL_SCANCODE_PAUSE: return GdkKeysyms.GDK_Pause;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_PAUSE),
    case SDL_SCANCODE_INSERT: return GdkKeysyms.GDK_Insert;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_INSERT),
    case SDL_SCANCODE_HOME: return GdkKeysyms.GDK_Home;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_HOME),
    case SDL_SCANCODE_PAGEUP: return GdkKeysyms.GDK_Page_Up;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_PAGEUP),
    case SDL_SCANCODE_DELETE: return GdkKeysyms.GDK_Delete;  // '\177',
    case SDL_SCANCODE_END: return GdkKeysyms.GDK_End;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_END),
    case SDL_SCANCODE_PAGEDOWN: return GdkKeysyms.GDK_Page_Down;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_PAGEDOWN),
    case SDL_SCANCODE_RIGHT: return GdkKeysyms.GDK_Right;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_RIGHT),
    case SDL_SCANCODE_LEFT: return GdkKeysyms.GDK_Left;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_LEFT),
    case SDL_SCANCODE_DOWN: return GdkKeysyms.GDK_Down;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_DOWN),
    case SDL_SCANCODE_UP: return GdkKeysyms.GDK_Up;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_UP),

    case SDL_SCANCODE_NUMLOCKCLEAR: return GdkKeysyms.GDK_Num_Lock;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_NUMLOCKCLEAR),
    case SDL_SCANCODE_KP_DIVIDE: return GdkKeysyms.GDK_KP_Divide;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_DIVIDE),
    case SDL_SCANCODE_KP_MULTIPLY: return GdkKeysyms.GDK_KP_Multiply;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_MULTIPLY),
    case SDL_SCANCODE_KP_MINUS: return GdkKeysyms.GDK_KP_Subtract;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_MINUS),
    case SDL_SCANCODE_KP_PLUS: return GdkKeysyms.GDK_KP_Add;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_PLUS),
    case SDL_SCANCODE_KP_ENTER: return GdkKeysyms.GDK_KP_Enter;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_ENTER),
    case SDL_SCANCODE_KP_1: return GdkKeysyms.GDK_KP_1;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_1),
    case SDL_SCANCODE_KP_2: return GdkKeysyms.GDK_KP_2;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_2),
    case SDL_SCANCODE_KP_3: return GdkKeysyms.GDK_KP_3;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_3),
    case SDL_SCANCODE_KP_4: return GdkKeysyms.GDK_KP_4;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_4),
    case SDL_SCANCODE_KP_5: return GdkKeysyms.GDK_KP_5;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_5),
    case SDL_SCANCODE_KP_6: return GdkKeysyms.GDK_KP_6;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_6),
    case SDL_SCANCODE_KP_7: return GdkKeysyms.GDK_KP_7;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_7),
    case SDL_SCANCODE_KP_8: return GdkKeysyms.GDK_KP_8;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_8),
    case SDL_SCANCODE_KP_9: return GdkKeysyms.GDK_KP_9;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_9),
    case SDL_SCANCODE_KP_0: return GdkKeysyms.GDK_KP_0;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_0),
    case SDL_SCANCODE_KP_PERIOD: return GdkKeysyms.GDK_KP_Decimal;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_PERIOD),

    case SDL_SCANCODE_APPLICATION: return GdkKeysyms.GDK_ApplicationLeft;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_APPLICATION),
    case SDL_SCANCODE_POWER: return GdkKeysyms.GDK_PowerOff;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_POWER),
    case SDL_SCANCODE_KP_EQUALS: return GdkKeysyms.GDK_KP_Equal;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_EQUALS),
    case SDL_SCANCODE_F13: return GdkKeysyms.GDK_F13;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F13),
    case SDL_SCANCODE_F14: return GdkKeysyms.GDK_F14;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F14),
    case SDL_SCANCODE_F15: return GdkKeysyms.GDK_F15;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F15),
    case SDL_SCANCODE_F16: return GdkKeysyms.GDK_F16;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F16),
    case SDL_SCANCODE_F17: return GdkKeysyms.GDK_F17;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F17),
    case SDL_SCANCODE_F18: return GdkKeysyms.GDK_F18;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F18),
    case SDL_SCANCODE_F19: return GdkKeysyms.GDK_F19;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F19),
    case SDL_SCANCODE_F20: return GdkKeysyms.GDK_F20;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F20),
    case SDL_SCANCODE_F21: return GdkKeysyms.GDK_F21;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F21),
    case SDL_SCANCODE_F22: return GdkKeysyms.GDK_F22;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F22),
    case SDL_SCANCODE_F23: return GdkKeysyms.GDK_F23;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F23),
    case SDL_SCANCODE_F24: return GdkKeysyms.GDK_F24;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F24),
    case SDL_SCANCODE_EXECUTE: return GdkKeysyms.GDK_Execute;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_EXECUTE),
    case SDL_SCANCODE_HELP: return GdkKeysyms.GDK_Help;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_HELP),
    case SDL_SCANCODE_MENU: return GdkKeysyms.GDK_Menu;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_MENU),
    case SDL_SCANCODE_SELECT: return GdkKeysyms.GDK_Select;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_SELECT),
    case SDL_SCANCODE_STOP: return GdkKeysyms.GDK_Stop;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_STOP),
//    case SDL_SCANCODE_AGAIN: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AGAIN),
    case SDL_SCANCODE_UNDO: return GdkKeysyms.GDK_Undo;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_UNDO),
    case SDL_SCANCODE_CUT: return GdkKeysyms.GDK_Cut;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_CUT),
    case SDL_SCANCODE_COPY: return GdkKeysyms.GDK_Copy;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_COPY),
    case SDL_SCANCODE_PASTE: return GdkKeysyms.GDK_Paste;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_PASTE),
    case SDL_SCANCODE_FIND: return GdkKeysyms.GDK_Find;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_FIND),
    case SDL_SCANCODE_MUTE: return GdkKeysyms.GDK_AudioMute;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_MUTE),
    case SDL_SCANCODE_VOLUMEUP: return GdkKeysyms.GDK_AudioRaiseVolume;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_VOLUMEUP),
    case SDL_SCANCODE_VOLUMEDOWN: return GdkKeysyms.GDK_AudioLowerVolume;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_VOLUMEDOWN),
//    case SDL_SCANCODE_KP_COMMA: return GdkKeysyms.GDK_KP;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_COMMA),
//    case SDL_SCANCODE_KP_EQUALSAS400: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_EQUALSAS400),
//
//    case SDL_SCANCODE_ALTERASE: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_ALTERASE),
//    case SDL_SCANCODE_SYSREQ: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_SYSREQ),
//    case SDL_SCANCODE_CANCEL: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_CANCEL),
//    case SDL_SCANCODE_CLEAR: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_CLEAR),
//    case SDL_SCANCODE_PRIOR: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_PRIOR),
//    case SDL_SCANCODE_RETURN2: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_RETURN2),
//    case SDL_SCANCODE_SEPARATOR: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_SEPARATOR),
//    case SDL_SCANCODE_OUT: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_OUT),
//    case SDL_SCANCODE_OPER: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_OPER),
//    case SDL_SCANCODE_CLEARAGAIN: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_CLEARAGAIN),
//    case SDL_SCANCODE_CRSEL: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_CRSEL),
//    case SDL_SCANCODE_EXSEL: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_EXSEL),
//
//    case SDL_SCANCODE_KP_00: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_00),
//    case SDL_SCANCODE_KP_000: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_000),
//    case SDL_SCANCODE_THOUSANDSSEPARATOR: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_THOUSANDSSEPARATOR),
//    case SDL_SCANCODE_DECIMALSEPARATOR: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_DECIMALSEPARATOR),
//    case SDL_SCANCODE_CURRENCYUNIT: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_CURRENCYUNIT),
//    case SDL_SCANCODE_CURRENCYSUBUNIT: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_CURRENCYSUBUNIT),
//    case SDL_SCANCODE_KP_LEFTPAREN: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_LEFTPAREN),
//    case SDL_SCANCODE_KP_RIGHTPAREN: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_RIGHTPAREN),
//    case SDL_SCANCODE_KP_LEFTBRACE: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_LEFTBRACE),
//    case SDL_SCANCODE_KP_RIGHTBRACE: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_RIGHTBRACE),
    case SDL_SCANCODE_KP_TAB: return GdkKeysyms.GDK_KP_Tab;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_TAB),
    case SDL_SCANCODE_KP_BACKSPACE: return GdkKeysyms.GDK_KP_Delete;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_BACKSPACE),
//    case SDL_SCANCODE_KP_A: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_A),
//    case SDL_SCANCODE_KP_B: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_B),
//    case SDL_SCANCODE_KP_C: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_C),
//    case SDL_SCANCODE_KP_D: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_D),
//    case SDL_SCANCODE_KP_E: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_E),
//    case SDL_SCANCODE_KP_F: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_F),
//    case SDL_SCANCODE_KP_XOR: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_XOR),
//    case SDL_SCANCODE_KP_POWER: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_POWER),
//    case SDL_SCANCODE_KP_PERCENT: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_PERCENT),
//    case SDL_SCANCODE_KP_LESS: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_LESS),
//    case SDL_SCANCODE_KP_GREATER: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_GREATER),
//    case SDL_SCANCODE_KP_AMPERSAND: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_AMPERSAND),
//    case SDL_SCANCODE_KP_DBLAMPERSAND: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_DBLAMPERSAND),
//    case SDL_SCANCODE_KP_VERTICALBAR: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_VERTICALBAR),
//    case SDL_SCANCODE_KP_DBLVERTICALBAR: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_DBLVERTICALBAR),
//    case SDL_SCANCODE_KP_COLON: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_COLON),
//    case SDL_SCANCODE_KP_HASH: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_HASH),
//    case SDL_SCANCODE_KP_SPACE: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_SPACE),
//    case SDL_SCANCODE_KP_AT: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_AT),
//    case SDL_SCANCODE_KP_EXCLAM: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_EXCLAM),
//    case SDL_SCANCODE_KP_MEMSTORE: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_MEMSTORE),
//    case SDL_SCANCODE_KP_MEMRECALL: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_MEMRECALL),
//    case SDL_SCANCODE_KP_MEMCLEAR: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_MEMCLEAR),
//    case SDL_SCANCODE_KP_MEMADD: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_MEMADD),
//    case SDL_SCANCODE_KP_MEMSUBTRACT: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_MEMSUBTRACT),
//    case SDL_SCANCODE_KP_MEMMULTIPLY: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_MEMMULTIPLY),
//    case SDL_SCANCODE_KP_MEMDIVIDE: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_MEMDIVIDE),
//    case SDL_SCANCODE_KP_PLUSMINUS: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_PLUSMINUS),
//    case SDL_SCANCODE_KP_CLEAR: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_CLEAR),
//    case SDL_SCANCODE_KP_CLEARENTRY: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_CLEARENTRY),
//    case SDL_SCANCODE_KP_BINARY: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_BINARY),
//    case SDL_SCANCODE_KP_OCTAL: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_OCTAL),
//    case SDL_SCANCODE_KP_DECIMAL: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_DECIMAL),
//    case SDL_SCANCODE_KP_HEXADECIMAL: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_HEXADECIMAL),

    case SDL_SCANCODE_LCTRL: return GdkKeysyms.GDK_Control_L;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_LCTRL),
    case SDL_SCANCODE_LSHIFT: return GdkKeysyms.GDK_Shift_L;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_LSHIFT),
    case SDL_SCANCODE_LALT: return GdkKeysyms.GDK_Alt_L;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_LALT),
    case SDL_SCANCODE_LGUI: return GdkKeysyms.GDK_Super_L;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_LGUI),
    case SDL_SCANCODE_RCTRL: return GdkKeysyms.GDK_Control_R;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_RCTRL),
    case SDL_SCANCODE_RSHIFT: return GdkKeysyms.GDK_Shift_R;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_RSHIFT),
    case SDL_SCANCODE_RALT: return GdkKeysyms.GDK_Alt_R;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_RALT),
    case SDL_SCANCODE_RGUI: return GdkKeysyms.GDK_Super_R;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_RGUI),

    case SDL_SCANCODE_MODE: return GdkKeysyms.GDK_Mode_switch;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_MODE),

    case SDL_SCANCODE_AUDIONEXT: return GdkKeysyms.GDK_AudioNext;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AUDIONEXT),
    case SDL_SCANCODE_AUDIOPREV: return GdkKeysyms.GDK_AudioPrev;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AUDIOPREV),
    case SDL_SCANCODE_AUDIOSTOP: return GdkKeysyms.GDK_AudioStop;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AUDIOSTOP),
    case SDL_SCANCODE_AUDIOPLAY: return GdkKeysyms.GDK_AudioPlay;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AUDIOPLAY),
    case SDL_SCANCODE_AUDIOMUTE: return GdkKeysyms.GDK_AudioMute;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AUDIOMUTE),
//    case SDL_SCANCODE_MEDIASELECT: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_MEDIASELECT),
    case SDL_SCANCODE_WWW: return GdkKeysyms.GDK_WWW;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_WWW),
    case SDL_SCANCODE_MAIL: return GdkKeysyms.GDK_Mail;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_MAIL),
    case SDL_SCANCODE_CALCULATOR: return GdkKeysyms.GDK_Calculator;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_CALCULATOR),
    case SDL_SCANCODE_COMPUTER: return GdkKeysyms.GDK_MyComputer;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_COMPUTER),
//    case SDL_SCANCODE_AC_SEARCH: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AC_SEARCH),
//    case SDL_SCANCODE_AC_HOME: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AC_HOME),
//    case SDL_SCANCODE_AC_BACK: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AC_BACK),
//    case SDL_SCANCODE_AC_FORWARD: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AC_FORWARD),
//    case SDL_SCANCODE_AC_STOP: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AC_STOP),
//    case SDL_SCANCODE_AC_REFRESH: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AC_REFRESH),
//    case SDL_SCANCODE_AC_BOOKMARKS: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AC_BOOKMARKS),
//
//    case SDL_SCANCODE_BRIGHTNESSDOWN: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_BRIGHTNESSDOWN),
//    case SDL_SCANCODE_BRIGHTNESSUP: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_BRIGHTNESSUP),
//    case SDL_SCANCODE_DISPLAYSWITCH: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_DISPLAYSWITCH),
//    case SDL_SCANCODE_KBDILLUMTOGGLE: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KBDILLUMTOGGLE),
//    case SDL_SCANCODE_KBDILLUMDOWN: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KBDILLUMDOWN),
//    case SDL_SCANCODE_KBDILLUMUP: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KBDILLUMUP),
//    case SDL_SCANCODE_EJECT: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_EJECT),
//    case SDL_SCANCODE_SLEEP: return GdkKeysyms.GDK_;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_SLEEP),
    }
}

SDL_Scancode to_sdl(GdkKeysyms key)
{
    switch (key)
    {
    default: return SDL_SCANCODE_UNKNOWN;  // 0,
    case GdkKeysyms.GDK_Return: return SDL_SCANCODE_RETURN;  // '\r',
    case GdkKeysyms.GDK_Escape: return SDL_SCANCODE_ESCAPE;  // '\033',
    case GdkKeysyms.GDK_BackSpace: return SDL_SCANCODE_BACKSPACE;  // '\b',
    case GdkKeysyms.GDK_Tab: return SDL_SCANCODE_TAB;  // '\t',
    case GdkKeysyms.GDK_space: return SDL_SCANCODE_SPACE;  // ' ',
//    case GdkKeysyms.GDK_exclam: return SDL_SCANCODE_EXCLAIM;  // '!',
//    case GdkKeysyms.GDK_quotedbl: return SDL_SCANCODE_QUOTEDBL;  // '"',
//    case GdkKeysyms.GDK_numbersign: return SDL_SCANCODE_HASH;  // '#',
//    case GdkKeysyms.GDK_percent: return SDL_SCANCODE_PERCENT;  // '%',
//    case GdkKeysyms.GDK_dollar: return SDL_SCANCODE_DOLLAR;  // '$',
//    case GdkKeysyms.GDK_ampersand: return SDL_SCANCODE_AMPERSAND;  // '&',
    case GdkKeysyms.GDK_quoteright: return SDL_SCANCODE_APOSTROPHE;  // '\'',
//    case GdkKeysyms.GDK_parenleft: return SDL_SCANCODE_LEFTPAREN;  // '(',
//    case GdkKeysyms.GDK_parenright: return SDL_SCANCODE_RIGHTPAREN;  // ')',
//    case GdkKeysyms.GDK_asterisk: return SDL_SCANCODE_ASTERISK;  // '*',
//    case GdkKeysyms.GDK_plus: return SDL_SCANCODE_PLUS;  // '+',
    case GdkKeysyms.GDK_comma: return SDL_SCANCODE_COMMA;  // ',',
    case GdkKeysyms.GDK_minus: return SDL_SCANCODE_MINUS;  // '-',
    case GdkKeysyms.GDK_period: return SDL_SCANCODE_PERIOD;  // '.',
    case GdkKeysyms.GDK_slash: return SDL_SCANCODE_SLASH;  // '/',
    case GdkKeysyms.GDK_0: return SDL_SCANCODE_0;  // '0',
    case GdkKeysyms.GDK_1: return SDL_SCANCODE_1;  // '1',
    case GdkKeysyms.GDK_2: return SDL_SCANCODE_2;  // '2',
    case GdkKeysyms.GDK_3: return SDL_SCANCODE_3;  // '3',
    case GdkKeysyms.GDK_4: return SDL_SCANCODE_4;  // '4',
    case GdkKeysyms.GDK_5: return SDL_SCANCODE_5;  // '5',
    case GdkKeysyms.GDK_6: return SDL_SCANCODE_6;  // '6',
    case GdkKeysyms.GDK_7: return SDL_SCANCODE_7;  // '7',
    case GdkKeysyms.GDK_8: return SDL_SCANCODE_8;  // '8',
    case GdkKeysyms.GDK_9: return SDL_SCANCODE_9;  // '9',
//    case GdkKeysyms.GDK_colon: return SDL_SCANCODE_COLON;  // ':',
    case GdkKeysyms.GDK_semicolon: return SDL_SCANCODE_SEMICOLON;  // ';',
//    case GdkKeysyms.GDK_less: return SDL_SCANCODE_LESS;  // '<',
    case GdkKeysyms.GDK_equal: return SDL_SCANCODE_EQUALS;  //  '=',
//    case GdkKeysyms.GDK_greater: return SDL_SCANCODE_GREATER;  // '>',
//    case GdkKeysyms.GDK_question: return SDL_SCANCODE_QUESTION;  // '?',
//    case GdkKeysyms.GDK_at: return SDL_SCANCODE_AT;  // '@',

    case GdkKeysyms.GDK_bracketleft: return SDL_SCANCODE_LEFTBRACKET;  // '[',
    case GdkKeysyms.GDK_backslash: return SDL_SCANCODE_BACKSLASH;  // '\\',
    case GdkKeysyms.GDK_bracketright: return SDL_SCANCODE_RIGHTBRACKET;  // ']',
//    case GdkKeysyms.GDK_caret: return SDL_SCANCODE_CARET;  // '^',
//    case GdkKeysyms.GDK_underscore: return SDL_SCANCODE_UNDERSCORE;  // '_',
    case GdkKeysyms.GDK_quoteleft: return SDL_SCANCODE_GRAVE;  // '`',
    case GdkKeysyms.GDK_A: return SDL_SCANCODE_A;  // 'a',
    case GdkKeysyms.GDK_B: return SDL_SCANCODE_B;  // 'b',
    case GdkKeysyms.GDK_C: return SDL_SCANCODE_C;  // 'c',
    case GdkKeysyms.GDK_D: return SDL_SCANCODE_D;  // 'd',
    case GdkKeysyms.GDK_E: return SDL_SCANCODE_E;  // 'e',
    case GdkKeysyms.GDK_F: return SDL_SCANCODE_F;  // 'f',
    case GdkKeysyms.GDK_G: return SDL_SCANCODE_G;  // 'g',
    case GdkKeysyms.GDK_H: return SDL_SCANCODE_H;  // 'h',
    case GdkKeysyms.GDK_I: return SDL_SCANCODE_I;  // 'i',
    case GdkKeysyms.GDK_J: return SDL_SCANCODE_J;  // 'j',
    case GdkKeysyms.GDK_K: return SDL_SCANCODE_K;  // 'k',
    case GdkKeysyms.GDK_L: return SDL_SCANCODE_L;  // 'l',
    case GdkKeysyms.GDK_M: return SDL_SCANCODE_M;  // 'm',
    case GdkKeysyms.GDK_N: return SDL_SCANCODE_N;  // 'n',
    case GdkKeysyms.GDK_O: return SDL_SCANCODE_O;  // 'o',
    case GdkKeysyms.GDK_P: return SDL_SCANCODE_P;  // 'p',
    case GdkKeysyms.GDK_Q: return SDL_SCANCODE_Q;  // 'q',
    case GdkKeysyms.GDK_R: return SDL_SCANCODE_R;  // 'r',
    case GdkKeysyms.GDK_S: return SDL_SCANCODE_S;  // 's',
    case GdkKeysyms.GDK_T: return SDL_SCANCODE_T;  // 't',
    case GdkKeysyms.GDK_U: return SDL_SCANCODE_U;  // 'u',
    case GdkKeysyms.GDK_V: return SDL_SCANCODE_V;  // 'v',
    case GdkKeysyms.GDK_W: return SDL_SCANCODE_W;  // 'w',
    case GdkKeysyms.GDK_X: return SDL_SCANCODE_X;  // 'x',
    case GdkKeysyms.GDK_Y: return SDL_SCANCODE_Y;  // 'y',
    case GdkKeysyms.GDK_Z: return SDL_SCANCODE_Z;  // 'z',

    case GdkKeysyms.GDK_Caps_Lock: return SDL_SCANCODE_CAPSLOCK;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_CAPSLOCK),

    case GdkKeysyms.GDK_F1: return SDL_SCANCODE_F1;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F1),
    case GdkKeysyms.GDK_F2: return SDL_SCANCODE_F2;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F2),
    case GdkKeysyms.GDK_F3: return SDL_SCANCODE_F3;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F3),
    case GdkKeysyms.GDK_F4: return SDL_SCANCODE_F4;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F4),
    case GdkKeysyms.GDK_F5: return SDL_SCANCODE_F5;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F5),
    case GdkKeysyms.GDK_F6: return SDL_SCANCODE_F6;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F6),
    case GdkKeysyms.GDK_F7: return SDL_SCANCODE_F7;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F7),
    case GdkKeysyms.GDK_F8: return SDL_SCANCODE_F8;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F8),
    case GdkKeysyms.GDK_F9: return SDL_SCANCODE_F9;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F9),
    case GdkKeysyms.GDK_F10: return SDL_SCANCODE_F10;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F10),
    case GdkKeysyms.GDK_F11: return SDL_SCANCODE_F11;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F11),
    case GdkKeysyms.GDK_F12: return SDL_SCANCODE_F12;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F12),

    case GdkKeysyms.GDK_3270_PrintScreen: return SDL_SCANCODE_PRINTSCREEN;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_PRINTSCREEN),
    case GdkKeysyms.GDK_Scroll_Lock: return SDL_SCANCODE_SCROLLLOCK;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_SCROLLLOCK),
    case GdkKeysyms.GDK_Pause: return SDL_SCANCODE_PAUSE;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_PAUSE),
    case GdkKeysyms.GDK_Insert: return SDL_SCANCODE_INSERT;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_INSERT),
    case GdkKeysyms.GDK_Home: return SDL_SCANCODE_HOME;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_HOME),
    case GdkKeysyms.GDK_Page_Up: return SDL_SCANCODE_PAGEUP;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_PAGEUP),
    case GdkKeysyms.GDK_Delete: return SDL_SCANCODE_DELETE;  // '\177',
    case GdkKeysyms.GDK_End: return SDL_SCANCODE_END;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_END),
    case GdkKeysyms.GDK_Page_Down: return SDL_SCANCODE_PAGEDOWN;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_PAGEDOWN),
    case GdkKeysyms.GDK_Right: return SDL_SCANCODE_RIGHT;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_RIGHT),
    case GdkKeysyms.GDK_Left: return SDL_SCANCODE_LEFT;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_LEFT),
    case GdkKeysyms.GDK_Down: return SDL_SCANCODE_DOWN;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_DOWN),
    case GdkKeysyms.GDK_Up: return SDL_SCANCODE_UP;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_UP),

    case GdkKeysyms.GDK_Num_Lock: return SDL_SCANCODE_NUMLOCKCLEAR;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_NUMLOCKCLEAR),
    case GdkKeysyms.GDK_KP_Divide: return SDL_SCANCODE_KP_DIVIDE;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_DIVIDE),
    case GdkKeysyms.GDK_KP_Multiply: return SDL_SCANCODE_KP_MULTIPLY;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_MULTIPLY),
    case GdkKeysyms.GDK_KP_Subtract: return SDL_SCANCODE_KP_MINUS;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_MINUS),
    case GdkKeysyms.GDK_KP_Add: return SDL_SCANCODE_KP_PLUS;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_PLUS),
    case GdkKeysyms.GDK_KP_Enter: return SDL_SCANCODE_KP_ENTER;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_ENTER),
    case GdkKeysyms.GDK_KP_1: return SDL_SCANCODE_KP_1;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_1),
    case GdkKeysyms.GDK_KP_2: return SDL_SCANCODE_KP_2;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_2),
    case GdkKeysyms.GDK_KP_3: return SDL_SCANCODE_KP_3;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_3),
    case GdkKeysyms.GDK_KP_4: return SDL_SCANCODE_KP_4;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_4),
    case GdkKeysyms.GDK_KP_5: return SDL_SCANCODE_KP_5;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_5),
    case GdkKeysyms.GDK_KP_6: return SDL_SCANCODE_KP_6;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_6),
    case GdkKeysyms.GDK_KP_7: return SDL_SCANCODE_KP_7;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_7),
    case GdkKeysyms.GDK_KP_8: return SDL_SCANCODE_KP_8;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_8),
    case GdkKeysyms.GDK_KP_9: return SDL_SCANCODE_KP_9;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_9),
    case GdkKeysyms.GDK_KP_0: return SDL_SCANCODE_KP_0;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_0),
    case GdkKeysyms.GDK_KP_Decimal: return SDL_SCANCODE_KP_PERIOD;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_PERIOD),

    case GdkKeysyms.GDK_ApplicationLeft: return SDL_SCANCODE_APPLICATION;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_APPLICATION),
    case GdkKeysyms.GDK_PowerOff: return SDL_SCANCODE_POWER;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_POWER),
    case GdkKeysyms.GDK_KP_Equal: return SDL_SCANCODE_KP_EQUALS;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_EQUALS),
    case GdkKeysyms.GDK_F13: return SDL_SCANCODE_F13;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F13),
    case GdkKeysyms.GDK_F14: return SDL_SCANCODE_F14;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F14),
    case GdkKeysyms.GDK_F15: return SDL_SCANCODE_F15;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F15),
    case GdkKeysyms.GDK_F16: return SDL_SCANCODE_F16;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F16),
    case GdkKeysyms.GDK_F17: return SDL_SCANCODE_F17;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F17),
    case GdkKeysyms.GDK_F18: return SDL_SCANCODE_F18;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F18),
    case GdkKeysyms.GDK_F19: return SDL_SCANCODE_F19;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F19),
    case GdkKeysyms.GDK_F20: return SDL_SCANCODE_F20;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F20),
    case GdkKeysyms.GDK_F21: return SDL_SCANCODE_F21;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F21),
    case GdkKeysyms.GDK_F22: return SDL_SCANCODE_F22;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F22),
    case GdkKeysyms.GDK_F23: return SDL_SCANCODE_F23;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F23),
    case GdkKeysyms.GDK_F24: return SDL_SCANCODE_F24;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_F24),
    case GdkKeysyms.GDK_Execute: return SDL_SCANCODE_EXECUTE;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_EXECUTE),
    case GdkKeysyms.GDK_Help: return SDL_SCANCODE_HELP;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_HELP),
    case GdkKeysyms.GDK_Menu: return SDL_SCANCODE_MENU;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_MENU),
    case GdkKeysyms.GDK_Select: return SDL_SCANCODE_SELECT;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_SELECT),
    case GdkKeysyms.GDK_Stop: return SDL_SCANCODE_STOP;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_STOP),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_AGAIN;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AGAIN),
    case GdkKeysyms.GDK_Undo: return SDL_SCANCODE_UNDO;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_UNDO),
    case GdkKeysyms.GDK_Cut: return SDL_SCANCODE_CUT;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_CUT),
    case GdkKeysyms.GDK_Copy: return SDL_SCANCODE_COPY;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_COPY),
    case GdkKeysyms.GDK_Paste: return SDL_SCANCODE_PASTE;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_PASTE),
    case GdkKeysyms.GDK_Find: return SDL_SCANCODE_FIND;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_FIND),
//    case GdkKeysyms.GDK_MUTE: return SDL_SCANCODE_MUTE;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_MUTE),
    case GdkKeysyms.GDK_AudioRaiseVolume: return SDL_SCANCODE_VOLUMEUP;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_VOLUMEUP),
    case GdkKeysyms.GDK_AudioLowerVolume: return SDL_SCANCODE_VOLUMEDOWN;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_VOLUMEDOWN),
//    case GdkKeysyms.GDK_KP: return SDL_SCANCODE_KP_COMMA;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_COMMA),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_EQUALSAS400;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_EQUALSAS400),
//
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_ALTERASE;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_ALTERASE),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_SYSREQ;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_SYSREQ),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_CANCEL;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_CANCEL),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_CLEAR;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_CLEAR),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_PRIOR;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_PRIOR),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_RETURN2;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_RETURN2),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_SEPARATOR;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_SEPARATOR),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_OUT;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_OUT),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_OPER;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_OPER),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_CLEARAGAIN;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_CLEARAGAIN),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_CRSEL;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_CRSEL),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_EXSEL;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_EXSEL),
//
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_00;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_00),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_000;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_000),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_THOUSANDSSEPARATOR;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_THOUSANDSSEPARATOR),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_DECIMALSEPARATOR;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_DECIMALSEPARATOR),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_CURRENCYUNIT;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_CURRENCYUNIT),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_CURRENCYSUBUNIT;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_CURRENCYSUBUNIT),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_LEFTPAREN;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_LEFTPAREN),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_RIGHTPAREN;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_RIGHTPAREN),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_LEFTBRACE;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_LEFTBRACE),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_RIGHTBRACE;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_RIGHTBRACE),
    case GdkKeysyms.GDK_KP_Tab: return SDL_SCANCODE_KP_TAB;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_TAB),
    case GdkKeysyms.GDK_KP_Delete: return SDL_SCANCODE_KP_BACKSPACE;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_BACKSPACE),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_A;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_A),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_B;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_B),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_C;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_C),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_D;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_D),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_E;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_E),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_F;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_F),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_XOR;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_XOR),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_POWER;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_POWER),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_PERCENT;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_PERCENT),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_LESS;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_LESS),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_GREATER;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_GREATER),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_AMPERSAND;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_AMPERSAND),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_DBLAMPERSAND;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_DBLAMPERSAND),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_VERTICALBAR;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_VERTICALBAR),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_DBLVERTICALBAR;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_DBLVERTICALBAR),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_COLON;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_COLON),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_HASH;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_HASH),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_SPACE;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_SPACE),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_AT;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_AT),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_EXCLAM;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_EXCLAM),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_MEMSTORE;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_MEMSTORE),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_MEMRECALL;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_MEMRECALL),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_MEMCLEAR;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_MEMCLEAR),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_MEMADD;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_MEMADD),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_MEMSUBTRACT;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_MEMSUBTRACT),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_MEMMULTIPLY;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_MEMMULTIPLY),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_MEMDIVIDE;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_MEMDIVIDE),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_PLUSMINUS;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_PLUSMINUS),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_CLEAR;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_CLEAR),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_CLEARENTRY;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_CLEARENTRY),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_BINARY;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_BINARY),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_OCTAL;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_OCTAL),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_DECIMAL;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_DECIMAL),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KP_HEXADECIMAL;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KP_HEXADECIMAL),

    case GdkKeysyms.GDK_Control_L: return SDL_SCANCODE_LCTRL;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_LCTRL),
    case GdkKeysyms.GDK_Shift_L: return SDL_SCANCODE_LSHIFT;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_LSHIFT),
    case GdkKeysyms.GDK_Alt_L: return SDL_SCANCODE_LALT;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_LALT),
    case GdkKeysyms.GDK_Super_L: return SDL_SCANCODE_LGUI;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_LGUI),
    case GdkKeysyms.GDK_Control_R: return SDL_SCANCODE_RCTRL;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_RCTRL),
    case GdkKeysyms.GDK_Shift_R: return SDL_SCANCODE_RSHIFT;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_RSHIFT),
    case GdkKeysyms.GDK_Alt_R: return SDL_SCANCODE_RALT;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_RALT),
    case GdkKeysyms.GDK_Super_R: return SDL_SCANCODE_RGUI;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_RGUI),

    case GdkKeysyms.GDK_Mode_switch: return SDL_SCANCODE_MODE;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_MODE),

    case GdkKeysyms.GDK_AudioNext: return SDL_SCANCODE_AUDIONEXT;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AUDIONEXT),
    case GdkKeysyms.GDK_AudioPrev: return SDL_SCANCODE_AUDIOPREV;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AUDIOPREV),
    case GdkKeysyms.GDK_AudioStop: return SDL_SCANCODE_AUDIOSTOP;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AUDIOSTOP),
    case GdkKeysyms.GDK_AudioPlay: return SDL_SCANCODE_AUDIOPLAY;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AUDIOPLAY),
    case GdkKeysyms.GDK_AudioMute: return SDL_SCANCODE_AUDIOMUTE;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AUDIOMUTE),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_MEDIASELECT;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_MEDIASELECT),
    case GdkKeysyms.GDK_WWW: return SDL_SCANCODE_WWW;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_WWW),
    case GdkKeysyms.GDK_Mail: return SDL_SCANCODE_MAIL;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_MAIL),
    case GdkKeysyms.GDK_Calculator: return SDL_SCANCODE_CALCULATOR;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_CALCULATOR),
    case GdkKeysyms.GDK_MyComputer: return SDL_SCANCODE_COMPUTER;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_COMPUTER),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_AC_SEARCH;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AC_SEARCH),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_AC_HOME;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AC_HOME),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_AC_BACK;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AC_BACK),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_AC_FORWARD;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AC_FORWARD),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_AC_STOP;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AC_STOP),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_AC_REFRESH;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AC_REFRESH),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_AC_BOOKMARKS;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_AC_BOOKMARKS),
//
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_BRIGHTNESSDOWN;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_BRIGHTNESSDOWN),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_BRIGHTNESSUP;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_BRIGHTNESSUP),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_DISPLAYSWITCH;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_DISPLAYSWITCH),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KBDILLUMTOGGLE;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KBDILLUMTOGGLE),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KBDILLUMDOWN;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KBDILLUMDOWN),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_KBDILLUMUP;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_KBDILLUMUP),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_EJECT;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_EJECT),
//    case GdkKeysyms.GDK_: return SDL_SCANCODE_SLEEP;  // SDL_SCANCODE_TO_KEYCODE!(SDL_Scancode.SDL_SCANCODE_SLEEP),
    }
}










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

//    IM_ASSERT(io.Fonts->IsBuilt() && "Font atlas not built! It is generally built by the renderer back-end. Missing call to renderer _NewFrame() function? e.g. ImGui_ImplOpenGL3_NewFrame().");

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