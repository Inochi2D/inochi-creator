module creator.widgets.modal;

public import creator.widgets.modal.nagscreen;
import bindbc.sdl;
import creator.widgets.label;
import creator.widgets.markdown;
import creator.widgets.dummy;
import creator.widgets.modal;
import creator.core;
import creator.core.i18n;
import std.string;
import creator.utils.link;
import i18n;
import inochi2d;
import creator.ver;
import creator.io;
import creator;
import creator.config;

private {
    __gshared Modal[] incModalList;
    ptrdiff_t incModalIndex = -1;

}
/**
    A modal widget
*/
abstract class Modal {
private:
    string title_;
    const(char)* imTitle;
    bool visible;
    bool hasTitlebar;


protected:
    bool drewWindow;
    ImGuiWindowFlags flags;

    abstract void onUpdate();

    void onBeginUpdate() {
        if (imTitle is null) imTitle = title_.toStringz;

        // TITLE
        if (visible && !igIsPopupOpen(imTitle)) {
            igOpenPopup(imTitle);
        }

        drewWindow = igBeginPopupModal(
            imTitle,
            &visible, 
            hasTitlebar ? ImGuiWindowFlags.None : ImGuiWindowFlags.NoResize | ImGuiWindowFlags.NoDecoration
        );
    }
    
    void onEndUpdate() {
        if (drewWindow) igEndPopup();

        // Handle the user closing the modal from the titlebar.
        if (!visible) {
            incModalCloseTop();
        }
    }

    string title() {
        return title_;
    }

public:


    /**
        Constructs a frame
    */
    this(string name, bool hasTitlebar) {
        this.title_ = name;
        this.hasTitlebar = hasTitlebar;
        this.visible = true;
    }

    /**
        Draws the frame
    */
    final void update() {
        this.onBeginUpdate();
            if(drewWindow) this.onUpdate();
        this.onEndUpdate();
    }
}

/**
    Renders current top modal
*/
void incModalRender() {
    if (incModalIndex > -1) {
        incModalList[incModalIndex].update();
    }
}
/** 
    incModalIsOpen returns true if a modal is open
*/
bool incModalIsOpen() {
    return incModalIndex > -1;
}

/**
    Adds a modal to the modal display list.
*/
void incModalAdd(Modal modal) {
    
    // Increase modal list length if need be
    if (incModalIndex+1 >= incModalList.length) incModalList.length++;

    // Set topmost modal
    incModalList[++incModalIndex] = modal;
}

/**
    Closest the top level modal
    Can only be called from within a modal.
*/
void incModalCloseTop() {
    if (incModalIndex >= 0) {
        incModalIndex--;
    }
}