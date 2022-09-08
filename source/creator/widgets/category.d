module creator.widgets.category;
import creator.core;
import creator.widgets;
import bindbc.imgui;

struct CategoryData {
    bool open;
    ImVec4 contentBounds;
    ImVec4 color;
}

/**
    Begins a category using slightly darkened versions of the main UI colors
    
    Remember to call incEndCategory after!
*/
bool incBeginCategory(const(char)* title) {
    ImVec4 col = igGetStyle().Colors[ImGuiCol.WindowBg];
    if (incGetDarkMode()) col = ImVec4(col.x-0.025, col.y-0.025, col.z-0.025, col.w);
    else col = ImVec4(col.x-0.025, col.y-0.025, col.z-0.025, col.w);
    return incBeginCategory(title, col);
}

/**
    Begins a category using the defined color

    Remember to call incEndCategory after!
*/
bool incBeginCategory(const(char)* title, ImVec4 color) {
    igPushID(title);
    auto storage = igGetStateStorage();
    auto id = igGetID("CATEGORYDATA");
    
    CategoryData* data = cast(CategoryData*)ImGuiStorage_GetVoidPtr(storage, id);
    if (!data) {
        data = cast(CategoryData*)igMemAlloc(CategoryData.sizeof);
        data.open = false;
        data.contentBounds = ImVec4(
            0, 0, 0, 0
        );
        ImGuiStorage_SetVoidPtr(storage, id, data);
    }
    
    data.color = color;
    data.contentBounds.x = igGetCursorPosX();
    data.contentBounds.y = igGetCursorPosY();
    data.contentBounds.z = incAvailableSpace().x;

    ImVec2 padding = igGetStyle().FramePadding;

    ImVec2 cursor;
    igGetCursorScreenPos(&cursor);
    ImDrawList_AddRectFilled(
        igGetWindowDrawList(),
        ImVec2(cursor.x-padding.x, cursor.y),
        ImVec2(cursor.x+data.contentBounds.z+padding.x, cursor.y+data.contentBounds.w+1),
        igGetColorU32(color)
    );

    incDummy(ImVec2(0, 2));
    data.open = igTreeNodeEx(title, ImGuiTreeNodeFlags.DefaultOpen | ImGuiTreeNodeFlags.NoTreePushOnOpen | ImGuiTreeNodeFlags.SpanFullWidth);
    if (data.open) {
        igSetCursorPosY(igGetCursorPosY()+2);
        igIndent();
    }

    return data.open;
}

/**
    Ends a category
*/
void incEndCategory() {
    auto storage = igGetStateStorage();
    auto id = igGetID("CATEGORYDATA");
    if (CategoryData* data = cast(CategoryData*)ImGuiStorage_GetVoidPtr(storage, id)) {
        if (data.open) {
            igUnindent();
            incDummy(ImVec2(0, 2));
        }

        data.contentBounds.w = igGetCursorPosY()-data.contentBounds.y;
        igPushStyleColor(ImGuiCol.Separator, ImVec4(0, 0, 0, 0.2));
            igSeparator();
        igPopStyleColor();
    }

    igPopID();
}