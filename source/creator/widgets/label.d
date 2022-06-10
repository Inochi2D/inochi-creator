module creator.widgets.label;
import bindbc.imgui;

/**
    Render text
*/
void incText(string text) {
    igTextUnformatted(text.ptr, text.ptr+text.length);
}

/**
    Render text colored
*/
void incTextColored(ImVec4 color, string text) {
    igPushStyleColor(ImGuiCol.Text, color);
        igTextUnformatted(text.ptr, text.ptr+text.length);
    igPopStyleColor();
}

/**
    Render disabled text
*/
void incTextDisabled(string text) {
    igPushStyleColor(ImGuiCol.Text, igGetStyle().Colors[ImGuiCol.TextDisabled]);
        igTextUnformatted(text.ptr, text.ptr+text.length);
    igPopStyleColor();
}

/**
    Render wrapped
*/
void incTextWrapped(string text) {
    igPushTextWrapPos(0f);
        igTextUnformatted(text.ptr, text.ptr+text.length);
    igPopTextWrapPos();
}