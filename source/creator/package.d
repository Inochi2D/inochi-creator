/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator;
import inochi2d;
import inochi2d.core.dbg;
import creator.core;
import creator.core.actionstack;
import creator.atlas;

public import creator.ver;
public import creator.atlas;
import creator.core.colorbleed;

/**
    A project
*/
class Project {
    /**
        The puppet in the project
    */
    Puppet puppet;

    /**
        Textures for use in the puppet

        Can be rearranged
    */
    Texture[] textures;
}

private {
    Project activeProject;
    Node[] selectedNodes;
    Drawable[] drawables;
}

/**
    Edit modes
*/
enum EditMode {
    ModelEdit,
    DeformEdit,
    VertexEdit
}

bool incShowVertices    = true; /// Show vertices of selected parts
bool incShowBounds      = true; /// Show bounds of selected parts
bool incShowOrientation = true; /// Show orientation gizmo of selected parts

/**
    Current edit mode
*/
EditMode editMode_;

void incBeginUpdate() {
    inBeginScene();
}

/**
    Updates the active Inochi2D project
*/
void incUpdateActiveProject() {

    activeProject.puppet.update();
    activeProject.puppet.draw();

    if (selectedNodes.length > 0) {
        foreach(selectedNode; selectedNodes) {
            if (selectedNode is null) continue; 
            if (incShowOrientation) selectedNode.drawOrientation();
            if (incShowBounds) selectedNode.drawBounds();

            if (Drawable selectedDraw = cast(Drawable)selectedNode) {

                if (incShowVertices || incEditMode != EditMode.ModelEdit) {
                    selectedDraw.drawMeshLines();
                    selectedDraw.drawMeshPoints();
                }
            }
            
        }
    }
}

void incEndUpdate() {
    inEndScene();
}


/**
    Creates a new project
*/
void incNewProject() {
    activeProject = new Project;
    activeProject.puppet = new Puppet;
    incSelectNode(null);

    inDbgDrawMeshVertexPoints = true;
    inDbgDrawMeshOutlines = true;
    inDbgDrawMeshOrientation = true;

    incTargetPosition = vec2(0);
    incTargetZoom = 1;

    incActionClearHistory();
    incFreeMemory();
}

/**
    Imports image files from a selected folder.
*/
void incImportFolder(string folder) {
    incNewProject();

    import std.file : dirEntries, SpanMode;
    import std.path : stripExtension, baseName;

    // For each file find PNG, TGA and JPEG files and import them
    Puppet puppet = new Puppet();
    size_t i;
    foreach(file; dirEntries(folder, SpanMode.shallow, false)) {

        // TODO: Check for position.ini

        auto tex = ShallowTexture(file);
        inTexPremultiply(tex.data);

        Part part = inCreateSimplePart(new Texture(tex), null, file.baseName.stripExtension);
        part.zSort = -((cast(float)i++)/100);
        puppet.root.addChild(part);
    }
    puppet.rescanNodes();
    incActiveProject().puppet = puppet;
    incFreeMemory();
}

/**
    Imports a PSD file.
*/
void incImportPSD(string file) {
    incTaskAdd("Import "~file, () {
        incNewProject();
        import psd : PSD, Layer, LayerType, LayerFlags, parseDocument, BlendingMode;
        PSD doc = parseDocument(file);
        vec2i docCenter = vec2i(doc.width/2, doc.height/2);

        Puppet puppet = new Puppet();
        foreach(i, Layer layer; doc.layers) {

            // Skip folders ( for now )
            if (layer.type != LayerType.Any) continue;

            incTaskStatus("Importing "~layer.name~"...");
            incTaskProgress(cast(float)i/doc.layers.length);
            incTaskYield();

            layer.extractLayerImage();
            inTexPremultiply(layer.data);
            auto tex = new Texture(layer.data, layer.width, layer.height);
            Part part = inCreateSimplePart(tex, puppet.root, layer.name);

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

            switch(layer.blendModeKey) {
                case BlendingMode.Multiply: 
                    part.blendingMode = BlendMode.Multiply; break;
                default:
                    part.blendingMode = BlendMode.Normal; break;
            }
            
            part.zSort = -(cast(float)i)/100;

            puppet.root.addChild(part);
        }
        puppet.rescanNodes();
        incActiveProject().puppet = puppet;
        incFreeMemory();
        incTaskStatus("Import Finished.");
    });
}

/**
    Imports an INP puppet
*/
void incImportINP(string file) {
    incNewProject();
    Puppet puppet = inLoadPuppet(file);
    incActiveProject().puppet = puppet;
    incFreeMemory();
}

/**
    Re-bleeds textures in a model
*/
void incRebleedTextures() {
    incTaskAdd("Rebleed", () {
        incTaskStatus("Bleeding textures...");
        foreach(i, Texture texture; activeProject.puppet.textureSlots) {
            incTaskProgress(cast(float)i/activeProject.puppet.textureSlots.length);
            incTaskYield();
            incColorBleedPixels(texture);
        }
    });
}

/**
    Force the garbage collector to collect model memory
*/
void incFreeMemory() {
    import core.memory : GC;
    GC.collect();
}

/**
    Gets puppet in active project
*/
ref Puppet incActivePuppet() {
    return activeProject.puppet;
}

/**
    Gets active project
*/
ref Project incActiveProject() {
    return activeProject;
}

/**
    Gets the currently selected node
*/
ref Node[] incSelectedNodes() {
    return selectedNodes;
}

/**
    Gets a list of the current drawables
*/
ref Drawable[] incDrawables() {
    return drawables;
}

/**
    Gets the currently selected root node
*/
ref Node incSelectedNode() {
    return selectedNodes.length == 0 ? incActivePuppet.root : selectedNodes[0];
}

/**
    Selects a node
*/
void incSelectNode(Node n = null) {
    if (n is null) selectedNodes.length = 0;
    else selectedNodes = [n];
}

/**
    Adds node to selection
*/
void incAddSelectNode(Node n) {
    selectedNodes ~= n;
}

/**
    Remove node from selection
*/
void incRemoveSelectNode(Node n) {
    foreach(i, nn; selectedNodes) {
        if (n.uuid == nn.uuid) {
            import std.algorithm.mutation : remove;
            selectedNodes = selectedNodes.remove(i);
        }
    }
}

private void incSelectAllRecurse(Node n) {
    incAddSelectNode(n);
    foreach(child; n.children) {
        incSelectAllRecurse(child);
    }
}

/**
    Selects all nodes
*/
void incSelectAll() {
    incSelectNode();
    foreach(child; incActivePuppet().root.children) {
        incSelectAllRecurse(child);
    }
}

/**
    Gets whether the node is in the selection
*/
bool incNodeInSelection(Node n) {
    foreach(i, nn; selectedNodes) {
        if (nn is null) continue;
        
        if (n.uuid == nn.uuid) return true;
    }

    return false;
}

/**
    Focus camera at node
*/
void incFocusCamera(Node node) {
    if (node !is null) {
        int width, height;
        inGetViewport(width, height);

        auto nt = node.transform;

        vec4 bounds = node.getCombinedBounds();
        vec2 boundsSize = bounds.zw - bounds.xy;
        if (auto drawable = cast(Drawable)node) boundsSize = drawable.bounds.zw - drawable.bounds.xy;
        else {
            nt.translation = vec3(bounds.x + ((bounds.z-bounds.x)/2), bounds.y + ((bounds.w-bounds.y)/2), 0);
        }
        

        float largestViewport = max(width, height);
        float largestBounds = max(boundsSize.x, boundsSize.y);

        float factor = largestViewport/largestBounds;
        incTargetZoom = clamp(factor*0.85, 0.1, 2);

        incTargetPosition = vec2(
            -nt.translation.x,
            -nt.translation.y
        );
    }

}

/**
    Gets the current editing mode
*/
EditMode incEditMode() {
    return editMode_;
}

/**
    Sets the current editing mode
*/
void incSetEditMode(EditMode editMode) {
    incSelectNode(null);
    if (editMode != EditMode.ModelEdit) {
        drawables = activeProject.puppet.findNodesType!Drawable(activeProject.puppet.root);
    }
    editMode_ = editMode;
}

/**
    Target camera position in scene
*/
vec2 incTargetPosition = vec2(0);

/**
    Target camera zoom in scene
*/
float incTargetZoom = 1;

enum incVIEWPORT_ZOOM_MIN = 0.05;
enum incVIEWPORT_ZOOM_MAX = 8.0;