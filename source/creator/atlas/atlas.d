/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.atlas.atlas;
import inochi2d;
import creator.atlas;
import creator.atlas.packer;

/**
    A texture atlas
*/
struct Atlas {
public:
    /**
        The underlying texture
    */
    Texture texture;

    /**
        Parts in the atlas
    */
    AtlasPart[] parts;

    /**
        MaxRects texture packer
    */
    TexturePacker packer;

    /**
        Repacks the atlas
    */
    void repack() {
        packer.clear();

        foreach(part; parts) {
            packer.packTexture(part.texture.size);
        }
    }
}