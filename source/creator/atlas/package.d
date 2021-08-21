/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.atlas;
import inochi2d;
import std.format;
import std.exception;

public import creator.atlas.part;
public import creator.atlas.atlas;
import creator.atlas.packer;

/**
    Atlas manager system
*/
AtlasManagerSystem AtlasManager;

/**
    The atlas manager
*/
class AtlasManagerSystem {
private:
    // Atlas parts
    AtlasPart[uint] loadedParts;
    Atlas[] atlasses;
    uint selectedPart;

    Atlas* findAtlasForTexture(Texture toFind) {
        
        foreach(i, atlas; atlasses) {
            if (atlas.texture == toFind) return &atlasses[i];
        }

        return null;
    }

public:

    /**
        Returns the current active part
    */
    AtlasPart* getActivePart() {
        return selectedPart in loadedParts;
    }

    /**
        Loads an existing puppet in to the texture atlasser
    */
    void loadFromPuppet(Puppet puppet) {
        
        // First off we need to take all the textures in the texture slots and turn them in to atlas parts
        foreach(Texture tex; puppet.textureSlots) {
            atlasses ~= Atlas(tex, new TexturePacker());
        }

        Part[] parts = puppet.getAllParts();
        foreach(inpart; parts) {
            AtlasPart part;
            part.texture = inpart.textures[0];
            part.mesh = inpart.getMesh();
            part.packedIn = findAtlasForTexture(part.texture);

            // Finally, add it to the atlasser
            loadedParts[inpart.uuid] = part;
        }
    }

    /**
        Clears the atlas manager of items
    */
    void clear() {
        loadedParts.clear();
        selectedPart = 0;
    }
}

static this() {
    AtlasManager = new AtlasManagerSystem();
}