/*
    Copyright © 2020-2023, Inochi2D Project
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
    ImFontAtlas* atlas;

    version (NoUIScaling) { } else { float uiScale; }

    FontEntry[] families;
    void _incInitFontList() {
        string fontsPath = incGetAppFontsPath();
        // TODO: load fonts
    }

    void _incAddFontData(string name, ref ubyte[] data, float size = 14, const ImWchar* ranges = null, ImVec2 offset = ImVec2(0f, 0f)) {
        auto cfg = ImFontConfig_ImFontConfig();
        cfg.FontBuilderFlags = 1 << 9;
        cfg.FontDataOwnedByAtlas = false;
        cfg.MergeMode = atlas.Fonts.empty() ? false : true;
        cfg.GlyphOffset = offset;
        cfg.OversampleH = 3;
        cfg.OversampleV = 2;

        char[40] nameDat;
        nameDat[0..name.length] = name[0..name.length];
        cfg.Name = nameDat;
        ImFontAtlas_AddFontFromMemoryTTF(atlas, cast(void*)data.ptr, cast(int)data.length, size, cfg, ranges);
    }

    ubyte[] OPEN_DYSLEXIC = cast(ubyte[])import("OpenDyslexic.otf");
    ubyte[] NOTO = cast(ubyte[])import("NotoSans-Regular.ttf");
    ubyte[] NOTO_CJK = cast(ubyte[])import("NotoSansCJK-Regular.ttc");
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
        if (incSettingsGet!bool("useOpenDyslexic")) {

            // Use OpenDyslexic for Latin
            _incAddFontData("APP\0", OPEN_DYSLEXIC, 24, (cast(ImWchar[])[
                0x0020, 0x024F, // Basic Latin + Latin Supplement & Extended
                0]).ptr,
                ImVec2(0, -8)
            );

            // Everything else will have to be NOTO
            _incAddFontData("APP\0", NOTO, 26, (cast(ImWchar[])[
                0x0250, 0x036F, // IPA Extensions + Spacings + Diacritical Marks
                0x0370, 0x03FF, // Greek and Coptic
                0x0400, 0x052F, // Cyrillic + Supplementary
                0x2000, 0x206F, // General Punctuation
                0xFFFD, 0xFFFD, // Invalid
                0]).ptr,
                ImVec2(0, -6)
            );
        } else {
            _incAddFontData("APP\0", NOTO, 26, (cast(ImWchar[])[
                0x0020, 0x024F, // Basic Latin + Latin Supplement & Extended
                0x0250, 0x036F, // IPA Extensions + Spacings + Diacritical Marks
                0x0370, 0x03FF, // Greek and Coptic
                0x0400, 0x052F, // Cyrillic + Supplementary
                0x2000, 0x206F, // General Punctuation
                0xFFFD, 0xFFFD, // Invalid
                0]).ptr,
                ImVec2(0, -6)
            );
        }

        _incAddFontData("APP\0", NOTO_CJK, 26, (cast(ImWchar[])[
            0x3000, 0x30FF, // CJK Symbols and Punctuations, Hiragana, Katakana
            0x31F0, 0x31FF, // Katakana Phonetic Extensions
            0xFF00, 0xFFEF, // Half-width characters
            0x4E00, 0x9FAF, // CJK Ideograms
            0]).ptr,
            ImVec2(0, -6)
        );

        _incAddFontData(
            "Icons", 
            ICONS, 
            32, 
            [
                cast(ImWchar)0xE000, 
                cast(ImWchar)0xF23B
            ].ptr, 
            ImVec2(0, 2)
        );
    ImFontAtlas_Build(atlas);

    // Half size because the extra size is for scaling
    igGetIO().FontGlobalScale = 0.5;
}

/**
    Returns a list of fonts
*/
FontEntry[] incFontsGet() {
    return families;
}