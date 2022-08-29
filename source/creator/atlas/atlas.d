/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.atlas.atlas;
import inochi2d;
import creator.atlas;
import creator.atlas.packer;
import bindbc.opengl;

private {
    GLuint writeFBO;
    GLuint writeVAO;
    GLuint writeVBO;

    GLint atlasMVP;
    Shader atlasShader;
    Texture currCanvas;

    void setCanvas(ref Texture canvas) {
        glBindVertexArray(writeVAO);
        currCanvas = canvas;

        glBindFramebuffer(GL_FRAMEBUFFER, writeFBO);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, canvas.getTextureId(), 0);
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }

    void renderToTexture(ref Texture toWrite, rect where, rect uvs) {
        glBindVertexArray(writeVAO);
        glBindFramebuffer(GL_FRAMEBUFFER, writeFBO);

        glViewport(0, 0, currCanvas.width, currCanvas.height);
        glDisable(GL_CULL_FACE);
        glDisable(GL_DEPTH_TEST);
        glEnable(GL_BLEND);

            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

            vec2[] bufData = [
                vec2(where.left,    where.top),
                vec2(uvs.left,      uvs.top),
                vec2(where.left,    where.bottom),
                vec2(uvs.left,      uvs.bottom),
                vec2(where.right,   where.top),
                vec2(uvs.right,     uvs.top),
                
                vec2(where.right,   where.top),
                vec2(uvs.right,     uvs.top),
                vec2(where.left,    where.bottom),
                vec2(uvs.left,      uvs.bottom),
                vec2(where.right,   where.bottom),
                vec2(uvs.right,     uvs.bottom),
            ];
            glBindBuffer(GL_ARRAY_BUFFER, writeVBO);
            glBufferData(GL_ARRAY_BUFFER, bufData.length*vec2.sizeof, bufData.ptr, GL_DYNAMIC_DRAW);

            glEnableVertexAttribArray(0);
            glEnableVertexAttribArray(1);
            glVertexAttribPointer(0, 2, GL_FLOAT, false, vec2.sizeof*2, null);
            glVertexAttribPointer(1, 2, GL_FLOAT, false, vec2.sizeof*2, cast(void*)vec2.sizeof);

            atlasShader.use();
            atlasShader.setUniform(atlasMVP, mat4.orthographic(
                0, currCanvas.width, currCanvas.height, 0, 0, 2
            ) * mat4.scaling(1, -1, 1) * mat4.translation(0, -currCanvas.height, -1));
            toWrite.bind();

            glDrawArrays(GL_TRIANGLES, 0, 6);

            glDisableVertexAttribArray(0);
            glDisableVertexAttribArray(1);
        glEnable(GL_CULL_FACE);
        glEnable(GL_DEPTH_TEST);
        glDisable(GL_BLEND);

        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }
}

void incInitAtlassing() {
    glGenFramebuffers(1, &writeFBO);
    glGenVertexArrays(1, &writeVAO);
    glGenBuffers(1, &writeVBO);

    atlasShader = new Shader(import("shaders/atlassing.vert"), import("shaders/atlassing.frag"));
    atlasMVP = atlasShader.getUniformLocation("mvp");
}

/**
    A texture atlas
*/
class Atlas {
public:
    /**
        The scale of every element
    */
    float scale = 1;

    /**
        How much padding in pixels to apply
    */
    int padding = 4;

    /**
        The underlying textures
    */
    Texture[TextureUsage.COUNT] textures;

    /**
        MaxRects texture packer
    */
    TexturePacker packer;

    /**
        Mappings from part UUID to an area on the atlas
    */
    rect[uint] mappings;

    /**
        Constructs a new atlas with the specified size
    */
    this(size_t atlasSize, int padding, float scale) {
        this.padding = padding;
        this.scale = scale;
        this.resize(atlasSize);
    }

    /**
        Packs a part in to a atlas, returns whether this was successful
        atlasArea contains the area in the atlas that the texture was packed in to.

        UVs should be stretched to cover this area.
    */
    bool pack(Part p) {
        auto mesh = p.getMesh();

        // Calculate how much of the texture is actually used in UV coordinates
        vec4 uvArea = vec4(1, 1, 0, 0);
        foreach(vec2 uv; mesh.uvs) {
            if (uv.x < uvArea.x) uvArea.x = uv.x;
            if (uv.y < uvArea.y) uvArea.y = uv.y;
            if (uv.x > uvArea.z) uvArea.z = uv.x;
            if (uv.y > uvArea.w) uvArea.w = uv.y;
        }

        rect uvRect = rect(uvArea.x, uvArea.y, uvArea.z-uvArea.x, uvArea.w-uvArea.y);
        if (uvRect.x < 0 || uvRect.y < 0) {
            float shiftX = uvRect.x < 0 ? abs(uvRect.x) : 0;
            float shiftY = uvRect.y < 0 ? abs(uvRect.y) : 0;
            uvRect.width += shiftX;
            uvRect.height += shiftY;
        }

        vec2i size = vec2i(
            cast(int)((p.textures[0].width*uvRect.width)*scale)+(padding*2), 
            cast(int)((p.textures[0].height*uvRect.height)*scale)+(padding*2)
        );

        // Get a slot for the texture in the atlas
        vec4 atlasArea = packer.packTexture(size);

        // Could not fit texture, return false
        if (atlasArea == vec4i(0, 0, 0, 0)) return false;

        // Render textures in to our atlas
        foreach(i, ref Texture texture; p.textures) {
            if (texture) {
                setCanvas(textures[i]);

                rect where = rect(atlasArea.x+padding, atlasArea.y+padding, atlasArea.z-(padding*2), atlasArea.w-(padding*2));
                mappings[p.uuid] = where;
                renderToTexture(texture, where, uvRect);
            }
        }
        return true;
    }

    /**
        Resizes the atlas
    */
    void resize(size_t atlasSize) {
        packer = new TexturePacker(vec2i(cast(int)atlasSize, cast(int)atlasSize));
        foreach(i; 0..textures.length) {
            if (textures[i]) textures[i].dispose();

            int channels = i == TextureUsage.Albedo ? 4 : 3;
            textures[i] = new Texture(cast(int)atlasSize, cast(int)atlasSize, channels);
        }
    }

    /**
        Finalize the atlas
    */
    void finalize() {
        foreach(texture; textures) {
            texture.genMipmap();
        }
    }

    /**
        Clears the texture packer
    */
    void clear() {
        mappings.clear();
        packer.clear();
    }
}