/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.core.font;
import creator.core;
import bindbc.imgui;
import core.stdc.stdlib : malloc;
import core.stdc.string : memcpy;
import std.string;
import std.array;

private {


    // ImFont* loadFont(ImFontAtlas* atlas, string name, ubyte[] data, uint size = 14, ImWchar* range = null, bool merge = false) {

    //     ubyte* c_data = cast(ubyte*)igMemAlloc(data.length);
    //     memcpy(c_data, data.ptr, data.length);

    //     if (range is null) {
    //         range = ImFontAtlas_GetGlyphRangesJapanese(atlas);
    //     }
    //     ImFontConfig* cfg = ImFontConfig_ImFontConfig();
    //     cfg.MergeMode = merge;

    //     // Add name
    //     const char* c_name = cast(char*)igMemAlloc(name.length);
    //     memcpy(cast(void*)c_name, name.ptr, name.length);
    //     cfg.Name[0..name.length] = c_name[0..name.length];

    //     // Load Font
    //     ImFont* font = ImFontAtlas_AddFontDefault(atlas, cfg); //ImFontAtlas_AddFontFromMemoryTTF(atlas, c_data, size, size, cfg, range);

    //     return font;
    // }
}

private {
    ImFontAtlas* atlas;

    FontEntry[] families;
    void _incInitFontList() {
        string fontsPath = incGetAppFontsPath();
        // TODO: load fonts
    }

    void _incAddFontData(string name, ref ubyte[] data, float size = 14, const ImWchar* ranges = null, ImVec2 offset = ImVec2(0f, 0f)) {
        auto cfg = ImFontConfig_ImFontConfig();
        cfg.FontDataOwnedByAtlas = false;
        cfg.MergeMode = atlas.Fonts.empty() ? false : true;
        cfg.GlyphOffset = offset;

        char[40] nameDat;
        nameDat[0..name.length] = name[0..name.length];
        cfg.Name = nameDat;
        ImFontAtlas_AddFontFromMemoryTTF(atlas, cast(void*)data.ptr, cast(int)data.length, size, cfg, ranges);
    }

    ubyte[] KOSUGI_MARU = cast(ubyte[])import("KosugiMaru-Regular.ttf");
    ubyte[] ICONS = cast(ubyte[])import("MaterialIcons.ttf");
}

/**
    A font entry in the fonts list
*/
struct FontEntry {
    /**
        Family name of the font
    */
    string name;
    
    /**
        Main language of the font
    */
    string lang;

    /**
        The file of the font
    */
    string file;
}

/**
    Initializes fonts
*/
void incInitFonts() {
    _incInitFontList();
    atlas = igGetIO().Fonts;
        _incAddFontData("APP\0", KOSUGI_MARU, 28, ImFontAtlas_GetGlyphRangesJapanese(atlas));
        _incAddFontData("Icons\0", ICONS, 32, [cast(ImWchar)0xE000, cast(ImWchar)0xF23B].ptr, ImVec2(0, 4));
    ImFontAtlas_Build(atlas);
    incSetUIScale(incGetUIScale());
}

/**
    Sets the UI scale for fonts
*/
void incSetUIScale(float scale) {
    incSettingsSet("UIScale", scale);
    igGetIO().FontGlobalScale = incGetUIScaleFont();
}

/**
    Get the UI scale in terms of font size
*/
float incGetUIScaleFont() {
    return incGetUIScale()/2;
}

/**
    Returns the UI Scale
*/
float incGetUIScale() {
    return incSettingsGet!float("UIScale", 1.0);
}

/**
    Gets the UI scale in text form
*/
string incGetUIScaleText() {
    import std.format : format;
    return "%s%%".format(cast(int)(incGetUIScale()*100));
}

/**
    Begins a section where text is double size
*/
void incFontsBeginLarge() {
    igGetIO().FontGlobalScale = incGetUIScaleFont()*2;
}

/**
    Ends a section where text is double size
*/
void incFontsEndLarge() {
    igGetIO().FontGlobalScale = incGetUIScaleFont();
}

/**
    Returns a list of fonts
*/
FontEntry[] incFontsGet() {
    return families;
}

// void incFontSet(string file) {

// }