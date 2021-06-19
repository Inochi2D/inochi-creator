module creator.frames.textureslots;
import creator.frames;
import creator.windows;
import creator : incActivePuppet;
import bindbc.imgui;
import inochi2d;
import std.conv;

/**
    The textures frame
*/
class TextureSlotsFrame : Frame {
private:

    void namedIcon(string name, Texture texture, ImVec2 size) {
        igBeginChild_Str(("tex_"~name~"\0").ptr, size, false);
            if (igSelectable_Bool("", false, ImGuiSelectableFlags.None, size)) {
                incPushWindowList(new TextureViewerWindow(texture));
            }
            igSameLine(0.1, 0);
            igBeginGroup();
                igImage(
                    cast(void*)texture.getTextureId(), 
                    ImVec2(size.x, size.y-18),
                    ImVec2(0, 0),
                    ImVec2(1, 1),
                    ImVec4(1, 1, 1, 1),
                    ImVec4(0, 0, 0, 0)
                );

                ImVec2 winSize;
                igGetWindowSize(&winSize);

                float fSize = (igGetFontSize() * name.length) / 2;
                float fSizeF = (winSize.x/2)+fSize;
                igIndent(fSizeF);
                    igText((name~"\0").ptr);
                igUnindent(fSizeF);
            igEndGroup();
        igEndChild();
    }

protected:
    override
    void onUpdate() {
        igBeginChild_Str("TexturesList", ImVec2(0, 0), false, ImGuiWindowFlags.HorizontalScrollbar);
            ImVec2 avail;
            igGetContentRegionAvail(&avail);

            foreach(i, texture; incActivePuppet().textureSlots) {
                namedIcon(i.text, texture, ImVec2(avail.y, avail.y));
                igSameLine(0, 4);
            }
        igEndChild();
    }

public:
    this() {
        super("Texture Slots", false);
    }
}

/**
    Generate logger frame
*/
mixin incFrame!TextureSlotsFrame;


