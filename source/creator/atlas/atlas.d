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


// /**
//     Clears the internal atlas of parts
// */
// void incAtlasClear() {
//     parts.length = 0;
//     atlasses.length = 0;
// }

// /**
//     Load atlas from a puppet
// */
// void incAtlasLoad(Puppet puppet) {
//     incAtlasClear();
//     foreach(texture; puppet.textureSlots) {
//         atlasses ~= texture;
//     }
// }

// /**
//     Adds part to atlas
// */
// void incAtlasAddPart(ShallowTexture texture, Node parent = null) {
//     AtlasPart* apart = new AtlasPart;
//     apart.uuid = inCreateUUID();
//     apart.textureData = texture;
//     apart.texture = new Texture(texture);
//     apart.part = new Part(apart.mesh, [], apart.uuid, parent);

//     parts ~= apart;
// }

// /**
//     Remove part from atlas

//     TODO: This needs to be plugged in to the action stack system
//           so for now this won't be used.
//           This does mean that Inochi Creator essentially leaks
//           memory.
// */
// void incAtlasRemovePart(uint partUUID) {
//     import std.algorithm.mutation : remove;

//     ptrdiff_t idx = incAtlasFindPartIndex(partUUID);
//     enforce(idx >= 0, "Could not find part with uuid %s".format(partUUID));

//     parts = parts.remove(idx);
// }

// /**
//     Find the index of a part in the internal list
// */
// ptrdiff_t incAtlasFindPartIndex(uint partUUID) {
//     foreach(i, part; parts) if (part.uuid == partUUID) return i;
//     return -1;
// }

// /**
//     Gets an atlas part from a in-node part
// */
// AtlasPart* incGetAtlasPartFromPart(Part part) {
//     foreach(ipart; parts) {
//         if (part.uuid == ipart.uuid) return ipart; 
//     }
//     throw new Exception("Could not find part with uuid %s".format(part.uuid));
// }