/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.utils.crashdump;
import std.file : write;
//import i18n;
import std.stdio;
import std.path;
import std.process : environment;
import std.traits;
import std.array;
import i18n;

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
}

string linuxStateHome() {
    // https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html#variables
    return environment.get("XDG_STATE_HOME", buildPath(environment["HOME"], ".local", "state"));
}

string getCrashDumpDir() {
    version(Windows) return getDesktopDir();
    else version(OSX) return expandTilde("~/Library/Logs/");
    else version(linux) return expandTilde(linuxStateHome() ~ "/");
    else return expandTilde("~");
}

string genCrashDumpPath(string filename) {
    import std.datetime;
    return buildPath(getCrashDumpDir(), filename ~ "-" ~ Clock.currTime.toISOString() ~ ".txt");
}

void mkdirCrashDumpDir() {
    import std.file : mkdir, exists, setAttributes;
    auto dir = getCrashDumpDir();
    if (exists(dir))
        return;
    
    // Should we set recursively make the directory or not?
    mkdir(dir);
    version(linux) {
        import std.conv : octal;
        // https://specifications.freedesktop.org/basedir-spec/latest/#referencing
        // TODO: Should we set permissions recursively?
        setAttributes(dir, octal!700);
    }
}

void crashdump(T...)(Throwable throwable, T state) {
    // Write crash dump to disk
    try {
        mkdirCrashDumpDir();
        write(genCrashDumpPath("inochi-creator-crashdump"), genCrashDump(throwable, state));
    } catch (Exception ex) {
        writeln("Failed to write crash dump" ~ ex.msg);
    }

    // Use appropriate system method to notify user where crash dump is.
    version(OSX) writeln(_("\n\n\n===   Inochi Creator has crashed   ===\nPlease send us the inochi-creator-crashdump.txt file in ~/Library/Logs\nAttach the file as a git issue @ https://github.com/Inochi2D/inochi-creator/issues"));
    else version(linux) writeln(_("\n\n\n===   Inochi Creator has crashed   ===\nPlease send us the inochi-creator-crashdump.txt file in your log directory, XDG_STATE_HOME. For Flatpak, this is in ~/.var/app/com.inochi2d.inochi-creator.\nAttach the file as a git issue @ https://github.com/Inochi2D/inochi-creator/issues"));
    else version(Windows) ShowMessageBox(
        _("The application has unexpectedly crashed\nPlease send the developers the inochi-creator-crashdump.txt which has been put on your desktop\nVia https://github.com/Inochi2D/inochi-creator/issues"),
        _("Inochi Creator Crashdump")
    );
}