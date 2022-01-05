/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.inspector;
import creator.core;
import creator.panels;
import creator.widgets;
import creator.utils;
import creator.windows;
import creator;
import inochi2d;
import std.string;
import std.algorithm.searching;
import std.algorithm.mutation;
import std.conv;

import creator.actions.node;

/**
    The inspector panel
*/
class InspectorPanel : Panel {
private:
    void handleTRS(Node node) {
        float adjustSpeed = 1;
        // if (igIsKeyDown(igGetKeyIndex(ImGuiKeyModFlags_Shift))) {
        //     adjustSpeed = 0.1;
        // }

        ImVec2 avail;
        igGetContentRegionAvail(&avail);

        float fontSize = 16;

        //
        // Translation
        //
        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Translation");
        igPushItemWidth((avail.x-4f-(fontSize*3f))/3f);

            // Translation X
            igPushID(0);
            if (incDragFloat("translation_x", &node.localTransform.translation.vector[0], adjustSpeed, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat)) {
                incActionPush(
                    new NodeValueChangeAction!(Node, float, "X")(
                        node, 
                        incGetDragFloatInitialValue("translation_x"),
                        node.localTransform.translation.vector[0],
                        &node.localTransform.translation.vector[0]
                    )
                );
            }
            igPopID();

            if (incLockButton(&node.localTransform.lockTranslationX, "tra_x")) {
                incActionPush(
                    new NodeValueChangeAction!(Node, bool, "Lock Translate X")(
                        node, 
                        !node.localTransform.lockTranslationX,
                        node.localTransform.lockTranslationX,
                        &node.localTransform.lockTranslationX
                    )
                );
            }

            igSameLine(0, 4);

            // Translation Y
            igPushID(1);
                if (incDragFloat("translation_y", &node.localTransform.translation.vector[1], adjustSpeed, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat)) {
                    incActionPush(
                        new NodeValueChangeAction!(Node, float, "Y")(
                            node, 
                            incGetDragFloatInitialValue("translation_y"),
                            node.localTransform.translation.vector[1],
                            &node.localTransform.translation.vector[1]
                        )
                    );
                }
            igPopID();
            
            if (incLockButton(&node.localTransform.lockTranslationY, "tra_y")) {
                incActionPush(
                    new NodeValueChangeAction!(Node, bool, "Lock Translate Y")(
                        node, 
                        !node.localTransform.lockTranslationY,
                        node.localTransform.lockTranslationY,
                        &node.localTransform.lockTranslationY
                    )
                );
            }

            igSameLine(0, 4);

            // Translation Z
            igPushID(2);
                if (incDragFloat("translation_z", &node.localTransform.translation.vector[2], adjustSpeed, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat)) {
                    incActionPush(
                        new NodeValueChangeAction!(Node, float, "Z")(
                            node, 
                            incGetDragFloatInitialValue("translation_z"),
                            node.localTransform.translation.vector[2],
                            &node.localTransform.translation.vector[2]
                        )
                    );
                }
            igPopID();
            
            if (incLockButton(&node.localTransform.lockTranslationZ, "tra_z")) {
                incActionPush(
                    new NodeValueChangeAction!(Node, bool, "Lock Translate Z")(
                        node, 
                        !node.localTransform.lockTranslationZ,
                        node.localTransform.lockTranslationZ,
                        &node.localTransform.lockTranslationZ
                    )
                );
            }

        igPopItemWidth();


        //
        // Rotation
        //
        igSpacing();
        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Rotation");
        igPushItemWidth((avail.x-4f-(fontSize*3f))/3f);

            // Rotation X
            igPushID(3);
                if (incDragFloat("rotation_x", &node.localTransform.rotation.vector[0], adjustSpeed/100, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat)) {
                    incActionPush(
                        new NodeValueChangeAction!(Node, float, "Rotation X")(
                            node, 
                            incGetDragFloatInitialValue("rotation_x"),
                            node.localTransform.rotation.vector[0],
                            &node.localTransform.rotation.vector[0]
                        )
                    );
                }
            igPopID();

            if (incLockButton(&node.localTransform.lockRotationX, "rot_x")) {
                incActionPush(
                    new NodeValueChangeAction!(Node, bool, "Lock Rotation X")(
                        node, 
                        !node.localTransform.lockRotationX,
                        node.localTransform.lockRotationX,
                        &node.localTransform.lockRotationX
                    )
                );
            }
            
            igSameLine(0, 4);

            // Rotation Y
            igPushID(4);
                if (incDragFloat("rotation_y", &node.localTransform.rotation.vector[1], adjustSpeed/100, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat)) {
                    incActionPush(
                        new NodeValueChangeAction!(Node, float, "Rotation Y")(
                            node, 
                            incGetDragFloatInitialValue("rotation_y"),
                            node.localTransform.rotation.vector[1],
                            &node.localTransform.rotation.vector[1]
                        )
                    );
                }
            igPopID();
            
            if (incLockButton(&node.localTransform.lockRotationY, "rot_y")) {
                incActionPush(
                    new NodeValueChangeAction!(Node, bool, "Lock Rotation Y")(
                        node, 
                        !node.localTransform.lockRotationY,
                        node.localTransform.lockRotationY,
                        &node.localTransform.lockRotationY
                    )
                );
            }

            igSameLine(0, 4);

            // Rotation Z
            igPushID(5);
                if (incDragFloat("rotation_z", &node.localTransform.rotation.vector[2], adjustSpeed/100, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat)) {
                    incActionPush(
                        new NodeValueChangeAction!(Node, float, "Rotation Z")(
                            node, 
                            incGetDragFloatInitialValue("rotation_z"),
                            node.localTransform.rotation.vector[2],
                            &node.localTransform.rotation.vector[2]
                        )
                    );
                }
            igPopID();
            
            if (incLockButton(&node.localTransform.lockRotationZ, "rot_z")) {
                incActionPush(
                    new NodeValueChangeAction!(Node, bool, "Lock Rotation Z")(
                        node, 
                        !node.localTransform.lockRotationZ,
                        node.localTransform.lockRotationZ,
                        &node.localTransform.lockRotationZ
                    )
                );
            }

        igPopItemWidth();

        avail.x += igGetFontSize();

        //
        // Scaling
        //
        igSpacing();
        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Scale");
        igPushItemWidth((avail.x-14f-(fontSize*2f))/2f);
            
            // Scale X
            igPushID(6);
                if (incDragFloat("scale_x", &node.localTransform.scale.vector[0], adjustSpeed/100, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat)) {
                    incActionPush(
                        new NodeValueChangeAction!(Node, float, "Scale X")(
                            node, 
                            incGetDragFloatInitialValue("scale_x"),
                            node.localTransform.scale.vector[0],
                            &node.localTransform.scale.vector[0]
                        )
                    );
                }
            igPopID();
            if (incLockButton(&node.localTransform.lockScaleX, "sca_x")) {
                incActionPush(
                    new NodeValueChangeAction!(Node, bool, "Lock Scale X")(
                        node, 
                        !node.localTransform.lockScaleX,
                        node.localTransform.lockScaleX,
                        &node.localTransform.lockScaleX
                    )
                );
            }

            igSameLine(0, 4);

            // Scale Y
            igPushID(7);
                if (incDragFloat("scale_y", &node.localTransform.scale.vector[1], adjustSpeed/100, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat)) {
                    incActionPush(
                        new NodeValueChangeAction!(Node, float, "Scale Y")(
                            node, 
                            incGetDragFloatInitialValue("scale_y"),
                            node.localTransform.scale.vector[1],
                            &node.localTransform.scale.vector[1]
                        )
                    );
                }
            igPopID();
            if (incLockButton(&node.localTransform.lockScaleY, "sca_y")) {
                incActionPush(
                    new NodeValueChangeAction!(Node, bool, "Lock Scale Y")(
                        node, 
                        !node.localTransform.lockScaleY,
                        node.localTransform.lockScaleY,
                        &node.localTransform.lockScaleY
                    )
                );
            }

        igPopItemWidth();

        igSpacing();
        igSpacing();

        ImVec2 textLength = incMeasureString("Snap to Pixel");
        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Snap to Pixel");
        incSpacer(ImVec2(-12, 1));
        if (incLockButton(&node.localTransform.pixelSnap, "pix_lk")) {
            incActionPush(
                new NodeValueChangeAction!(Node, bool, "Snap to Pixel")(
                    node, 
                    !node.localTransform.pixelSnap,
                    node.localTransform.pixelSnap,
                    &node.localTransform.pixelSnap
                )
            );
        }
        
        // Padding
        igSpacing();
        igSpacing();
    }

    void handleDrawableNodes(Drawable node) {
        igText("Drawable");
        igSeparator();

        igPushStyleVar_Vec2(ImGuiStyleVar.FramePadding, ImVec2(8, 8));
            igSpacing();
            igSpacing();

            if (igButton("")) {
                // TODO: Switch to editing that mesh
                incSetEditMode(EditMode.VertexEdit);
                incSelectNode(node);
                incFocusCamera(node);
            }
            incTooltip("Edit Mesh");

            igSpacing();
            igSpacing();
        igPopStyleVar();
    }

    void handlePartNodes(Node node) {
        if (Part partNode = cast(Part)node) {

            if (!partNode.getMesh().isReady()) { 
                igText("Part");
                igSeparator();
                igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Cannot inspect an unmeshed part");
                return;
            }

            igText("Part");
            igSeparator();

            igSliderFloat("Opacity", &partNode.opacity, 0, 1f, "%0.2f");
            igSpacing();
            igSpacing();

            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Masks");
            igSpacing();

            // MASK MODE
            if (igBeginCombo("Mode", partNode.maskingMode ? "Dodge" : "Mask")) {

                if (igSelectable("Mask", partNode.maskingMode == MaskingMode.Mask)) {
                    partNode.maskingMode = MaskingMode.Mask;
                }
                if (igSelectable("Dodge", partNode.maskingMode == MaskingMode.DodgeMask)) {
                    partNode.maskingMode = MaskingMode.DodgeMask;
                }
                igEndCombo();
            }

            // Sensitivity slider
            igSliderFloat("Threshold", &partNode.maskAlphaThreshold, 0.0, 1.0, "%.2f");

            // MASKED BY

            if (igBeginListBox("Masked By", ImVec2(0, 128))) {
                foreach(i, masker; partNode.mask) {
                    igPushID(cast(int)i);
                        igText(masker.name.toStringz);
                        if(igBeginDragDropSource(ImGuiDragDropFlags.SourceAllowNullID)) {
                            igSetDragDropPayload("_MASKITEM", cast(void*)&masker, (&masker).sizeof, ImGuiCond.Always);
                            igText(masker.name.toStringz);
                            igEndDragDropSource();
                        }
                    igPopID();
                }
                igEndListBox();
            }

            if(igBeginDragDropTarget()) {
                ImGuiPayload* payload = igAcceptDragDropPayload("_PUPPETNTREE");
                if (payload !is null) {
                    if (Drawable payloadDrawable = cast(Drawable)*cast(Node*)payload.Data) {

                        // Make sure we don't mask against ourselves as well as don't double mask
                        if (payloadDrawable != partNode && !partNode.mask.canFind(payloadDrawable)) {
                            partNode.mask ~= payloadDrawable;
                        }
                    }
                }
                
                igEndDragDropTarget();
            }

            igButton("ー", ImVec2(0, 0));
            if(igBeginDragDropTarget()) {
                ImGuiPayload* payload = igAcceptDragDropPayload("_MASKITEM");
                if (payload !is null) {
                    if (Drawable payloadDrawable = cast(Drawable)*cast(Node*)payload.Data) {
                        foreach(i; 0..partNode.mask.length) {
                            if (payloadDrawable.uuid == partNode.mask[i].uuid) {
                                partNode.mask = partNode.mask.remove(i);
                                break;
                            }
                        }
                    }
                }
                igEndDragDropTarget();
            }
        
            // Padding
            igSpacing();
            igSpacing();
        }
    }

protected:
    override
    void onUpdate() {
        auto nodes = incSelectedNodes();
        if (nodes.length == 1) {
            Node node = nodes[0];
            if (node !is null) {
                igPushID(node.uuid);
                    string typeString = "%s\0".format(incTypeIdToIcon(node.typeId()));
                    auto len = incMeasureString(typeString);
                    incInputText("", node.name);
                    igSameLine(0, 0);
                    incDummy(ImVec2(-(len.x-14), len.y));
                    igSameLine(0, 0);
                    igText(typeString.ptr);
                igPopID();
                igSeparator();

                handleTRS(node);

                igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Sorting");
                float zsortV = node.relZSort;
                if (igInputFloat("ZSort", &zsortV, 0.01, 0.05, "%0.2f")) {
                    node.zSort = zsortV;
                }

                // If the node has a mesh allow editing it
                if (Drawable drawable = cast(Drawable)node) {

                    // Padding
                    igSpacing();
                    igSpacing();
                    igSpacing();
                    igSpacing();
                    handleDrawableNodes(drawable);
                }

                if (node.typeId == "Part") {

                    // Padding
                    igSpacing();
                    igSpacing();
                    igSpacing();
                    igSpacing();
                    handlePartNodes(node);
                }
            } 
        } else if (nodes.length == 0) {
            igText("No nodes selected...");
        } else {
            igText("Can only inspect a single node...");
        }
    }

public:
    this() {
        super("Inspector", true);
    }
}

/**
    Generate logger frame
*/
mixin incPanel!InspectorPanel;


