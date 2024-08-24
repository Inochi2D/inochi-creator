/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.io.kra;
import creator;
import creator.ext;
import creator.core.tasks;
import creator.widgets.dialog;
import inochi2d.math;
import inochi2d;
import kra;
import i18n;
import std.format;
import creator.io;
import mir.serde;

private {

}

bool incImportShowKRADialog() {
    TFD_Filter[] filters = [{ ["*.kra"], "Krita Document (*.kra)" }];
    string file = incShowImportDialog(filters, _("Import..."));
    return incAskImportKRA(file);
}

class IncKRALayer {
    string name;

    bool hidden;
    bool isLayerGroup;
    BlendMode blendMode;

    @serdeIgnore
    Layer kraLayerRef;

    @serdeIgnore
    int index;

    @serdeIgnore
    IncKRALayer parent;

    IncKRALayer[] children;

    this(Layer layer, bool isGroup, IncKRALayer parent = null, int index = 0) {
        this.parent = parent;
        this.kraLayerRef = layer;
        this.name = kraLayerRef.name;
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

IncKRALayer[] incKRABuildLayerLayout(KRA document) {
    IncKRALayer[] outLayers;

    IncKRALayer[] groupStack;
    int index = 0;
    foreach(layer; document.layers) {
        index--;
        if (layer.type == LayerType.SectionDivider) {
            if (groupStack.length == 1) {

                outLayers ~= groupStack[$-1];
                groupStack.length--;
                continue;
            } else if (groupStack.length > 1) {
                groupStack[$-2].children ~= groupStack[$-1];
                groupStack.length--;
                continue;
            }

            // uh, this should not happen?
            throw new Exception("Unexpected closing layer group");
        }

        IncKRALayer curLayer = new IncKRALayer(
            layer, 
            !layer.type == LayerType.Any, 
            groupStack.length > 0 ? groupStack[$-1] : null,
            index
        );

        // Add output layers in
        if (curLayer.isLayerGroup) groupStack ~= curLayer;
        else if (groupStack.length > 0) {
            groupStack[$-1].children ~= curLayer;
        } else {
            outLayers ~= curLayer;
        }

    }

    return outLayers;
}

struct IncKRAImportSettings {
    bool keepStructure = false;
}

/**
    Imports a KRA file with user prompt.
    also see incAskImportPSD()
*/
bool incAskImportKRA(string file) {
    if (!file) return false;

    // Note: currently KRA not supported Preserve layer structure, so we just skip the dialog
    // until we have a proper implementation.
    // KRALoadHandler handler = new KRALoadHandler(file);
    // return incKeepStructDialog(handler);

    incImportKRA(file, IncKRAImportSettings(false));
    return true;
}

class KRALoadHandler : ImportKeepHandler {
    private string file;

    this(string file) {
        super();
        this.file = file;
    }

    override
    bool load(AskKeepLayerFolder select) {
        switch (select) {
            case AskKeepLayerFolder.NotPreserve:
                incImportKRA(file, IncKRAImportSettings(false));
                return true;
            case AskKeepLayerFolder.Preserve:
                incImportKRA(file, IncKRAImportSettings(true));
                return true;
            case AskKeepLayerFolder.Cancel:
                return false;
            default:
                throw new Exception("Invalid selection");
        }
    }
}

/**
    Imports a KRA file.
    Note: You should invoke incAskImportKRA for UI interaction.
*/
void incImportKRA(string file, IncKRAImportSettings settings = IncKRAImportSettings.init) {
    incNewProject();
    // TODO: Split this up to a seperate file and make it cleaner
    try {
        import kra : KRA, Layer, LayerType, parseDocument, BlendingMode;

        KRA doc = parseDocument(file);
        IncKRALayer[] layers = incKRABuildLayerLayout(doc);
        vec2i docCenter = vec2i(doc.width/2, doc.height/2);
        Puppet puppet = new ExPuppet();

        void recurseAdd(Node n, IncKRALayer layer) {
            if (!layer.kraLayerRef.isLayerUseful) return;
            
            Node child;
            if (layer.isLayerGroup) {
                if (layer.kraLayerRef.blendModeKey == BlendingMode.PassThrough || layer.kraLayerRef.blendModeKey == BlendingMode.Normal) {
                    if (settings.keepStructure) child = new Node(cast(Node)null);
                } else {
                    child = new Composite(null);
                    (cast(Composite)child).blendingMode = layer.blendMode;
                }
            } else {
                
                layer.kraLayerRef.extractLayerImage();

                // Early escape, layer has 0 data.
                if (layer.kraLayerRef.data.length == 0) return;

                inTexPremultiply(layer.kraLayerRef.data);
                auto tex = new Texture(layer.kraLayerRef.data, layer.kraLayerRef.width, layer.kraLayerRef.height);
                ExPart part = incCreateExPart(tex, null, layer.name);
                part.layerPath = layer.getLayerPath();

                auto layerSize = cast(int[2])layer.kraLayerRef.size();
                vec2i layerPosition = vec2i(
                    layer.kraLayerRef.left,
                    layer.kraLayerRef.top
                );

                // TODO: more intelligent placement
                part.localTransform.translation = vec3(
                    (layerPosition.x+(layerSize[0]/2))-docCenter.x,
                    (layerPosition.y+(layerSize[1]/2))-docCenter.y,
                    0
                );


                part.enabled = layer.kraLayerRef.isVisible;
                part.opacity = (cast(float)layer.kraLayerRef.opacity)/255;
                part.blendingMode = layer.blendMode;

                child = part;
            }

            if (child) {
                child.name = layer.name;
                child.zSort = -(cast(float)layer.index);
                child.reparent(n, 0);
            }


            // Add children
            foreach(sublayer; layer.children) {
                if (!sublayer.kraLayerRef.isLayerUseful) continue;
                if (settings.keepStructure) {

                    // Normal adding
                    recurseAdd(child, sublayer);
                } else {

                    if (auto composite = cast(Composite)child) {
                    
                        // Composite child iteration
                        recurseAdd(composite, sublayer);
                    } else {

                        // Non-composite child iteration
                        recurseAdd(n, sublayer);
                    }
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
        incDialog(__("Error"), _("An error occured during KRA import:\n%s").format(ex.msg));
    }
    incFreeMemory();
}