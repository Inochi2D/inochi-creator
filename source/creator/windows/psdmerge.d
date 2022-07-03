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
import std.uni : toLower;

/**
    Binding between layer and node
*/
struct NodeLayerBinding {
    Layer layer;
    Texture layerTexture;
    vec4 texturePreviewBounds;

    Node node;
    bool replaceTexture;
    string layerPath;
    const(char)* layerName;
    string indexableName;
    bool ignore;
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
    bool onlyUnmapped;
    ExPart[] parts;

    string layerFilter;
    string nodeFilter;

    enum PreviewSize = 128f;

    void populateBindings() {
        import std.array : join;
        auto puppet = incActivePuppet();
        parts = puppet.findNodesType!ExPart(puppet.root);


        ExPart findPartForSegment(string segment) {
            foreach(ref ExPart part; parts) {
                if (part.layerPath == segment) return part;
            }
            return null;
        }

        ExPart findPartForName(string segment) {
            import std.path : baseName;
            foreach(ref ExPart part; parts) {
                if (baseName(part.layerPath) == baseName(segment)) return part;
            }
            return null;
        }

        string[] layerPathSegments;
        string calcSegment;
        foreach_reverse(layer; document.layers) {

            // Build layer path segments
            if (layer.type != LayerType.Any) {
                if (layer.name != "</Layer set>" && layer.name != "</Layer group>") layerPathSegments ~= layer.name; 
                else layerPathSegments.length--;

                calcSegment = layerPathSegments.length > 0 ? "/"~layerPathSegments.join("/") : "";
                continue;
            }

            // Load texture in to memory
            layer.extractLayerImage();
            inTexPremultiply(layer.data);
            auto layerTexture = new Texture(layer.data, layer.width, layer.height);

            // Calculate render size
            float widthScale = PreviewSize / cast(float)layer.width;
            float heightScale = PreviewSize / cast(float)layer.height;
            float scale = min(widthScale, heightScale);
            
            vec4 bounds = vec4(0, 0, layer.width*scale, layer.height*scale);
            if (widthScale > heightScale) bounds.x = (PreviewSize-bounds.z)/2;
            else if (widthScale < heightScale) bounds.y = (PreviewSize-bounds.w);

            // See if any matching segments can be found
            string currSegment = "%s/%s".format(calcSegment, layer.name);
            ExPart seg = findPartForSegment(currSegment);
            if (seg) {

                // If so, default to replace
                bindings ~= NodeLayerBinding(layer, layerTexture, bounds, seg, true, currSegment, layer.name.toStringz, layer.name.toLower);
            } else {

                // Try to match name only if path match fails
                seg = findPartForName(currSegment);
                if (seg) {

                    // If so, default to replace
                    bindings ~= NodeLayerBinding(layer, layerTexture, bounds, seg, true, currSegment, layer.name.toStringz, layer.name.toLower);
                    continue;
                }

                // Otherwise, default to add
                bindings ~= NodeLayerBinding(layer, layerTexture, bounds, puppet.root, false, currSegment, layer.name.toStringz, layer.name.toLower);
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
            if (binding.ignore) continue;

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
        float scale = incGetUIScale();

        import std.algorithm.searching : canFind;
        foreach(i; 0..bindings.length) {
            auto layer = &bindings[i];

            if (onlyUnmapped && layer.replaceTexture) continue;
            if (layerFilter.length > 0 && !layer.indexableName.canFind(layerFilter.toLower)) continue;

            igPushID(cast(int)i);
                const(char)* displayName = layer.layerName;
                if (layer.replaceTexture) {
                    displayName = _("%s  %s").format(layer.layer.name, layer.node.name).toStringz;
                }

                if (layer.ignore) incTextDisabled("");
                else incText("");
                if (igIsItemClicked()) {
                    layer.ignore = !layer.ignore;
                }
                igSameLine(0, 8*scale);

                igSelectable(displayName, false, ImGuiSelectableFlagsI.SpanAvailWidth);

                if(igBeginDragDropSource(ImGuiDragDropFlags.SourceAllowNullID)) {
                    igSetDragDropPayload("__REMAP", cast(void*)&layer, (&layer).sizeof, ImGuiCond.Always);
                    igText(layer.layerName);
                    igEndDragDropSource();
                }

                if (igIsItemHovered()) {
                    igBeginTooltip();
                        ImVec2 tl;
                        igGetCursorPos(&tl);

                        igItemSize(ImVec2(PreviewSize*scale, PreviewSize*scale));

                        igSetCursorPos(
                            ImVec2(layer.texturePreviewBounds.x, layer.texturePreviewBounds.y)
                        );

                        igImage(
                            cast(void*)layer.layerTexture.getTextureId(), 
                            ImVec2(layer.texturePreviewBounds.z*scale, layer.texturePreviewBounds.w*scale)
                        );
                    igEndTooltip();
                }
                igOpenPopupOnItemClick("LAYER_POPUP");

                if (igBeginPopup("LAYER_POPUP")) {
                    if (igMenuItem(__("Unmap"))) {
                        layer.replaceTexture = false;
                        layer.node = incActivePuppet.root;
                    }

                    if (igMenuItem(!layer.ignore ? __("Ignore") : __("Use"))) {
                        layer.ignore = !layer.ignore;
                    }
                    igEndPopup();
                }
            igPopID();
        }
    }

    void treeView() {
        float scale = incGetUIScale();

        import std.algorithm.searching : canFind;
        foreach(ref ExPart part; parts) {
            if (nodeFilter.length > 0 && !part.name.toLower.canFind(nodeFilter.toLower)) continue;

            igSelectable(part.cName, false, ImGuiSelectableFlagsI.SpanAvailWidth);

            // Only allow reparenting one node
            if(igBeginDragDropTarget()) {
                const(ImGuiPayload)* payload = igAcceptDragDropPayload("__REMAP");
                if (payload !is null) {
                    NodeLayerBinding* payloadNode = *cast(NodeLayerBinding**)payload.Data;
                    
                    payloadNode.node = part;
                    payloadNode.replaceTexture = true;

                    igEndDragDropTarget();
                    return;
                }
                igEndDragDropTarget();
            }

            // Incredibly cursed preview image
            if (igIsItemHovered()) {
                igBeginTooltip();
                    // Calculate render size
                    float widthScale = PreviewSize / cast(float)part.textures[0].width;
                    float heightScale = PreviewSize / cast(float)part.textures[0].height;
                    float fscale = min(widthScale, heightScale);
                    
                    vec4 bounds = vec4(0, 0, part.textures[0].width*fscale, part.textures[0].height*fscale);
                    if (widthScale > heightScale) bounds.x = (PreviewSize-bounds.z)/2;
                    else if (widthScale < heightScale) bounds.y = (PreviewSize-bounds.w);

                    ImVec2 tl;
                    igGetCursorPos(&tl);

                    igItemSize(ImVec2(PreviewSize*fscale, PreviewSize*fscale));

                    igSetCursorPos(
                        ImVec2(bounds.x, bounds.y)
                    );

                    igImage(
                        cast(void*)part.textures[0].getTextureId(), 
                        ImVec2(bounds.z*scale, bounds.w*scale)
                    );
                igEndTooltip();
            }
        }

    }

protected:

    override
    void onBeginUpdate() {
        float scale = incGetUIScale();
        igSetNextWindowSizeConstraints(ImVec2(640*scale, 480*scale), ImVec2(float.max, float.max));
        super.onBeginUpdate();
    }

    override
    void onUpdate() {
        float scale = incGetUIScale();
        ImVec2 space = incAvailableSpace();
        float gapspace = 8*scale;
        float childWidth = (space.x/2);
        float childHeight = space.y-(24*scale);
        float filterWidgetHeight = 24*scale;
        float optionsListHeight = 24*scale;

        igBeginGroup();
            if (igBeginChild("###Layers", ImVec2(childWidth, childHeight))) {
                incInputText("", childWidth-gapspace, layerFilter);

                igBeginListBox("###LayerList", ImVec2(childWidth-gapspace, childHeight-filterWidgetHeight-optionsListHeight));
                    layerView();
                igEndListBox();
                
                igCheckbox(__("Only show unmapped"), &onlyUnmapped);
            }
            igEndChild();

            igSameLine(0, gapspace);

            if (igBeginChild("###Nodes", ImVec2(childWidth, childHeight))) {
                incInputText("", childWidth, nodeFilter);

                igBeginListBox("###NodeList", ImVec2(childWidth, childHeight-filterWidgetHeight-optionsListHeight));
                    treeView();
                igEndListBox();
            }
            igEndChild();
        igEndGroup();


        igBeginGroup();

            // Auto-rename
            igCheckbox(__("Auto-rename"), &renameMapped);
            incTooltip(_("Renames all mapped nodes to match the names of the PSD layer that was merged in to them."));

            igSameLine(0, 8*scale);
            igCheckbox(__("Re-translate"), &retranslateMapped);
            incTooltip(_("Moves all nodes so that they visually match their position in the canvas."));

            // igSameLine(0, 8*scale);
            // igCheckbox(__("Re-sort"), &resortModel);
            // incTooltip(_("[NOT IMPLEMENTED] Sorts all nodes zSorting position to match the sorting in the PSD."));


            // Spacer
            space = incAvailableSpace();
            incSpacer(ImVec2(-(64*scale), 32*scale));

            // 
            igSameLine(0, 0);
            if (igButton(__("Merge"), ImVec2(64*scale, 24*scale))) {
                apply();
                this.close();
                
                igEndGroup();
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

