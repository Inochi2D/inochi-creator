/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets.dialog;
import creator.widgets.dummy;
import creator.core.font;
import bindbc.imgui;
import i18n;

enum DialogLevel : size_t {
    Info = 0,
    Warning = 1,
    Error = 2
}

enum DialogButtons {
    NONE = 0,
    OK = 1,
    Cancel = 2,
    Yes = 4,
    No = 8
}

/**
    Render dialogs
*/
void incRenderDialogs() {
    if (entries.length > 0) {
        auto entry = &entries[0];

        if (!igIsPopupOpen(entry.tag)) {
            igOpenPopup(entry.tag);
        }

        if (igBeginPopupModal(entry.tag, null, ImGuiWindowFlags.NoSavedSettings | ImGuiWindowFlags.NoResize)) {
            float uiScale = incGetUIScale();
            float errImgScale = 96*uiScale;

            igBeginGroup();
                // TODO: Render image of Ada depending on the DialogLevel
                if (igBeginChild("ErrorMainBoxLogo", ImVec2(errImgScale, errImgScale))) {
                    version (InBranding) {
                        import creator.core : incGetLogo;
                        igImage(cast(void*)incGetLogo(), ImVec2(errImgScale, errImgScale));
                    }
                    igEndChild();
                }
                igSameLine(0, 8);
                igText(entry.text);
            igEndGroup();


            //
            // BUTTONS
            //
            auto avail = incAvailableSpace();
            float btnHeight = 24*uiScale;
            float btnSize = (avail.x/2)/entry.btncount;
            igDummy(ImVec2(avail.x/2, btnHeight));
            igSameLine(0, 0);

            if ((entry.btns & DialogButtons.OK) == 1) {
                if (igButton(__("OK"), ImVec2(btnSize, btnHeight))) {
                    entry.selected = DialogButtons.OK;
                    igCloseCurrentPopup();
                }
                igSameLine();
            }
            
            if ((entry.btns & DialogButtons.Cancel) == 2) {
                if (igButton(__("Cancel"), ImVec2(btnSize, btnHeight))) {
                    entry.selected = DialogButtons.Cancel;
                    igCloseCurrentPopup();
                }
                igSameLine();
            }
            
            if ((entry.btns & DialogButtons.Yes) == 4) {
                if (igButton(__("Yes"), ImVec2(btnSize, btnHeight))) {
                    entry.selected = DialogButtons.Yes;
                    igCloseCurrentPopup();
                }
                igSameLine();
            }
            
            if ((entry.btns & DialogButtons.No) == 8) {
                if (igButton(__("No"), ImVec2(btnSize, btnHeight))) {
                    entry.selected = DialogButtons.No;
                    igCloseCurrentPopup();
                }
            }
            igEndPopup();
        }
    }
}

/**
    Clean up dialogs
*/
void incCleanupDialogs() {
    if (entries.length > 0 && entries[0].selected > 0) {
        entries = entries[1..$];
    }
}

void incDialog(const(char)* title, string body_, DialogLevel level = DialogLevel.Error, DialogButtons btns = DialogButtons.OK) {
    import std.string : toStringz;
    int btncount = 0;
    if ((btns & DialogButtons.OK) == 1) btncount++;
    if ((btns & DialogButtons.Cancel) == 2) btncount++;
    if ((btns & DialogButtons.Yes) == 4) btncount++;
    if ((btns & DialogButtons.No) == 8) btncount++;

    entries ~= DialogEntry(
        title,
        body_.toStringz,
        level,
        btns,
        DialogButtons.NONE,
        btncount
    );
}

/**
    Gets which button the user selected in the last dialog box with the selected tag.
    Returns NONE if the last dialog was *not* the looked for tag or if there's no dialogs open
*/
DialogButtons incDialogButtonSelected(const(char)* tag) {
    if (entries.length == 0) return DialogButtons.NONE;
    if (entries[0].tag != tag) return DialogButtons.NONE;
    return entries[0].selected;
}

private {
    DialogEntry[] entries;

    DialogEntry* findDialogEntry(const(char)* tag) {
        foreach(i; 0..entries.length) {
            if (entries[i].tag == tag) return &entries[i];
        }
        return null;
    }

    struct DialogEntry {
        const(char)* tag;
        const(char)* text;
        DialogLevel level;
        DialogButtons btns;
        DialogButtons selected;
        int btncount;
    }
}