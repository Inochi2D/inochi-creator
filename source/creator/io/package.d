/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.io;
public import creator.io.psd;
public import creator.io.kra;
public import creator.io.inpexport;
public import creator.io.videoexport;
public import creator.io.imageexport;

import tinyfiledialogs;
public import tinyfiledialogs : TFD_Filter;
import std.string;
import std.uri;
import i18n;

import bindbc.sdl;
import creator.core;

version (linux) {
    import dportals.filechooser;
    import dportals.promise;
}

private {
    version (linux) {
        string getWindowHandle() {
            SDL_SysWMinfo info;
            SDL_GetWindowWMInfo(incGetWindowPtr(), &info);
            if (info.subsystem == SDL_SYSWM_TYPE.SDL_SYSWM_X11) {
                import std.conv : to;

                return "x11:" ~ info.info.x11.window.to!string(16);
            }
            return "";
        }

        FileFilter[] tfdToFileFilter(const(TFD_Filter)[] filters) {
            FileFilter[] out_;

            foreach (filter; filters) {
                auto of = FileFilter(
                    cast(string) filter.description.fromStringz,
                    []
                );

                foreach (i, pattern; filter.patterns) {
                    of.items ~= FileFilterItem(
                        cast(uint) i,
                        cast(string) pattern.fromStringz
                    );
                }

                out_ ~= of;
            }

            return out_;
        }

        string uriFromPromise(Promise promise) {
            if (promise.success) {
                import std.array : replace;

                string uri = promise.value["uris"].data.array[0].str;
                uri = uri.replace("%20", " ");
                return uri[7 .. $];
            }
            return null;
        }
    }
}

string incShowImportDialog(const(TFD_Filter)[] filters, string title, bool multiple = false) {
    version (linux) {
        try {
            FileOpenOptions op;
            op.filters = tfdToFileFilter(filters);
            op.multiple = multiple;
            auto promise = dpFileChooserOpenFile(getWindowHandle(), title, op);
            promise.await();
            return promise.uriFromPromise().decode.dup;
        } catch (Throwable ex) {

            // FALLBACK: If xdg-desktop-portal is not available then try tinyfiledialogs.
            c_str filename = tinyfd_openFileDialog(title.toStringz, "", filters, multiple);
            if (filename !is null) {
                string file = cast(string) filename.fromStringz;
                return file.dup;
            }
            return null;
        }
    } else {
        c_str filename = tinyfd_openFileDialog(title.toStringz, "", filters, multiple);
        if (filename !is null) {
            string file = cast(string) filename.fromStringz;
            return file.dup;
        }
        return null;
    }
}

string incShowOpenFolderDialog(string title = "Open...") {
    version (linux) {
        try {
            FileOpenOptions op;
            op.directory = true;
            auto promise = dpFileChooserOpenFile(getWindowHandle(), title, op);
            promise.await();
            return promise.uriFromPromise().decode.dup;
        } catch (Throwable _) {

            // FALLBACK: If xdg-desktop-portal is not available then try tinyfiledialogs.
            c_str filename = tinyfd_selectFolderDialog(title.toStringz, null);
            if (filename !is null)
                return cast(string) filename.fromStringz.dup;
            return null;
        }
    } else {
        c_str filename = tinyfd_selectFolderDialog(title.toStringz, null);
        if (filename !is null)
            return cast(string) filename.fromStringz.dup;
        return null;
    }
}

string incShowOpenDialog(const(TFD_Filter)[] filters, string title = "Open...") {
    version (linux) {
        try {
            FileOpenOptions op;
            op.filters = tfdToFileFilter(filters);
            auto promise = dpFileChooserOpenFile(getWindowHandle(), title, op);
            promise.await();
            return promise.uriFromPromise().decode.dup;
        } catch (Throwable ex) {

            // FALLBACK: If xdg-desktop-portal is not available then try tinyfiledialogs.
            c_str filename = tinyfd_openFileDialog(title.toStringz, "", filters, false);
            if (filename !is null) {
                string file = cast(string) filename.fromStringz;
                return file.dup;
            }
            return null;
        }
    } else {
        c_str filename = tinyfd_openFileDialog(title.toStringz, "", filters, false);
        if (filename !is null) {
            string file = cast(string) filename.fromStringz;
            return file.dup;
        }
        return null;
    }
}

string incShowSaveDialog(const(TFD_Filter)[] filters, string fname, string title = "Save...") {
    version (linux) {
        try {
            FileSaveOptions op;
            op.filters = tfdToFileFilter(filters);
            auto promise = dpFileChooserSaveFile(getWindowHandle(), title, op);
            promise.await();
            return promise.uriFromPromise().decode.dup;
        } catch (Throwable ex) {

            // FALLBACK: If xdg-desktop-portal is not available then try tinyfiledialogs.
            c_str filename = tinyfd_saveFileDialog(title.toStringz, fname.toStringz, filters);
            if (filename !is null) {
                string file = cast(string) filename.fromStringz;
                return file.dup;
            }
            return null;
        }
    } else {
        c_str filename = tinyfd_saveFileDialog(title.toStringz, fname.toStringz, filters);
        if (filename !is null) {
            string file = cast(string) filename.fromStringz;
            return file.dup;
        }
        return null;
    }
}

//
// Reusable basic loaders
//

void incCreatePartsFromFiles(string[] files) {
    import std.path: baseName, extension;
    import inochi2d: ShallowTexture, inTexPremultiply, Puppet, inCreateSimplePart;
    import creator.actions: incAddChildWithHistory;
    import creator.widgets: incDialog;
    import creator: incActivePuppet, incSelectedNode;

    foreach (file; files) {
        string fname = file.baseName;

        switch (fname.extension.toLower) {
            case ".png", ".tga", ".jpeg", ".jpg":
                try {
                    auto tex = new ShallowTexture(file);
                    inTexPremultiply(tex.data, tex.channels);

                    incAddChildWithHistory(
                        inCreateSimplePart(*tex, null, fname),
                        incSelectedNode(),
                        fname
                    );
                } catch (Exception ex) {

                    if (ex.msg[0 .. 11] == "unsupported") {
                        incDialog(__("Error"), _("%s is not supported").format(fname));
                    } else incDialog(__("Error"), ex.msg);
                }

                // We've added new stuff, rescan nodes
                incActivePuppet().rescanNodes();
                break;
            default: throw new Exception("Invalid file type "~fname.extension.toLower);
        }
    }
}
