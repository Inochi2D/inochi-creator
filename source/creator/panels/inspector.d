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
import creator.medit;
import i18n;

import creator.actions.node;

/**
    The inspector panel
*/
class InspectorPanel : Panel {
private:


protected:
    override
    void onUpdate() {
        auto nodes = incSelectedNodes();
        if (nodes.length == 1) {
            Node node = nodes[0];
            if (node !is null && node != incActivePuppet().root) {

                // Per-edit mode inspector drawers
                switch(incEditMode()) {
                    case EditMode.ModelEdit:
                        incModelModeHeader(node);
                        incInspectorModelTRS(node);

                        // The sorting order ID, which Inochi2D uses to sort
                        // Parts to draw in the user specified order.
                        // negative values = closer to camera
                        // positive values = further away from camera
                        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Sorting"));
                        float zsortV = node.relZSort;
                        if (igInputFloat("ZSort", &zsortV, 0.01, 0.05, "%0.2f")) {
                            node.zSort = zsortV;
                        }

                        // Node Drawable Section
                        if (Drawable drawable = cast(Drawable)node) {

                            // Padding
                            igSpacing();
                            igSpacing();
                            igSpacing();
                            igSpacing();
                            incInspectorModelDrawable(drawable);
                        }

                        // Node Part Section
                        if (Part part = cast(Part)node) {

                            // Padding
                            igSpacing();
                            igSpacing();
                            igSpacing();
                            igSpacing();
                            incInspectorModelPart(part);
                        }
                    
                    break;
                    case EditMode.VertexEdit:
                        incCommonNonEditHeader(node);
                        incInspectorMeshEditDrawable(cast(Drawable)node);
                        break;
                    case EditMode.DeformEdit:
                        incCommonNonEditHeader(node);
                        break;
                    default: assert(0);
                }
            } else incInspectorModelInfo();
        } else if (nodes.length == 0) {
            igText(__("No nodes selected..."));
        } else {
            igText(__("Can only inspect a single node..."));
        }
    }

public:
    this() {
        super("Inspector", _("Inspector"), true);
    }
}

/**
    Generate logger frame
*/
mixin incPanel!InspectorPanel;



private:

//
// COMMON
//

void incCommonNonEditHeader(Node node) {
    // Top level
    igPushID(node.uuid);
        string typeString = "%s\0".format(incTypeIdToIcon(node.typeId()));
        auto len = incMeasureString(typeString);
        igText(node.name.toStringz);
        igSameLine(0, 0);
        incDummy(ImVec2(-(len.x-14), len.y));
        igSameLine(0, 0);
        igText(typeString.ptr);
    igPopID();
    igSeparator();
}

//
//  MODEL MODE
//

void incInspectorModelInfo() {
    auto rootNode = incActivePuppet().root; 
    auto puppet = incActivePuppet();

    // Top level
    igPushID(rootNode.uuid);
        string typeString = "\0";
        auto len = incMeasureString(typeString);
        igText(__("Puppet"));
        igSameLine(0, 0);
        incDummy(ImVec2(-(len.x-14), len.y));
        igSameLine(0, 0);
        igText(typeString.ptr);
    igPopID();
    igSeparator();
    
    igSpacing();
    igSpacing();

    // Version info
    {
        len = incMeasureString(_("Inochi2D Ver."));
        igText(puppet.meta.version_.toStringz);
        igSameLine(0, 0);
        incDummy(ImVec2(-(len.x), len.y));
        igSameLine(0, 0);
        igText(__("Inochi2D Ver."));
    }
    
    igSpacing();
    igSpacing();

    igText(__("General Info"));
    igSeparator();

    igPushID("Name");
        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Name"));
        incTooltip(_("Name of the puppet"));
        incInputText("", puppet.meta.name);
    igPopID();
    igSpacing();

    igPushID("Artists");
        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Artist(s)"));
        incTooltip(_("Artists who've drawn the puppet, seperated by comma"));
        incInputText("", puppet.meta.artist);
    igPopID();
    igSpacing();

    igPushID("Riggers");
        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Rigger(s)"));
        incTooltip(_("Riggers who've rigged the puppet, seperated by comma"));
        incInputText("", puppet.meta.rigger);
    igPopID();
    igSpacing();

    igPushID("Contact");
        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Contact"));
        incTooltip(_("Where to contact the main author of the puppet"));
        incInputText("", puppet.meta.contact);
    igPopID();
    igSpacing();

    igText(__("License Info"));
    igSeparator();

    igPushID("LicenseURL");
        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("License URL"));
        incTooltip(_("Link/URL to license"));
        incInputText("", puppet.meta.licenseURL);
    igPopID();
    igSpacing();

    igPushID("Copyright");
        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Copyright"));
        incTooltip(_("Copyright holder information of the puppet"));
        incInputText("", puppet.meta.copyright);
    igPopID();
    igSpacing();

    igPushID("Origin");
        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Origin"));
        incTooltip(_("Where the model comes from on the internet."));
        incInputText("", puppet.meta.reference);
    igPopID();
}

void incModelModeHeader(Node node) {
    // Top level
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
}

void incInspectorModelTRS(Node node) {
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

    // Translation portion of the transformation matrix.
    igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Translation"));
    igPushItemWidth((avail.x-4f-(fontSize*3f))/3f);

        // Translation X
        igPushID(0);
        if (incDragFloat("translation_x", &node.localTransform.translation.vector[0], adjustSpeed, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat)) {
            incActionPush(
                new NodeValueChangeAction!(Node, float)(
                    "X",
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
                new NodeValueChangeAction!(Node, bool)(
                    _("Lock Translate X"),
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
                    new NodeValueChangeAction!(Node, float)(
                        "Y",
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
                new NodeValueChangeAction!(Node, bool, )(
                    _("Lock Translate Y"),
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
                    new NodeValueChangeAction!(Node, float)(
                        "Z",
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
                new NodeValueChangeAction!(Node, bool)(
                    _("Lock Translate Z"),
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
    
    // Rotation portion of the transformation matrix.
    igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Rotation"));
    igPushItemWidth((avail.x-4f-(fontSize*3f))/3f);

        // Rotation X
        igPushID(3);
            if (incDragFloat("rotation_x", &node.localTransform.rotation.vector[0], adjustSpeed/100, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat)) {
                incActionPush(
                    new NodeValueChangeAction!(Node, float)(
                        _("Rotation X"),
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
                new NodeValueChangeAction!(Node, bool)(
                    _("Lock Rotation X"),
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
                    new NodeValueChangeAction!(Node, float)(
                        _("Rotation Y"),
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
                new NodeValueChangeAction!(Node, bool)(
                    _("Lock Rotation Y"),
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
                    new NodeValueChangeAction!(Node, float)(
                        _("Rotation Z"),
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
                new NodeValueChangeAction!(Node, bool)(
                    _("Lock Rotation Z"),
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
    
    // Scaling portion of the transformation matrix.
    igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Scale"));
    igPushItemWidth((avail.x-14f-(fontSize*2f))/2f);
        
        // Scale X
        igPushID(6);
            if (incDragFloat("scale_x", &node.localTransform.scale.vector[0], adjustSpeed/100, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat)) {
                incActionPush(
                    new NodeValueChangeAction!(Node, float)(
                        _("Scale X"),
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
                new NodeValueChangeAction!(Node, bool)(
                    _("Lock Scale X"),
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
                    new NodeValueChangeAction!(Node, float)(
                        _("Scale Y"),
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
                new NodeValueChangeAction!(Node, bool)(
                    _("Lock Scale Y"),
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

    // An option in which positions will be snapped to whole integer values.
    // In other words texture will always be on a pixel.
    ImVec2 textLength = incMeasureString(_("Snap to Pixel"));
    igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Snap to Pixel"));
    incSpacer(ImVec2(-12, 1));
    if (incLockButton(&node.localTransform.pixelSnap, "pix_lk")) {
        incActionPush(
            new NodeValueChangeAction!(Node, bool)(
                _("Snap to Pixel"),
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

void incInspectorModelDrawable(Drawable node) {
    // The main type of anything that can be drawn to the screen
    // in Inochi2D.
    igText(__("Drawable"));
    igSeparator();

    igPushStyleVar_Vec2(ImGuiStyleVar.FramePadding, ImVec2(8, 8));
        igSpacing();
        igSpacing();

        if (igButton("")) {
            incSetEditMode(EditMode.VertexEdit);
            incSelectNode(node);
            incFocusCamera(node);
            incMeshEditSetTarget(node);
        }

        // Switches Inochi Creator over to Mesh Edit mode
        // and selects the mesh that you had selected previously
        // in Model Edit mode.
        incTooltip(_("Edit Mesh"));

        igSpacing();
        igSpacing();
    igPopStyleVar();
}

void incInspectorModelPart(Part node) {
    if (!node.getMesh().isReady()) { 
        igText(__("Part"));
        igSeparator();
        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Cannot inspect an unmeshed part"));
        return;
    }

    igText(__("Part"));
    igSeparator();

    // BLENDING MODE
    import std.conv : text;
    import std.string : toStringz;

    // Header for the Blending options for Parts
    igText(__("Blending"));
    if (igBeginCombo("###Blending", __(node.blendingMode.text))) {

        // Normal blending mode as used in Photoshop, generally
        // the default blending mode photoshop starts a layer out as.
        if (igSelectable(__("Normal"), node.blendingMode == BlendMode.Normal)) node.blendingMode = BlendMode.Normal;
        
        // Multiply blending mode, in which this texture's color data
        // will be multiplied with the color data already in the framebuffer.
        if (igSelectable(__("Multiply"), node.blendingMode == BlendMode.Multiply)) node.blendingMode = BlendMode.Multiply;
        
        igEndCombo();
    }

    igSpacing();

    igText(__("Opacity"));
    igSliderFloat("###Opacity", &node.opacity, 0, 1f, "%0.2f");
    igSpacing();
    igSpacing();

    igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Masks"));
    igSpacing();

    // The masking mode to apply if there's any source specified.
    igText(__("Mode"));
    if (igBeginCombo("###Mode", node.maskingMode ? __("Dodge") : __("Mask"))) {

        // A masking mode where only areas of this Part that overlap the other
        // source drawables gets drawn
        if (igSelectable(__("Mask"), node.maskingMode == MaskingMode.Mask)) {
            node.maskingMode = MaskingMode.Mask;
        }

        // A masking mode where areas of this Part that overlap the other
        // source drawables gets discarded
        if (igSelectable(__("Dodge"), node.maskingMode == MaskingMode.DodgeMask)) {
            node.maskingMode = MaskingMode.DodgeMask;
        }
        igEndCombo();
    }

    igSpacing();

    // Threshold slider name for adjusting how transparent a pixel can be
    // before it gets discarded.
    igText(__("Threshold"));
    igSliderFloat("###Threshold", &node.maskAlphaThreshold, 0.0, 1.0, "%.2f");
    
    igSpacing();

    // The sources that the part gets masked by. Depending on the masking mode
    // either the sources will cut out things that don't overlap, or cut out
    // things that do.
    igText(__("Mask Sources"));
    if (igBeginListBox("###MaskSources", ImVec2(0, 128))) {
        foreach(i, masker; node.mask) {
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
                if (payloadDrawable != node && !node.mask.canFind(payloadDrawable)) {
                    node.mask ~= payloadDrawable;
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
                foreach(i; 0..node.mask.length) {
                    if (payloadDrawable.uuid == node.mask[i].uuid) {
                        node.mask = node.mask.remove(i);
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

//
//  MESH EDIT MODE
//
void incInspectorMeshEditDrawable(Drawable node) {
    igText(__("Drawable"));
    igSeparator();

    igPushStyleVar_Vec2(ImGuiStyleVar.FramePadding, ImVec2(8, 8));
        igSpacing();
        igSpacing();

        igBeginDisabled(!incMeshEditCanTriangulate());
            if (igButton(__("Triangulate"))) {
                incMeshEditDbg();
                incMeshEditDbg();
            }
            incTooltip(_("Automatically connects vertices"));
        igEndDisabled();
        

        igBeginDisabled(!incMeshEditCanApply());
            if (igButton("")) {
                // incSetEditMode(EditMode.ModelEdit);
                // incSelectNode(node);
                // incFocusCamera(node);
                incMeshEditApply();
            }
            incTooltip(_("Apply"));
        igEndDisabled();

        igSameLine(0, 4);

        if (igButton("")) {
            // incSetEditMode(EditMode.ModelEdit);
            // incSelectNode(node);
            // incFocusCamera(node);
            incMeshEditReset();
        }
        incTooltip(_("Cancel"));

        igSpacing();
        igSpacing();
    igPopStyleVar();
}