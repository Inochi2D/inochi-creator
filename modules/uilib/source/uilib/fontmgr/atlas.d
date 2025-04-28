/**
    Font Atlas

    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module uilib.fontmgr.atlas;
import hairetsu.glyph;
import i2d.imgui;

/**
    Font atlas wrapping an imgui font atlas.

    Multiple font atlasses may exist and the atlas manager
    will swap them out as need be.
*/
class FontAtlas {
private:
    ImFontAtlas* atlas;

public:

    /**
        Gets the underlying font atlas handle.
    */
    @property ImFontAtlas* handle() { return atlas; }


    /**
        Adds the given hairetsu glyph into the atlas (if possible).
    */
    void addGlyph(ref HaGlyph glyph) {
        
    }
}

