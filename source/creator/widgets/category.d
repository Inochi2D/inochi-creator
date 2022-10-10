module creator.widgets.category;
import creator.core;
import creator.widgets;
import bindbc.imgui;

private {
    struct CategoryData {
        bool open;
        bool badColor;
        bool isDark;
        ImVec4 contentBounds;
        IncCategoryFlags flags;
    }

    void incGetCategoryColors(ImVec4 color, out ImVec4 hoverColor, out ImVec4 activeColor, out ImVec4 bgColor, out ImVec4 shadowColor, ref ImVec4 textColor, ref bool isDark) {
        
        // First get HSV version of color
        float h, s, v;
        hoverColor = color;
        activeColor = color;
        shadowColor = color;
        bgColor = color;

        // Assume all colors are dark and invert them if we're in light mode
        igColorConvertRGBtoHSV(color.x, color.y, color.z, &h, &s, &v);
        isDark = v <= 0.5;
        if (!isDark) textColor = ImVec4(0, 0, 0, 1);
        else textColor = ImVec4(1, 1, 1, 1);

        // Then darken/lighten it the first time for active color
        s -= 0.075*s;
        if (v > 0.5) v -= 0.05;
        else v += 0.15;
        igColorConvertHSVtoRGB(h, s, v, &activeColor.x, &activeColor.y, &activeColor.z);

        // Then darken/lighten it the second time for hover color
        s -= 0.075*s;
        if (v > 0.5) v -= 0.05;
        else v += 0.15;
        igColorConvertHSVtoRGB(h, s, v, &hoverColor.x, &hoverColor.y, &hoverColor.z);
        
        // Then darken it for bg color
        igColorConvertRGBtoHSV(color.x, color.y, color.z, &h, &s, &v);
        s *= 0.90;
        if (v <= 0.15) v = 0.15;
        else v *= 0.80;
        igColorConvertHSVtoRGB(h, s, v, &bgColor.x, &bgColor.y, &bgColor.z);
    
        // Finally the shadow color
        igColorConvertRGBtoHSV(color.x, color.y, color.z, &h, &s, &v);
        s *= 0.85;
        v *= 0.75;
        igColorConvertHSVtoRGB(h, s, v, &shadowColor.x, &shadowColor.y, &shadowColor.z);
        shadowColor.w *= 2;
    }
}

enum IncCategoryFlags {
    None = 0,
    NoCollapse = 1
}

/**
    Begins a category using slightly darkened versions of the main UI colors
    
    Remember to call incEndCategory after!
*/
bool incBeginCategory(const(char)* title, IncCategoryFlags flags = IncCategoryFlags.None) {
    ImVec4 col = igGetStyle().Colors[ImGuiCol.WindowBg];
    col = ImVec4(col.x-0.025, col.y-0.025, col.z-0.025, col.w);
    return incBeginCategory(title, col, flags);
}

/**
    Begins a category using the defined color

    Remember to call incEndCategory after!
*/
bool incBeginCategory(const(char)* title, ImVec4 color, IncCategoryFlags flags = IncCategoryFlags.None) {
    import inmath : clamp;

    // We do not support transparency
    color.w = 1;
    color.x = clamp(color.x, 0.15, 1);
    color.y = clamp(color.y, 0.15, 1);
    color.z = clamp(color.z, 0.15, 1);
    
    // Calculate colors for category
    ImVec4 hoverColor;
    ImVec4 activeColor;
    ImVec4 shadowColor;
    ImVec4 bgColor;
    ImVec4 textColor;
    bool isDark;
    incGetCategoryColors(color, hoverColor, activeColor, bgColor, shadowColor, textColor, isDark);

    // Push ID of our category
    igPushID(title);
    auto storage = igGetStateStorage();
    auto id = igGetID("CATEGORYDATA");
    auto window = igGetCurrentWindow();    

    // The fun stuff starts
    igPushStyleColor(ImGuiCol.HeaderHovered, hoverColor);
    igPushStyleColor(ImGuiCol.HeaderActive, activeColor);
    igPushStyleColor(ImGuiCol.Text, textColor);
    CategoryData* data = cast(CategoryData*)ImGuiStorage_GetVoidPtr(storage, id);
    if (!data) {
        data = cast(CategoryData*)igMemAlloc(CategoryData.sizeof);
        data.open = false;
        data.contentBounds = ImVec4(
            0, 0, 0, 0
        );
        ImGuiStorage_SetVoidPtr(storage, id, data);
    }

    // Calculate some values for drawing our background color.
    data.flags = flags;
    data.badColor = isDark != incGetDarkMode();
    data.isDark = isDark;
    data.contentBounds.x = igGetCursorPosX();
    data.contentBounds.y = igGetCursorPosY();
    data.contentBounds.z = incAvailableSpace().x;

    ImVec2 cursor;
    igGetCursorScreenPos(&cursor);

    // Draw background color
    ImDrawList_AddRectFilled(
        igGetWindowDrawList(),
        ImVec2(cursor.x, cursor.y),
        ImVec2(cursor.x+data.contentBounds.z, cursor.y+data.contentBounds.w+1),
        igGetColorU32(bgColor)
    );
    
    // Draw "shadow" underneath
    ImDrawList_AddRectFilled(
        igGetWindowDrawList(),
        ImVec2(cursor.x, cursor.y+data.contentBounds.w-1),
        ImVec2(cursor.x+data.contentBounds.z, cursor.y+data.contentBounds.w+1),
        igGetColorU32(shadowColor)
    );

    // Our fancy tree node which will be used to open/close the category.
    incDummy(ImVec2(0, 2));

    float paddingX = igGetStyle().WindowPadding.x/2;
    window.ContentRegionRect.Min.x -= paddingX;
    window.WorkRect.Min.x -= paddingX;
    igSetCursorPosX(igGetCursorPosX()+paddingX);

    if ((data.flags & IncCategoryFlags.NoCollapse) == IncCategoryFlags.NoCollapse) {
        data.open = true;
        igIndent();
            igText(title);
        igUnindent();
    } else data.open = igTreeNodeEx(title, ImGuiTreeNodeFlags.DefaultOpen | ImGuiTreeNodeFlags.NoTreePushOnOpen | ImGuiTreeNodeFlags.SpanAvailWidth);

    window.ContentRegionRect.Min.x += paddingX;
    window.WorkRect.Min.x += paddingX;

    if (data.open) {
        ImVec2 newCursor;
        igGetCursorScreenPos(&newCursor);

        float diffY = newCursor.y-cursor.y;

        // Draw lighter fill color for contents when open
        ImDrawList_AddRectFilled(
            igGetWindowDrawList(),
            ImVec2(newCursor.x+2, newCursor.y),
            ImVec2(newCursor.x+data.contentBounds.z-2, newCursor.y+data.contentBounds.w-(diffY+1)),
            igGetColorU32(color)
        );
    }
    
    // NOTE: We use these instead of incDummy since otherwise you can't drag
    // the tree node via drag/drop.
    igSetCursorPosY(igGetCursorPosY()+2);

    if (data.open) {
        igSetCursorPosY(igGetCursorPosY()+2);
        igIndent();
    }


    igPopStyleColor(3);

    // We force our childrens' content to fit better within ourselves
    // This gets undone after incEndCategory is called.
    float indentSpacing = igGetStyle().IndentSpacing;
    window.ContentRegionRect.Min.x -= indentSpacing;
    window.WorkRect.Min.x -= indentSpacing;

    if (data.badColor && data.isDark) incPushDarkColorScheme();
    else if (data.badColor && !data.isDark) incPushLightColorScheme();
    

    return data.open;
}

/**
    Ends a category
*/
void incEndCategory() {
    auto window = igGetCurrentWindow();

    // Undo our fancy content fit math.
    // This needs to be here otherwise the usable size of the child
    // window will continue to shrink
    window.ContentRegionRect.Min.x += igGetStyle().IndentSpacing;
    window.WorkRect.Min.x += igGetStyle().IndentSpacing;

    auto storage = igGetStateStorage();
    auto id = igGetID("CATEGORYDATA");
    if (CategoryData* data = cast(CategoryData*)ImGuiStorage_GetVoidPtr(storage, id)) {
        if (data.badColor) incPopColorScheme();
        if (data.open) {
            igUnindent();
            incDummy(ImVec2(0, 2));
        }

        data.contentBounds.w = igGetCursorPosY()-data.contentBounds.y;

        igSpacing();
        igSpacing();
    }

    igPopID();
}