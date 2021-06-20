module creator;
import inochi2d;
import inochi2d.core.dbg;
import creator.core.actionstack;

public import creator.ver;

/**
    A project
*/
class Project {
    /**
        The puppet in the project
    */
    Puppet puppet;
}

private {
    Project activeProject;
    Node selectedNode;
}

/**
    Edit modes
*/
enum EditMode {
    ModelEdit,
    ParamEdit,
    VertexEdit
}

/**
    Current edit mode
*/
EditMode incEditMode;

/**
    Updates the active Inochi2D project
*/
void incUpdateActiveProject() {
    inBeginScene();

        activeProject.puppet.update();
        activeProject.puppet.draw();

        if (selectedNode !is null) {
            selectedNode.drawOutlineOne();
        }

    inEndScene();
}


/**
    Creates a new project
*/
void incNewProject() {
    activeProject = new Project;
    activeProject.puppet = new Puppet;

    inDbgDrawMeshVertexPoints = true;
    inDbgDrawMeshOutlines = true;
    inDbgDrawMeshOrientation = true;

    incTargetPosition = vec2(0);
    incTargetZoom = 1;

    incActionClearHistory();
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
ref Node incSelectedNode() {
    return selectedNode;
}

/**
    Selects a node
*/
void incSelectNode(Node n = null) {
    selectedNode = n;
}

/**
    Focus camera at node
*/
void incFocusCamera(Node node) {
    auto nt = node.transform;

    if (Drawable drawable = cast(Drawable)node) {
        int width, height;
        inGetViewport(width, height);
        
        vec2 boundsSize = drawable.bounds.zw - drawable.bounds.xy;

        float largestViewport = max(width, height);
        float largestBounds = max(boundsSize.x, boundsSize.y);

        float factor = largestViewport/largestBounds;
        incTargetZoom = clamp(factor*0.85, 0.1, 2);
    } else {
        incTargetZoom = 1;
    }

    incTargetPosition = vec2(
        -nt.translation.x,
        -nt.translation.y
    );

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