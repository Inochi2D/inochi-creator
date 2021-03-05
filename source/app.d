/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
import std.stdio;
import creator.app;
import gtk.Main;
import crashdump;
import std.process;
import bindbc.imgui;

int main(string[] args)
{

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // The following code bypasses GTK windows hooking that causes problems with visual studio debugging(slow keyboard, it is a hack and may not work in general)
    // from: https://forum.dlang.org/post/hgrxkmmtholjrzznaclm@forum.dlang.org
    //debug {
    //    import core.sys.windows.windows, core.stdc.string;
    //    alias HHOOK function(int, HOOKPROC, HINSTANCE, DWORD) SetWindowsHookExAProc;
    //    alias HHOOK function(int, HOOKPROC, HINSTANCE, DWORD) SetWindowsHookExWProc;
    //    static extern (Windows) HHOOK KBHook(int, HOOKPROC, HINSTANCE, DWORD)
    //    {
    //        asm
    //        {
    //            naked;
    //            ret;
    //        }
    //    }
    //    DWORD old;
    //    auto err = GetLastError();
    //    auto hModule = LoadLibrary("User32.dll");
    //    auto proc = cast(SetWindowsHookExAProc)GetProcAddress(hModule, "SetWindowsHookExA");
    //    err = GetLastError();
    //    VirtualProtect(proc, 40, PAGE_EXECUTE_READWRITE, &old);
    //    err = GetLastError();
    //    memcpy(proc, &KBHook, 7);
    //    // Cleanup	
    //    //FreeLibrary(hModule);
    //}


    // We do NOT want this app themed
    environment.remove("GTK_THEME");

    try {
        loadImGui();
        Main.init(args);
        (new InochiCreator).showAll();
        Main.run();
    } catch(Throwable throwable) {
        crashdump.crashdump(throwable, args);
        return -1;
    }
    return 0;
}
