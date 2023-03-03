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
                vec2 maxUV = uvArea.zw;
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
                    
                    // Skip textures that are not needed.
                    if (atlas.packedIndices[i] == 0) part.textures[i] = null;
                    else part.textures[i] = atlas.textures[i];
                }

                break;
            }
        }
    }

    // Flatten all parameter groups
    Parameter[] params;
    foreach(i, ref param; editable.parameters) {
        import std.array : insertInPlace;
        if (auto group = cast(ExParameterGroup)param) params ~= group.children;
        else params ~= param;
    }
    editable.parameters = params;

    // Apply all deformation of mesh groups to its children.
    editable.applyDeformToChildren();

    // Discard invalid lanes
    foreach(ref Animation animation; editable.getAnimations()) {
        animation.finalize(editable);
        AnimationLane[] workingLanes;
        foreach(ref AnimationLane lane; animation.lanes) {
            if (lane.paramRef.targetParam) workingLanes ~= lane;
        }
        animation.lanes = workingLanes;
    }

    // Remove cameras
    foreach(ref camera; editable.findNodesType!ExCamera(editable.root)) {
        camera.parent = null;
    }

    editable.populateTextureSlots();
    inWriteINPPuppet(editable, file);
}