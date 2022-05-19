/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.inspector;
import creator.viewport.vertex;
import creator.core;
import creator.panels;
import creator.widgets;
import creator.utils;
import creator.windows;
import creator;
import inochi2d;
import inochi2d.core.nodes.common;
import std.string;
import std.algorithm.searching;
import std.algorithm.mutation;
import std.conv;
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
                        if (incArmedParameter()) {
                            Parameter param = incArmedParameter();
                            vec2u cursor = param.findClosestKeypoint();
                            incCommonNonEditHeader(node);
                            incInspectorDeformTRS(node, param, cursor);

                            // Node Part Section
                            if (Part part = cast(Part)node) {

                                // Padding
                                igSpacing();
                                igSpacing();
                                igSpacing();
                                igSpacing();
                                incInspectorDeformPart(part, param, cursor);
                            }

                            if (Composite composite = cast(Composite)node) {

                                // Padding
                                igSpacing();
                                igSpacing();
                                igSpacing();
                                igSpacing();
                                incInspectorDeformComposite(composite, param, cursor);
                            }

                        } else {
                            incModelModeHeader(node);
                            incInspectorModelTRS(node);

                            // Node Drawable Section
                            if (Composite composite = cast(Composite)node) {

                                // Padding
                                igSpacing();
                                igSpacing();
                                igSpacing();
                                igSpacing();
                                incInspectorModelComposite(composite);
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

                            // Node SimplePhysics Section
                            if (SimplePhysics part = cast(SimplePhysics)node) {

                                // Padding
                                igSpacing();
                                igSpacing();
                                igSpacing();
                                igSpacing();
                                incInspectorModelSimplePhysics(part);
                            }
                        }
                    
                    break;
                    case EditMode.VertexEdit:
                        incCommonNonEditHeader(node);
                        incInspectorMeshEditDrawable(cast(Drawable)node);
                        break;
                    default:
                        incCommonNonEditHeader(node);
                        break;
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

    if (igCollapsingHeader(__("General Info"), ImGuiTreeNodeFlags.DefaultOpen)) {
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
    }

    if (igCollapsingHeader(__("Licensing"), ImGuiTreeNodeFlags.DefaultOpen)) {
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

    if (igCollapsingHeader(__("Physics Globals"), ImGuiTreeNodeFlags.DefaultOpen)) {
        igPushID("PixelsPerMeter");
            igText(__("Pixels per meter"));
            incTooltip(_("Number of pixels that correspond to 1 meter in the physics engine."));
            incDragFloat("PixelsPerMeter", &puppet.physics.pixelsPerMeter, 1, 1, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
        igPopID();
        igSpacing();

        igPushID("Gravity");
            igText(__("Gravity"));
            incTooltip(_("Acceleration due to gravity, in m/s². Earth gravity is 9.8."));
            incDragFloat("Gravity", &puppet.physics.gravity, 0.01, 0, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
        igPopID();
        igSpacing();
    }
}

void incModelModeHeader(Node node) {
    // Top level
    igPushID(node.uuid);
        string typeString = "%s\0".format(incTypeIdToIcon(node.typeId()));
        auto len = incMeasureString(typeString);
        incInputText("", incAvailableSpace().x-24, node.name);
        igSameLine(0, 0);
        incDummy(ImVec2(-(len.x-14), len.y));
        igSameLine(0, 0);
        igText(typeString.ptr);
    igPopID();
    igSeparator();
}

void incInspectorModelTRS(Node node) {
    if (!igCollapsingHeader(__("Transform"), ImGuiTreeNodeFlags.DefaultOpen)) 
        return;
    
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
    igPushItemWidth((avail.x-4f)/3f);

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


    
        // Padding
        igSpacing();
        igSpacing();
        
        igBeginGroup();
            // Button which locks all transformation to be based off the root node
            // of the puppet, this more or less makes the item stay in place
            // even if the parent moves.
            ImVec2 textLength = incMeasureString(_("Lock to Root Node"));
            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Lock to Root Node"));

            incSpacer(ImVec2(-12, 1));
            bool lockToRoot = node.lockToRoot;
            if (incLockButton(&lockToRoot, "root_lk")) {

                // TODO: Store this in undo history.
                node.lockToRoot = lockToRoot;
            }
        igEndGroup();

        // Button which locks all transformation to be based off the root node
        // of the puppet, this more or less makes the item stay in place
        // even if the parent moves.
        incTooltip(_("Makes so that the translation of this node is based off the root node, making it stay in place even if its parent moves."));
    
        // Padding
        igSpacing();
        igSpacing();

    igPopItemWidth();


    //
    // Rotation
    //
    igSpacing();
    
    // Rotation portion of the transformation matrix.
    igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Rotation"));
    igPushItemWidth((avail.x-4f)/3f);

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

    igPopItemWidth();

    avail.x += igGetFontSize();

    //
    // Scaling
    //
    igSpacing();
    
    // Scaling portion of the transformation matrix.
    igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Scale"));
    igPushItemWidth((avail.x-14f)/2f);
        
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

    igPopItemWidth();

    igSpacing();
    igSpacing();

    // An option in which positions will be snapped to whole integer values.
    // In other words texture will always be on a pixel.
    textLength = incMeasureString(_("Snap to Pixel"));
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

    // The sorting order ID, which Inochi2D uses to sort
    // Parts to draw in the user specified order.
    // negative values = closer to camera
    // positive values = further away from camera
    igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Sorting"));
    float zsortV = node.relZSort;
    if (igInputFloat("###ZSort", &zsortV, 0.01, 0.05, "%0.2f")) {
        node.zSort = zsortV;
    }
}

void incInspectorModelDrawable(Drawable node) {
    // The main type of anything that can be drawn to the screen
    // in Inochi2D.
    if (!igCollapsingHeader(__("Drawable"), ImGuiTreeNodeFlags.DefaultOpen)) 
        return;

    float adjustSpeed = 1;
    ImVec2 avail = incAvailableSpace();

    igBeginGroup();
        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Texture Offset"));
        igPushItemWidth((avail.x-4f)/2f);

            // Translation X
            igPushID(42);
            if (incDragFloat("offset_x", &node.getMesh().origin.vector[0], adjustSpeed, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat)) {
                incActionPush(
                    new NodeValueChangeAction!(Node, float)(
                        "X",
                        node, 
                        incGetDragFloatInitialValue("offset_x"),
                        node.getMesh().origin.vector[0],
                        &node.getMesh().origin.vector[0]
                    )
                );
            }
            igPopID();

            igSameLine(0, 4);

            // Translation Y
            igPushID(43);
                if (incDragFloat("offset_y", &node.getMesh().origin.vector[1], adjustSpeed, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat)) {
                    incActionPush(
                        new NodeValueChangeAction!(Node, float)(
                            "Y",
                            node, 
                            incGetDragFloatInitialValue("offset_y"),
                            node.getMesh().origin.vector[1],
                            &node.getMesh().origin.vector[1]
                        )
                    );
                }
            igPopID();
        igPopItemWidth();
    igEndGroup();

    igPushStyleVar_Vec2(ImGuiStyleVar.FramePadding, ImVec2(8, 8));
        igSpacing();
        igSpacing();

        if (igButton("", ImVec2(avail.x, 32))) {
            incSetEditMode(EditMode.VertexEdit);
            incSelectNode(node);
            incVertexEditSetTarget(node);
            incFocusCamera(node, vec2(0, 0));
        }

        // Allow copying mesh data via drag n drop for now
        if(igBeginDragDropTarget()) {
            ImGuiPayload* payload = igAcceptDragDropPayload("_PUPPETNTREE");
            if (payload !is null) {
                if (Drawable payloadDrawable = cast(Drawable)*cast(Node*)payload.Data) {
                    incSetEditMode(EditMode.VertexEdit);
                    incSelectNode(node);
                    incVertexEditSetTarget(node);
                    incFocusCamera(node, vec2(0, 0));
                    incVertexEditCopyMeshDataToTarget(payloadDrawable.getMesh());
                }
            }
            
            igEndDragDropTarget();
        } else {


            // Switches Inochi Creator over to Mesh Edit mode
            // and selects the mesh that you had selected previously
            // in Model Edit mode.
            incTooltip(_("Edit Mesh"));
        }

        igSpacing();
        igSpacing();
    igPopStyleVar();
}

void incInspectorModelPart(Part node) {
    if (!igCollapsingHeader(__("Part"), ImGuiTreeNodeFlags.DefaultOpen)) 
        return;
    
    if (!node.getMesh().isReady()) { 
        igSpacing();
        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Cannot inspect an unmeshed part"));
        return;
    }
    igSpacing();

    // BLENDING MODE
    import std.conv : text;
    import std.string : toStringz;

    igBeginGroup();
        igIndent(16);
            // Header for texture options    
            if (igCollapsingHeader(__("Textures")))  {

                igText("(TODO: Texture Select)");

                igSpacing();
                igSpacing();

                igText(__("Tint"));
                igColorEdit3("", cast(float[3]*)node.tint.ptr);

                // Padding
                igSeparator();
                igSpacing();
                igSpacing();
            }
        igUnindent();
    igEndGroup();

    // Header for the Blending options for Parts
    igText(__("Blending"));
    if (igBeginCombo("###Blending", __(node.blendingMode.text))) {

        // Normal blending mode as used in Photoshop, generally
        // the default blending mode photoshop starts a layer out as.
        if (igSelectable(__("Normal"), node.blendingMode == BlendMode.Normal)) node.blendingMode = BlendMode.Normal;
        
        // Multiply blending mode, in which this texture's color data
        // will be multiplied with the color data already in the framebuffer.
        if (igSelectable(__("Multiply"), node.blendingMode == BlendMode.Multiply)) node.blendingMode = BlendMode.Multiply;
                
        // Color Dodge blending mode
        if (igSelectable(__("Color Dodge"), node.blendingMode == BlendMode.ColorDodge)) node.blendingMode = BlendMode.ColorDodge;
                
        // Linear Dodge blending mode
        if (igSelectable(__("Linear Dodge"), node.blendingMode == BlendMode.LinearDodge)) node.blendingMode = BlendMode.LinearDodge;
                        
        // Screen blending mode
        if (igSelectable(__("Screen"), node.blendingMode == BlendMode.Screen)) node.blendingMode = BlendMode.Screen;
                        
        // Clip to Lower blending mode
        if (igSelectable(__("Clip to Lower"), node.blendingMode == BlendMode.ClipToLower)) node.blendingMode = BlendMode.ClipToLower;
        incTooltip(_("Special blending mode that causes (while respecting transparency) the part to be clipped to everything underneath"));
                        
        // Slice from Lower blending mode
        if (igSelectable(__("Slice from Lower"), node.blendingMode == BlendMode.SliceFromLower)) node.blendingMode = BlendMode.SliceFromLower;
        incTooltip(_("Special blending mode that causes (while respecting transparency) the part to be slice by everything underneath.\nBasically reverse Clip to Lower."));
        
        igEndCombo();
    }

    igSpacing();

    igText(__("Opacity"));
    igSliderFloat("###Opacity", &node.opacity, 0, 1f, "%0.2f");
    igSpacing();
    igSpacing();

    igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Masks"));
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
        foreach(i; 0..node.masks.length) {
            MaskBinding* masker = &node.masks[i];
            igPushID(cast(int)i);
                if (igBeginPopup("###MaskSettings")) {
                    if (igBeginMenu(__("Mode"))) {
                        if (igMenuItem(__("Mask"), null, masker.mode == MaskingMode.Mask)) masker.mode = MaskingMode.Mask;
                        if (igMenuItem(__("Dodge"), null, masker.mode == MaskingMode.DodgeMask)) masker.mode = MaskingMode.DodgeMask;
                        
                        igEndMenu();
                    }

                    if (igMenuItem(__("Delete"))) {
                        import std.algorithm.mutation : remove;
                        node.masks = node.masks.remove(i);
                        igEndPopup();
                        igPopID();
                        igEndListBox();
                        return;
                    }

                    igEndPopup();
                }

                if (masker.mode == MaskingMode.Mask) igSelectable(_("%s (Mask)").format(masker.maskSrc.name).toStringz);
                else igSelectable(_("%s (Dodge)").format(masker.maskSrc.name).toStringz);

                
                if(igBeginDragDropTarget()) {
                    ImGuiPayload* payload = igAcceptDragDropPayload("_MASKITEM");
                    if (payload !is null) {
                        if (MaskBinding* binding = cast(MaskBinding*)payload.Data) {
                            ptrdiff_t maskIdx = node.getMaskIdx(binding.maskSrcUUID);
                            if (maskIdx >= 0) {
                                import std.algorithm.mutation : remove;

                                node.masks = node.masks.remove(maskIdx);
                                if (i == 0) node.masks = *binding ~ node.masks;
                                else if (i >= node.masks.length-1) node.masks ~= *binding;
                                else node.masks = node.masks[0..i] ~ *binding ~ node.masks[i+1..$];
                            }
                        }
                    }
                    
                    igEndDragDropTarget();
                }

                // TODO: We really should account for left vs. right handedness
                if (igIsItemClicked(ImGuiMouseButton.Right)) {
                    igOpenPopup("###MaskSettings");
                }

                if(igBeginDragDropSource(ImGuiDragDropFlags.SourceAllowNullID)) {
                    igSetDragDropPayload("_MASKITEM", cast(void*)masker, MaskBinding.sizeof, ImGuiCond.Always);
                    igText(masker.maskSrc.name.toStringz);
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
                if (payloadDrawable != node && !node.isMaskedBy(payloadDrawable)) {
                    node.masks ~= MaskBinding(payloadDrawable.uuid, MaskingMode.Mask, payloadDrawable);
                }
            }
        }
        
        igEndDragDropTarget();
    }

    // Padding
    igSpacing();
    igSpacing();
}

void incInspectorModelComposite(Composite node) {
    if (!igCollapsingHeader(__("Composite"), ImGuiTreeNodeFlags.DefaultOpen)) 
        return;
    

    igSpacing();

    // BLENDING MODE
    import std.conv : text;
    import std.string : toStringz;


    igText(__("Tint"));
    igColorEdit3("", cast(float[3]*)node.tint.ptr);

    // Header for the Blending options for Parts
    igText(__("Blending"));
    if (igBeginCombo("###Blending", __(node.blendingMode.text))) {

        // Normal blending mode as used in Photoshop, generally
        // the default blending mode photoshop starts a layer out as.
        if (igSelectable(__("Normal"), node.blendingMode == BlendMode.Normal)) node.blendingMode = BlendMode.Normal;
        
        // Multiply blending mode, in which this texture's color data
        // will be multiplied with the color data already in the framebuffer.
        if (igSelectable(__("Multiply"), node.blendingMode == BlendMode.Multiply)) node.blendingMode = BlendMode.Multiply;
                
        // Color Dodge blending mode
        if (igSelectable(__("Color Dodge"), node.blendingMode == BlendMode.ColorDodge)) node.blendingMode = BlendMode.ColorDodge;
                
        // Linear Dodge blending mode
        if (igSelectable(__("Linear Dodge"), node.blendingMode == BlendMode.LinearDodge)) node.blendingMode = BlendMode.LinearDodge;
                        
        // Screen blending mode
        if (igSelectable(__("Screen"), node.blendingMode == BlendMode.Screen)) node.blendingMode = BlendMode.Screen;
        
        igEndCombo();
    }

    igSpacing();

    igText(__("Opacity"));
    igSliderFloat("###Opacity", &node.opacity, 0, 1f, "%0.2f");
    igSpacing();
    igSpacing();

    igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Masks"));
    igSpacing();

    // Threshold slider name for adjusting how transparent a pixel can be
    // before it gets discarded.
    igText(__("Threshold"));
    igSliderFloat("###Threshold", &node.threshold, 0.0, 1.0, "%.2f");
    
    igSpacing();

    // Padding
    igSpacing();
    igSpacing();
}

void incInspectorModelSimplePhysics(SimplePhysics node) {
    if (!igCollapsingHeader(__("SimplePhysics"), ImGuiTreeNodeFlags.DefaultOpen))
        return;

    float adjustSpeed = 1;

    igSpacing();

    // BLENDING MODE
    import std.conv : text;
    import std.string : toStringz;

    igPushID("TargetParam");
        igText(__("Parameter"));
        string paramName = _("(unassigned)");
        if (node.param !is null) paramName = node.param.name;
        igInputText("", cast(char*)paramName.toStringz, paramName.length, ImGuiInputTextFlags.ReadOnly);

        if(igBeginDragDropTarget()) {
            ImGuiPayload* payload = igAcceptDragDropPayload("_PARAMETER");
            if (payload !is null) {
                Parameter payloadParam = *cast(Parameter*)payload.Data;
                node.param = payloadParam;
            }

            igEndDragDropTarget();
        }

    igPopID();

    igText(__("Type"));
    if (igBeginCombo("###PhysType", __(node.modelType.text))) {

        if (igSelectable(__("Pendulum"), node.modelType == PhysicsModel.Pendulum)) node.modelType = PhysicsModel.Pendulum;

        if (igSelectable(__("SpringPendulum"), node.modelType == PhysicsModel.SpringPendulum)) node.modelType = PhysicsModel.SpringPendulum;

        igEndCombo();
    }

    igSpacing();

    igText(__("Mapping mode"));
    if (igBeginCombo("###PhysMapMode", __(node.mapMode.text))) {

        if (igSelectable(__("AngleLength"), node.mapMode == ParamMapMode.AngleLength)) node.mapMode = ParamMapMode.AngleLength;

        if (igSelectable(__("XY"), node.mapMode == ParamMapMode.XY)) node.mapMode = ParamMapMode.XY;

        igEndCombo();
    }

    igSpacing();

    igPushID("SimplePhysics");

    igPushID(0);
    igText(__("Gravity scale"));
    incDragFloat("gravity", &node.gravity, adjustSpeed/100, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
    igSpacing();
    igSpacing();
    igPopID();

    igPushID(1);
    igText(__("Length"));
    incDragFloat("length", &node.length, adjustSpeed/100, 0, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
    igSpacing();
    igSpacing();
    igPopID();

    igPushID(2);
    igText(__("Resonant frequency"));
    incDragFloat("frequency", &node.frequency, adjustSpeed/100, 0.01, 30, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
    igSpacing();
    igSpacing();
    igPopID();

    igPushID(3);
    igText(__("Damping"));
    incDragFloat("damping_angle", &node.angleDamping, adjustSpeed/100, 0, 5, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
    igPopID();

    igPushID(4);
    incDragFloat("damping_length", &node.lengthDamping, adjustSpeed/100, 0, 5, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
    igSpacing();
    igSpacing();
    igPopID();

    igPushID(5);
    igText(__("Output scale"));
    incDragFloat("output_scale.x", &node.outputScale.vector[0], adjustSpeed/100, 0, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
    igPopID();

    igPushID(6);
    incDragFloat("output_scale.y", &node.outputScale.vector[1], adjustSpeed/100, 0, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
    igSpacing();
    igSpacing();
    igPopID();

    // Padding
    igSpacing();
    igSpacing();

    igPopID();
}

//
//  MODEL MODE ARMED
//
void incInspectorDeformFloatDragVal(string name, string paramName, float adjustSpeed, Node node, Parameter param, vec2u cursor) {
    float currFloat = node.getDefaultValue(paramName);
    if (ValueParameterBinding b = cast(ValueParameterBinding)param.getBinding(node, paramName)) {
        currFloat = b.getValue(cursor);
    }
    if (incDragFloat(name, &currFloat, adjustSpeed, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat)) {
        ValueParameterBinding b = cast(ValueParameterBinding)param.getOrAddBinding(node, paramName);
        b.setValue(cursor, currFloat);
    }
}

void incInspectorDeformInputFloat(string name, string paramName, float step, float stepFast, Node node, Parameter param, vec2u cursor) {
    float currFloat = node.getDefaultValue(paramName);
    if (ValueParameterBinding b = cast(ValueParameterBinding)param.getBinding(node, paramName)) {
        currFloat = b.getValue(cursor);
    }
    if (igInputFloat(name.toStringz, &currFloat, step, stepFast, "%.2f")) {
        ValueParameterBinding b = cast(ValueParameterBinding)param.getOrAddBinding(node, paramName);
        b.setValue(cursor, currFloat);
    }
}

void incInspectorDeformColorEdit3(string[3] paramNames, Node node, Parameter param, vec2u cursor) {
    import std.math : isNaN;
    float[3] rgb = [float.nan, float.nan, float.nan];
    float[3] rgbadj = [1, 1, 1];
    bool[3] rgbchange = [false, false, false];
    ValueParameterBinding pbr = cast(ValueParameterBinding)param.getBinding(node, paramNames[0]);
    ValueParameterBinding pbg = cast(ValueParameterBinding)param.getBinding(node, paramNames[1]);
    ValueParameterBinding pbb = cast(ValueParameterBinding)param.getBinding(node, paramNames[2]);

    if (pbr) {
        rgb[0] = pbr.getValue(cursor);
        rgbadj[0] = rgb[0];
    }

    if (pbg) {
        rgb[1] = pbg.getValue(cursor);
        rgbadj[1] = rgb[1];
    }

    if (pbb) {
        rgb[2] = pbb.getValue(cursor);
        rgbadj[2] = rgb[2];
    }

    if (igColorEdit3("", &rgbadj)) {

        // RED
        if (rgbadj[0] != 1) {
            auto b = cast(ValueParameterBinding)param.getOrAddBinding(node, paramNames[0]);
            b.setValue(cursor, rgbadj[0]);
        } else if (pbr) {
            pbr.setValue(cursor, rgbadj[0]);
        }

        // GREEN
        if (rgbadj[1] != 1) {
            auto b = cast(ValueParameterBinding)param.getOrAddBinding(node, paramNames[1]);
            b.setValue(cursor, rgbadj[1]);
        } else if (pbg) {
            pbg.setValue(cursor, rgbadj[1]);
        }

        // BLUE
        if (rgbadj[2] != 1) {
            auto b = cast(ValueParameterBinding)param.getOrAddBinding(node, paramNames[2]);
            b.setValue(cursor, rgbadj[2]);
        } else if (pbb) {
            pbb.setValue(cursor, rgbadj[2]);
        }
    }
}

void incInspectorDeformSliderFloat(string name, string paramName, float min, float max, Node node, Parameter param, vec2u cursor) {
    float currFloat = node.getDefaultValue(paramName);
    if (ValueParameterBinding b = cast(ValueParameterBinding)param.getBinding(node, paramName)) {
        currFloat = b.getValue(cursor);
    }
    if (igSliderFloat(name.toStringz, &currFloat, min, max, "%.2f")) {
        ValueParameterBinding b = cast(ValueParameterBinding)param.getOrAddBinding(node, paramName);
        b.setValue(cursor, currFloat);
    }
}

void incInspectorDeformTRS(Node node, Parameter param, vec2u cursor) {
    if (!igCollapsingHeader(__("Transform"), ImGuiTreeNodeFlags.DefaultOpen)) 
        return;
    
    float adjustSpeed = 1;

    ImVec2 avail;
    igGetContentRegionAvail(&avail);

    float fontSize = 16;

    //
    // Translation
    //



    // Translation portion of the transformation matrix.
    igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Translation"));
    igPushItemWidth((avail.x-4f)/3f);

        // Translation X
        igPushID(0);
            incInspectorDeformFloatDragVal("translation_x", "transform.t.x", 1f, node, param, cursor);
        igPopID();

        igSameLine(0, 4);

        // Translation Y
        igPushID(1);
            incInspectorDeformFloatDragVal("translation_y", "transform.t.y", 1f, node, param, cursor);
        igPopID();

        igSameLine(0, 4);

        // Translation Z
        igPushID(2);
            incInspectorDeformFloatDragVal("translation_z", "transform.t.z", 1f, node, param, cursor);
        igPopID();


    
        // Padding
        igSpacing();
        igSpacing();

    igPopItemWidth();


    //
    // Rotation
    //
    igSpacing();
    
    // Rotation portion of the transformation matrix.
    igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Rotation"));
    igPushItemWidth((avail.x-4f)/3f);

        // Rotation X
        igPushID(3);
            incInspectorDeformFloatDragVal("rotation.x", "transform.r.x", 0.05f, node, param, cursor);
        igPopID();

        igSameLine(0, 4);

        // Rotation Y
        igPushID(4);
            incInspectorDeformFloatDragVal("rotation.y", "transform.r.y", 0.05f, node, param, cursor);
        igPopID();

        igSameLine(0, 4);

        // Rotation Z
        igPushID(5);
            incInspectorDeformFloatDragVal("rotation.z", "transform.r.z", 0.05f, node, param, cursor);
        igPopID();

    igPopItemWidth();

    avail.x += igGetFontSize();

    //
    // Scaling
    //
    igSpacing();
    
    // Scaling portion of the transformation matrix.
    igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Scale"));
    igPushItemWidth((avail.x-14f)/2f);
        
        // Scale X
        igPushID(6);
            incInspectorDeformFloatDragVal("scale.x", "transform.s.x", 0.1f, node, param, cursor);
        igPopID();

        igSameLine(0, 4);

        // Scale Y
        igPushID(7);
            incInspectorDeformFloatDragVal("scale.y", "transform.s.y", 0.1f, node, param, cursor);
        igPopID();

    igPopItemWidth();

    igSpacing();
    igSpacing();

    igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Sorting"));
    incInspectorDeformInputFloat("zSort", "zSort", 0.01, 0.05, node, param, cursor);
}

void incInspectorDeformPart(Part node, Parameter param, vec2u cursor) {
    if (!igCollapsingHeader(__("Part"), ImGuiTreeNodeFlags.DefaultOpen)) 
        return;

    igBeginGroup();
        igIndent(16);
            // Header for texture options    
            if (igCollapsingHeader(__("Textures")))  {

                igText(__("Tint"));

                incInspectorDeformColorEdit3(["tint.r", "tint.g", "tint.b"], node, param, cursor);

                // Padding
                igSeparator();
                igSpacing();
                igSpacing();
            }
        igUnindent();
    igEndGroup();

    igText(__("Opacity"));
    incInspectorDeformSliderFloat("###Opacity", "opacity", 0, 1f, node, param, cursor);
    igSpacing();
    igSpacing();

    // Threshold slider name for adjusting how transparent a pixel can be
    // before it gets discarded.
    igText(__("Threshold"));
    incInspectorDeformSliderFloat("###Threshold", "alphaThreshold", 0.0, 1.0, node, param, cursor);
}

void incInspectorDeformComposite(Composite node, Parameter param, vec2u cursor) {
    if (!igCollapsingHeader(__("Composite"), ImGuiTreeNodeFlags.DefaultOpen)) 
        return;

    igBeginGroup();
        igIndent(16);
            // Header for texture options    
            if (igCollapsingHeader(__("Textures")))  {

                igText(__("Tint"));

                incInspectorDeformColorEdit3(["tint.r", "tint.g", "tint.b"], node, param, cursor);

                // Padding
                igSeparator();
                igSpacing();
                igSpacing();
            }
        igUnindent();
    igEndGroup();

    igText(__("Opacity"));
    incInspectorDeformSliderFloat("###Opacity", "opacity", 0, 1f, node, param, cursor);
    igSpacing();
    igSpacing();
}

//
//  MESH EDIT MODE
//
void incInspectorMeshEditDrawable(Drawable node) {
    igPushStyleVar_Vec2(ImGuiStyleVar.FramePadding, ImVec2(8, 8));
        igSpacing();
        igSpacing();

        incViewportVertexInspector(node);

        ImVec2 avail = incAvailableSpace();
        incDummy(ImVec2(avail.x, avail.y-38));

        // Right align
        incDummy(ImVec2(avail.x-72, 32));
        igSameLine(0, 0);

        if (igButton("", ImVec2(32, 32))) {
            if (igGetIO().KeyShift) {
                incMeshEditReset();
            } else {
                incMeshEditClear();
            }

            incSetEditMode(EditMode.ModelEdit);
            incSelectNode(node);
            incFocusCamera(node);
        }
        incTooltip(_("Cancel"));

        igSameLine(0, 8);

        if (igButton("", ImVec2(32, 32))) {
            incMeshEditApply();

            incSetEditMode(EditMode.ModelEdit);
            incSelectNode(node);
            incFocusCamera(node);
        }
        incTooltip(_("Apply"));
    igPopStyleVar();
}