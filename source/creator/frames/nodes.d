module creator.frames.nodes;
import creator.frames;
import creator;
import bindbc.imgui;
import inochi2d;
import std.string;

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
        igBeginChildStr("##nolabel", ImVec2(0, avail.y-24), false, ImGuiWindowFlags_HorizontalScrollbar);
            treeAddNode!true(incActivePuppet.root);
        igEndChild();
        if (igIsItemClicked(ImGuiMouseButton_Left)) {
            incSelectNode(null);
        }
        
        if (igButton("Trash", ImVec2(0, 0))) {
            Node payloadNode = incSelectedNode();
            payloadNode.parent = null;
            destroy(payloadNode);
            incActivePuppet().rescanNodes();
        }
        if(igBeginDragDropTarget()) {
            ImGuiPayload* payload = igAcceptDragDropPayload("_PUPPETNTREE", 0);
            if (payload !is null) {
                Node payloadNode = *cast(Node*)payload.Data;
                payloadNode.parent = null;
                destroy(payloadNode);
                incActivePuppet().rescanNodes();
                
                return;
            }
            igEndDragDropTarget();
        }
    }

public:

    this() {
        super("Nodes");
        this.visible = true;
    }
}

/**
    Generate nodes frame
*/
mixin incFrame!NodesFrame;


