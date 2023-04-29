/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.io.psd;
import creator;
import creator.ext;
import creator.core.tasks;
import creator.widgets.dialog;
import inochi2d.math;
import inochi2d;
import psd;
import i18n;
import std.format;
import creator.io;
import std.xml;

private {

}

bool incImportShowPSDDialog() {
    TFD_Filter[] filters = [{ ["*.psd"], "Photoshop Document (*.psd)" }];
    string file = incShowImportDialog(filters, _("Import..."));

    if (file) {
        incImportPSD(file, IncPSDImportSettings(false));
        return true;
    }
    return false;
}

class IncPSDLayer {
    string name;

    bool hidden;
    bool isLayerGroup;
    BlendMode blendMode;
    Layer psdLayerRef;

    int index;

    IncPSDLayer parent;
    IncPSDLayer[] children;

    this(Layer layer, bool isGroup, IncPSDLayer parent = null, int index = 0) {
        this.parent = parent;
        this.psdLayerRef = layer;
        this.name = psdLayerRef.name;
        this.isLayerGroup = isGroup;
        this.index = index;

        switch(layer.blendModeKey) {
            case BlendingMode.Normal: blendMode = BlendMode.Normal; break;
            case BlendingMode.Multiply: blendMode = BlendMode.Multiply; break;
            case BlendingMode.Screen: blendMode = BlendMode.Screen; break;
            case BlendingMode.Overlay: blendMode = BlendMode.Overlay; break;
            case BlendingMode.Darken: blendMode = BlendMode.Darken; break;
            case BlendingMode.Lighten: blendMode = BlendMode.Lighten; break;
            case BlendingMode.ColorDodge: blendMode = BlendMode.ColorDodge; break;
            case BlendingMode.LinearDodge: blendMode = BlendMode.LinearDodge; break;
            case BlendingMode.ColorBurn: blendMode = BlendMode.ColorBurn; break;
            case BlendingMode.HardLight: blendMode = BlendMode.HardLight; break;
            case BlendingMode.SoftLight: blendMode = BlendMode.SoftLight; break;
            case BlendingMode.Difference: blendMode = BlendMode.Difference; break;
            case BlendingMode.Exclusion: blendMode = BlendMode.Exclusion; break;
            case BlendingMode.Subtract: blendMode = BlendMode.Subtract; break;
            default: blendMode = BlendMode.Normal; break;
        }
    }

    /**
        Gets the layer path
    */
    string getLayerPath() {
        return parent !is null ? parent.getLayerPath() ~ "/" ~ name : "/" ~ name;
    }

    /**
        Gets the amount of layers
    */
    int count() {
        int c = 1;
        foreach(child; children) {
            c += child.count;
        }
        return c;
    }
}

IncPSDLayer[] incPSDBuildLayerLayout(PSD document) {
    IncPSDLayer[] outLayers;

    IncPSDLayer[] groupStack;
    int index = 0;
    foreach_reverse(layer; document.layers) {
        index--;
        if (layer.name == "</Layer set>" || layer.name == "</Layer group>") {
            if (groupStack.length == 1) {

                outLayers ~= groupStack[$-1];
                groupStack.length--;
                continue;
            } else if (groupStack.length > 1) {
                groupStack.length--;
                continue;
            }

            // uh, this should not happen?
            throw new Exception("Unexpected closing layer group");
        }

        IncPSDLayer curLayer = new IncPSDLayer(
            layer, 
            !layer.type == LayerType.Any, 
            groupStack.length > 0 ? groupStack[$-1] : null,
            index
        );

        // Add output layers in
        if (groupStack.length > 0) {
            groupStack[$-1].children ~= curLayer;
        } else {
            outLayers ~= curLayer;
        }

        if (curLayer.isLayerGroup) groupStack ~= curLayer;
    }

    return outLayers;
}

struct IncPSDImportSettings {
    bool keepStructure = false;
}

/**
    Imports a PSD file.
*/
void incImportPSD(string file, IncPSDImportSettings settings = IncPSDImportSettings.init) {
    incNewProject();
    // TODO: Split this up to a seperate file and make it cleaner
    try {
        import psd : PSD, Layer, LayerType, LayerFlags, parseDocument, BlendingMode;

        PSD doc = parseDocument(file);
        IncPSDLayer[] layers = incPSDBuildLayerLayout(doc);
        vec2i docCenter = vec2i(doc.width/2, doc.height/2);
        Puppet puppet = new ExPuppet();

        void recurseAdd(Node n, IncPSDLayer layer) {
            
            Node child;
            if (layer.isLayerGroup) {
                if (layer.psdLayerRef.blendModeKey == BlendingMode.PassThrough || layer.psdLayerRef.blendModeKey == BlendingMode.Normal) {
                    if (settings.keepStructure) child = new Node(cast(Node)null);
                } else {
                    child = new Composite(null);
                    (cast(Composite)child).blendingMode = layer.blendMode;
                }
            } else {
                
                layer.psdLayerRef.extractLayerImage();
                inTexPremultiply(layer.psdLayerRef.data);
                auto tex = new Texture(layer.psdLayerRef.data, layer.psdLayerRef.width, layer.psdLayerRef.height);
                ExPart part = incCreateExPart(tex, null, layer.name);
                part.layerPath = layer.getLayerPath();

                auto layerSize = cast(int[2])layer.psdLayerRef.size();
                vec2i layerPosition = vec2i(
                    layer.psdLayerRef.left,
                    layer.psdLayerRef.top
                );

                // TODO: more intelligent placement
                part.localTransform.translation = vec3(
                    (layerPosition.x+(layerSize[0]/2))-docCenter.x,
                    (layerPosition.y+(layerSize[1]/2))-docCenter.y,
                    0
                );


                part.enabled = (layer.psdLayerRef.flags & LayerFlags.Visible) == 0;
                part.opacity = (cast(float)layer.psdLayerRef.opacity)/255;

                child = part;
            }

            if (child) {
                child.name = layer.name;
                child.zSort = -(cast(float)layer.index);
                child.reparent(n, 0);
            }

            // Add children
            foreach(sublayer; layer.children) {
                if (settings.keepStructure) {
                    recurseAdd(child, sublayer);
                } else {
                    if (auto composite = cast(Composite)child) {
                        recurseAdd(composite, sublayer);
                        continue;
                    }
                    recurseAdd(n, sublayer);
                }
            }
        }

        foreach(layer; layers) {
            recurseAdd(puppet.root, layer);
        }

        puppet.populateTextureSlots();
        incActiveProject().puppet = puppet;
        incFocusCamera(incActivePuppet().root);

        incSetStatus(_("%s was imported...".format(file)));
    } catch (Exception ex) {

        incSetStatus(_("Import failed..."));
        incDialog(__("Error"), _("An error occured during PSD import:\n%s").format(ex.msg));
    }
    incFreeMemory();
}