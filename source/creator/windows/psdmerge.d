/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.psdmerge;
import creator.windows;
import creator.core;
import creator.widgets;
import creator;
import creator.ext;
import std.string;
import creator.utils.link;
import inochi2d;
import i18n;
import psd;

/**
    Binding between layer and node
*/
struct NodeLayerBinding {
    Layer layer;
    Texture layerTexture;

    Node node;
    bool replaceTexture;
    string layerPath;
    int depth() {
        return replaceTexture ? node.depth-1 : node.depth;
    }
}

class PSDMergeWindow : Window {
private:
    PSD document;
    NodeLayerBinding[] bindings;
    bool renameMapped;
    bool retranslateMapped;
    bool resortModel;

    void populateBindings() {
        import std.array : join;
        auto puppet = incActivePuppet();
        auto parts = puppet.findNodesType!ExPart(puppet.root);

        ExPart findPartForSegment(string segment) {
            foreach(ref ExPart part; parts) {
                if (part.layerPath == segment) return part;
            }
            return null;
        }

        string[] layerPathSegments;
        string calcSegment;
        foreach_reverse(layer; document.layers) {

            // Build layer path segments
            if (layer.type != LayerType.Any) {
                if (layer.name != "</Layer set>") layerPathSegments ~= layer.name; 
                else layerPathSegments.length--;

                calcSegment = layerPathSegments.length > 0 ? "/"~layerPathSegments.join("/") : "";
                continue;
            }

            // Load texture in to memory
            layer.extractLayerImage();
            inTexPremultiply(layer.data);
            auto layerTexture = new Texture(layer.data, layer.width, layer.height);

            // See if any matching segments can be found
            string currSegment = "%s/%s".format(calcSegment, layer.name);
            ExPart seg = findPartForSegment(currSegment);
            if (seg) {

                // If so, default to replace
                bindings ~= NodeLayerBinding(layer, layerTexture, seg, true, currSegment);
            } else {

                // Otherwise, default to add
                bindings ~= NodeLayerBinding(layer, layerTexture, puppet.root, false, currSegment);
            }
        }
    }

    void apply() {
        import std.algorithm.sorting : sort;
        bindings.sort!((a, b) => a.depth < b.depth)();
        
        vec2i docCenter = vec2i(document.width/2, document.height/2);
        auto puppet = incActivePuppet();

        // Apply all the bindings to the node tree.
        foreach(binding; bindings) {
            auto layerSize = cast(int[2])binding.layer.size();
            vec2i layerPosition = vec2i(
                binding.layer.left,
                binding.layer.top
            );

            vec3 worldTranslation = vec3(
                (layerPosition.x+(layerSize[0]/2))-cast(float)docCenter.x,
                (layerPosition.y+(layerSize[1]/2))-cast(float)docCenter.y,
                0
            );

            vec3 localPosition = 
                binding.node ? 
                Node.getRelativePosition(binding.node.transformNoLock.matrix, mat4.translation(worldTranslation)) : 
                worldTranslation;

            if (binding.replaceTexture) {
                localPosition = 
                    binding.node.parent ? 
                    Node.getRelativePosition(binding.node.parent.transformNoLock.matrix, mat4.translation(worldTranslation)) : 
                    worldTranslation;

                // If we don't do this the subsequent child nodes will work on old data.
                binding.node.recalculateTransform = true;

                // If the user requests that nodes should be renamed to match their respective layers, do so.
                if (renameMapped) {
                    (cast(ExPart)binding.node).name = binding.layer.name;
                }

                if (retranslateMapped) {
                    binding.node.localTransform.translation = localPosition;
                }


                (cast(ExPart)binding.node).textures[0] = binding.layerTexture;
                (cast(ExPart)binding.node).layerPath = binding.layerPath;
            } else {
                auto part = incCreateExPart(binding.layerTexture, binding.node, binding.layer.name);
                part.layerPath = binding.layerPath;
                part.localTransform.translation = localPosition;
            }
        }
        
        // Unload PSD, we're done with it
        destroy(document);

        // Repopulate texture slots, removing unused textures
        puppet.populateTextureSlots();
    }

    void layerView() {

    }

    void treeView() {

    }

protected:

    override
    void onUpdate() {
        float scale = incGetUIScale();
        ImVec2 space;

        igBeginGroup();
            // Auto-rename
            igCheckbox(__("Auto-rename"), &renameMapped);
            incTooltip(_("Renames all mapped nodes to match the names of the PSD layer that was merged in to them."));

            igSameLine(0, 8*scale);
            igCheckbox(__("Re-translate"), &retranslateMapped);
            incTooltip(_("Moves all nodes so that they visually match their position in the canvas."));

            igSameLine(0, 8*scale);
            igCheckbox(__("Re-sort"), &resortModel);
            incTooltip(_("[NOT IMPLEMENTED] Sorts all nodes zSorting position to match the sorting in the PSD."));


            // Spacer
            space = incAvailableSpace();
            incSpacer(ImVec2(-(64*scale), 32*scale));

            // 
            igSameLine(0, 0);
            if (igButton(__("Merge"), ImVec2(64*scale, 24*scale))) {
                apply();
                this.close();
                return;
            }
        igEndGroup();
    }

public:
    ~this() {
        destroy(document);
    }

    this(string path) {
        document = parseDocument(path);
        this.populateBindings();
        super(_("PSD Merging"));
    }
}

