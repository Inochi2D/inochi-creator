/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.texviewer;
import creator.windows;
import creator.core;
import std.string;
import creator.utils.link;
import inochi2d;

class TextureViewerWindow : Window {
private:
    Texture texture;
    float zoom = 1;

protected:

    override
    void onBeginUpdate(int id) {
        igSetNextWindowSize(ImVec2(512, 512), ImGuiCond.FirstUseEver);
        super.onBeginUpdate(id);
    }

    override
    void onUpdate() {
        igSliderFloat("Zoom", &zoom, 0.1, 10, "%.2f");
        igBeginChild("TextureViewerArea", ImVec2(0, 0), false, ImGuiWindowFlags.HorizontalScrollbar);
            igImage(
                cast(void*)texture.getTextureId(), 
                ImVec2(texture.width*zoom, texture.height*zoom), 
                ImVec2(0, 0), 
                ImVec2(1, 1), 
                ImVec4(1, 1, 1, 1), 
                ImVec4(0, 0, 0, 0)
            );
        igEndChild();
    }

public:
    this(Texture texture) {
        this.texture = texture;
        super("Texture Viewer");
    }
}