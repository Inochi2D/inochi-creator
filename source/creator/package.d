/*
    Copyright © 2020-2023, Inochi2D Project
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
import creator.windows.autosave;
import creator.atlas;
import creator.ext;
import creator.io.autosave;
import creator.widgets.dialog;

public import creator.ver;
public import creator.atlas;
public import creator.io;
import creator.core.colorbleed;

import std.path;
import std.format;
import std.file : rename;
import i18n;
import std.algorithm.searching;
import inochi2d.core.animation.player;


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
    size_t armedParamIdx;
    string currProjectPath;

    void function(Puppet)[] loadCallbacks;
    void function(Puppet)[] saveCallbacks;

    AnimationPlayer incAnimationPlayer;
    AnimationPlaybackRef incAnimationCurrent;
}

void incRegisterLoadFunc(void function(Puppet) func) {
    loadCallbacks ~= func;
}

void incRegisterSaveFunc(void function(Puppet) func) {
    saveCallbacks ~= func;
}

/**
    Edit modes
*/
enum EditMode {
    /**
        Model editing mode
    */
    ModelEdit = 0x1,

    /**
        Vertex Editing Mode
    */
    VertexEdit = 0x2,

    /**
        Animation Editing Mode
    */
    AnimEdit = 0x4,

    /**
        Model testing mode
    */
    ModelTest = 0x8,

    /**
        Not real edit mode, contains all the combined modes
    */
    ALL = ModelEdit | VertexEdit | AnimEdit | ModelTest,
}

bool incShowVertices    = true; /// Show vertices of selected parts
bool incShowBounds      = true; /// Show bounds of selected parts
bool incShowOrientation = true; /// Show orientation gizmo of selected parts

/**
    Current edit mode
*/
EditMode editMode_;

/**
    Clears the imgui data
*/
void incClearImguiData() {
    auto ctx = igGetCurrentContext();
    if (ctx) {
        foreach(ImGuiWindow* window; ctx.Windows.Data[0..ctx.Windows.Size]) {
            if (window) {
                ImGuiStorage_Clear(&window.StateStorage);
            }
        }
    }
}

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
    string[] projects = incGetPrevProjects();

    ptrdiff_t idx = projects.countUntil(path);
    if (idx >= 0) {
        projects = projects.remove(idx);
    }

    // Put project to the start of the "previous" list and
    // limit to 10 elements
    projects = path.dup ~ projects;
    if(projects.length > 10) projects.length = 10;

    // Then save.
    incSettingsSet("prev_projects", projects);
    incSettingsSave();
}

void incInitAnimationPlayer(Puppet puppet) {
    incAnimationPlayer = new AnimationPlayer(activeProject.puppet);
    incAnimationCurrent = null;
}

/**
    Creates a new project
*/
void incNewProject() {
    incPopWelcomeWindow();

    // Release lockfile, etc. from prev project
    if (currProjectPath.length > 0) incReleaseLockfile();
    incClearImguiData();

    currProjectPath = "";
    editMode_ = EditMode.ModelEdit;
    import creator.viewport : incViewportReset;
    
    incPopWindowListAll();

    activeProject = new Project;
    activeProject.puppet = new ExPuppet;
    incInitAnimationPlayer(activeProject.puppet);
    incFocusCamera(activeProject.puppet.root);
    incSelectNode(null);
    incDisarmParameter();

    inDbgDrawMeshVertexPoints = true;
    inDbgDrawMeshOutlines = true;
    inDbgDrawMeshOrientation = true;

    incViewportReset();

    incActionClearHistory();
    incFreeMemory();

    incViewportPresentMode(editMode_);
    incSetWindowTitle(_("New Project"));

    startAutosaveTimer();
}

void incResetRootNode(ref Puppet puppet) {
    puppet.root.localTransform.translation = vec3(0, 0, 0);
    puppet.root.localTransform.rotation = vec3(0, 0, 0);
    puppet.root.localTransform.scale = vec2(1, 1);
}

bool incOpenProject(string path) {
    if (incCheckLockfile(path)) {
        incPushWindow(new RestoreSaveWindow(path));

        //Answering that window is the new trigger for loading the project.
        return false;
    }

    // Usual case
    return incOpenProject(path, "");
}

/**
    mainPath is the canonical project path that the user normally saves to.
    backupPath is the inx file to load all the data from, but is empty string
    when just loading a normal mainsave project file.

    Note: You should not write try-catch blocks when calling this function, as it
        handles FileException internally. Adding try-catch blocks would make debugging more difficult.
*/
bool incOpenProject(string mainPath, string backupPath) {
    import std.path : setExtension, baseName;
    import std.file : FileException;

    incClearImguiData();
    
    Puppet puppet;

    // Load the puppet from file
    try {
        if (backupPath.length > 0) {
            puppet = inLoadPuppet!ExPuppet(backupPath);
        } else {
            puppet = inLoadPuppet!ExPuppet(mainPath);
        }
    } catch (FileException ex) {
        // Also handle NFS or I/O errors
        incDialog(__("Error"), ex.msg);
        return false;
    } catch (Exception ex) {
        // for user, we should show a dialog and dump the thrown stack
        import std.file : write;
        import creator.utils.crashdump;
        string report;

        try {
            mkdirCrashDumpDir();
            string path = genCrashDumpPath("inochi-creator-runtime-error");
            write(path, genCrashDump(ex));
            report = _("Please report this file to the developers:\n\n%s").format(path);
        } catch (Exception dumpEx) {
            report = _("Failed to write crash dump file." ~ dumpEx.msg);
        }

        incDialog(__("Error"), ex.msg ~ "\n\n" ~ report);
        return false;
    }

    // Clear out stuff by creating a new project
    incNewProject();

    // Set the path
    currProjectPath = mainPath;
    incAddPrevProject(mainPath);

    incResetRootNode(puppet);

    incActiveProject().puppet = puppet;
    foreach (func; loadCallbacks)
        func(puppet);
    incFocusCamera(incActivePuppet().root);
    incFreeMemory();

    incInitAnimationPlayer(puppet);

    incSetStatus(_("%s opened successfully.").format(currProjectPath));
    incSetWindowTitle(currProjectPath.baseName);

    return true;
}

void incSaveProject(string path, string autosaveStamp = "") {
    import std.path : setExtension, baseName;
    try {
        string finalPath;
        bool isAutosave = autosaveStamp.length > 0 ? true : false;
        if (isAutosave) {
            finalPath = path ~ "_" ~ autosaveStamp ~ ".inx";
            incAddPrevAutosave(finalPath);
        } else {
            finalPath = path.setExtension(".inx");
            currProjectPath = path;
            incAddPrevProject(finalPath);
        }

        // Remember to populate texture slots otherwise things will break real bad!
        incActivePuppet().populateTextureSlots();
        foreach (func; saveCallbacks)
            func(incActivePuppet());

        // Write the puppet to file, using swp prevent file corruption
        string swapPath = finalPath ~ ".swp";
        inWriteINPPuppet(incActivePuppet(), swapPath);
        rename(swapPath, finalPath);

        if (!isAutosave) incReleaseLockfile();
        incActivePuppet().resetDrivers();

        incSetStatus(_("%s saved successfully.").format(currProjectPath));
        incSetWindowTitle(currProjectPath.baseName);
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
    Puppet puppet = new ExPuppet();
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
    incInitAnimationPlayer(puppet);
    incFocusCamera(incActivePuppet().root);
    incFreeMemory();

    if (failedFiles.length > 0) incSetStatus(_("Folder import completed with errors..."));
    else incSetStatus(_("Folder import completed..."));
    
}

/**
    Imports an Inochi2D puppet
*/
void incImportINP(string file) {
    import std.path : baseName;
    
    incNewProject();
    Puppet puppet;
    try {

        puppet = inLoadPuppet!ExPuppet(file);
        incSetStatus(_("%s was imported...".format(file)));
        incSetWindowTitle(file.baseName);
    } catch(Exception ex) {
        
        incDialog(__("Error"), ex.msg);
        incSetStatus(_("Import failed..."));
        return;
    }
    incActiveProject().puppet = puppet;
    incAnimationPlayer = new AnimationPlayer(puppet);
    incAnimationCurrent = null;
    incFocusCamera(incActivePuppet().root);
    incFreeMemory();
}

/**
    Exports an Inochi2D Puppet
*/
void incExportINP(string file) {
    import creator.windows.inpexport;
    import std.path : setExtension;
    string oFile = file.setExtension(".inp");
    incPushWindow(new ExportWindow(oFile));
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
    GC.minimize();
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
    Gets the currently armed parameter index
*/
size_t incArmedParameterIdx() {
    return editMode_ == EditMode.ModelEdit ? armedParamIdx : 0;
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
void incArmParameter(size_t i, ref Parameter param) {
    armedParam = param;
    armedParamIdx = i;
    incViewportNodeDeformNotifyParamValueChanged();
    incActivePuppet.enableDrivers = false;
    incActivePuppet.resetDrivers();
}

/**
    Disarms parameter recording
*/
void incDisarmParameter() {
    armedParam = null;
    armedParamIdx = 0;
    incViewportNodeDeformNotifyParamValueChanged();
    incActivePuppet.enableDrivers = true;
    incActivePuppet.resetDrivers();
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
    if (selectedNodes.canFind(n))
        return;
    selectedNodes ~= n;
    incViewportModelNodeSelectionChanged();
}

/**
    Remove node from selection
*/
void incRemoveSelectNode(Node n) {
    foreach(i, nn; selectedNodes) {
        if (n.uuid == nn.uuid) {
            import std.algorithm.mutation : remove;
            selectedNodes = selectedNodes.remove(i);
            incViewportModelNodeSelectionChanged();
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

    // Calculate actual center.
    vec4 bounds = node.getCombinedBounds();
    if (auto drawable = cast(Drawable)node) {
        drawable.updateBounds();
        bounds = drawable.bounds;
    }
    vec2 pos = bounds.xy+((bounds.zw - bounds.xy)*0.5);

    // Focus camera to calculated center
    incFocusCamera(node, vec2(-pos.x, -pos.y));
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
    if (auto drawable = cast(Drawable)node) {
        boundsSize = drawable.bounds.zw - drawable.bounds.xy;
    } else {
        nt.translation = vec3(bounds.x + ((bounds.z-bounds.x)*0.5), bounds.y + ((bounds.w-bounds.y)*0.5), 0);
    }
    

    float largestViewport = min(width, height);
    float largestBounds = max(boundsSize.x, boundsSize.y);

    float factor = largestViewport/largestBounds;
    incViewportTargetZoom = clamp(factor*0.90, 0.1, 2.5);

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
    incAnimationPlayer.stopAll(true);
    incAnimationPlayer.destroyAll();
    incAnimationCurrent = null;
}

/**
    Sets the current animation being edited
*/
void incAnimationChange(string name) {
    incAnimationPlayer.stopAll(true);
    incAnimationCurrent = incAnimationPlayer.createOrGet(name);
    
    import creator.panels.timeline : incAnimationTimelineUpdate;
    incAnimationTimelineUpdate(*incAnimationCurrent.animation);
}

/**
    Gets a list of editable animations
*/
string[] incAnimationKeysGet() {
    return incActivePuppet().getAnimations().keys;
}

/**
    Gets the current animation being edited
*/
ref AnimationPlayer incAnimationPlayerGet() {
    return incAnimationPlayer;
}

/**
    Gets the current animation being edited
*/
AnimationPlaybackRef incAnimationGet() {
    return incAnimationCurrent;
}

void incAnimationRender() {
    incAnimationPlayer.update(deltaTime());
    if (incAnimationCurrent) incAnimationCurrent.render();
}

/**
    Updates the current animation being edited
*/
void incAnimationUpdate() {

    if (incAnimationCurrent && (incAnimationCurrent.isRunning() || incAnimationCurrent.isPlayingLeadOut()) && !incAnimationCurrent.paused) {
        incAnimationRender();
    }

    if (incEditMode() == EditMode.AnimEdit && incAnimationCurrent && incGetWindowsOpen() == 0) {
        if (igIsKeyPressed(ImGuiKey.Space, false)) {
            if (!incAnimationCurrent.playing || incAnimationCurrent.paused){
                if (igIsKeyDown(ImGuiKey.LeftCtrl) || igIsKeyDown(ImGuiKey.RightCtrl) && incAnimationCurrent.frame != 0) {
                    incAnimationCurrent.seek(0);
                }
                
                incAnimationCurrent.play(true);
            } else {
                if (igIsKeyDown(ImGuiKey.LeftCtrl) || igIsKeyDown(ImGuiKey.RightCtrl)) {
                    incAnimationPlayer.stopAll(igIsKeyDown(ImGuiKey.LeftShift) || igIsKeyDown(ImGuiKey.RightShift));
                } else {
                    incAnimationCurrent.pause();
                }
            }
        }

        if (igIsKeyPressed(ImGuiKey.LeftArrow, true) && incAnimationCurrent.frame > 0) {
            incAnimationCurrent.seek(incAnimationCurrent.frame-1);
            incAnimationRender();
        }

        if (igIsKeyPressed(ImGuiKey.RightArrow, true) && incAnimationCurrent.frame+1 < incAnimationCurrent.frames) {
            incAnimationCurrent.seek(incAnimationCurrent.frame+1);
            incAnimationRender();
        }

        if (igIsKeyPressed(ImGuiKey.N, false) || igIsKeyPressed(ImGuiKey.Insert, false)) {
            foreach(ref lane; incAnimationCurrent.animation.lanes) {
                auto param = lane.paramRef.targetParam;
                auto axis = lane.paramRef.targetAxis;
                auto value = param.value.vector[axis];

                incAnimationKeyframeAdd(param, axis, value);
            }
        }

        if (igIsKeyPressed(ImGuiKey.R, false) || igIsKeyPressed(ImGuiKey.Delete, false)) {
            foreach(ref lane; incAnimationCurrent.animation.lanes) {
                auto param = lane.paramRef.targetParam;
                auto axis = lane.paramRef.targetAxis;
                auto value = param.value.vector[axis];

                incAnimationKeyframeRemove(param, axis);
            }
        }
    }
}

/**
    Adds a keyframe to the current animation
*/
void incAnimationKeyframeAdd(ref Parameter param, int axis, float value) {
    foreach(ref lane; incAnimationCurrent.animation.lanes) {
        if (lane.paramRef.targetParam == param && axis == lane.paramRef.targetAxis) {

            // Try editing current frame
            foreach(ref frame; lane.frames) {
                if (frame.frame == incAnimationCurrent.frame) {
                    frame.value = value;
                    return;
                }
            }

            // Try adding a new keyframe
            lane.frames ~= Keyframe(
                incAnimationCurrent.frame,
                value,
                0.5
            );
            lane.updateFrames();
            return;
        }
    }

    incAnimationCurrent.animation.lanes ~= AnimationLane(
        param.uuid,
        new AnimationParameterRef(param, axis),
        [
            Keyframe(
                incAnimationCurrent.frame,
                value,
                0.5
            ),
        ],
        InterpolateMode.Linear
    );
    
    import creator.panels.timeline : incAnimationTimelineUpdate;
    incAnimationTimelineUpdate(*incAnimationCurrent.animation);
}

/**
    Removes a keyframe to the current animation
*/
bool incAnimationKeyframeRemove(ref Parameter param, int axis) {
    import std.algorithm.mutation : remove;
    foreach(ref lane; incAnimationCurrent.animation.lanes) {
        if (lane.paramRef.targetParam == param && axis == lane.paramRef.targetAxis) {

            // Try editing current frame
            foreach(i; 0..lane.frames.length) {
                if (lane.frames[i].frame == incAnimationCurrent.frame) {
                    lane.frames = lane.frames.remove(i);
                    return true;
                }
            }
        }
    }

    return false;
}