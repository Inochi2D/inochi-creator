module creator.core.font;
import bindbc.imgui;
import bindbc.imgui.ogl;
import core.stdc.stdlib : malloc;
import core.stdc.string : memcpy;

void loadFont(string name, ubyte[] data, uint size = 14, ImWchar* range = null, bool merge = false) {

    ubyte* cdata = cast(ubyte*)malloc(data.length);
    memcpy(cdata, data.dup.ptr, data.length);

    auto io = igGetIO();
    if (range is null) {
        range = ImFontAtlas_GetGlyphRangesJapanese(io.Fonts);
    }
    ImFontConfig* cfg = ImFontConfig_ImFontConfig();
    cfg.MergeMode = merge;
    cfg.Name[0..name.length] = name[0..name.length];

    ImFontAtlas_AddFontFromMemoryTTF(io.Fonts, cdata, size, size, cfg, range);
    ImFontAtlas_Build(io.Fonts);
}