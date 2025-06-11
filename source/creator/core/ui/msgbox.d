module creator.core.ui.msgbox;
import sdl.messagebox;

enum MessageType : SDL_MessageBoxFlags {
    info = SDL_MessageBoxFlags.SDL_MESSAGEBOX_INFORMATION,
    warning = SDL_MessageBoxFlags.SDL_MESSAGEBOX_WARNING,
    error = SDL_MessageBoxFlags.SDL_MESSAGEBOX_ERROR,
}

/**
    Interface for messages boxes.
*/
class MessageBox {

    /**
        Shows an informational message box without requiring Inochi Creator
        to be fully initialized.
    */
    static bool show(MessageType type, string msgtitle, string msgbody) {
        nstring _title = msgtitle;
        nstring _body = msgbody;
        return SDL_ShowSimpleMessageBox(type, _title.ptr, _body.ptr);
    }
}