module creator.io.inpexport;
import creator.atlas;
import creator.ext;
import inochi2d;
import std.algorithm.sorting;
import std.algorithm.mutation;
import i18n;
import std.exception;
import std.file : rename;

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

    vec2 incINPExportGetPartSize(Part part, IncINPExportSettings settings) {
        return vec2(
            (part.bounds.z-part.bounds.x)+settings.padding, 
            (part.bounds.w-part.bounds.y)+settings.padding
        );
    }

    vec2 incINPExportGetPackingRatio(vec2 size, IncINPExportSettings settings) {
        float xRatio = ((size.x*settings.scale)/cast(float)settings.atlasResolution)+0.01;
        float yRatio = ((size.y*settings.scale)/cast(float)settings.atlasResolution)+0.01;
        return vec2(xRatio, yRatio);
    }

    bool incINPExportPackPart(Part part, IncINPExportSettings settings, float rscale, ref Atlas atlas) {
        if (settings.nonLinearScaling) {

            // Apply new rscale internally
            vec2 size = incINPExportGetPartSize(part, settings);
            vec2 ratio = incINPExportGetPackingRatio(size, settings);
            if (ratio.x > 1.0) rscale = cast(float)(settings.atlasResolution/size.x)-0.01;
            if (ratio.y > 1.0) rscale = cast(float)(settings.atlasResolution/size.y)-0.01;
            return atlas.pack(part, rscale);
        } else {

            // Use provided rscale
            return atlas.pack(part, rscale);
        }
    }

    /**
        Returns the best packing ratio that can be achieved for the provided settings
    */
    float incINPExportGetPossiblePackingRatio(Part[] parts, IncINPExportSettings settings) {
        if (settings.nonLinearScaling) return 1;

        float rscale = 1;
        foreach(part; parts) {
            vec2 size = incINPExportGetPartSize(part, settings);
            vec2 ratio = incINPExportGetPackingRatio(size, settings);
            if (ratio.x > 1.0) rscale = cast(float)(settings.atlasResolution/size.x)-0.015;
            if (ratio.y > 1.0) rscale = cast(float)(settings.atlasResolution/size.y)-0.015;
        }

        return rscale;
    }
}


struct IncINPPreviewInfo {

    /**
        The resulting output scale from packing
    */
    float outputScale;

    /**
        The preview texture
    */
    Texture preview;
}

/**
    Export settings for the INP exporter.
*/
struct IncINPExportSettings {

    /**
        Resolution of the output texture atlas
    */
    size_t atlasResolution = 2048;

    /**
        Whether textures should be scaled non-linearly to fit the atlas if they're too big.
    */
    bool nonLinearScaling = false;

    /**
        Scaling factor
    */
    float scale = 1;

    /**
        Padding amount
    */
    int padding = 16;

    /**
        Unused (disabled) branches of the node tree should be discarded.
    */
    bool optimizePruneUnused = true;


    /**
        Watermark texture to apply to texture atlas

        If texture is null then no watermark decoration will happen
    */
    Texture decorateWatermark;

    /**
        Watermark opacity
    */
    float decorateWatermarkOpacity = 1;

    /**
        Blending mode to use for the watermark
    */
    BlendMode decorateWatermarkBlendMode = BlendMode.ClipToLower;

    /**
        How many times the watermark will loop over the atlas
    */
    uint decorateWatermarkLoops = 10;
}

/**
    Gets the best Part packing order for the puppet
*/
Part[] incINPExportGetBestSort(Puppet puppet) {

    // TODO: Implement a better sorting strategy that optimizes rendering perf.
    Part[] parts = puppet.getAllParts().dup;
    parts.sort!(
        (a, b) => a.textures[0].width+a.textures[0].height > b.textures[0].width+b.textures[0].height, 
        SwapStrategy.stable
    )();

    return parts;
}

/**
    Generates a copy of the puppet which may be edited.

    If optimize is set to true optimizations specified in settings will be applied.
*/
Puppet incINPExportGenPuppet(Puppet puppet, IncINPExportSettings settings, bool optimize=false) {
    
    // TODO: Don't do this encode-decode shenannigans
    // A clone() function should be added to Puppet, which creates
    // an identical deep clone with a reference to the same textures.
    Puppet p = inLoadINPPuppet(inWriteINPPuppetMemory(puppet));

    if (optimize) {

        // Prune optimization
        incINPExportOptimizePrune(p, settings);
    }
    return p;
}


/**
    Optimization which prunes unused nodes
*/
void incINPExportOptimizePrune(Puppet puppet, IncINPExportSettings settings) {
    if (!settings.optimizePruneUnused) return;

    // TODO: Later nodes may be enabled or disabled arbitrarily
    // Once that feature is implemented we need to check if there's
    // any possibility that the user could enable the deleted node
    //
    // TODO: early prune animation parameters that try to access deleted
    // nodes as well.
    void nodePruneIter(ref Node self) {
        foreach(ref Node child; self.children) {
            if (!child.enabled) child.parent = null;
            else nodePruneIter(child);
        }
    }

    puppet.populateTextureSlots();
    nodePruneIter(puppet.root);
}

/**
    Decorates the output texture atlasses with watermarks
*/
void incINPExportDecorateWatermark(ref Atlas atlas, ref IncINPExportSettings settings) {
    if (settings.decorateWatermark && atlas.textures.length > 0) {
        float loops = clamp(settings.decorateWatermarkLoops, 1, float.max);

        // TODO: Decorate the atlas with a watermark
        atlas.renderOnTop(
            0, 
            settings.decorateWatermark, 
            rect(0, 0, cast(float)settings.atlasResolution, cast(float)settings.atlasResolution), 
            rect(0, 0, loops, loops),
            settings.decorateWatermarkBlendMode,
            settings.decorateWatermarkOpacity
        );
    }
}

/**
    Generates a preview of how the atlas will be packed.
*/
IncINPPreviewInfo incINPExportGenPreview(Puppet puppet, IncINPExportSettings settings) {

    Atlas previewAtlas = new Atlas(settings.atlasResolution, settings.padding, settings.scale);
    Part[] parts = incINPExportGetBestSort(puppet);

    // Pack with settings
    float rscale = incINPExportGetPossiblePackingRatio(parts, settings);
    foreach(part; parts) {
        
        // Don't waste time packing textures after we've filled our test atlas
        if (!incINPExportPackPart(part, settings, rscale, previewAtlas)) break;
    }

    // Decorate with watermark (if any exists)
    incINPExportDecorateWatermark(previewAtlas, settings);

    previewAtlas.finalize();
    return IncINPPreviewInfo(
        rscale,
        previewAtlas.textures[0]
    );
}

/**
    Attempts to generate texture atlasses for the puppet
*/
Atlas[] incINPExportGenAtlasses(Puppet puppet, IncINPExportSettings settings) {
    Atlas[] atlasses = [new Atlas(settings.atlasResolution, settings.padding, settings.scale)];

    // Initial State
    Part[] parts = incINPExportGetBestSort(puppet);
    size_t partsLeft = parts.length;
    bool[Part] taken;
    bool failed = false;

    // Optimal packing ratio
    float optimalRatio = incINPExportGetPossiblePackingRatio(parts, settings);

    // Fill out taken array.
    foreach(part; parts) taken[part] = false;

    mwhile: while(partsLeft > 0) {
        foreach(part; parts) {

            // Skip already atlassed parts
            if (taken[part]) continue;

            // Try to pack part, if failed, skip
            if (incINPExportPackPart(part, settings, optimalRatio, atlasses[$-1])) {
                taken[part] = true;
                partsLeft--;
                failed = false;
                continue mwhile;
            }
        }

        // If this is executed it's a bug, using enforce here to prevent infinite loop.
        enforce(!failed, _("A texture is too big for the atlas."));

        // Decorate with watermark (if any exists)
        incINPExportDecorateWatermark(atlasses[$-1], settings);

        // Finalize finished atlas and push a new one on
        atlasses[$-1].finalize();
        atlasses ~= new Atlas(settings.atlasResolution, settings.padding, settings.scale);

        // This should ideally get reset above.
        failed = true;
    }

    return atlasses;
}

/**
    Flattens the target puppet
*/
void incINPExportFlatten(ref Puppet target) {
    
    // Flatten all parameter groups
    Parameter[] params;
    foreach(i, ref param; target.parameters) {
        import std.array : insertInPlace;
        if (auto group = cast(ExParameterGroup)param) params ~= group.children;
        else params ~= param;
    }
    target.parameters = params;

    // Apply all deformation of mesh groups to its children.
    target.applyDeformToChildren();

    // Discard invalid lanes
    foreach(ref Animation animation; target.getAnimations()) {
        animation.finalize(target);
        AnimationLane[] workingLanes;
        foreach(ref AnimationLane lane; animation.lanes) {
            if (lane.paramRef.targetParam) workingLanes ~= lane;
        }
        animation.lanes = workingLanes;
    }

    // Remove cameras
    foreach(ref camera; target.findNodesType!ExCamera(target.root)) {
        camera.parent = null;
    }
}

/**
    Finalizes the export by fitting everything to the atlas.
    As well as flattening deformation data.
*/
void incINPExportFinalizePacking(ref Puppet source, Atlas[] atlasses) {
    
    // Apply all atlasses
    foreach(Part part; source.getAllParts()) {
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

    source.populateTextureSlots();
}

/**
    Exports a INP, may throw an exception if any of the steps fail.
*/
void incINPExport(Puppet puppet, IncINPExportSettings settings, string file) {
    Puppet source = incINPExportGenPuppet(puppet, settings, true);

    Atlas[] atlasses = incINPExportGenAtlasses(puppet, settings);

    // Flatten and finish packing
    incINPExportFlatten(source);
    incINPExportFinalizePacking(source, atlasses);
    
    // using swp prevent file corruption
    string swapPath = file ~ ".export.swp";
    inWriteINPPuppet(source, swapPath);
    rename(swapPath, file);
}