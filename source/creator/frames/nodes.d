module creator.frames.nodes;
import creator.core.actionstack;
import creator.frames;
import creator;
import creator.core;
import bindbc.imgui;
import inochi2d;
import std.string;
import std.format;

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

    void treeAddNode(bool isRoot = false)(Node n) {
        igPushIDInt(n.uuid());

            ImGuiTreeNodeFlags flags;
            if (n.children.length == 0) flags |= ImGuiTreeNodeFlags_Leaf;
            flags |= ImGuiTreeNodeFlags_DefaultOpen;
            flags |= ImGuiTreeNodeFlags_OpenOnArrow;

            bool open = igTreeNodeExPtr(cast(void*)n.uuid, flags, "");

            // Show node entry stuff
            igSameLine(0, 4);
            
            static if (!isRoot) {
                bool selected = n == incSelectedNode();
                if (igSelectableBool(n.name.toStringz, selected, ImGuiSelectableFlags_None, ImVec2(0, 0))) {
                    if (selected) {
                        vec3 tr = n.transform.translation;
                        incTargetPosition = -vec2(tr.x, tr.y);
                    }
                    incSelectNode(n);
                }

                if(igBeginDragDropSource(0)) {
                    igSetDragDropPayload("_PUPPETNTREE", cast(void*)&n, (&n).sizeof, ImGuiCond_Always);
                    igText(n.name.toStringz);
                    igEndDragDropSource();
                }
            } else {
                igText(n.name.toStringz);
            }

            if(igBeginDragDropTarget()) {
                ImGuiPayload* payload = igAcceptDragDropPayload("_PUPPETNTREE", 0);
                if (payload !is null) {
                    Node payloadNode = *cast(Node*)payload.Data;

                    // Push action to stack
                    incActionPush(new NodeChangeAction(
                        payloadNode.parent,
                        payloadNode,
                        n
                    ));

                    payloadNode.parent = n;
                    
                    igTreePop();
                    igPopID();
                    return;
                }
                igEndDragDropTarget();
            }

            // Draw children
            if (open) {
                foreach(child; n.children) {
                    treeAddNode(child);
                }
                igTreePop();
            }
        igPopID();
    }

    override
    void onBeginUpdate() {
        igBegin(name.ptr, &this.visible, ImGuiWindowFlags_AlwaysAutoResize);
    }

    override
    void onUpdate() {
        igText("<Action Buttons Go Here>");
        igSeparator();

        ImVec2 avail;
        igGetContentRegionAvail(&avail);
        
        igBeginChildStr("##nolabel", ImVec2(0, avail.y-28), false, ImGuiWindowFlags_HorizontalScrollbar);
            treeAddNode!true(incActivePuppet.root);
        igEndChild();

        if (igIsItemClicked(ImGuiMouseButton_Left)) {
            incSelectNode(null);
        }
        
        igPushFont(incIconFont());
            //igText("\ue92e", ImVec2(0, 0));
            if (igButton("\ue92e", ImVec2(24, 24))) {
                Node payloadNode = incSelectedNode();

                // Push action to stack
                incActionPush(new NodeChangeAction(
                    payloadNode.parent,
                    payloadNode,
                    null
                ));

                payloadNode.parent = null;
                incActivePuppet().rescanNodes();
            }
            if(igBeginDragDropTarget()) {
                ImGuiPayload* payload = igAcceptDragDropPayload("_PUPPETNTREE", 0);
                if (payload !is null) {
                    Node payloadNode = *cast(Node*)payload.Data;

                    // Push action to stack
                    incActionPush(new NodeChangeAction(
                        payloadNode.parent,
                        payloadNode,
                        null
                    ));

                    payloadNode.parent = null;
                    incActivePuppet().rescanNodes();
                    
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


