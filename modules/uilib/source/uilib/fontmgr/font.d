module uilib.fontmgr.font;
import hairetsu.font.font;
import i2d.imgui;

/**
    An object which wraps together an ImFont and a Hairetsu font.
*/
class UIFont {
private:
    HaFont haFont;
    ImFontConfig* imFont;

public:

    /**
        Creates a font from a hairetsu font.
    */
    this(HaFont font) {
        this.haFont = font;
        this.imFont = ImFontConfig_ImFontConfig();

        this.imFont.FontDataOwnedByAtlas = false;
        this.imFont.PixelSnapH = true;
    }
}