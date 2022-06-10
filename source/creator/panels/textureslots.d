/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.textureslots;
import creator.panels;
import creator.windows;
import creator : incActivePuppet;
import bindbc.imgui;
import inochi2d;
import std.conv;
import i18n;

/**
    The textures frame
*/
class TextureSlotsPanel : Panel {
private:

    void namedIcon(string name, Texture texture, ImVec2 size) {
        if (igBeginChild(("tex_"~name~"\0").ptr, size)) {
            igPushID(name.ptr, name.ptr+name.length);
                if (igSelectable("###TEXTURE", false, ImGuiSelectableFlags.None, size)) {
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
            igPopID();
            igEndChild();
        }
    }

protected:
    override
    void onUpdate() {
        if (igBeginChild("TexturesList", ImVec2(0, 0), false, ImGuiWindowFlags.HorizontalScrollbar)) {
            ImVec2 avail;
            igGetContentRegionAvail(&avail);

            foreach(i, texture; incActivePuppet().textureSlots) {
                namedIcon(i.text, texture, ImVec2(avail.y, avail.y));
                igSameLine(0, 4);
            }

            igEndChild();
        }
    }

public:
    this() {
        super("Texture Slots", _("Texture Slots"), false);
    }
}

/**
    Generate logger frame
*/
mixin incPanel!TextureSlotsPanel;


