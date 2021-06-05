module creator.core.font;
import creator.core;
import bindbc.imgui;
import bindbc.imgui.ogl;
import core.stdc.stdlib : malloc;
import core.stdc.string : memcpy;
import std.string;

private {
    bool fontChangeRequested;
    bool fontClearRequested;
    QFont[] requestedAdditions;
    ImFont*[] loadedFonts;

    struct QFont {
        string name;
        ubyte[] data;
        uint size;
        ImWchar* range;
        bool merge;
    }

    ImFont* loadFont(ImFontAtlas* atlas, string name, ubyte[] data, uint size = 14, ImWchar* range = null, bool merge = false) {

        ubyte* c_data = cast(ubyte*)igMemAlloc(data.length);
        memcpy(c_data, data.dup.ptr, data.length);

        if (range is null) {
            range = ImFontAtlas_GetGlyphRangesJapanese(atlas);
        }
        ImFontConfig* cfg = ImFontConfig_ImFontConfig();
        cfg.MergeMode = merge;

        // Add name
        const char* c_name = cast(char*)igMemAlloc(name.length);
        memcpy(cast(void*)c_name, name.ptr, name.length);
        cfg.Name[0..name.length] = c_name[0..name.length];

        // Load Font
        ImFont* font = ImFontAtlas_AddFontFromMemoryTTF(atlas, c_data, size, size, cfg, range);

        return font;
    }
}

/**
    Clear fonts
*/
void incFontsClear() {
    fontClearRequested = true;
    loadedFonts.length = 0;
}

/**
    Load font
*/
void incFontsLoad(string name, ubyte[] data, uint size = 14, ImWchar* range = null, bool merge = false) {
    fontChangeRequested = true;
    requestedAdditions ~= QFont(name, data, size, range, merge);
}


/**
    Process change in fonts
*/
void incFontsProcessChanges() {
    auto io = igGetIO();
    if (fontClearRequested) {
        incRecreateContext();
        io = igGetIO();
    }

    if (fontChangeRequested) {
        foreach(addition; requestedAdditions) {
            loadedFonts ~= loadFont(io.Fonts, addition.name, addition.data, addition.size, addition.range, addition.merge);
        }
        ImFontAtlas_Build(io.Fonts);
    }

    requestedAdditions.length = 0;
    fontClearRequested = false;
    fontChangeRequested = false;
}

/**
    Gets font from id
*/
ImFont* incFontsGet(size_t id) {
    return loadedFonts[id];
}