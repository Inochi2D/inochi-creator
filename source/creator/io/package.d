/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.io;
public import creator.io.psd;
public import creator.io.inpexport;
public import creator.io.videoexport;
public import creator.io.imageexport;

import tinyfiledialogs;
public import tinyfiledialogs : TFD_Filter;
import std.string;
import i18n;

import bindbc.sdl;
import creator.core;

version(linux) {
    import dportals.filechooser;
    import dportals.promise;
}

private {
    version(linux) {
        string getWindowHandle() {
            SDL_SysWMinfo info;
            SDL_GetWindowWMInfo(incGetWindowPtr(), &info);
            if (info.subsystem == SDL_SYSWM_TYPE.SDL_SYSWM_X11) {
                import std.conv : to;
                return "x11:"~info.info.x11.window.to!string(16);
            }
            return "";
        }
        
        FileFilter[] tfdToFileFilter(const(TFD_Filter)[] filters) {
            FileFilter[] out_;

            foreach(filter; filters) {
                auto of = FileFilter(
                    cast(string)filter.description.fromStringz,
                    []
                );

                foreach(i, pattern; filter.patterns) {
                    of.items ~= FileFilterItem(
                        cast(uint)i,
                        cast(string)pattern.fromStringz
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
                return uri[7..$];
            }
            return "";
        }
    }
}

string incShowImportDialog(const(TFD_Filter)[] filters) {
    version(linux) {
        FileOpenOptions op;
        op.filters = tfdToFileFilter(filters);
        auto promise = dpFileChooserOpenFile(getWindowHandle(), "Import...", op);
        promise.await();
        return promise.uriFromPromise();
    } else {
        c_str filename = tinyfd_openFileDialog(__("Import..."), "", filters, false);
        if (filename !is null) {
            string file = cast(string)filename.fromStringz;
            return file;
        }
        return null;
    }
}

string incShowOpenFolderDialog(string title="Open...") {
    version(linux) {
        FileOpenOptions op;
        op.directory = true;
        auto promise = dpFileChooserOpenFile(getWindowHandle(), title, op);
        promise.await();
        return promise.uriFromPromise();
    } else {
        c_str filename = tinyfd_selectFolderDialog(title, null);
        if (filename !is null) return cast(string)filename.fromStringz;
        return null;
    }
}

string incShowOpenDialog(const(TFD_Filter)[] filters, string title="Open...") {
    version(linux) {
        FileOpenOptions op;
        op.filters = tfdToFileFilter(filters);
        auto promise = dpFileChooserOpenFile(getWindowHandle(), title, op);
        promise.await();
        return promise.uriFromPromise();
    } else {
        c_str filename = tinyfd_openFileDialog(title, "", filters, false);
        if (filename !is null) {
            string file = cast(string)filename.fromStringz;
            return file;
        }
        return null;
    }
}

string incShowSaveDialog(const(TFD_Filter)[] filters, string fname, string title = "Save...") {
    version(linux) {
        FileSaveOptions op;
        op.filters = tfdToFileFilter(filters);
        auto promise = dpFileChooserSaveFile(getWindowHandle(), title, op);
        promise.await();
        return promise.uriFromPromise();
    } else {
        c_str filename = tinyfd_saveFileDialog(title, fname.toStringz, filters);
        if (filename !is null) {
            string file = cast(string)filename.fromStringz;
            return file;
        }
        return null;
    }
}