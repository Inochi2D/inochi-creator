module creator.frames.inspector;
import creator.core;
import creator.frames;
import creator.widgets;
import creator;
import inochi2d;
import std.string;
import std.algorithm.searching;
import std.algorithm.mutation;
import std.conv;

/**
    The inspector frame
*/
class InspectorFrame : Frame {
private:
    void createLock(bool* val, string origin) {
        
        igSameLine(0, 0);
        igPushID(origin.ptr);
            igPushFont(incIconFont());
                igPushItemWidth(16);
                    igText(((*val ? "\uE897" : "\uE898")).toStringz);
                    
                    if (igIsItemClicked(ImGuiMouseButton.Left)) {
                        *val = !*val;
                    }
                igPopItemWidth();
            igPopFont();
        igPopID();
    }

    void handleTRS(Node node) {
        float adjustSpeed = 1;
        // if (igIsKeyDown(igGetKeyIndex(ImGuiKeyModFlags_Shift))) {
        //     adjustSpeed = 0.1;
        // }

        ImVec2 avail;
        igGetContentRegionAvail(&avail);

        float fontSize = 16;

        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Translation");
        igPushItemWidth((avail.x-4f-(fontSize*3f))/3f);
            igDragFloat("##translation_x", &node.localTransform.translation.vector[0], adjustSpeed, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
            createLock(&node.localTransform.lockTranslationX, "tra_x");

            igSameLine(0, 4);
            igDragFloat("##translation_y", &node.localTransform.translation.vector[1], adjustSpeed, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
            createLock(&node.localTransform.lockTranslationY, "tra_y");

            igSameLine(0, 4);
            igDragFloat("##translation_z", &node.localTransform.translation.vector[2], adjustSpeed, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
            createLock(&node.localTransform.lockTranslationZ, "tra_z");
        igPopItemWidth();

        igSpacing();
        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Rotation");
        igPushItemWidth((avail.x-4f-(fontSize*3f))/3f);
            igDragFloat("##rotation_x", &node.localTransform.rotation.vector[0], adjustSpeed/100, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
            
            createLock(&node.localTransform.lockRotationX, "rot_x");
            
            igSameLine(0, 4);
            igDragFloat("##rotation_y", &node.localTransform.rotation.vector[1], adjustSpeed/100, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
            
            createLock(&node.localTransform.lockRotationY, "rot_y");

            igSameLine(0, 4);
            igDragFloat("##rotation_z", &node.localTransform.rotation.vector[2], adjustSpeed/100, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
            
            createLock(&node.localTransform.lockRotationZ, "rot_z");
        igPopItemWidth();

        avail.x += igGetFontSize();

        igSpacing();
        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Scale");
        igPushItemWidth((avail.x-14f-(fontSize*2f))/2f);
            igDragFloat("##scale_x", &node.localTransform.scale.vector[0], adjustSpeed/100, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
            createLock(&node.localTransform.lockScaleX, "sca_z");

            igSameLine(0, 4);
            igDragFloat("##scale_y", &node.localTransform.scale.vector[1], adjustSpeed/100, -float.max, float.max, "%.2f", ImGuiSliderFlags.NoRoundToFormat);
            createLock(&node.localTransform.lockScaleY, "sca_z");
        igPopItemWidth();

        igSpacing();

        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Pixel Locking");
        createLock(&node.localTransform.pixelSnap, "pix_lk");

        // Padding
        igSpacing();
    }

    void handlePartNodes(Node node) {
        if (Part partNode = cast(Part)node) {
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
        Node node = incSelectedNode();
        if (node !is null) {
            igPushID(node.uuid);
                igText(node.typeId().toStringz);
                igSameLine(0, 4);
                igSeparatorEx(ImGuiSeparatorFlags.Vertical);
                igSameLine(0, 8);
                incInputText("", node.name);
            igPopID();
            igSeparator();

            handleTRS(node);

            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Sorting");
            float zsortV = node.relZSort;
            if (igInputFloat("ZSort", &zsortV, 0.01, 0.05, "%0.2f")) {
                node.zSort = zsortV;
            }

            if (node.typeId == "Part") {

                // Padding
                igSpacing();
                igSpacing();
                igSpacing();
                igSpacing();
                handlePartNodes(node);
            }
        } else {
            igText("No nodes selected...");
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
mixin incFrame!InspectorFrame;


