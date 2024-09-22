/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.nodes;
import creator.viewport.vertex;
import creator.widgets.dragdrop;
import creator.actions;
import creator.panels;
import creator.ext;
import creator;
import creator.widgets;
import creator.ext;
import creator.core;
import creator.utils;
import inochi2d;
import std.string;
import std.format;
import std.conv;
import i18n;

enum SelectState {
    Init, Started, Ended
}

struct SelectStateData {
    SelectState state;
    Node lastClick;
    Node shiftSelect;

    // tracking for closed nodes
    bool hasRenderedLastClick;
    bool hasRenderedShiftSelect;
}

/**
    The Nodes Tree Panel
*/
class NodesPanel : Panel {
private:
    string filter;
    bool[uint] filterResult;

    SelectStateData nextSelectState;
    SelectStateData curSelectState;
    Node[] rangeSelectNodes;
    bool selectStateUpdate = false;

protected:
    /**
        track the last click and shift select if they are rendered
    */
    void trackingRenderedNode(ref Node node) {
        if (nextSelectState.lastClick is node)
            nextSelectState.hasRenderedLastClick = true;

        if (nextSelectState.shiftSelect is node)
            nextSelectState.hasRenderedShiftSelect = true;
    }

    void startTrackingRenderedNodes() {
        nextSelectState.hasRenderedLastClick = false;
        nextSelectState.hasRenderedShiftSelect = false;
    }

    void endTrackingRenderedNodes() {
        if (!nextSelectState.hasRenderedLastClick && nextSelectState.lastClick !is null) {
            nextSelectState.lastClick = null;
            nextSelectState.shiftSelect = null;
            selectStateUpdate = true;
        }

        if (!nextSelectState.hasRenderedShiftSelect && nextSelectState.shiftSelect !is null) {
            nextSelectState.shiftSelect = null;
            selectStateUpdate = true;
        }
    }

    void treeSetEnabled(Node n, bool enabled) {
        n.enabled = enabled;
        foreach(child; n.children) {
            treeSetEnabled(child, enabled);
        }
    }

    void recalculateNodeOrigin(Node node, bool recursive = true) {
        auto mgroup = cast(MeshGroup)node;
        auto drawable = cast(Drawable)node;

        if (recursive) {
            foreach (child; node.children) {
                recalculateNodeOrigin(child, recursive);
            }
        }
        if (mgroup !is null || drawable is null) {
            vec4 bounds;
            vec4[] childTranslations;
            if (node.children.length > 0) {
                bounds = node.children[0].getCombinedBounds();
                foreach (child; node.children) {
                    auto cbounds = child.getCombinedBounds();
                    bounds.x = min(bounds.x, cbounds.x);
                    bounds.y = min(bounds.y, cbounds.y);
                    bounds.z = max(bounds.z, cbounds.z);
                    bounds.w = max(bounds.w, cbounds.w);
                    childTranslations ~= child.transform.matrix() * vec4(0, 0, 0, 1);
                }
            } else {
                bounds = node.transform.translation.xyxy;
            }
            vec2 center = (bounds.xy + bounds.zw) / 2;
            if (node.parent !is null) {
                center = (node.parent.transform.matrix.inverse * vec4(center, 0, 1)).xy;
            }
            auto diff = center - node.localTransform.translation.xy;
            node.localTransform.translation.x = center.x;
            node.localTransform.translation.y = center.y;
            node.transformChanged();
            if (mgroup !is null) {
                foreach (ref v; mgroup.vertices) {
                    v -= diff;
                }
                mgroup.clearCache();
            }
            foreach (i, child; node.children) {
                child.localTransform.translation = (node.transform.matrix.inverse * childTranslations[i]).xyz;
                child.transformChanged();
            }
        }
    }

    void nodeActionsPopup(bool isRoot = false)(Node n) {
        if (igIsItemClicked(ImGuiMouseButton.Right)) {
            igOpenPopup("NodeActionsPopup");
        }

        if (igBeginPopup("NodeActionsPopup")) {
            
            auto selected = incSelectedNodes();
            
            if (igBeginMenu(__("Add"), true)) {

                incText(incTypeIdToIcon("Node"));
                igSameLine(0, 2);
                if (igMenuItem(__("Node"), "", false, true)) incAddChildWithHistory(new Node(cast(Node)null), n);
                
                incText(incTypeIdToIcon("Mask"));
                igSameLine(0, 2);
                if (igMenuItem(__("Mask"), "", false, true)) {
                    MeshData empty;
                    incAddChildWithHistory(new Mask(empty, cast(Node)null), n);
                }
                
                incText(incTypeIdToIcon("Composite"));
                igSameLine(0, 2);
                if (igMenuItem(__("Composite"), "", false, true)) {
                    incAddChildWithHistory(new Composite(cast(Node)null), n);
                }
                
                incText(incTypeIdToIcon("SimplePhysics"));
                igSameLine(0, 2);
                if (igMenuItem(__("Simple Physics"), "", false, true)) incAddChildWithHistory(new SimplePhysics(cast(Node)null), n);

                
                incText(incTypeIdToIcon("Camera"));
                igSameLine(0, 2);
                if (igMenuItem(__("Camera"), "", false, true)) incAddChildWithHistory(new ExCamera(cast(Node)null), n);

                incText(incTypeIdToIcon("MeshGroup"));
                igSameLine(0, 2);
                if (igMenuItem(__("MeshGroup"), "", false, true)) incAddChildWithHistory(new MeshGroup(cast(Node)null), n);

                igEndMenu();
            }

            static if (!isRoot) {

                // Edit mesh option for drawables
                if (Drawable d = cast(Drawable)n) {
                    if (!incArmedParameter()) {
                        if (igMenuItem(__("Edit Mesh"))) {
                            incVertexEditStartEditing(d);
                        }
                    }
                }
                
                if (igMenuItem(n.enabled ? /* Option to hide the node (and subnodes) */ __("Hide") :  /* Option to show the node (and subnodes) */ __("Show"))) {
                    n.enabled = !n.enabled;
                }

                if (igMenuItem(__("Delete"), "", false, !isRoot)) {

                    if (selected.length > 1) {
                        incDeleteChildrenWithHistory(selected);
                        incSelectNode(null);
                    } else {

                        // Make sure we don't keep selecting a node we've removed
                        if (incNodeInSelection(n)) {
                            incSelectNode(null);
                        }

                        incDeleteChildWithHistory(n);
                    }
                    
                    // Make sure we don't keep selecting a node we've removed
                    incSelectNode(null);
                }
                

                if (igBeginMenu(__("More Info"), true)) {
                    if (selected.length > 1) {
                        foreach(sn; selected) {
                            
                            // %s is the name of the node in the More Info menu
                            // %u is the UUID of the node in the More Info menu
                            incText(_("%s ID: %u").format(sn.name, sn.uuid));

                            if (ExPart exp = cast(ExPart)sn) {
                                incText(_("%s Layer: %s").format(exp.name, exp.layerPath));
                            }
                        }
                    } else {
                        // %u is the UUID of the node in the More Info menu
                        incText(_("ID: %u").format(n.uuid));

                        if (ExPart exp = cast(ExPart)n) {
                            incText(_("Layer: %s").format(exp.layerPath));
                        }
                    }

                    igEndMenu();
                }

                if (igMenuItem(__("Recalculate origin"), "", false, true)) {
                    recalculateNodeOrigin(n, true);
                }
            }
            igEndPopup();
        }
    }

    void toggleSelect(ref Node n) {
        if (incNodeInSelection(n))
            incRemoveSelectNode(n);
        else
            incAddSelectNode(n);

        rangeSelectNodes = [];
    }

    /**
        Select a range of nodes, it should be called when the user is holding shift key and click on a node
    */
    void selectRange(ref Node n) {
        if (curSelectState.lastClick is null) {
            nextSelectState.lastClick = n;
            incSelectNode(n);
            return;
        }

        // recover rangeSelectNodes if selected
        foreach(node; rangeSelectNodes) {
            incRemoveSelectNode(node);
        }
        rangeSelectNodes = [];

        nextSelectState.shiftSelect = n;
    }

    /**
        Handle range selection, this function should be called in the treeAddNode or recursive function
        we assume caller would traverse the tree nodes in order
    */
    void handleRangeSelect(ref Node n) {
        if (curSelectState.state == SelectState.Ended ||
            curSelectState.lastClick is null ||
            curSelectState.shiftSelect is null
            ) {
            return;
        }

        if (n == curSelectState.lastClick || n == curSelectState.shiftSelect) {
            switch(curSelectState.state) {
                case SelectState.Init:
                    curSelectState.state = SelectState.Started;
                    break;
                case SelectState.Started:
                    curSelectState.state = SelectState.Ended;
                    nextSelectState.shiftSelect = null;
                    break;
                default:
                    break;
            }
        }

        if (curSelectState.state != SelectState.Init && !incNodeInSelection(n)) {
            incAddSelectNode(n);
        }

        if (curSelectState.state != SelectState.Init && n != curSelectState.lastClick) {
            rangeSelectNodes ~= n;
        }
    }

    void treeAddNode(bool isRoot = false)(ref Node n) {
        if (n.uuid !in filterResult)
            return;

        if (!filterResult[n.uuid])
            return;

        igTableNextRow();

        auto io = igGetIO();

        // // Draw Enabler for this node first
        // igTableSetColumnIndex(1);
        // igPushFont(incIconFont());
        //     incText(n.enabled ? "\ue8f4" : "\ue8f5");
        // igPopFont();


        // Prepare node flags
        ImGuiTreeNodeFlags flags;
        if (n.children.length == 0) flags |= ImGuiTreeNodeFlags.Leaf;
        flags |= ImGuiTreeNodeFlags.DefaultOpen;
        flags |= ImGuiTreeNodeFlags.OpenOnArrow;


        // Then draw the node tree index
        igTableSetColumnIndex(0);
        igSetNextItemWidth(8);
        bool open = igTreeNodeEx(cast(void*)n.uuid, flags, "");

            // Show node entry stuff
            igSameLine(0, 4);

            auto selectedNodes = incSelectedNodes();
            igPushID(n.uuid);
                    bool selected = incNodeInSelection(n);

                    igBeginGroup();
                        igIndent(4);

                        // Type Icon
                        static if (!isRoot) {
                            incNodeIconButton(n);
                        } else {
                            incText("");
                        }
                        igSameLine(0, 2);

                        handleRangeSelect(n);

                        // Selectable
                        if (igSelectable(isRoot ? __("Puppet") : n.name.toStringz, selected, ImGuiSelectableFlags.None, ImVec2(0, 0))) {
                            switch(incEditMode) {
                                default:
                                    selectStateUpdate = true;
                                    if (!io.KeyShift)
                                        nextSelectState.lastClick = n;

                                    if (io.KeyCtrl && !io.KeyShift)
                                        toggleSelect(n);
                                    else if (!io.KeyCtrl && io.KeyShift)
                                        selectRange(n);
                                    else if (selected && selectedNodes.length == 1)
                                        incFocusCamera(n);
                                    else
                                        incSelectNode(n);
                                    break;
                            }
                        }

                        trackingRenderedNode(n);

                        this.nodeActionsPopup!isRoot(n);
                    igEndGroup();

                    static if (!isRoot) {
                        if(igBeginDragDropSource(ImGuiDragDropFlags.SourceAllowNullID)) {
                            igSetDragDropPayload("_PUPPETNTREE", cast(void*)&n, (&n).sizeof, ImGuiCond.Always);
                            if (selectedNodes.length > 1) {
                                incDragdropNodeList(selectedNodes);
                            } else {
                                incDragdropNodeList(n);
                            }
                            igEndDragDropSource();
                        }
                    }
            igPopID();

            if(igBeginDragDropTarget()) {
                const(ImGuiPayload)* payload = igAcceptDragDropPayload("_PUPPETNTREE");
                if (payload !is null) {
                    Node payloadNode = *cast(Node*)payload.Data;
                    
                    try {
                        if (selectedNodes.length > 1) incMoveChildrenWithHistory(selectedNodes, n, 0);
                        else incMoveChildWithHistory(payloadNode, n, 0);
                    } catch (Exception ex) {
                        incDialog(__("Error"), ex.msg);
                    }

                    if (open) igTreePop();
                    igEndDragDropTarget();
                    return;
                }
                igEndDragDropTarget();
            }

        if (open) {
            // Draw children
            foreach(i, child; n.children) {
                if (child.uuid !in filterResult)
                    continue;

                if (!filterResult[child.uuid])
                    continue;

                igPushID(cast(int)i);
                    igTableNextRow();
                    igTableSetColumnIndex(0);
                    igInvisibleButton("###TARGET", ImVec2(128, 4));

                    if(igBeginDragDropTarget()) {
                        const(ImGuiPayload)* payload = igAcceptDragDropPayload("_PUPPETNTREE");
                        if (payload !is null) {
                            Node payloadNode = *cast(Node*)payload.Data;
                            
                            try {
                                if (selectedNodes.length > 1) incMoveChildrenWithHistory(selectedNodes, n, i);
                                else incMoveChildWithHistory(payloadNode, n, i);
                            } catch (Exception ex) {
                                incDialog(__("Error"), ex.msg);
                            }
                            
                            igEndDragDropTarget();
                            igPopID();
                            igTreePop();
                            return;
                        }
                        igEndDragDropTarget();
                    }
                igPopID();

                treeAddNode(child);
            }
            igTreePop();
        }
        

    }

    bool filterNodes(Node n) {
        import std.algorithm;
        bool result = false;
        if (n.name.toLower.canFind(filter)) {
            result = true;
        } else if (n.children.length == 0) {
            result = false;
        }

        foreach(child; n.children) {
            result |= filterNodes(child);
        }

        filterResult[n.uuid] = result;
        return result;
    }

    override
    void onUpdate() {

        incModelEditorCommonHotKeys();

        if (incEditMode == EditMode.VertexEdit) {
            incLabelOver(_("In vertex edit mode..."), ImVec2(0, 0), true);
            return;
        }

        if (igBeginChild("NodesMain", ImVec2(0, -30), false)) {
            
            // temp variables
            float scrollDelta = 0;
            auto avail = incAvailableSpace();

            // Get the screen position of our node window
            // as well as the size for the drag/drop scroll
            ImVec2 screenPos;
            igGetCursorScreenPos(&screenPos);
            ImRect crect = ImRect(
                screenPos,
                ImVec2(screenPos.x+avail.x, screenPos.y+avail.y)
            );

            // Handle figuring out whether the user is trying to scroll the list via drag & drop
            // We're only peeking in to the contents of the payload.
            incBeginDragDropFake();
                auto data = igAcceptDragDropPayload("_PUPPETNTREE", ImGuiDragDropFlags.AcceptPeekOnly | ImGuiDragDropFlags.SourceAllowNullID);
                if (igIsMouseDragging(ImGuiMouseButton.Left) && data && data.Data) {
                    ImVec2 mousePos;
                    igGetMousePos(&mousePos);

                    // If mouse is inside the window
                    if (mousePos.x > crect.Min.x && mousePos.x < crect.Max.x) {
                        float scrollSpeed = (4*60)*deltaTime();

                        if (mousePos.y < crect.Min.y+32 && mousePos.y >= crect.Min.y) scrollDelta = -scrollSpeed;
                        if (mousePos.y > crect.Max.y-32 && mousePos.y <= crect.Max.y) scrollDelta = scrollSpeed;
                    }
                }
            incEndDragDropFake();

            igPushStyleVar(ImGuiStyleVar.CellPadding, ImVec2(4, 1));
            igPushStyleVar(ImGuiStyleVar.IndentSpacing, 14);

            igPushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 8));
                if (incInputText("Node Filter", filter)) {
                    filter = filter.toLower;
                    filterResult.clear();
                }

                incTooltip(_("Filter, search for specific nodes"));
            igPopStyleVar();

            // filter nodes
            filterNodes(incActivePuppet.root);

            auto frameColor = *igGetStyleColorVec4(ImGuiCol.FrameBg);
            igPushStyleColor_Vec4(ImGuiCol.ChildBg, frameColor);
                if (igBeginTable("NodesContent", 2, ImGuiTableFlags.ScrollX, ImVec2(0, -8), 0)) {
                    auto window = igGetCurrentWindow();
                    igSetScrollY(window.Scroll.y+scrollDelta);
                    igTableSetupColumn("Nodes", ImGuiTableColumnFlags.WidthFixed, 0, 0);
                    //igTableSetupColumn("Visibility", ImGuiTableColumnFlags_WidthFixed, 32, 1);
                    
                    if (incEditMode == EditMode.ModelEdit) {
                        if (selectStateUpdate) {
                            curSelectState = nextSelectState;
                            curSelectState.state = SelectState.Init;
                            selectStateUpdate = false;
                        }

                        startTrackingRenderedNodes();
                        igPushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(4, 4));
                            treeAddNode!true(incActivePuppet.root);
                        igPopStyleVar();
                        endTrackingRenderedNodes();
                    }

                    igEndTable();
                }
                if (igIsItemClicked(ImGuiMouseButton.Left)) {
                    incSelectNode(null);
                }
            igPopStyleColor(1);
            igPopStyleVar();
            igPopStyleVar();
        }
        igEndChild();

        igSeparator();
        igSpacing();
        
        if (incEditMode() == EditMode.ModelEdit) {
            auto selected = incSelectedNodes();
            if (igButton("", ImVec2(24, 24))) {
                foreach(payloadNode; selected) incDeleteChildWithHistory(payloadNode);
            }

            if(igBeginDragDropTarget()) {
                const(ImGuiPayload)* payload = igAcceptDragDropPayload("_PUPPETNTREE");
                if (payload !is null) {
                    Node payloadNode = *cast(Node*)payload.Data;

                    if (selected.length > 1) {
                        foreach(pn; selected) incDeleteChildrenWithHistory(selected);
                        incSelectNode(null);
                    } else {

                        // Make sure we don't keep selecting a node we've removed
                        if (incNodeInSelection(payloadNode)) {
                            incSelectNode(null);
                        }

                        incDeleteChildWithHistory(payloadNode);
                    }
                    
                    igPopFont();
                    return;
                }
                igEndDragDropTarget();
            }
        }

    }

public:

    this() {
        super("Nodes", _("Nodes"), true);
        flags |= ImGuiWindowFlags.NoScrollbar;
        activeModes = EditMode.ModelEdit;
    }
}

/**
    Generate nodes frame
*/
mixin incPanel!NodesPanel;


