/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator;
import inochi2d;
import inochi2d.core.dbg;
import inochi2d.core.nodes.common;
import creator.viewport;
import creator.viewport.model;
import creator.viewport.model.deform;
import creator.core;
import creator.core.actionstack;
import creator.windows;
import creator.atlas;
import creator.ext;
import creator.widgets.dialog;

public import creator.ver;
public import creator.atlas;
import creator.core.colorbleed;

import std.file;
import std.format;
import i18n;

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
    Parameter armedParam;
    string currProjectPath;
    string[] prevProjects;
}

/**
    Edit modes
*/
enum EditMode {
    /**
        Model editing mode
    */
    ModelEdit,

    /**
        Vertex Editing Mode
    */
    VertexEdit,

    /**
        Animation Editing Mode
    */
    AnimEdit,

    /**
        Model testing mode
    */
    ModelTest
}

bool incShowVertices    = true; /// Show vertices of selected parts
bool incShowBounds      = true; /// Show bounds of selected parts
bool incShowOrientation = true; /// Show orientation gizmo of selected parts

/**
    Current edit mode
*/
EditMode editMode_;


/**
    Returns the current project path
*/
string incProjectPath() {
    return currProjectPath;
}

/**
    Return a list of prior projects
*/
string[] incGetPrevProjects() {
    return incSettingsGet!(string[])("prev_projects");
}

void incAddPrevProject(string path) {
    import std.algorithm.searching : countUntil;
    import std.algorithm.mutation : remove;
    string[] projects = incSettingsGet!(string[])("prev_projects");

    ptrdiff_t idx = projects.countUntil(path);
    if (idx >= 0) {
        projects = projects.remove(idx);
    }

    // Put project to the start of the "previous" list and
    // limit to 10 elements
    projects = path ~ projects;
    if(projects.length > 10) projects.length = 10;

    // Then save.
    incSettingsSet("prev_projects", projects);
    incSettingsSave();
}

/**
    Creates a new project
*/
void incNewProject() {
    currProjectPath = "";
    editMode_ = EditMode.ModelEdit;
    import creator.viewport : incViewportReset;
    
    incPopWindowListAll();

    activeProject = new Project;
    activeProject.puppet = new Puppet;
    incSelectNode(null);

    inDbgDrawMeshVertexPoints = true;
    inDbgDrawMeshOutlines = true;
    inDbgDrawMeshOrientation = true;

    incViewportReset();

    incActionClearHistory();
    incFreeMemory();

    incViewportPresentMode(editMode_);
}

void incOpenProject(string path) {
    Puppet puppet;

    // Load the puppet from file
    try {
        puppet = inLoadPuppet(path);
    } catch (Exception ex) {
        incDialog(__("Error"), ex.msg);
        return;
    }

    // Clear out stuff by creating a new project
    incNewProject();

    // Set the path
    currProjectPath = path;
    incAddPrevProject(path);

    incActiveProject().puppet = puppet;
    incFocusCamera(incActivePuppet().root);
    incFreeMemory();

    incSetStatus(_("%s opened successfully.").format(currProjectPath));
}

void incSaveProject(string path) {
    import std.path : setExtension;
    try {
        string finalPath = path.setExtension(".inx");
        currProjectPath = path;
        incAddPrevProject(finalPath);

        // Remember to populate texture slots otherwise things will break real bad!
        incActivePuppet().populateTextureSlots();

        // Write the puppet to file
        inWriteINPPuppet(incActivePuppet(), finalPath);

        incSetStatus(_("%s saved successfully.").format(currProjectPath));
    } catch(Exception ex) {
        incSetStatus(_("Failed to save %s").format(currProjectPath));
        incDialog(__("Error"), ex.msg);
    }
}

/**
    Imports image files from a selected folder.
*/
void incImportFolder(string folder) {
    incNewProject();

    import std.file : dirEntries, SpanMode;
    import std.path : stripExtension, baseName;

    string[] failedFiles;
    // For each file find PNG, TGA and JPEG files and import them
    Puppet puppet = new Puppet();
    size_t i;
    foreach(file; dirEntries(folder, SpanMode.shallow, false)) {
        try {

            // TODO: Check for position.ini

            auto tex = ShallowTexture(file);
            inTexPremultiply(tex.data);

            Part part = inCreateSimplePart(new Texture(tex), null, file.baseName.stripExtension);
            part.zSort = -((cast(float)i++)/100);
            puppet.root.addChild(part);
        } catch(Exception ex) {
            failedFiles ~= ex.msg;
        }
    }

    if (failedFiles.length > 0) {
        import std.array : join;
        incDialog("ImgLoadError", format(_("The following errors occured during file loading\n%s"), failedFiles.join("\n")));
    }
    
    puppet.rescanNodes();
    puppet.populateTextureSlots();
    incActiveProject().puppet = puppet;
    incFocusCamera(incActivePuppet().root);
    incFreeMemory();

    if (failedFiles.length > 0) incSetStatus(_("Folder import completed with errors..."));
    else incSetStatus(_("Folder import completed..."));
    
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
        Puppet puppet = new Puppet();

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
                if (layer.name != "</Layer set>") {
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
            part.zSort = -(cast(float)i)/10;
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

/**
    Imports an Inochi2D puppet
*/
void incImportINP(string file) {
    incNewProject();
    Puppet puppet;
    try {

        puppet = inLoadPuppet(file);
        incSetStatus(_("%s was imported...".format(file)));
    } catch(Exception ex) {
        
        incDialog(__("Error"), ex.msg);
        incSetStatus(_("Import failed..."));
        return;
    }
    incActiveProject().puppet = puppet;
    incFocusCamera(incActivePuppet().root);
    incFreeMemory();
}

/**
    Exports an Inochi2D Puppet
*/
void incExportINP(string file) {
    import std.path : setExtension;
    try {

        string oFile = file.setExtension(".inp");
        // Remember to populate texture slots otherwise things will break real bad!
        incActivePuppet().populateTextureSlots();

        // TODO: Generate optimized puppet from this puppet.

        // Write the puppet to file
        inWriteINPPuppet(incActivePuppet(), oFile);
        incSetStatus(_("%s was exported...".format(oFile)));
    } catch(Exception ex) {
        incDialog(__("Error"), ex.msg);
        incSetStatus(_("Export failed..."));
        return;
    }

}

void incRegenerateMipmaps() {

    // Allow for nice looking filtering
    foreach(texture; incActiveProject().puppet.textureSlots) {
        texture.genMipmap();
        texture.setFiltering(Filtering.Linear);
    }
    incSetStatus(_("Mipmap generation completed."));
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
    incSetStatus(_("Texture bleeding completed."));
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
    Gets the currently armed parameter
*/
Parameter incArmedParameter() {
    return editMode_ == EditMode.ModelEdit ? armedParam : null;
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
    Arms a parameter
*/
void incArmParameter(ref Parameter param) {
    armedParam = param;
    incViewportNodeDeformNotifyParamValueChanged();
    activeProject.puppet.renderParameters = false;
}

/**
    Disarms parameter recording
*/
void incDisarmParameter() {
    armedParam = null;
    incViewportNodeDeformNotifyParamValueChanged();
    activeProject.puppet.renderParameters = true;
}

/**
    Selects a node
*/
void incSelectNode(Node n = null) {
    if (n is null) selectedNodes.length = 0;
    else selectedNodes = [n];
    incViewportModelNodeSelectionChanged();
}

/**
    Adds node to selection
*/
void incAddSelectNode(Node n) {
    if (incArmedParameter()) return;
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
    if (incArmedParameter()) return;
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
    import creator.viewport : incViewportTargetZoom, incViewportTargetPosition;
    if (node is null) return;

    auto nt = node.transform;
    incFocusCamera(node, vec2(-nt.translation.x, -nt.translation.y));
}

/**
    Focus camera at node
*/
void incFocusCamera(Node node, vec2 position) {
    import creator.viewport : incViewportTargetZoom, incViewportTargetPosition;
    if (node is null) return;

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
    incViewportTargetZoom = clamp(factor*0.85, 0.1, 2);

    incViewportTargetPosition = vec2(
        position.x,
        position.y
    );
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
void incSetEditMode(EditMode editMode, bool unselect = true) {
    incViewportWithdrawMode(editMode_);

    if (armedParam) {
        armedParam.value = armedParam.getClosestKeypointValue(armedParam.value);
    }
    if (unselect) incSelectNode(null);
    if (editMode != EditMode.ModelEdit) {
        drawables = activeProject.puppet.findNodesType!Drawable(activeProject.puppet.root);
    }
    editMode_ = editMode;

    incViewportPresentMode(editMode_);
}