module creator.core.texture;
import inochi2d.math;
import inochi2d.core;

/**
    Inochi Creator texture
*/
struct IncTexture {
public:
    /**
        Size of the texture
    */
    vec2 size;

    /**
        The texture data of the texture
    */
    ShallowTexture textureData;
}
