/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.inspector;
import creator.viewport.vertex;
import creator.viewport.model.deform;
import creator.core;
import creator.panels;
import creator.widgets;
import creator.utils;
import creator.windows;
import creator.actions;
import creator.ext;
import creator;
import inochi2d;
import inochi2d.core.nodes.common;
import std.string;
import std.algorithm.searching;
import std.algorithm.mutation;
import std.conv;
import i18n;

// Drag drop data
import creator.panels.parameters;

import creator.actions.node;

/**
    The inspector panel
*/
class InspectorPanel : Panel {
private:


protected:
    override
    void onUpdate() {
        if (incEditMode == EditMode.VertexEdit) {
            incLabelOver(_("In vertex edit mode..."), ImVec2(0, 0), true);
            return;
        }

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
                                incInspectorDeformPart(part, param, cursor);
                            }

                            if (Composite composite = cast(Composite)node) {
                                incInspectorDeformComposite(composite, param, cursor);
                            }

                        } else {
                            incModelModeHeader(node);
                            incInspectorModelTRS(node);

                            // Node Camera Section
                            if (ExCamera camera = cast(ExCamera)node) {
                                incInspectorModelCamera(camera);
                            }

                            // Node Drawable Section
                            if (Composite composite = cast(Composite)node) {
                                incInspectorModelComposite(composite);
                            }


                            // Node Drawable Section
                            if (Drawable drawable = cast(Drawable)node) {
                                incInspectorModelDrawable(drawable);
                            }

                            // Node Part Section
                            if (Part part = cast(Part)node) {
                                incInspectorModelPart(part);
                            }

                            // Node SimplePhysics Section
                            if (SimplePhysics part = cast(SimplePhysics)node) {
                                incInspectorModelSimplePhysics(part);
                            }

                            // Node MeshGroup Section
                            if (MeshGroup group = cast(MeshGroup)node) {
                                incInspectorModelMeshGroup(group);
                            }
                        }
                    
                    break;
                    default:
                        incCommonNonEditHeader(node);
                        break;
                }
            } else incInspectorModelInfo();
        } else if (nodes.length == 0) {
            incLabelOver(_("No nodes selected..."), ImVec2(0, 0), true);
        } else {
            incLabelOver(_("Can only inspect a single node..."), ImVec2(0, 0), true);
        }
    }

public:
    this() {
        super("Inspector", _("Inspector"), true);
        activeModes = EditMode.ModelEdit;
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
        string typeString = "%s".format(incTypeIdToIcon(node.typeId()));
        auto len = incMeasureString(typeString);
        incText(node.name);
        igSameLine(0, 0);
        incDummy(ImVec2(-len.x, len.y));
        igSameLine(0, 0);
        incText(typeString);
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
        string typeString = "";
        auto len = incMeasureString(typeString);
        incText(_("Puppet"));
        igSameLine(0, 0);
        incDummy(ImVec2(-len.x, len.y));
        igSameLine(0, 0);
        incText(typeString);
    igPopID();
    igSeparator();
    
    igSpacing();
    igSpacing();

    // Version info
    {
        len = incMeasureString(_("Inochi2D Ver."));
        incText(puppet.meta.version_);
        igSameLine(0, 0);
        incDummy(ImVec2(-(len.x), len.y));
        igSameLine(0, 0);
        incText(_("Inochi2D Ver."));
    }
    
    igSpacing();
    igSpacing();

    if (incBeginCategory(__("General Info"))) {
        igPushID("Part Count");
            incTextColored(ImVec4(0.7, 0.5, 0.5, 1), _("Part Count"));
            incTextColored(ImVec4(0.7, 0.5, 0.5, 1), "%s".format(incActivePuppet().getRootParts().length));
        igPopID();
        igSpacing();

        igPushID("Name");
            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Name"));
            incTooltip(_("Name of the puppet"));
            incInputText("META_NAME", puppet.meta.name);
        igPopID();
        igSpacing();

        igPushID("Artists");
            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Artist(s)"));
            incTooltip(_("Artists who've drawn the puppet, seperated by comma"));
            incInputText("META_ARTISTS", puppet.meta.artist);
        igPopID();
        igSpacing();

        igPushID("Riggers");
            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Rigger(s)"));
            incTooltip(_("Riggers who've rigged the puppet, seperated by comma"));
            incInputText("META_RIGGERS", puppet.meta.rigger);
        igPopID();
        igSpacing();

        igPushID("Contact");
            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Contact"));
            incTooltip(_("Where to contact the main author of the puppet"));
            incInputText("META_CONTACT", puppet.meta.contact);
        igPopID();
    }
    incEndCategory();

    if (incBeginCategory(__("Licensing"))) {
        igPushID("LicenseURL");
            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("License URL"));
            incTooltip(_("Link/URL to license"));
            incInputText("META_LICENSEURL", puppet.meta.licenseURL);
        igPopID();
        igSpacing();

        igPushID("Copyright");
            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Copyright"));
            incTooltip(_("Copyright holder information of the puppet"));
            incInputText("META_COPYRIGHT", puppet.meta.copyright);
        igPopID();
        igSpacing();

        igPushID("Origin");
            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Origin"));
            incTooltip(_("Where the model comes from on the internet."));
            incInputText("META_ORIGIN", puppet.meta.reference);
        igPopID();
    }
    incEndCategory();

    if (incBeginCategory(__("Physics Globals"))) {
        igPushID("PixelsPerMeter");
            incText(_("Pixels per meter"));
            incTooltip(_("Number of pixels that correspond to 1 meter in the physics engine."));
            incDragFloat("PixelsPerMeter", &puppet.physics.pixelsPerMeter, 1, 1, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
        igPopID();
        igSpacing();

        igPushID("Gravity");
            incText(_("Gravity"));
            incTooltip(_("Acceleration due to gravity, in m/s². Earth gravity is 9.8."));
            incDragFloat("Gravity", &puppet.physics.gravity, 0.01, 0, float.max, _("%.2f m/s²"), ImGuiSliderFlags.NoRoundToFormat);
        igPopID();
    }
    incEndCategory();

    if (incBeginCategory(__("Rendering Settings"))) {
        igPushID("Filtering");
            if (igCheckbox(__("Use Point Filtering"), &incActivePuppet().meta.preservePixels)) {
                incActivePuppet().populateTextureSlots();
                incActivePuppet().updateTextureState();
            }
            incTooltip(_("Makes Inochi2D model use point filtering, removing blur for low-resolution models."));
        igPopID();
    }
    incEndCategory();
}

void incModelModeHeader(Node node) {
    // Top level
    igPushID(node.uuid);
        string typeString = "%s".format(incTypeIdToIcon(node.typeId()));
        auto len = incMeasureString(typeString);
        incInputText("###MODEL_NODE_HEADER", incAvailableSpace().x-24, node.name);
        igSameLine(0, 0);
        incDummy(ImVec2(-len.x, len.y));
        igSameLine(0, 0);
        incText(typeString);
    igPopID();
}

void incInspectorModelTRS(Node node) {
    if (incBeginCategory(__("Transform"))) {
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
                    incLockToRootNode(node);
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
            float rotationDegrees;

            // Rotation X
            igPushID(3);
                rotationDegrees = degrees(node.localTransform.rotation.vector[0]);
                if (incDragFloat("rotation_x", &rotationDegrees, adjustSpeed/100, -float.max, float.max, "%.2f°", ImGuiSliderFlags.NoRoundToFormat)) {       
                    node.localTransform.rotation.vector[0] = radians(rotationDegrees);         
                    
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
                rotationDegrees = degrees(node.localTransform.rotation.vector[1]);
                if (incDragFloat("rotation_y", &rotationDegrees, adjustSpeed/100, -float.max, float.max, "%.2f°", ImGuiSliderFlags.NoRoundToFormat)) {
                    node.localTransform.rotation.vector[1] = radians(rotationDegrees);

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
                rotationDegrees = degrees(node.localTransform.rotation.vector[2]);
                if (incDragFloat("rotation_z", &rotationDegrees, adjustSpeed/100, -float.max, float.max, "%.2f°", ImGuiSliderFlags.NoRoundToFormat)) {
                    node.localTransform.rotation.vector[2] = radians(rotationDegrees);

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
    incEndCategory();
}

void incInspectorModelDrawable(Drawable node) {
    // The main type of anything that can be drawn to the screen
    // in Inochi2D.
    if (incBeginCategory(__("Drawable"))) {
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
    }
    incEndCategory();
}

void incInspectorTextureSlot(Part p, TextureUsage usage, string title, ImVec2 elemSize) {
    igPushID(p.uuid);
    igPushID(cast(uint)usage);
        import std.path : baseName, extension, setExtension;
        import std.uni : toLower;
        incTextureSlot(title, p.textures[usage], elemSize);

        void applyTextureToSlot(Part p, TextureUsage usage, string file) {
            switch(file.extension.toLower) {
                case ".png", ".tga", ".jpeg", ".jpg":

                    try {
                        ShallowTexture tex;
                        switch(usage) {
                            case TextureUsage.Albedo:
                                tex = ShallowTexture(file, 4);
                                break;
                            case TextureUsage.Emissive:
                                tex = ShallowTexture(file, 3);
                                break;
                            case TextureUsage.Bumpmap:
                                tex = ShallowTexture(file, 3);
                                break;
                            default:
                                tex = ShallowTexture(file);
                                break;
                        }

                        if (usage != TextureUsage.Albedo) {

                            // Error out if post processing textures don't match
                            if (tex.width != p.textures[0].width || tex.height != p.textures[0].height) {
                                incDialog(__("Error"), _("Size of given texture does not match the Albedo texture."));
                                break;
                            }
                        }

                        if (tex.convChannels == 4) {
                            inTexPremultiply(tex.data);
                        }
                        p.textures[usage] = new Texture(tex);
                        
                        if (usage == TextureUsage.Albedo) {
                            foreach(i, _; p.textures[1..$]) {
                                if (p.textures[i] && (p.textures[i].width != p.textures[0].width || p.textures[i].height != p.textures[0].height)) {
                                    p.textures[i] = null;
                                }
                            }
                        }
                    } catch(Exception ex) {
                        if (ex.msg[0..11] == "unsupported") {
                            incDialog(__("Error"), _("%s is not supported").format(file));
                        } else incDialog(__("Error"), ex.msg);
                    }


                    // We've added new stuff, rescan nodes
                    incActivePuppet().rescanNodes();
                    incActivePuppet().populateTextureSlots();
                    break;
                    
                default:
                    incDialog(__("Error"), _("%s is not supported").format(file)); 
                    break;
            }
        }

        // Only have dropdown if there's actually textures in the slot
        if (p.textures[usage]) {
            igOpenPopupOnItemClick("TEX_OPTIONS");
            if (igBeginPopup("TEX_OPTIONS")) {

                // Allow saving texture to file
                if (igMenuItem(__("Save to File"))) {
                    TFD_Filter[] filters = [
                        {["*.png"], "PNG File"}
                    ];
                    string file = incShowSaveDialog(filters, "texture.png");
                    if (file) {
                        if (file.extension.empty) {
                            file = file.setExtension("png");
                        }
                        p.textures[usage].save(file);
                    }
                }

                // Allow saving texture to file
                if (igMenuItem(__("Load from File"))) {
                    TFD_Filter[] filters = [
                        { ["*.png"], "Portable Network Graphics (*.png)" },
                        { ["*.jpeg", "*.jpg"], "JPEG Image (*.jpeg)" },
                        { ["*.tga"], "TARGA Graphics (*.tga)" }
                    ];

                    string file = incShowImportDialog(filters, _("Import..."));
                    if (file) {
                        applyTextureToSlot(p, usage, file);
                    }
                }

                if (usage != TextureUsage.Albedo) {
                    if (igMenuItem(__("Remove"))) {
                        p.textures[usage] = null;
                        
                        incActivePuppet().rescanNodes();
                        incActivePuppet().populateTextureSlots();
                    }
                } else {
                    // Option which causes the Albedo color to be the emission color.
                    // The item will glow the same color as it, itself is.
                    if (igMenuItem(__("Make Emissive"))) {
                        p.textures[TextureUsage.Emissive] = new Texture(
                            ShallowTexture(
                                p.textures[usage].getTextureData(true),
                                p.textures[usage].width,
                                p.textures[usage].height,
                                4,  // Input is RGBA
                                3   // Output should be RGB only
                            )
                        );

                        incActivePuppet().rescanNodes();
                        incActivePuppet().populateTextureSlots();
                    }
                }

                igEndPopup();
            }
        }

        // FILE DRAG & DROP
        if (igBeginDragDropTarget()) {
            const(ImGuiPayload)* payload = igAcceptDragDropPayload("__PARTS_DROP");
            if (payload !is null) {
                string[] files = *cast(string[]*)payload.Data;
                if (files.length > 0) {
                    applyTextureToSlot(p, usage, files[0]);
                }

                // Finish the file drag
                incFinishFileDrag();
            }

            igEndDragDropTarget();
        }
    igPopID();
    igPopID();
}

void incInspectorModelPart(Part node) {
    if (incBeginCategory(__("Part"))) {
        
        if (!node.getMesh().isReady()) { 
            igSpacing();
            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Cannot inspect an unmeshed part"));
            return;
        }
        igSpacing();

        // BLENDING MODE
        import std.conv : text;
        import std.string : toStringz;

        ImVec2 avail = incAvailableSpace();
        float availForTextureSlots = round((avail.x/3.0)-2.0);
        ImVec2 elemSize = ImVec2(availForTextureSlots, availForTextureSlots);

        incInspectorTextureSlot(node, TextureUsage.Albedo, _("Albedo"), elemSize);
        igSameLine(0, 4);
        incInspectorTextureSlot(node, TextureUsage.Emissive, _("Emissive"), elemSize);
        igSameLine(0, 4);
        incInspectorTextureSlot(node, TextureUsage.Bumpmap, _("Bumpmap"), elemSize);
        
        igSpacing();
        igSpacing();

        incText(_("Tint (Multiply)"));
        igColorEdit3("###TINT", cast(float[3]*)node.tint.ptr);

        incText(_("Tint (Screen)"));
        igColorEdit3("###S_TINT", cast(float[3]*)node.screenTint.ptr);

        incText(_("Emission Strength"));
        float strengthPerc = node.emissionStrength*100;
        if (igDragFloat("###S_EMISSION", &strengthPerc, 0.1, 0, float.max, "%.0f%%")) {
            node.emissionStrength = strengthPerc*0.01;
        }

        // Padding
        igSpacing();
        igSpacing();
        igSpacing();

        // Header for the Blending options for Parts
        incText(_("Blending"));
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

        incText(_("Opacity"));
        igSliderFloat("###Opacity", &node.opacity, 0, 1f, "%0.2f");
        igSpacing();
        igSpacing();

        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Masks"));
        igSpacing();

        // Threshold slider name for adjusting how transparent a pixel can be
        // before it gets discarded.
        incText(_("Threshold"));
        igSliderFloat("###Threshold", &node.maskAlphaThreshold, 0.0, 1.0, "%.2f");
        
        igSpacing();

        // The sources that the part gets masked by. Depending on the masking mode
        // either the sources will cut out things that don't overlap, or cut out
        // things that do.
        incText(_("Mask Sources"));
        if (igBeginListBox("###MaskSources", ImVec2(0, 128))) {
            if (node.masks.length == 0) {
                incText(_("(Drag a Part or Mask Here)"));
            }

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
                            incEndCategory();
                            return;
                        }

                        igEndPopup();
                    }

                    if (masker.mode == MaskingMode.Mask) igSelectable(_("%s (Mask)").format(masker.maskSrc.name).toStringz);
                    else igSelectable(_("%s (Dodge)").format(masker.maskSrc.name).toStringz);

                    
                    if(igBeginDragDropTarget()) {
                        const(ImGuiPayload)* payload = igAcceptDragDropPayload("_MASKITEM");
                        if (payload !is null) {
                            if (MaskBinding* binding = cast(MaskBinding*)payload.Data) {
                                ptrdiff_t maskIdx = node.getMaskIdx(binding.maskSrcUUID);
                                if (maskIdx >= 0) {
                                    import std.algorithm.mutation : remove;

                                    node.masks = node.masks.remove(maskIdx);
                                    if (i == 0) node.masks = *binding ~ node.masks;
                                    else if (i+1 >= node.masks.length) node.masks ~= *binding;
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
                        incText(masker.maskSrc.name);
                        igEndDragDropSource();
                    }
                igPopID();
            }
            igEndListBox();
        }

        if(igBeginDragDropTarget()) {
            const(ImGuiPayload)* payload = igAcceptDragDropPayload("_PUPPETNTREE");
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
    incEndCategory();
}

void incInspectorModelCamera(ExCamera node) {
    if (incBeginCategory(__("Camera"))) {
        
        incText(_("Viewport"));
        igIndent();
            igSetNextItemWidth(incAvailableSpace().x);
            igDragFloat2("###VIEWPORT", &node.getViewport().vector);
        igUnindent();

        // Padding
        igSpacing();
        igSpacing();
    }
    incEndCategory();
}

void incInspectorModelComposite(Composite node) {
    if (incBeginCategory(__("Composite"))) {
        

        igSpacing();

        // BLENDING MODE
        import std.conv : text;
        import std.string : toStringz;


        incText(_("Tint (Multiply)"));
        igColorEdit3("###TINT", cast(float[3]*)node.tint.ptr);

        incText(_("Tint (Screen)"));
        igColorEdit3("###S_TINT", cast(float[3]*)node.screenTint.ptr);

        // Header for the Blending options for Parts
        incText(_("Blending"));
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

        incText(_("Opacity"));
        igSliderFloat("###Opacity", &node.opacity, 0, 1f, "%0.2f");
        igSpacing();
        igSpacing();

        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Masks"));
        igSpacing();

        // Threshold slider name for adjusting how transparent a pixel can be
        // before it gets discarded.
        incText(_("Threshold"));
        igSliderFloat("###Threshold", &node.threshold, 0.0, 1.0, "%.2f");
        
        igSpacing();

        // Padding
        igSpacing();
        igSpacing();
    }
    incEndCategory();
}

void incInspectorModelSimplePhysics(SimplePhysics node) {
    if (incBeginCategory(__("SimplePhysics"))) {
        float adjustSpeed = 1;

        igSpacing();

        // BLENDING MODE
        import std.conv : text;
        import std.string : toStringz;

        igPushID("TargetParam");
            if (igBeginPopup("TPARAM")) {
                if (node.param) {
                    if (igMenuItem(__("Unmap"))) {
                        node.param = null;
                        incActivePuppet().rescanNodes();
                    }
                } else {
                    incDummyLabel(_("Unassigned"), ImVec2(128, 16));
                }

                igEndPopup();
            }

            incText(_("Parameter"));
            string paramName = _("(unassigned)");
            if (node.param !is null) paramName = node.param.name;
            igInputText("###TARGET_PARAM", cast(char*)paramName.toStringz, paramName.length, ImGuiInputTextFlags.ReadOnly);
            igOpenPopupOnItemClick("TPARAM", ImGuiPopupFlags.MouseButtonRight);

            if(igBeginDragDropTarget()) {
                const(ImGuiPayload)* payload = igAcceptDragDropPayload("_PARAMETER");
                if (payload !is null) {
                    ParamDragDropData* payloadParam = *cast(ParamDragDropData**)payload.Data;
                    node.param = payloadParam.param;
                    incActivePuppet().rescanNodes();
                }

                igEndDragDropTarget();
            }

        igPopID();

        incText(_("Type"));
        if (igBeginCombo("###PhysType", __(node.modelType.text))) {

            if (igSelectable(__("Pendulum"), node.modelType == PhysicsModel.Pendulum)) node.modelType = PhysicsModel.Pendulum;

            if (igSelectable(__("SpringPendulum"), node.modelType == PhysicsModel.SpringPendulum)) node.modelType = PhysicsModel.SpringPendulum;

            igEndCombo();
        }

        igSpacing();

        incText(_("Mapping mode"));
        if (igBeginCombo("###PhysMapMode", __(node.mapMode.text))) {

            if (igSelectable(__("AngleLength"), node.mapMode == ParamMapMode.AngleLength)) node.mapMode = ParamMapMode.AngleLength;

            if (igSelectable(__("XY"), node.mapMode == ParamMapMode.XY)) node.mapMode = ParamMapMode.XY;

            igEndCombo();
        }

        igSpacing();

        igPushID("SimplePhysics");
        
        igPushID(-1);
            igCheckbox(__("Local Transform Lock"), &node.localOnly);
            incTooltip(_("Whether the physics system only listens to the movement of the physics node itself"));
            igSpacing();
            igSpacing();
        igPopID();

        igPushID(0);
            incText(_("Gravity scale"));
            incDragFloat("gravity", &node.gravity, adjustSpeed/100, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
            igSpacing();
            igSpacing();
        igPopID();

        igPushID(1);
            incText(_("Length"));
            incDragFloat("length", &node.length, adjustSpeed/100, 0, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
            igSpacing();
            igSpacing();
        igPopID();

        igPushID(2);
            incText(_("Resonant frequency"));
            incDragFloat("frequency", &node.frequency, adjustSpeed/100, 0.01, 30, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
            igSpacing();
            igSpacing();
        igPopID();

        igPushID(3);
            incText(_("Damping"));
            incDragFloat("damping_angle", &node.angleDamping, adjustSpeed/100, 0, 5, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
        igPopID();

        igPushID(4);
            incDragFloat("damping_length", &node.lengthDamping, adjustSpeed/100, 0, 5, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
            igSpacing();
            igSpacing();
        igPopID();

        igPushID(5);
            incText(_("Output scale"));
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
    incEndCategory();
}


void incInspectorModelMeshGroup(MeshGroup node) {
    if (incBeginCategory(__("MeshGroup"))) {
        

        igSpacing();

        bool dynamic = node.dynamic;
        if (igCheckbox(__("Dynamic Deformation (slower)"), &dynamic)) {
            node.switchMode(dynamic);
        }
        incTooltip(_("Whether the MeshGroup should dynamically deform children,\nthis is an expensive operation and should not be overused."));

        // Padding
        igSpacing();
    }
    incEndCategory();
}

//
//  MODEL MODE ARMED
//
void incInspectorDeformFloatDragVal(string name, string paramName, float adjustSpeed, Node node, Parameter param, vec2u cursor, bool rotation=false) {
    float currFloat = node.getDefaultValue(paramName);
    if (ValueParameterBinding b = cast(ValueParameterBinding)param.getBinding(node, paramName)) {
        currFloat = b.getValue(cursor);
    }

    // Convert to degrees for display
    if (rotation) currFloat = degrees(currFloat);

    if (incDragFloat(name, &currFloat, adjustSpeed, -float.max, float.max, rotation ? "%.2f°" : "%.2f", ImGuiSliderFlags.NoRoundToFormat)) {
        
        // Convert back to radians for data managment
        if (rotation) currFloat = radians(currFloat);

        // Set binding
        GroupAction groupAction = null;
        ValueParameterBinding b = cast(ValueParameterBinding)param.getBinding(node, paramName);
        if (b is null) {
            b = cast(ValueParameterBinding)param.createBinding(node, paramName);
            param.addBinding(b);
            groupAction = new GroupAction();
            auto addAction = new ParameterBindingAddAction(param, b);
            groupAction.addAction(addAction);
        }

        // Push action
        auto action = new ParameterBindingValueChangeAction!(float)(b.getName(), b, cursor.x, cursor.y);
        b.setValue(cursor, currFloat);
        action.updateNewState();
        if (groupAction) {
            groupAction.addAction(action);
            incActionPush(groupAction);
        } else {
            incActionPush(action);
        }

        if (auto editor = incViewportModelDeformGetEditor()) {
            if (auto e = editor.getEditorFor(node)) {
                e.adjustPathTransform();
            }
        }
    }
}

void incInspectorDeformInputFloat(string name, string paramName, float step, float stepFast, Node node, Parameter param, vec2u cursor) {
    float currFloat = node.getDefaultValue(paramName);
    if (ValueParameterBinding b = cast(ValueParameterBinding)param.getBinding(node, paramName)) {
        currFloat = b.getValue(cursor);
    }
    if (igInputFloat(name.toStringz, &currFloat, step, stepFast, "%.2f")) {
        GroupAction groupAction = null;
        ValueParameterBinding b = cast(ValueParameterBinding)param.getBinding(node, paramName);
        if (b is null) {
            b = cast(ValueParameterBinding)param.createBinding(node, paramName);
            param.addBinding(b);
            groupAction = new GroupAction();
            auto addAction = new ParameterBindingAddAction(param, b);
            groupAction.addAction(addAction);
        }
        auto action = new ParameterBindingValueChangeAction!(float)(b.getName(), b, cursor.x, cursor.y);
        b.setValue(cursor, currFloat);
        action.updateNewState();
        if (groupAction) {
            groupAction.addAction(action);
            incActionPush(groupAction);
        } else {
            incActionPush(action);
        }
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

    if (igColorEdit3("###COLORADJ", &rgbadj)) {

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
        GroupAction groupAction = null;
        ValueParameterBinding b = cast(ValueParameterBinding)param.getBinding(node, paramName);
        if (b is null) {
            b = cast(ValueParameterBinding)param.createBinding(node, paramName);
            param.addBinding(b);
            groupAction = new GroupAction();
            auto addAction = new ParameterBindingAddAction(param, b);
            groupAction.addAction(addAction);
        }
        auto action = new ParameterBindingValueChangeAction!(float)(b.getName(), b, cursor.x, cursor.y);
        b.setValue(cursor, currFloat);
        action.updateNewState();
        if (groupAction) {
            groupAction.addAction(action);
            incActionPush(groupAction);
        } else {
            incActionPush(action);
        }
    }
}

void incInspectorDeformDragFloat(string name, string paramName, float speed, float min, float max, const(char)* fmt, Node node, Parameter param, vec2u cursor) {
    float value = incInspectorDeformGetValue(node, param, paramName, cursor);
    if (igDragFloat(name.toStringz, &value, speed, min, max, fmt)) {
        incInspectorDeformSetValue(node, param, paramName, cursor, value);
    }
}

float incInspectorDeformGetValue(Node node, Parameter param, string paramName, vec2u cursor) {
    float currFloat = node.getDefaultValue(paramName);
    if (ValueParameterBinding b = cast(ValueParameterBinding)param.getBinding(node, paramName)) {
        currFloat = b.getValue(cursor);
    }
    return currFloat;
}

void incInspectorDeformSetValue(Node node, Parameter param, string paramName, vec2u cursor, float value) {
        GroupAction groupAction = null;
        ValueParameterBinding b = cast(ValueParameterBinding)param.getBinding(node, paramName);
        if (b is null) {
            b = cast(ValueParameterBinding)param.createBinding(node, paramName);
            param.addBinding(b);
            groupAction = new GroupAction();
            auto addAction = new ParameterBindingAddAction(param, b);
            groupAction.addAction(addAction);
        }
        auto action = new ParameterBindingValueChangeAction!(float)(b.getName(), b, cursor.x, cursor.y);
        b.setValue(cursor, value);
        action.updateNewState();
        if (groupAction) {
            groupAction.addAction(action);
            incActionPush(groupAction);
        } else {
            incActionPush(action);
        }

        if (auto editor = incViewportModelDeformGetEditor()) {
            if (auto e = editor.getEditorFor(node)) {
                e.adjustPathTransform();
            }
        }
}

void incInspectorDeformTRS(Node node, Parameter param, vec2u cursor) {
    if (incBeginCategory(__("Transform"))) {   
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
                incInspectorDeformFloatDragVal("rotation.x", "transform.r.x", 0.05f, node, param, cursor, true);
            igPopID();

            igSameLine(0, 4);

            // Rotation Y
            igPushID(4);
                incInspectorDeformFloatDragVal("rotation.y", "transform.r.y", 0.05f, node, param, cursor, true);
            igPopID();

            igSameLine(0, 4);

            // Rotation Z
            igPushID(5);
                incInspectorDeformFloatDragVal("rotation.z", "transform.r.z", 0.05f, node, param, cursor, true);
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
    incEndCategory();
}

void incInspectorDeformPart(Part node, Parameter param, vec2u cursor) {
    if (incBeginCategory(__("Part"))) {
        igBeginGroup();
            igIndent(16);
                // Header for texture options    
                if (incBeginCategory(__("Textures")))  {

                    incText(_("Tint (Multiply)"));

                    incInspectorDeformColorEdit3(["tint.r", "tint.g", "tint.b"], node, param, cursor);

                    incText(_("Tint (Screen)"));
                    incInspectorDeformColorEdit3(["screenTint.r", "screenTint.g", "screenTint.b"], node, param, cursor);
                    
                    incText(_("Emission Strength"));
                    float strengthPerc = incInspectorDeformGetValue(node, param, "emissionStrength", cursor)*100;
                    if (igDragFloat("###S_EMISSION", &strengthPerc, 0.1, 0, float.max, "%.0f%%")) {
                        incInspectorDeformSetValue(node, param, "emissionStrength", cursor, strengthPerc*0.01);
                    }

                    // Padding
                    igSeparator();
                    igSpacing();
                    igSpacing();
                }
                incEndCategory();
            igUnindent();
        igEndGroup();

        incText(_("Opacity"));
        incInspectorDeformSliderFloat("###Opacity", "opacity", 0, 1f, node, param, cursor);
        igSpacing();
        igSpacing();

        // Threshold slider name for adjusting how transparent a pixel can be
        // before it gets discarded.
        incText(_("Threshold"));
        incInspectorDeformSliderFloat("###Threshold", "alphaThreshold", 0.0, 1.0, node, param, cursor);
    }
    incEndCategory();
}

void incInspectorDeformComposite(Composite node, Parameter param, vec2u cursor) {
    if (incBeginCategory(__("Composite"))) {
        igBeginGroup();
            igIndent(16);
                // Header for texture options    
                if (incBeginCategory(__("Textures")))  {

                    incText(_("Tint (Multiply)"));

                    incInspectorDeformColorEdit3(["tint.r", "tint.g", "tint.b"], node, param, cursor);

                    incText(_("Tint (Screen)"));

                    incInspectorDeformColorEdit3(["screenTint.r", "screenTint.g", "screenTint.b"], node, param, cursor);

                    // Padding
                    igSeparator();
                    igSpacing();
                    igSpacing();
                }
                incEndCategory();
            igUnindent();
        igEndGroup();

        incText(_("Opacity"));
        incInspectorDeformSliderFloat("###Opacity", "opacity", 0, 1f, node, param, cursor);
        igSpacing();
        igSpacing();
    }
    incEndCategory();
}