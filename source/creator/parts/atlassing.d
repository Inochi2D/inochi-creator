module creator.parts.atlassing;
import inochi2d;

/**
    A packed part in the atlasser
*/
struct PackedPart {
    /**
        UVs of the part
    */
    vec2[] uvs;

    /**
        Reference to texture
    */
    Texture textureRef;
}

/**
    A texture atlasser
*/
class TextureAtlasser {
private:
    Texture[] textures;
    PackedPart[] packedParts;

public:
}