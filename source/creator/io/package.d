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
import creator.widgets: DialogButtons;
import creator.widgets.dialog;

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

string incToDString(c_str cstr1) {
    if (cstr1 !is null) {
        return cast(string) cstr1.fromStringz;
    }
    return null;
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
            return incToDString(filename).dup;
        }
    } else {
        c_str filename = tinyfd_openFileDialog(title.toStringz, "", filters, multiple);
        return incToDString(filename).dup;
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
            return incToDString(filename).dup;
        }
    } else {
        c_str filename = tinyfd_selectFolderDialog(title.toStringz, null);
        return incToDString(filename).dup;
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
            return incToDString(filename).dup;
        }
    } else {
        c_str filename = tinyfd_openFileDialog(title.toStringz, "", filters, false);
        return incToDString(filename).dup;
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
            return incToDString(filename).dup;
        }
    } else {
        c_str filename = tinyfd_saveFileDialog(title.toStringz, fname.toStringz, filters);
        return incToDString(filename).dup;
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

string incGetKeepLayerFolder() {
    if (incSettingsCanGet("KeepLayerFolder"))
        return incSettingsGet!string("KeepLayerFolder");
    else
        // also see incSettingsLoad()
        // Preserve the original behavior for existing users
        return "NotPreserve";
}

bool incSetKeepLayerFolder(string select) {
    incSettingsSet("KeepLayerFolder", select);
    return true;
}

enum AskKeepLayerFolder {
    Preserve, NotPreserve, Cancel
}

/**
    Function for importing pop-up dialog
*/
bool incKeepStructDialog(ImportKeepHandler handler) {
    if (incGetKeepLayerFolder() == "Preserve") {
        handler.load(AskKeepLayerFolder.Preserve);
    } else if (incGetKeepLayerFolder() == "NotPreserve") {
        handler.load(AskKeepLayerFolder.NotPreserve);
    } else {
        handler.register();
        handler.show();
    }

    return true;
}

class ImportKeepHandler : DialogHandler {
    const(char)* INC_KEEP_STRUCT_DIALOG_NAME = "ImportKeepFolderStructPopup";

    this () {
        super(INC_KEEP_STRUCT_DIALOG_NAME);
    }

    override
    bool onClickCancel() {
        return this.load(AskKeepLayerFolder.Cancel);
    }

    override
    bool onClickYes() {
        return this.load(AskKeepLayerFolder.Preserve);
    }

    override
    bool onClickNo() {
        return this.load(AskKeepLayerFolder.NotPreserve);
    }

    bool load(AskKeepLayerFolder select) {
        // override this
        return false;
    }

    void show() {
        incDialog(
            INC_KEEP_STRUCT_DIALOG_NAME,
            __("File import"),
            _("Would you like to keep the folder structure of the imported file?\n\nYou can change the default behaviour in the settings."),
            DialogLevel.Warning,
            DialogButtons.Yes | DialogButtons.No | DialogButtons.Cancel
        );
    }
}