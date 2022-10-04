/*
    Copyright © 2020, Inochi2D Project
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

private {

}

bool incImportShowPSDDialog() {
    TFD_Filter[] filters = [{ ["*.psd"], "Photoshop Document (*.psd)" }];
    string file = incShowImportDialog(filters);

    if (file) {
        incImportPSD(file);
        return true;
    }
    return false;
}

/**
    Imports a PSD file.
*/
void incImportPSD(string file) {
    incNewProject();
    // TODO: Split this up to a seperate file and make it cleaner
    try {
        import psd : PSD, Layer, LayerType, LayerFlags, parseDocument, BlendingMode;
        import std.array : join;
        PSD doc = parseDocument(file);
        vec2i docCenter = vec2i(doc.width/2, doc.height/2);
        Puppet puppet = new ExPuppet();

        Layer[] layerGroupStack;
        bool isLastStackItemHidden() {
            return layerGroupStack.length > 0 ? (layerGroupStack[$-1].flags & LayerFlags.Visible) != 0 : false;
        }

        string[] path;
        string calcPath;
        void pushGroupStackName(string layerName) {
            path ~= layerName;
            calcPath = "/"~path.join("/");
        }

        void popGroupStackName() {
            path.length--;
            calcPath = "/"~path.join("/");
        }

        foreach_reverse(i, Layer layer; doc.layers) {
            import std.stdio : writeln;
            debug writeln(layer.name, " ", layer.blendModeKey);

            // Skip folders ( for now )
            if (layer.type != LayerType.Any) {
                if (layer.name != "</Layer set>" && layer.name != "</Layer group>") {
                    layerGroupStack ~= layer;
                    pushGroupStackName(layer.name);
                } else {
                    layerGroupStack.length--;
                    popGroupStackName();
                }

                continue;
            } else pushGroupStackName(layer.name);

            layer.extractLayerImage();
            inTexPremultiply(layer.data);
            auto tex = new Texture(layer.data, layer.width, layer.height);
            ExPart part = incCreateExPart(tex, puppet.root, layer.name);
            part.layerPath = calcPath;

            auto layerSize = cast(int[2])layer.size();
            vec2i layerPosition = vec2i(
                layer.left,
                layer.top
            );

            part.localTransform.translation = vec3(
                (layerPosition.x+(layerSize[0]/2))-docCenter.x,
                (layerPosition.y+(layerSize[1]/2))-docCenter.y,
                0
            );


            part.enabled = (layer.flags & LayerFlags.Visible) == 0;
            part.opacity = (cast(float)layer.opacity)/255;
            part.zSort = -(cast(float)i);
            switch(layer.blendModeKey) {
                case BlendingMode.Multiply: 
                    part.blendingMode = BlendMode.Multiply; break;
                case BlendingMode.LinearDodge: 
                    part.blendingMode = BlendMode.LinearDodge; break;
                case BlendingMode.ColorDodge: 
                    part.blendingMode = BlendMode.ColorDodge; break;
                case BlendingMode.Screen: 
                    part.blendingMode = BlendMode.Screen; break;
                default:
                    part.blendingMode = BlendMode.Normal; break;
            }
            debug writeln(part.name, ": ", part.blendingMode);

            // Handle layer stack stuff
            if (layerGroupStack.length > 0) {
                if (isLastStackItemHidden()) part.enabled = false;
                if (layerGroupStack[$-1].blendModeKey != BlendingMode.PassThrough) {
                    switch(layerGroupStack[$-1].blendModeKey) {
                        case BlendingMode.Multiply: 
                            part.blendingMode = BlendMode.Multiply; break;
                        case BlendingMode.LinearDodge: 
                            part.blendingMode = BlendMode.LinearDodge; break;
                        case BlendingMode.ColorDodge: 
                            part.blendingMode = BlendMode.ColorDodge; break;
                        case BlendingMode.Screen: 
                            part.blendingMode = BlendMode.Screen; break;
                        default:
                            part.blendingMode = BlendMode.Normal; break;
                    }
                }
            }

            puppet.root.addChild(part);

            if (layer.type == LayerType.Any) popGroupStackName();
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