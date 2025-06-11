/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.core.ui.backend.win32;
version(Windows):

import sdl.loadso;
import core.sys.windows.windows;
import core.sys.windows.winuser;

// Windows 8.1+ DPI awareness context enum
enum DPIAwarenessContext { 
    DPI_AWARENESS_CONTEXT_UNAWARE = 0,
    DPI_AWARENESS_CONTEXT_SYSTEM_AWARE = 1,
    DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE = 2,
    DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = 3
}

// Windows 8.1+ DPI awareness enum
enum ProcessDPIAwareness { 
    PROCESS_DPI_UNAWARE = 0,
    PROCESS_SYSTEM_DPI_AWARE = 1,
    PROCESS_PER_MONITOR_DPI_AWARE = 2
}

void uiSetWin32DPIAwareness() {
    void* userDLL, shcoreDLL;

    extern(Windows) bool function() dpiAwareFunc8;
    extern(Windows) HRESULT function(DPIAwarenessContext) dpiAwareFuncCtx81;
    extern(Windows) HRESULT function(ProcessDPIAwareness) dpiAwareFunc81;

    userDLL = SDL_LoadObject("USER32.DLL");
    if (userDLL) {
        dpiAwareFunc8 = cast(typeof(dpiAwareFunc8)) SDL_LoadFunction(userDLL, "SetProcessDPIAware");
        dpiAwareFuncCtx81 = cast(typeof(dpiAwareFuncCtx81)) SDL_LoadFunction(userDLL, "SetProcessDpiAwarenessContext");
    }
    
    shcoreDLL = SDL_LoadObject("SHCORE.DLL");
    if (shcoreDLL) {
        dpiAwareFunc81 = cast(typeof(dpiAwareFunc81)) SDL_LoadFunction(shcoreDLL, "SetProcessDpiAwareness");
    }
    
    if (dpiAwareFuncCtx81) {
        dpiAwareFuncCtx81(DPIAwarenessContext.DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE);
        dpiAwareFuncCtx81(DPIAwarenessContext.DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
    } else if (dpiAwareFunc81) {
        dpiAwareFunc81(ProcessDPIAwareness.PROCESS_PER_MONITOR_DPI_AWARE);
    } else if (dpiAwareFunc8) dpiAwareFunc8();

    // Unload the DLLs
    if (userDLL) SDL_UnloadObject(userDLL);
    if (shcoreDLL) SDL_UnloadObject(shcoreDLL);        
}
