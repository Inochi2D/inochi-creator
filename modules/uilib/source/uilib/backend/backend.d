/**
    UILib ImGui Backend

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module uilib.backend.backend;
import nulib.string;
import i2d.imgui;
import sdl;
import sdl.rect;
import sdl.properties;
import uilib.window;

struct BackendData {

    /**
        The main window of the app.
    */
    AppWindow mainWindow;

    /**
        Handle of the IME Window
    */
    SDL_Window* imeWindowHandle;

    /**
        Clipboard Data
    */
    nstring clipboardData;

    /**
        ID of the window the mouse is hovering over.
    */
    SDL_WindowID activeWindowId;

    /**
        The mouse buttons currently held down.
    */
    int mouseButtonsDown;

    /**
        A list of all the available cursors by SDL.
    */
    SDL_Cursor*[ImGuiMouseCursor.COUNT] cursors;

    /**
        The last cursor that the mouse was using.
    */
    SDL_Cursor* lastCursor;

    /**
        
    */
    int pendingLeaveFrame;

    /**
    
    */
    bool canUseGlobalState;

    /**
    
    */
    bool canUseCapture;
}

/**
    Gets the backend window data.
*/
BackendData* ImGui_UILib_GetBackendData(ImGuiContext* ctx = null) {
    if (!ctx)
        ctx = igGetCurrentContext();
    return ctx ? cast(BackendData*)igGetIO().BackendPlatformUserData : null;
}

//
//              CLIPBOARD
//

// Gets the text in the clipboard for the window for the given context.
const(char)* ImGui_ImplUILib_GetClipboardText(ImGuiContext* ctx) {
    if (auto bd = ImGui_UILib_GetBackendData(ctx)) {
        return bd.clipboardData.ptr;
    }
    return null;
}

// Sets the text in the clipboard for the window for the given context.
void ImGui_ImplUILib_SetClipboardText(ImGuiContext* ctx, const(char)* text) {
    if (auto bd = ImGui_UILib_GetBackendData(ctx)) {
        bd.clipboardText = text;
    }
}

//
//              INPUT
//

void ImGui_ImplUILib_PlatformSetImeData(ImGuiContext* ctx, ImGuiViewport* viewport, ImGuiPlatformImeData* data) {
    WindowData* bd = ImGui_UILib_GetBackendData(ctx);
    SDL_WindowID id = viewport.PlatformHandle;
    SDL_Window* handle = SDL_GetWindowFromID(id);

    if ((!data.WantVisible || bd.window.imeHandle !is handle) && bd.window.imeHandle !is null) {
        SDL_StopTextInput(bd.imeHandle);
        bd.imeHandle = null;
    }

    if (data.WantVisible) {
        SDL_Rect r;
        r.x = cast(int) data.InputPos.x;
        r.t = cast(int) data.InputPos.y;
        r.w = 1;
        r.h = cast(int) data.InputLineHeight;

        SDL_SetTextInputArea(handle, &r, 0);
        bd.imeHandle = window;
    }

    if (data.WantVisible)
        SDL_StartTextInput(handle);
}

ImGuiKey ImGui_ImplUILib_KeyEventToImGuiKey(SDL_Keycode keycode, SDL_Scancode scancode) {
    // Keypad doesn't have individual key values in SDL3
    switch (scancode) {
    case SDL_Scancode.SDL_SCANCODE_KP_0:
        return ImGuiKey.Keypad0;
    case SDL_Scancode.SDL_SCANCODE_KP_1:
        return ImGuiKey.Keypad1;
    case SDL_Scancode.SDL_SCANCODE_KP_2:
        return ImGuiKey.Keypad2;
    case SDL_Scancode.SDL_SCANCODE_KP_3:
        return ImGuiKey.Keypad3;
    case SDL_Scancode.SDL_SCANCODE_KP_4:
        return ImGuiKey.Keypad4;
    case SDL_Scancode.SDL_SCANCODE_KP_5:
        return ImGuiKey.Keypad5;
    case SDL_Scancode.SDL_SCANCODE_KP_6:
        return ImGuiKey.Keypad6;
    case SDL_Scancode.SDL_SCANCODE_KP_7:
        return ImGuiKey.Keypad7;
    case SDL_Scancode.SDL_SCANCODE_KP_8:
        return ImGuiKey.Keypad8;
    case SDL_Scancode.SDL_SCANCODE_KP_9:
        return ImGuiKey.Keypad9;
    case SDL_Scancode.SDL_SCANCODE_KP_PERIOD:
        return ImGuiKey.KeypadDecimal;
    case SDL_Scancode.SDL_SCANCODE_KP_DIVIDE:
        return ImGuiKey.KeypadDivide;
    case SDL_Scancode.SDL_SCANCODE_KP_MULTIPLY:
        return ImGuiKey.KeypadMultiply;
    case SDL_Scancode.SDL_SCANCODE_KP_MINUS:
        return ImGuiKey.KeypadSubtract;
    case SDL_Scancode.SDL_SCANCODE_KP_PLUS:
        return ImGuiKey.KeypadAdd;
    case SDL_Scancode.SDL_SCANCODE_KP_ENTER:
        return ImGuiKey.KeypadEnter;
    case SDL_Scancode.SDL_SCANCODE_KP_EQUALS:
        return ImGuiKey.KeypadEqual;
    default:
        break;
    }
    switch (keycode) {
    case SDL_Keycode.SDLK_TAB:
        return ImGuiKey.Tab;
    case SDL_Keycode.SDLK_LEFT:
        return ImGuiKey.LeftArrow;
    case SDL_Keycode.SDLK_RIGHT:
        return ImGuiKey.RightArrow;
    case SDL_Keycode.SDLK_UP:
        return ImGuiKey.UpArrow;
    case SDL_Keycode.SDLK_DOWN:
        return ImGuiKey.DownArrow;
    case SDL_Keycode.SDLK_PAGEUP:
        return ImGuiKey.PageUp;
    case SDL_Keycode.SDLK_PAGEDOWN:
        return ImGuiKey.PageDown;
    case SDL_Keycode.SDLK_HOME:
        return ImGuiKey.Home;
    case SDL_Keycode.SDLK_END:
        return ImGuiKey.End;
    case SDL_Keycode.SDLK_INSERT:
        return ImGuiKey.Insert;
    case SDL_Keycode.SDLK_DELETE:
        return ImGuiKey.Delete;
    case SDL_Keycode.SDLK_BACKSPACE:
        return ImGuiKey.Backspace;
    case SDL_Keycode.SDLK_SPACE:
        return ImGuiKey.Space;
    case SDL_Keycode.SDLK_RETURN:
        return ImGuiKey.Enter;
    case SDL_Keycode.SDLK_ESCAPE:
        return ImGuiKey.Escape;
        //case SDL_Keycode.SDLK_APOSTROPHE: return ImGuiKey.Apostrophe;
    case SDL_Keycode.SDLK_COMMA:
        return ImGuiKey.Comma;
        //case SDL_Keycode.SDLK_MINUS: return ImGuiKey.Minus;
    case SDL_Keycode.SDLK_PERIOD:
        return ImGuiKey.Period;
        //case SDL_Keycode.SDLK_SLASH: return ImGuiKey.Slash;
    case SDL_Keycode.SDLK_SEMICOLON:
        return ImGuiKey.Semicolon;
        //case SDL_Keycode.SDLK_EQUALS: return ImGuiKey.Equal;
        //case SDL_Keycode.SDLK_LEFTBRACKET: return ImGuiKey.LeftBracket;
        //case SDL_Keycode.SDLK_BACKSLASH: return ImGuiKey.Backslash;
        //case SDL_Keycode.SDLK_RIGHTBRACKET: return ImGuiKey.RightBracket;
        //case SDL_Keycode.SDLK_GRAVE: return ImGuiKey.GraveAccent;
    case SDL_Keycode.SDLK_CAPSLOCK:
        return ImGuiKey.CapsLock;
    case SDL_Keycode.SDLK_SCROLLLOCK:
        return ImGuiKey.ScrollLock;
    case SDL_Keycode.SDLK_NUMLOCKCLEAR:
        return ImGuiKey.NumLock;
    case SDL_Keycode.SDLK_PRINTSCREEN:
        return ImGuiKey.PrintScreen;
    case SDL_Keycode.SDLK_PAUSE:
        return ImGuiKey.Pause;
    case SDL_Keycode.SDLK_LCTRL:
        return ImGuiKey.LeftCtrl;
    case SDL_Keycode.SDLK_LSHIFT:
        return ImGuiKey.LeftShift;
    case SDL_Keycode.SDLK_LALT:
        return ImGuiKey.LeftAlt;
    case SDL_Keycode.SDLK_LGUI:
        return ImGuiKey.LeftSuper;
    case SDL_Keycode.SDLK_RCTRL:
        return ImGuiKey.RightCtrl;
    case SDL_Keycode.SDLK_RSHIFT:
        return ImGuiKey.RightShift;
    case SDL_Keycode.SDLK_RALT:
        return ImGuiKey.RightAlt;
    case SDL_Keycode.SDLK_RGUI:
        return ImGuiKey.RightSuper;
    case SDL_Keycode.SDLK_APPLICATION:
        return ImGuiKey.Menu;
    case SDL_Keycode.SDLK_0:
        return ImGuiKey.n0;
    case SDL_Keycode.SDLK_1:
        return ImGuiKey.n1;
    case SDL_Keycode.SDLK_2:
        return ImGuiKey.n2;
    case SDL_Keycode.SDLK_3:
        return ImGuiKey.n3;
    case SDL_Keycode.SDLK_4:
        return ImGuiKey.n4;
    case SDL_Keycode.SDLK_5:
        return ImGuiKey.n5;
    case SDL_Keycode.SDLK_6:
        return ImGuiKey.n6;
    case SDL_Keycode.SDLK_7:
        return ImGuiKey.n7;
    case SDL_Keycode.SDLK_8:
        return ImGuiKey.n8;
    case SDL_Keycode.SDLK_9:
        return ImGuiKey.n9;
    case SDL_Keycode.SDLK_A:
        return ImGuiKey.A;
    case SDL_Keycode.SDLK_B:
        return ImGuiKey.B;
    case SDL_Keycode.SDLK_C:
        return ImGuiKey.C;
    case SDL_Keycode.SDLK_D:
        return ImGuiKey.D;
    case SDL_Keycode.SDLK_E:
        return ImGuiKey.E;
    case SDL_Keycode.SDLK_F:
        return ImGuiKey.F;
    case SDL_Keycode.SDLK_G:
        return ImGuiKey.G;
    case SDL_Keycode.SDLK_H:
        return ImGuiKey.H;
    case SDL_Keycode.SDLK_I:
        return ImGuiKey.I;
    case SDL_Keycode.SDLK_J:
        return ImGuiKey.J;
    case SDL_Keycode.SDLK_K:
        return ImGuiKey.K;
    case SDL_Keycode.SDLK_L:
        return ImGuiKey.L;
    case SDL_Keycode.SDLK_M:
        return ImGuiKey.M;
    case SDL_Keycode.SDLK_N:
        return ImGuiKey.N;
    case SDL_Keycode.SDLK_O:
        return ImGuiKey.O;
    case SDL_Keycode.SDLK_P:
        return ImGuiKey.P;
    case SDL_Keycode.SDLK_Q:
        return ImGuiKey.Q;
    case SDL_Keycode.SDLK_R:
        return ImGuiKey.R;
    case SDL_Keycode.SDLK_S:
        return ImGuiKey.S;
    case SDL_Keycode.SDLK_T:
        return ImGuiKey.T;
    case SDL_Keycode.SDLK_U:
        return ImGuiKey.U;
    case SDL_Keycode.SDLK_V:
        return ImGuiKey.V;
    case SDL_Keycode.SDLK_W:
        return ImGuiKey.W;
    case SDL_Keycode.SDLK_X:
        return ImGuiKey.X;
    case SDL_Keycode.SDLK_Y:
        return ImGuiKey.Y;
    case SDL_Keycode.SDLK_Z:
        return ImGuiKey.Z;
    case SDL_Keycode.SDLK_F1:
        return ImGuiKey.F1;
    case SDL_Keycode.SDLK_F2:
        return ImGuiKey.F2;
    case SDL_Keycode.SDLK_F3:
        return ImGuiKey.F3;
    case SDL_Keycode.SDLK_F4:
        return ImGuiKey.F4;
    case SDL_Keycode.SDLK_F5:
        return ImGuiKey.F5;
    case SDL_Keycode.SDLK_F6:
        return ImGuiKey.F6;
    case SDL_Keycode.SDLK_F7:
        return ImGuiKey.F7;
    case SDL_Keycode.SDLK_F8:
        return ImGuiKey.F8;
    case SDL_Keycode.SDLK_F9:
        return ImGuiKey.F9;
    case SDL_Keycode.SDLK_F10:
        return ImGuiKey.F10;
    case SDL_Keycode.SDLK_F11:
        return ImGuiKey.F11;
    case SDL_Keycode.SDLK_F12:
        return ImGuiKey.F12;
    case SDL_Keycode.SDLK_F13:
        return ImGuiKey.F13;
    case SDL_Keycode.SDLK_F14:
        return ImGuiKey.F14;
    case SDL_Keycode.SDLK_F15:
        return ImGuiKey.F15;
    case SDL_Keycode.SDLK_F16:
        return ImGuiKey.F16;
    case SDL_Keycode.SDLK_F17:
        return ImGuiKey.F17;
    case SDL_Keycode.SDLK_F18:
        return ImGuiKey.F18;
    case SDL_Keycode.SDLK_F19:
        return ImGuiKey.F19;
    case SDL_Keycode.SDLK_F20:
        return ImGuiKey.F20;
    case SDL_Keycode.SDLK_F21:
        return ImGuiKey.F21;
    case SDL_Keycode.SDLK_F22:
        return ImGuiKey.F22;
    case SDL_Keycode.SDLK_F23:
        return ImGuiKey.F23;
    case SDL_Keycode.SDLK_F24:
        return ImGuiKey.F24;
    case SDL_Keycode.SDLK_AC_BACK:
        return ImGuiKey.AppBack;
    case SDL_Keycode.SDLK_AC_FORWARD:
        return ImGuiKey.AppForward;
    default:
        break;
    }

    // Fallback to scancode
    switch (scancode) {
    case SDL_Scancode.SDL_SCANCODE_GRAVE:
        return ImGuiKey.GraveAccent;
    case SDL_Scancode.SDL_SCANCODE_MINUS:
        return ImGuiKey.Minus;
    case SDL_Scancode.SDL_SCANCODE_EQUALS:
        return ImGuiKey.Equal;
    case SDL_Scancode.SDL_SCANCODE_LEFTBRACKET:
        return ImGuiKey.LeftBracket;
    case SDL_Scancode.SDL_SCANCODE_RIGHTBRACKET:
        return ImGuiKey.RightBracket;
    case SDL_Scancode.SDL_SCANCODE_NONUSBACKSLASH:
        return ImGuiKey.Oem102;
    case SDL_Scancode.SDL_SCANCODE_BACKSLASH:
        return ImGuiKey.Backslash;
    case SDL_Scancode.SDL_SCANCODE_SEMICOLON:
        return ImGuiKey.Semicolon;
    case SDL_Scancode.SDL_SCANCODE_APOSTROPHE:
        return ImGuiKey.Apostrophe;
    case SDL_Scancode.SDL_SCANCODE_COMMA:
        return ImGuiKey.Comma;
    case SDL_Scancode.SDL_SCANCODE_PERIOD:
        return ImGuiKey.Period;
    case SDL_Scancode.SDL_SCANCODE_SLASH:
        return ImGuiKey.Slash;
    default:
        break;
    }
    return ImGuiKey.None;
}

void ImGui_ImplUILib_UpdateKeyModifiers(SDL_Keymod sdlKeyMods) {
    ImGuiIO io = igGetIO();
    ImGuiIO_AddKeyEvent(io, ImGuiMod.Ctrl, (sdlKeyMods & SDL_Keymod.SDL_KMOD_CTRL) != 0);
    ImGuiIO_AddKeyEvent(io, ImGuiMod.Shift, (sdlKeyMods & SDL_Keymod.SDL_KMOD_SHIFT) != 0);
    ImGuiIO_AddKeyEvent(io, ImGuiMod.Alt, (sdlKeyMods & SDL_Keymod.SDL_KMOD_ALT) != 0);
    ImGuiIO_AddKeyEvent(io, ImGuiMod.Super, (sdlKeyMods & SDL_Keymod.SDL_KMOD_GUI) != 0);
}

ImGuiViewport* ImGui_ImplUILib_GetViewportForWindowID(SDL_WindowID id) {
    BackendData* bd = ImGui_UILib_GetBackendData(ctx);
    return (id == bd.mainWindow.id) ? igGetMainViewport() : null;
}

bool ImGui_ImplUILib_ProcessEvent(const(SDL_Event)* event) {
    BackendData* bd = ImGui_UILib_GetBackendData();
    assert(bd !is null, "Context or backend not initialized! Did you call ImGui_ImplUILib_Init()?");
    ImGuiIO* io = igGetIOEx();

    switch (event.type) {
    case SDL_EventType.SDL_EVENT_MOUSE_MOTION:
        if (ImGui_ImplUILib_GetViewportForWindowID(event.motion.windowID) is null)
            return false;

        ImVec2 mousePos = {cast(float) event.motion.x, cast(float) event.motion.y};
        ImGuiIO_AddMouseSourceEvent(io,
            event.motion.which == SDL_TOUCH_MOUSEID ?
                ImGuiMouseSource.TouchScreen : ImGuiMouseSource.Mouse
        );
        ImGuiIO_AddMousePosEvent(io, mousePos.x, mousePos.y);
        return true;

    case SDL_EventType.SDL_EVENT_MOUSE_WHEEL:
        if (ImGui_ImplUILib_GetViewportForWindowID(event.wheel.windowID) is null)
            return false;

        ImVec2 wheel = {cast(float)-event.wheel.x, cast(float) event.wheel.y};
        ImGuiIO_AddMouseSourceEvent(io,
            event.wheel.which == SDL_TOUCH_MOUSEID ?
                ImGuiMouseSource.TouchScreen : ImGuiMouseSource.Mouse
        );
        ImGuiIO_AddMouseWheelEvent(io, wheel.x, wheel.y);
        return true;

    case SDL_EventType.SDL_EVENT_MOUSE_BUTTON_DOWN:
    case SDL_EventType.SDL_EVENT_MOUSE_BUTTON_UP:
        if (ImGui_ImplUILib_GetViewportForWindowID(event.button.windowID) is null)
            return false;
        int mouseButton = -1;
        if (event.button.button == SDL_MouseButtonFlags.SDL_BUTTON_LEFT) {
            mouseButton = 0;
        }
        if (event.button.button == SDL_MouseButtonFlags.SDL_BUTTON_RIGHT) {
            mouseButton = 1;
        }
        if (event.button.button == SDL_MouseButtonFlags.SDL_BUTTON_MIDDLE) {
            mouseButton = 2;
        }
        if (event.button.button == SDL_MouseButtonFlags.SDL_BUTTON_X1) {
            mouseButton = 3;
        }
        if (event.button.button == SDL_MouseButtonFlags.SDL_BUTTON_X2) {
            mouseButton = 4;
        }
        if (mouseButton == -1)
            break;

        ImGuiIO_AddMouseSourceEvent(io,
            event.button.which == SDL_TOUCH_MOUSEID ?
            ImGuiMouseSource.TouchScreen : 
            ImGuiMouseSource.Mouse
        );
        ImGuiIO_AddMouseButtonEvent(io,
            mouseButton,
            (event.type == SDL_EVENT_MOUSE_BUTTON_DOWN)
        );

        bd.mouseButtonsDown = 
            (event.type == SDL_EVENT_MOUSE_BUTTON_DOWN) ?
            (bd.mouseButtonsDown | (1 << mouseButton)) : 
            (bd.mouseButtonsDown & ~(1 << mouseButton)
        );
        return true;

    case SDL_EventType.SDL_EVENT_TEXT_INPUT:
        if (ImGui_ImplUILib_GetViewportForWindowID(event.text.windowID) is null)
            return false;
        
        ImGuiIO_AddInputCharactersUTF8(io, event.text.text);
        return true;

    case SDL_EventType.SDL_EVENT_KEY_DOWN:
    case SDL_EventType.SDL_EVENT_KEY_UP:
        if (ImGui_ImplUILib_GetViewportForWindowID(event.key.windowID) is null)
            return false;

        ImGuiKey key = ImGui_ImplUILib_KeyEventToImGuiKey(event.key.key, event.key.scancode);

        ImGui_ImplUILib_UpdateKeyModifiers(cast(SDL_Keymod) event.key.mod);
        ImGuiIO_AddKeyEvent(io, key, (event.type == SDL_EVENT_KEY_DOWN));
        ImGuiIO_SetKeyEventNativeData(io, key, event.key.key, event.key.scancode, event.key.scancode);
        return true;

    case SDL_EventType.SDL_EVENT_WINDOW_MOUSE_ENTER:
        if (ImGui_ImplUILib_GetViewportForWindowID(event.window.windowID) is null)
            return false;
        
        bd.activeWindowId = event.window.windowID;
        bd.pendingLeaveFrame = 0;
        return true;

    case SDL_EventType.SDL_EVENT_WINDOW_MOUSE_LEAVE:
        if (ImGui_ImplUILib_GetViewportForWindowID(event.window.windowID) is null)
            return false;
        
        bd.pendingLeaveFrame = igGetFrameCount() + 1;
        return true;

    case SDL_EventType.SDL_EVENT_WINDOW_FOCUS_GAINED:
    case SDL_EventType.ImGui_ImplUILib_GetViewportForWindowID:
        if (ImGui_ImplUILib_GetViewportForWindowID(event.window.windowID) is null)
            return false;

        ImGuiIO_AddFocusEvent(io, event.type == SDL_EventType.SDL_EVENT_WINDOW_FOCUS_GAINED);
        return true;
    }
    return false;
}


//
//          INITIALIZATION
//

void ImGui_ImplUILib_SetupPlatformHandles(ImGuiViewport* viewport, SDL_Window* window) {
    viewport.PlatformHandle = cast(void*)SDL_GetWindowID(window);

    version(Windows) {
        viewport.PlatformHandleRaw = cast(void*)SDL_GetPointerProperty(SDL_GetWindowProperties(window), SDL_PROP_WINDOW_WIN32_HWND_POINTER, null);
    } else version(OSX) {
        viewport.PlatformHandleRaw = cast(void*)SDL_GetPointerProperty(SDL_GetWindowProperties(window), SDL_PROP_WINDOW_COCOA_WINDOW_POINTER, null);
    } else {    
        viewport.PlatformHandleRaw = null;
    }
}

bool ImGui_ImplUILib_Init(AppWindow window) {
    ImGuiIO* io = igGetIO();
    assert(io.BackendPlatformUserData is null, "Already initialized a platform backend!");

    io.BackendPlatformUserData = cast(void*)nogc_new!BackendData();
    io.BackendPlatformName = "Inochi2D UI Lib";
    io.BackendFlags |= ImGuiBackendFlags.HasMouseCursors;           // We can honor GetMouseCursor() values (optional)
    io.BackendFlags |= ImGuiBackendFlags.HasSetMousePos;            // We can honor io.WantSetMousePos requests (optional, rarely used)
    bd.mainWindow = window;

    // Check and store if we are on a SDL backend that supports SDL_GetGlobalMouseState() and SDL_CaptureMouse()
    // ("wayland" and "rpi" don't support it, but we chose to use a white-list instead of a black-list)
    bd.canUseGlobalState = false;
    bd.canUseCapture = false;

    const(char)* sdlBackend = SDL_GetCurrentVideoDriver();
    string[] captureAndGlobalStateWhitelist = { "windows", "cocoa", "x11", "DIVE", "VMAN" };
    foreach(string item; captureAndGlobalStateWhitelist) {
        if (strncmp(sdlBackend, item, item.length) == 0) {
            bd.canUseGlobalState = true;
            bd.canUseCapture = true;
        }
    }

    ImGuiPlatformIO* platformIO = igGetPlatformIO();
    platformIO.Platform_SetClipboardTextFn = &ImGui_ImplUILib_SetClipboardText;
    platformIO.Platform_GetClipboardTextFn = &ImGui_ImplUILib_GetClipboardText;
    platformIO.Platform_SetImeDataFn = &ImGui_ImplUILib_PlatformSetImeData;
    platformIO.Platform_OpenInShellFn = (ImGuiContext*, const char* url) { return SDL_OpenURL(url) == 0; };

    // Load mouse cursors
    bd.cursors[ImGuiMouseCursor.Arrow] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_DEFAULT);
    bd.cursors[ImGuiMouseCursor.TextInput] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_TEXT);
    bd.cursors[ImGuiMouseCursor.ResizeAll] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_MOVE);
    bd.cursors[ImGuiMouseCursor.ResizeNS] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_NS_RESIZE);
    bd.cursors[ImGuiMouseCursor.ResizeEW] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_EW_RESIZE);
    bd.cursors[ImGuiMouseCursor.ResizeNESW] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_NESW_RESIZE);
    bd.cursors[ImGuiMouseCursor.ResizeNWSE] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_NWSE_RESIZE);
    bd.cursors[ImGuiMouseCursor.Hand] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_POINTER);
    bd.cursors[ImGuiMouseCursor.Wait] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_WAIT);
    bd.cursors[ImGuiMouseCursor.Progress] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_PROGRESS);
    bd.cursors[ImGuiMouseCursor.NotAllowed] = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_NOT_ALLOWED);

    // Set platform dependent data in viewport
    // Our mouse update function expect PlatformHandle to be filled for the main viewport
    ImGuiViewport* mainViewport = igGetMainViewport();
    ImGui_ImplUILib_SetupPlatformHandles(mainViewport, window);

    // From 2.0.5: Set SDL hint to receive mouse click events on window focus, otherwise SDL doesn't emit the event.
    // Without this, when clicking to gain focus, our widgets wouldn't activate even though they showed as hovered.
    // (This is unfortunately a global SDL setting, so enabling it might have a side-effect on your application.
    // It is unlikely to make a difference, but if your app absolutely needs to ignore the initial on-focus click:
    // you can ignore SDL_EVENT_MOUSE_BUTTON_DOWN events coming right after a SDL_WINDOWEVENT_FOCUS_GAINED)
    SDL_SetHint(SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH, "1");

    // From 2.0.22: Disable auto-capture, this is preventing drag and drop across multiple windows (see #5710)
    SDL_SetHint(SDL_HINT_MOUSE_AUTO_CAPTURE, "0");
    return true;
}

void ImGui_ImplUILib_Shutdown() {
    if (BackendData* bd = ImGui_UILib_GetBackendData()) {
        ImGuiIO* io = igGetIO();

        bd.clipboardData.clear();
        foreach(cursor; bd.cursors)
            SDL_DestroyCursor(cursor);
        

        nogc_delete(bd);

        io.BackendPlatformUserData = null;
        io.BackendPlatformName = null;
        io.BackendFlags = ImGuiBackendFlags.None;
    }
}
