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
            return promise.uriFromPromise().decode;
        } catch (Throwable ex) {

            // FALLBACK: If xdg-desktop-portal is not available then try tinyfiledialogs.
            c_str filename = tinyfd_openFileDialog(title.toStringz, "", filters, multiple);
            return incToDString(filename);
        }
    } else {
        c_str filename = tinyfd_openFileDialog(title.toStringz, "", filters, multiple);
        return incToDString(filename);
    }
}

string incShowOpenFolderDialog(string title = "Open...") {
    version (linux) {
        try {
            FileOpenOptions op;
            op.directory = true;
            auto promise = dpFileChooserOpenFile(getWindowHandle(), title, op);
            promise.await();
            return promise.uriFromPromise().decode;
        } catch (Throwable _) {

            // FALLBACK: If xdg-desktop-portal is not available then try tinyfiledialogs.
            c_str filename = tinyfd_selectFolderDialog(title.toStringz, null);
            return incToDString(filename);
        }
    } else {
        c_str filename = tinyfd_selectFolderDialog(title.toStringz, null);
        return incToDString(filename);
    }
}

string incShowOpenDialog(const(TFD_Filter)[] filters, string title = "Open...") {
    version (linux) {
        try {
            FileOpenOptions op;
            op.filters = tfdToFileFilter(filters);
            auto promise = dpFileChooserOpenFile(getWindowHandle(), title, op);
            promise.await();
            return promise.uriFromPromise().decode;
        } catch (Throwable ex) {

            // FALLBACK: If xdg-desktop-portal is not available then try tinyfiledialogs.
            c_str filename = tinyfd_openFileDialog(title.toStringz, "", filters, false);
            return incToDString(filename);
        }
    } else {
        c_str filename = tinyfd_openFileDialog(title.toStringz, "", filters, false);
        return incToDString(filename);
    }
}

string incShowSaveDialog(const(TFD_Filter)[] filters, string fname, string title = "Save...") {
    version (linux) {
        try {
            FileSaveOptions op;
            op.filters = tfdToFileFilter(filters);
            auto promise = dpFileChooserSaveFile(getWindowHandle(), title, op);
            promise.await();
            return promise.uriFromPromise().decode;
        } catch (Throwable ex) {

            // FALLBACK: If xdg-desktop-portal is not available then try tinyfiledialogs.
            c_str filename = tinyfd_saveFileDialog(title.toStringz, fname.toStringz, filters);
            return incToDString(filename);
        }
    } else {
        c_str filename = tinyfd_saveFileDialog(title.toStringz, fname.toStringz, filters);
        return incToDString(filename);
    }
}

enum DialogButton {
    Cancel, Yes, No
}

enum DialogType : c_str {
    Ok = "ok",
    OkCancel = "okcancel",
    YesNo = "yesno",
    YesNoCancel = "yesnocancel"
}

enum IconType : c_str {
    Info = "info", 
    Warning = "warning",
    Error = "error",
    Question = "question"
}

// tinyfd api may make confusion with the button id
// 0 cancel/no, 1 ok/yes , 2 no in yesnocancel
// so we need to impelement incDialogButtonToTinyfd() and incTinyfdToDialogButton()
int incDialogButtonToTinyfd(DialogButton button, DialogType dialogType) {
    if (dialogType == DialogType.YesNoCancel) {
        switch (button) {
            case DialogButton.Cancel: return 0;
            case DialogButton.Yes: return 1;
            case DialogButton.No: return 2;
            default: assert(0);
        }
    } else {
        throw new Exception("Not implemented");
    }
}

DialogButton incTinyfdToDialogButton(int button, DialogType dialogType) {
    if (dialogType == DialogType.YesNoCancel) {
        switch (button) {
            case 0: return DialogButton.Cancel;
            case 1: return DialogButton.Yes;
            case 2: return DialogButton.No;
            default: assert(0);
        }
    } else {
        throw new Exception("Not implemented");
    }
}

// TODO: incDialogButtonToTinyfd() / incTinyfdToDialogButton() unit test?

DialogButton incMessageBox(
        string title, string message,
        DialogType dialogType = DialogType.Ok,
        IconType iconType = IconType.Info,
        DialogButton defaultButton = DialogButton.Cancel
    ) {
    // is necessary check on linux? or just using tinyfd_messageBox?
    int result = tinyfd_messageBox(
        title.toStringz,
        message.toStringz,
        dialogType,
        iconType,
        incDialogButtonToTinyfd(defaultButton, dialogType),
    );
    
    return incTinyfdToDialogButton(result, dialogType);
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
    returns "Preserve" or "NotPreserve" or "Cancel"
*/
AskKeepLayerFolder incImportKeepFolderStructPop() {
    if (incGetKeepLayerFolder() == "Preserve")
        return AskKeepLayerFolder.Preserve;
    if (incGetKeepLayerFolder() == "NotPreserve")
        return AskKeepLayerFolder.NotPreserve;
 
    DialogButton result = incMessageBox(
        "Import File",
        "Do you want to preserve the folder structure of the imported file? You can change this in the settings.",
        DialogType.YesNoCancel,
        IconType.Question,
    );

    switch (result) {
        case DialogButton.Cancel:
            return AskKeepLayerFolder.Cancel;
        case DialogButton.Yes:
            return AskKeepLayerFolder.Preserve;
        case DialogButton.No:
            return AskKeepLayerFolder.NotPreserve;
        default: assert(0);
    }
}