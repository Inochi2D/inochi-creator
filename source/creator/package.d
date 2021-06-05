module creator;
import inochi2d;
import inochi2d.core.dbg;
import creator.core.actionstack;

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
Puppet incActivePuppet() {
    return activeProject.puppet;
}

/**
    Gets active project
*/
Project incActiveProject() {
    return activeProject;
}

/**
    Gets the currently selected node
*/
Node incSelectedNode() {
    return selectedNode;
}

/**
    Selects a node
*/
void incSelectNode(Node n = null) {
    selectedNode = n;
}

/**
    Target camera position in scene
*/
vec2 incTargetPosition;

/**
    Target camera zoom in scene
*/
float incTargetZoom;

enum incVIEWPORT_ZOOM_MIN = 0.15;
enum incVIEWPORT_ZOOM_MAX = 8.0;