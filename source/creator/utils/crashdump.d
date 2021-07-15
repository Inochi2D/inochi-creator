/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.utils.crashdump;
import std.file : write;
//import i18n;
import std.stdio;
import std.path;
import std.traits;
import std.array;

string genCrashDump(T...)(Throwable t, T state) {
    string[] args;
    static foreach(i; 0 .. state.length) {
        args ~= serializeToPrettyJson(state[i]);
    }
    Appender!string str;
    str.put("=== Args State ===\n");
    str.put(args.join(",\n"));
    str.put("\n\n=== Exception ===\n");
    str.put(t.toString());
    return str.data;
}

version(Windows) {
    pragma(lib, "user32.lib");
    pragma(lib, "shell32.lib");
    import core.sys.windows.winuser : MessageBoxW;
    import std.utf : toUTF16z, toUTF8;
    import std.string : fromStringz;

    private string getDesktopDir() {
        import core.sys.windows.windows;
        import core.sys.windows.shlobj;
        wstring desktopDir = new wstring(MAX_PATH);
        SHGetSpecialFolderPath(HWND_DESKTOP, cast(wchar*)desktopDir.ptr, CSIDL_DESKTOP, FALSE);
        return (cast(wstring)fromStringz!wchar(desktopDir.ptr)).toUTF8;
    }

    private void ShowMessageBox(string message, string title) {
        MessageBoxW(null, toUTF16z(message), toUTF16z(title), 0);
    }

    void crashdump(T...)(Throwable throwable, T state) {
        write(buildPath(getDesktopDir(), "inochi-creator-crashdump.txt"), genCrashDump!T(throwable, state));

        ShowMessageBox(
            _("The application has unexpectedly crashed\nPlease send the developers the inochi-creator-crashdump.txt which has been put on your desktop\nVia https://github.com/Inochi2D/inochi-creator/issues"),
            _("Inochi Creator Crashdump")
        );
    }
}

version(Posix) {
    void crashdump(T...)(Throwable throwable, T state) {
        write(expandTilde("~/inochi-creator-crashdump.txt"), genCrashDump!T(throwable, state));
        writeln(_("\n\n\n===   Inochi Creator has crashed   ===\nPlease send us the inochi-creator-crashdump.txt file in your home folder\nAttach the file as a git issue @ https://github.com/Inochi2D/inochi-creator/issues"));
    }
}