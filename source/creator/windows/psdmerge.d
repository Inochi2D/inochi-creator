/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.psdmerge;
import creator.windows;
import creator.core;
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
}

class PSDMergeWindow : Window {
private:
    PSD document;
    NodeLayerBinding[] bindings;

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
                bindings ~= NodeLayerBinding(layer, layerTexture, seg, true);
            } else {

                // Otherwise, default to add
                bindings ~= NodeLayerBinding(layer, layerTexture, puppet.root, false);
            }
        }
    }

    void apply() {
        auto puppet = incActivePuppet();

        // Apply all the bindings to the node tree.
        foreach(binding; bindings) {
            if (binding.replaceTexture) {
                (cast(ExPart)binding.node).textures[0] = binding.layerTexture;
                (cast(ExPart)binding.node).layerPath = binding.layerPath;
            } else {
                auto part = incCreateExPart(binding.layerTexture, binding.node, binding.layer.name);
                part.layerPath = binding.layerPath;
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
        if (igButton(__("Merge"))) {
            apply();
            this.close();
            return;
        }
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

