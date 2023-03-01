/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.flipconfig;
import creator.windows;
import creator.core;
import creator.widgets;
import creator;
import creator.ext;
import std.string;
import creator.utils.link;
import inochi2d;
import i18n;
import psd;
import std.uni : toLower;
import std.stdio : File;
import std.string;
import std.algorithm.searching : canFind, countUntil;
import std.algorithm.mutation : remove;

/**
    Binding between layer and node
*/

class FlipPair {
    Node[2] parts;
    string name;
    this(Node[2] parts, string name) {
        this.parts = parts;
        this.name = name;
        this.update();
    }
    void flip() {}
    void update () {
        name = "%s <-> %s".format((parts[0] !is null)? parts[0].name: "", (parts[1] !is null)? parts[1].name: "");
    }
};

private {
    FlipPair[] flipPairs;
    Puppet activePuppet = null;
}

FlipPair[] incGetFlipPairs() {
    if (incActivePuppet() != activePuppet) {
        activePuppet = incActivePuppet();
        flipPairs.length = 0;
    }
    return flipPairs;
}

FlipPair incGetFlipPairFor(Node node) {
    foreach (pair; flipPairs) {
        if (pair.parts[0].uuid == node.uuid || pair.parts[1].uuid == node.uuid) {
            return pair;
        }
    }
    return null;
}

class FlipPairWindow : Window {
private:

    string nodeFilter;
    string part1Pattern;
    string part2Pattern;

    enum PreviewSize = 128f;
    Node[] nodes;
    ulong[uint] map;
    FlipPair[] pairs;

    FlipPair* active = null;

    void apply() {
        flipPairs = pairs;
    }


    void autoPair(string part1, string part2) {
        foreach(i, ref Node node; nodes) {
            string targetName = node.name.replace(part1, part2);
            if (node.uuid in map) continue;
            foreach (ref Node node2; nodes) {
                if (node.name.indexOf(part1) >= 0 && node2.name == targetName) {
                    if (node2.uuid != node.uuid) {
                        pairs ~= new FlipPair([node, node2], "");
                        map[node.uuid] = pairs.length - 1;
                        map[node2.uuid] = pairs.length - 1;
                    }
                    break;
                }
            }
        }
    }


    vec4 previewImage(Part part, ImVec2 centerPos, float previewSize, ImVec2 uv0 = ImVec2(0, 0), ImVec2 uv1 = ImVec2(1, 1), ImVec4 tintColor=ImVec4(1, 1, 1, 1)) {
        if (part.textures[0].width < previewSize && part.textures[0].height < previewSize)
            previewSize = max(part.textures[0].width, part.textures[0].height);

        float widthScale = previewSize / cast(float)part.textures[0].width;
        float heightScale = previewSize / cast(float)part.textures[0].height;
        float fscale = min(widthScale, heightScale);
        
        vec4 bounds = vec4(0, 0, part.textures[0].width*fscale, part.textures[0].height*fscale);
        if (widthScale > heightScale) bounds.x = (previewSize-bounds.z)/2;
        else if (widthScale < heightScale) bounds.y = (previewSize-bounds.w)/2;

        ImVec2 tl;
        igGetCursorPos(&tl);

        igItemSize(ImVec2(PreviewSize, PreviewSize));

        igSetCursorPos(
            ImVec2(tl.x+centerPos.x-previewSize/2+bounds.x, tl.y+centerPos.y-previewSize/2+bounds.y)
        );

        igImage(
            cast(void*)part.textures[0].getTextureId(), 
            ImVec2(bounds.z, bounds.w), uv0, uv1, tintColor
        );
        return bounds;

    }

    void treeView() {

        import std.algorithm.searching : canFind;
        foreach(i, ref Node node; nodes) {
            if (nodeFilter.length > 0 && !node.name.toLower.canFind(nodeFilter.toLower)) continue;
            if (node.uuid in map) continue;

            igPushID(cast(int)i);

            igSelectable(node.cName, false, ImGuiSelectableFlagsI.SpanAvailWidth);

            if(igBeginDragDropSource(ImGuiDragDropFlags.SourceAllowNullID)) {
                igSetDragDropPayload("__PAIRING", cast(void*)&node, (&node).sizeof, ImGuiCond.Always);
                igText(node.cName);
                igEndDragDropSource();
            }

            // Incredibly cursed preview image
            if (igIsItemHovered()) {
                igBeginTooltip();
                    incText(node.name);
                    // Calculate render size
                    if (auto part = cast(Part)node) {
                        vec4 bounds = previewImage(part, ImVec2(PreviewSize/2, PreviewSize/2), PreviewSize);
                    }
                igEndTooltip();
            }
            igPopID();
        }

    }

    void pairView() {

        import std.stdio;
        ImGuiStyle* style = igGetStyle();
        int deleted = -1;

        foreach(i, ref FlipPair pair; pairs) {

            igPushID(cast(int)i);

            igTableNextRow();
            igTableNextColumn();
            igPushStyleColor(ImGuiCol.FrameBg, ImVec4(0.5, 0.5, 0.5, 0));
            igSelectable("##%s".format(pair.parts[0].cName).toStringz, active == &pair, ImGuiSelectableFlags.SpanAllColumns);
            if (igIsItemClicked()) {
                active = &pair;
            }
            igSetItemAllowOverlap();
            igPopStyleColor();
            igSameLine();
            igText(pair.parts[0].cName);
            // Only allow reparenting one node
            if(igBeginDragDropTarget()) {
                const(ImGuiPayload)* payload = igAcceptDragDropPayload("__PAIRING");
                if (payload !is null) {
                    Node node = *cast(Node*)payload.Data;

                    FlipPair* targetPair = null;
                    foreach (pair2; pairs) {
                        if (pair2.parts[0].uuid == node.uuid || pair2.parts[1] && pair2.parts[1].uuid == node.uuid) {
                            targetPair = &pair2;
                            break;
                        }
                    }
                    writefln("parts[0]: flippable set=%s, node=%s", targetPair, node);
                    if (targetPair !is null && targetPair != &pair) {
                        if ((*targetPair).parts[0].uuid == node.uuid) {
                            (*targetPair).parts[0] = null;
                        } else {
                            (*targetPair).parts[1] = null;
                        }
                    }
                    pair.parts[0] = node;
                    map[node.uuid] = i;
                    pair.update();
                    writefln("set parts[0]: name=%s", pair.name);

                    igEndDragDropTarget();
                    igPopID();
                    return;
                }
                igEndDragDropTarget();
            }

            igTableNextColumn();
            igText(pair.parts[1]? pair.parts[1].cName: "<< Not assigned >>");
            // Only allow reparenting one node
            if(igBeginDragDropTarget()) {
                const(ImGuiPayload)* payload = igAcceptDragDropPayload("__PAIRING");
                if (payload !is null) {
                    Node node = *cast(Node*)payload.Data;

                    FlipPair* targetPair = null;
                    foreach (pair2; pairs) {
                        if (pair2.parts[0].uuid == node.uuid || pair2.parts[1] && pair2.parts[1].uuid == node.uuid) {
                            targetPair = &pair2;
                            break;
                        }
                    }
                    writefln("pair: flippable set=%s, node=%s", targetPair, node);
                    if (targetPair !is null && targetPair != &pair) {
                        if ((*targetPair).parts[0].uuid == node.uuid) {
                            (*targetPair).parts[0] = null;
                        } else {
                            (*targetPair).parts[1] = null;
                        }
                    }
                    pair.parts[1] = node;
                    map[node.uuid] = i;
                    pair.update();
                    writefln("set parts[1]: name=%s", pair.name);

                    igEndDragDropTarget();
                    igPopID();
                    return;
                }
                igEndDragDropTarget();
            }
            igSameLine(0, 0);
            incDummy(ImVec2(-16, 12));
            igSameLine(0, 0);
            igPushID(cast(int)(i + pairs.length));
            if (igButton("-", ImVec2(16, 16))) {
                deleted = cast(int)i;
            }
            igPopID();
            igPopID();

        }

        if (deleted >= 0) {
            FlipPair pair = pairs[deleted];
            if (pair.parts[0] !is null)
                map.remove(pair.parts[0].uuid);
            if (pair.parts[1] !is null)
                map.remove(pair.parts[1].uuid);
            pairs = pairs.remove(deleted);
        }

        igTableNextRow();
        igTableNextColumn();
        igText(__("< Add new row >"));
    }

protected:

    override
    void onBeginUpdate() {
        igSetNextWindowSizeConstraints(ImVec2(480, 480), ImVec2(float.max, float.max));
        super.onBeginUpdate();
    }

    override
    void onUpdate() {
        ImVec2 space = incAvailableSpace();
        float gapspace = 8;
        float childWidth = (space.x/2);
        float previewSize = min(space.x/3, space.y/3);
        float childHeight = space.y-(28)-(previewSize+gapspace+4);
        float filterWidgetHeight = 26;
        float optionsListHeight = 26;

        igBeginGroup();
            ImVec2 tl;
            igGetCursorPos(&tl);
            igSetCursorPos(
                ImVec2(
                    tl.x+(childWidth-(previewSize/2)),
                    tl.y
                )
            );

            // Preview
            if (igBeginChild("###Preview", ImVec2(previewSize, previewSize), true)) {
                vec4 bounds;               
                if (active !is null) {
                    igGetCursorPos(&tl);
                    if ((*active).parts[0] && cast(Part)(active.parts[0]))
                        bounds = previewImage(cast(Part)(active.parts[0]), ImVec2(previewSize / 2, previewSize / 2), previewSize, ImVec2(0, 0), ImVec2(1, 1), ImVec4(1, 1, 1, 0.6));
                    igSetCursorPos(tl);
                    if ((*active).parts[1] && cast(Part)(active.parts[1]))
                        previewImage(cast(Part)(active.parts[1]), ImVec2(previewSize / 2, previewSize / 2), previewSize, ImVec2(1, 0), ImVec2(0, 1), ImVec4(1, 1, 1, 0.6));
                }

            }
            igEndChild();

            igDummy(ImVec2(0, gapspace));

            // Selection
            if (igBeginChild("###Nodes", ImVec2(childWidth, childHeight))) {
                incInputText("##", childWidth, nodeFilter);

                igBeginListBox("###NodeList", ImVec2(childWidth, childHeight-filterWidgetHeight));
                    treeView();
                igEndListBox();
            }
            igEndChild();

            igSameLine(0, gapspace);

            if (igBeginChild("###Pairs", ImVec2(childWidth, childHeight))) {
                incInputText("##part1", (childWidth - 50) / 2, part1Pattern);
                igSameLine(0, 0);
                if (igButton(__("Pair"), ImVec2(48, 0))) {
                    autoPair(part1Pattern, part2Pattern);
                }
                igSameLine(0, 0);
                incInputText("##part2", (childWidth - 50) / 2, part2Pattern);
                if (igBeginChild("###PairList", ImVec2(childWidth, childHeight-optionsListHeight))) {
                    igBeginTable("###PairsTable", 2, ImGuiTableFlags.RowBg | ImGuiTableFlags.Borders, ImVec2(childWidth-gapspace, childHeight-optionsListHeight));
                        igTableHeader("###PairsTableHeader");
                        igTableSetupColumn("Part 1", ImGuiTableColumnFlags.WidthStretch);
                        igTableSetupColumn("Part 2", ImGuiTableColumnFlags.WidthStretch);
                        igTableHeadersRow();
                        pairView();
                    igEndTable();
                    if(igBeginDragDropTarget()) {
                        const(ImGuiPayload)* payload = igAcceptDragDropPayload("__PAIRING");
                        if (payload !is null) {
                            Node node = *cast(Node*)payload.Data;
                            FlipPair* targetPair = null;
                            foreach (pair; pairs) {
                                if (pair.parts[0].uuid == node.uuid || pair.parts[1] !is null && pair.parts[1].uuid == node.uuid) {
                                    targetPair = &pair;
                                    break;
                                }
                            }

                            if (targetPair is null) {
                                pairs ~= new FlipPair([node, null], null);
                                map[node.uuid] = pairs.length - 1;
                            }
                        }
                        igEndDragDropTarget();
                    }
                }
                igEndChild();

            }
            igEndChild();

        igEndGroup();


        igBeginGroup();
            incDummy(ImVec2(-192, 0));
            igSameLine(0, 0);
            // 
            if (igButton(__("Cancel"), ImVec2(96, 24))) {
                this.close();
                
                igEndGroup();
                return;
            }
            igSameLine(0, 0);
            if (igButton(__("Save"), ImVec2(96, 24))) {
                apply();
                this.close();
                
                igEndGroup();
                return;
            }
        igEndGroup();
    }

    override
    void onClose() {
        import core.memory : GC;
        GC.collect();
        GC.minimize();
    }

public:
    ~this() { }

    this() {
        auto puppet = incActivePuppet();
        nodes = puppet.findNodesType!Node(puppet.root);
        pairs = incGetFlipPairs().dup;
        foreach (i, pair; pairs) {
            if (pair.parts[0] !is null)
                map[pair.parts[0].uuid] = i;
            if (pair.parts[1] !is null)
                map[pair.parts[1].uuid] = i;
        }

        super(_("Flip Pairing"));
    }
}

