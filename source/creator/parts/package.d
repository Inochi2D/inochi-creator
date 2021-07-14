module creator.parts;
import inochi2d;

/**
    
*/
struct AtlasPart {

    /**
        The Inochi2D part this atlas part is connected to 
    */
    Part part;

    /**
        The texture data of this part
    */
    ShallowTexture texture;

    /**
        This part's mesh
    */
    MeshData mesh;

    /**
        Applies the UVs to the part in question
    */
    void apply() {
        part.rebuffer(mesh);
    }
}