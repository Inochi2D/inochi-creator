/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.atlas.part;
import creator.atlas.atlas;
import inochi2d;

/**
    A part in the texture atlas
*/
struct AtlasPart {

    /**
        The atlas this part is packed in

        null if the part hasn't been packed yet.
    */
    Atlas* packedIn;

    /**
        The Inochi2D part this atlas part is attached to 
    */
    Part part;

    /**
        The texture of the part
    */
    Texture texture;

    /**
        This part's mesh
    */
    MeshData mesh;

    /**
        UUID of atlas part
    */
    uint uuid() { return part.uuid; }

    /**
        Returns the size of the part in pixels
    */
    vec2i size() {
        return texture.size();
    }

    /**
        Applies the UVs to the part in question
    */
    void apply() {
        part.rebuffer(mesh);
    }

    /**
        Draws the part
    */
    void draw() {
        inDrawTextureAtPart(texture, part);
    }
}