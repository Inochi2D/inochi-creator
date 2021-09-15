/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.atlas.atlas;
import inochi2d;
import creator.atlas;
import creator.atlas.part;
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
        MaxRects texture packer
    */
    TexturePacker packer;

    /**
        Clears the texture packer
    */
    void clear() {
        packer.clear();
    }
}