module creator.frames.nodes;
import creator.actions;
import creator.frames;
import creator;
import creator.widgets;
import creator.core;
import inochi2d;
import std.string;
import std.format;
import std.conv;

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

    void nodeActionsPopup(bool isRoot = false)(Node n) {
        if (igIsItemClicked(ImGuiMouseButton.Right)) {
            igOpenPopup("NodeActionsPopup");
        }

        if (igBeginPopup("NodeActionsPopup")) {

            if (igBeginMenu("Add", true)) {

                igPushFont(incIconFont());
                    igText(typeIdToIcon("Node").ptr);
                igPopFont();
                igSameLine(0, 2);
                if (igMenuItem("Node", "", false, true)) incAddChildWithHistory(new Node(n), n);
                
                igPushFont(incIconFont());
                    igText(typeIdToIcon("Mask").ptr);
                igPopFont();
                igSameLine(0, 2);
                if (igMenuItem("Mask", "", false, true)) {
                    MeshData empty;
                    incAddChildWithHistory(new Mask(empty, n), n);
                }
                
                igPushFont(incIconFont());
                    igText(typeIdToIcon("PathDeform").ptr);
                igPopFont();
                igSameLine(0, 2);
                if (igMenuItem("PathDeform", "", false, true)) incAddChildWithHistory(new PathDeform(n), n);
                
                igEndMenu();
            }
            
            // We don't want to delete the root
            if (igMenuItem("Delete", "", false, !isRoot)) {

                // Make sure we don't keep selecting a node we've removed
                if (n == incSelectedNode()) {
                    incSelectNode(null);
                }

                incDeleteChildWithHistory(n);
            }
            
            // We don't want to delete the root
            if (igBeginMenu("More Info", true)) {
                igText("ID: %lu", n.uuid);

                igEndMenu();
            }
            igEndPopup();
        }
    }

    void treeAddNode(bool isRoot = false)(Node n) {
        igTableNextRow();

        // // Draw Enabler for this node first
        // igTableSetColumnIndex(1);
        // igPushFont(incIconFont());
        //     igText(n.enabled ? "\ue8f4" : "\ue8f5");
        // igPopFont();

        ImGuiTreeNodeFlags flags;
        if (n.children.length == 0) flags |= ImGuiTreeNodeFlags.Leaf;
        flags |= ImGuiTreeNodeFlags.DefaultOpen;
        flags |= ImGuiTreeNodeFlags.OpenOnArrow;
        //flags |= ImGuiTreeNodeFlags.SpanAvailWidth;

        // Then draw the node tree index
        igTableSetColumnIndex(0);
        bool open = igTreeNodeEx(cast(void*)n.uuid, flags, "");

            // Show node entry stuff
            igSameLine(0, 4);

            static if (!isRoot) {
                bool selected = n == incSelectedNode();

                igPushFont(incIconFont());
                    igText(typeIdToIcon(n.typeId).ptr);
                igPopFont();
                igSameLine(0, 2);
                if (igSelectable(n.name.toStringz, selected, ImGuiSelectableFlags.None, ImVec2(0, 0))) {
                    if (selected) {
                        incFocusCamera(n);
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
                    incMoveChildWithHistory(payloadNode, n);
                    
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
                incDeleteChildWithHistory(payloadNode);
            }

            if(igBeginDragDropTarget()) {
                ImGuiPayload* payload = igAcceptDragDropPayload("_PUPPETNTREE");
                if (payload !is null) {
                    Node payloadNode = *cast(Node*)payload.Data;

                    // Make sure we don't keep selecting a node we've removed
                    if (payloadNode == incSelectedNode()) {
                        incSelectNode(null);
                    }

                    incDeleteChildWithHistory(payloadNode);
                    
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


