module creator.frames.nodes;
import creator.core.actionstack;
import creator.frames;
import creator;
import creator.widgets;
import creator.core;
import inochi2d;
import std.string;
import std.format;
import std.conv;

/**
    An action that happens when a node is changed
*/
class NodeChangeAction : Action {
public:
    /**
        Creates a new node change action
    */
    this(Node prev, Node self, Node new_) {
        this.prevParent = prev;
        this.self = self;
        this.newParent = new_;
    }

    /**
        Previous parent of node
    */
    Node prevParent;

    /**
        Node itself
    */
    Node self;

    /**
        New parent of node
    */
    Node newParent;

    /**
        Rollback
    */
    void rollback() {
        self.parent = prevParent;
        incActivePuppet().rescanNodes();
    }

    /**
        Redo
    */
    void redo() {
        self.parent = newParent;
        incActivePuppet().rescanNodes();
    }

    /**
        Describe the action
    */
    string describe() {
        if (prevParent is null) return "Created %s".format(self.name);
        if (newParent is null) return "Deleted %s".format(self.name);
        return "Moved %s to %s".format(self.name, newParent.name);
    }

    /**
        Describe the action
    */
    string describeUndo() {
        if (prevParent is null) return "Created %s".format(self.name);
        return "Moved %s from %s".format(self.name, prevParent.name);
    }
}

/**
    Action for whether a node was activated or deactivated
*/
class NodeActiveAction : Action {
public:
    Node self;
    bool newState;

    /**
        Rollback
    */
    void rollback() {
        self.enabled = !newState;
    }

    /**
        Redo
    */
    void redo() {
        self.enabled = newState;
    }

    /**
        Describe the action
    */
    string describe() {
        return "%s %s".format(newState ? "Enabled" : "Disabled", self.name);
    }

    /**
        Describe the action
    */
    string describeUndo() {
        return "%s was %s".format(self.name, !newState ? "Enabled" : "Disabled");
    }
}

/**
    The logger frame
*/
class NodesFrame : Frame {
protected:
    void treeSetEnabled(Node n, bool enabled) {
        n.enabled = enabled;
        foreach(child; n.children) {
            treeSetEnabled(child, enabled);
        }
    }

    string typeIdToIcon(string typeId) {
        switch(typeId) {
            case "Part": return "\ue40a\0";
            case "Mask": return "\ue14e\0";
            case "PathDeform": return "\ue922\0";
            default: return "\ue97a\0"; 
        }
    }

    void moveChildWithHistory(Node n, Node to) {
        // Push action to stack
        incActionPush(new NodeChangeAction(
            n.parent,
            n,
            to
        ));
        n.parent = to;
        incActivePuppet().rescanNodes();
    }

    void addChildWithHistory(Node n, Node to) {
        // Push action to stack
        incActionPush(new NodeChangeAction(
            null,
            n,
            to
        ));

        n.name = "Unnamed "~n.typeId();
        to.addChild(n);
        incActivePuppet().rescanNodes();
    }

    void deleteChildWithHistory(Node n) {
        // Push action to stack
        incActionPush(new NodeChangeAction(
            n.parent,
            n,
            null
        ));

        n.parent = null;
        incActivePuppet().rescanNodes();
    }

    void nodeActionsPopup(bool isRoot = false)(Node n) {
        if (igIsItemClicked(ImGuiMouseButton.Right)) {
            igOpenPopup("NodeActionsPopup");
        }

        if (igBeginPopup("NodeActionsPopup")) {
            igText("%lu", n.uuid);

            if (igBeginMenu("Add", true)) {

                igPushFont(incIconFont());
                    igText(typeIdToIcon("Node").ptr);
                igPopFont();
                igSameLine(0, 2);
                if (igMenuItem_Bool("Node", "", false, true)) this.addChildWithHistory(new Node, n);
                
                igPushFont(incIconFont());
                    igText(typeIdToIcon("Mask").ptr);
                igPopFont();
                igSameLine(0, 2);
                if (igMenuItem_Bool("Mask", "", false, true)) this.addChildWithHistory(new Mask, n);
                
                igPushFont(incIconFont());
                    igText(typeIdToIcon("PathDeform").ptr);
                igPopFont();
                igSameLine(0, 2);
                if (igMenuItem_Bool("PathDeform", "", false, true)) this.addChildWithHistory(new PathDeform, n);
                
                igEndMenu();
            }
            
            // We don't want to delete the root
            if (igMenuItem_Bool("Delete", "", false, !isRoot)) {
                this.deleteChildWithHistory(n);
            }
            igEndPopup();
        }
    }

    void treeAddNode(bool isRoot = false)(Node n) {
        igTableNextRow(ImGuiTableRowFlags.None, 0);

        // // Draw Enabler for this node first
        // igTableSetColumnIndex(1);
        // igPushFont(incIconFont());
        //     igText(n.enabled ? "\ue8f4" : "\ue8f5");
        // igPopFont();

        ImGuiTreeNodeFlags flags;
        if (n.children.length == 0) flags |= ImGuiTreeNodeFlags.Leaf;
        flags |= ImGuiTreeNodeFlags.DefaultOpen;
        flags |= ImGuiTreeNodeFlags.OpenOnArrow;
        //flags |= ImGuiTreeNodeFlags_SpanAvailWidth;

        // Then draw the node tree index
        igTableSetColumnIndex(0);
        bool open = igTreeNodeEx_Ptr(cast(void*)n.uuid, flags, "");

            // Show node entry stuff
            igSameLine(0, 4);

            static if (!isRoot) {
                bool selected = n == incSelectedNode();

                igPushFont(incIconFont());
                    igText(typeIdToIcon(n.typeId).ptr);
                igPopFont();
                igSameLine(0, 2);
                if (igSelectable_Bool(n.name.toStringz, selected, ImGuiSelectableFlags.None, ImVec2(0, 0))) {
                    if (selected) {
                        vec3 tr = n.transform.translation;
                        incTargetPosition = -vec2(tr.x, tr.y);
                    }
                    incSelectNode(n);
                }
                this.nodeActionsPopup(n);

                if(igBeginDragDropSource(ImGuiDragDropFlags.SourceAllowNullID)) {
                    igSetDragDropPayload("_PUPPETNTREE", cast(void*)&n, (&n).sizeof, ImGuiCond.Always);
                    igText(n.name.toStringz);
                    igEndDragDropSource();
                }
            } else {
                igPushFont(incIconFont());
                    igText("\ue97a");
                igPopFont();
                igSameLine(0, 2);
                igText(n.name.toStringz);
                this.nodeActionsPopup!true(n);
            }

            if(igBeginDragDropTarget()) {
                ImGuiPayload* payload = igAcceptDragDropPayload("_PUPPETNTREE");
                if (payload !is null) {
                    Node payloadNode = *cast(Node*)payload.Data;
                    this.moveChildWithHistory(payloadNode, n);
                    
                    igTreePop();
                    return;
                }
                igEndDragDropTarget();
            }

        if (open) {
            // Draw children
            foreach(child; n.children) {
                treeAddNode(child);
            }
            igTreePop();
        }
        

    }

    override
    void onBeginUpdate() {
        igBegin(name.ptr, &this.visible, ImGuiWindowFlags.AlwaysAutoResize);
    }

    override
    void onUpdate() {
        igText("<Action Buttons Go Here>");
        igSeparator();

        ImVec2 avail;
        igGetContentRegionAvail(&avail);

        igBeginChild_Str("NodesMain", ImVec2(0, -28), false);

            if (igBeginTable("NodesContent", 2, ImGuiTableFlags.ScrollX, ImVec2(0, 0), 0)) {
                igTableSetupColumn("Nodes", ImGuiTableColumnFlags.WidthFixed, 0, 0);
                //igTableSetupColumn("Visibility", ImGuiTableColumnFlags_WidthFixed, 32, 1);
                
                treeAddNode!true(incActivePuppet.root);

                igEndTable();
            }
        igEndChild();

        if (igIsItemClicked(ImGuiMouseButton.Left)) {
            incSelectNode(null);
        }
        
        igPushFont(incIconFont());
            //igText("\ue92e", ImVec2(0, 0));
            if (igButton("\ue92e", ImVec2(24, 24))) {
                Node payloadNode = incSelectedNode();
                this.deleteChildWithHistory(payloadNode);
            }

            if(igBeginDragDropTarget()) {
                ImGuiPayload* payload = igAcceptDragDropPayload("_PUPPETNTREE");
                if (payload !is null) {
                    Node payloadNode = *cast(Node*)payload.Data;
                    this.deleteChildWithHistory(payloadNode);
                    
                    igPopFont();
                    return;
                }
                igEndDragDropTarget();
            }
        igPopFont();
    }

public:

    this() {
        super("Nodes", true);
    }
}

/**
    Generate nodes frame
*/
mixin incFrame!NodesFrame;


