module creator.io.inpexport;
import creator.atlas;
import creator.ext;
import inochi2d;

private {
    vec2 mapUVCoord(vec2 value, vec2 min, vec2 max) {
        vec2 range = max - min;
        vec2 tmp = (value - min);
        vec2 off = vec2(tmp.x / range.x, tmp.y / range.y);

        vec2 clamped = vec2(
            clamp(off.x, 0, 1),
            clamp(off.y, 0, 1),
        );
        return clamped;
    }
}

void incExportINP(Puppet origin, Atlas[] atlasses, string file) {
    Puppet editable = inLoadINPPuppet(inWriteINPPuppetMemory(origin));
    
    // Apply all atlasses
    foreach(Part part; editable.getAllParts()) {
        foreach(Atlas atlas; atlasses) {
            
            // Look for our part in the atlas
            if (part.uuid in atlas.mappings) {

                // This will remap the UV coordinates of the part
                // To 0..1 range if need be.
                vec2[] uvs = part.getMesh().uvs.dup;
                vec4 uvArea = vec4(1, 1, 0, 0);
                foreach(vec2 uv; uvs) {
                    if (uv.x < uvArea.x) uvArea.x = uv.x;
                    if (uv.y < uvArea.y) uvArea.y = uv.y;
                    if (uv.x > uvArea.z) uvArea.z = uv.x;
                    if (uv.y > uvArea.w) uvArea.w = uv.y;
                }
                vec2 minUV = uvArea.xy;
                vec2 maxUV = vec2(uvArea.z-uvArea.x, uvArea.w-uvArea.y);
                foreach(ref uv; uvs) uv = uv.mapUVCoord(minUV, maxUV);

                // Now we need to scale those UV coordinates to fit within the mapping
                float atlasSize = cast(float)atlas.textures[0].width;
                rect mapping = atlas.mappings[part.uuid];
                foreach(ref uv; uvs) {
                    uv.x = (mapping.x+(uv.x*mapping.width))/atlasSize;
                    uv.y = (mapping.y+(uv.y*mapping.height))/atlasSize;
                }

                // Apply our UVs
                part.getMesh().uvs = uvs;

                // Finally apply our atlas textures to the part
                foreach(i; 0..TextureUsage.COUNT) {
                    part.textures[i] = atlas.textures[i];
                }

                break;
            }
        }
    }

    // Flatten all parameter groups
    foreach(i, ref param; editable.parameters) {
        import std.array : insertInPlace;
        if (auto group = cast(ExParameterGroup)param) {
            if (i == 0) editable.parameters = group.children ~ editable.parameters[1..$];
            else if (i+1 == editable.parameters.length) editable.parameters = editable.parameters[0..$-1] ~ group.children;
            else editable.parameters = editable.parameters[0..i] ~ group.children ~ editable.parameters[i+1..$];
        }
    }

    // Remove cameras
    foreach(ref camera; editable.findNodesType!ExCamera(editable.root)) {
        camera.parent = null;
    }

    editable.populateTextureSlots();
    inWriteINPPuppet(editable, file);
}