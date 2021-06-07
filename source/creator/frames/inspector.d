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
        igPushIDStr(origin.ptr);
            igPushFont(incIconFont());
                igPushItemWidth(16);
                    igText(((*val ? "\uE897" : "\uE898")).toStringz);
                    
                    if (igIsItemClicked(ImGuiMouseButton_Left)) {
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
            igDragFloat("##translation_x", &node.localTransform.translation.vector[0], adjustSpeed, -float.max, float.max, "%.2f", ImGuiSliderFlags_NoRoundToFormat);
            createLock(&node.localTransform.lockTranslationX, "tra_x");

            igSameLine(0, 4);
            igDragFloat("##translation_y", &node.localTransform.translation.vector[1], adjustSpeed, -float.max, float.max, "%.2f", ImGuiSliderFlags_NoRoundToFormat);
            createLock(&node.localTransform.lockTranslationY, "tra_y");

            igSameLine(0, 4);
            igDragFloat("##translation_z", &node.localTransform.translation.vector[2], adjustSpeed, -float.max, float.max, "%.2f", ImGuiSliderFlags_NoRoundToFormat);
            createLock(&node.localTransform.lockTranslationZ, "tra_z");
        igPopItemWidth();

        igSpacing();
        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Rotation");
        igPushItemWidth((avail.x-4f-(fontSize*3f))/3f);
            igDragFloat("##rotation_x", &node.localTransform.rotation.vector[0], adjustSpeed/100, -float.max, float.max, "%.2f", ImGuiSliderFlags_NoRoundToFormat);
            
            createLock(&node.localTransform.lockRotationX, "rot_x");
            
            igSameLine(0, 4);
            igDragFloat("##rotation_y", &node.localTransform.rotation.vector[1], adjustSpeed/100, -float.max, float.max, "%.2f", ImGuiSliderFlags_NoRoundToFormat);
            
            createLock(&node.localTransform.lockRotationY, "rot_y");

            igSameLine(0, 4);
            igDragFloat("##rotation_z", &node.localTransform.rotation.vector[2], adjustSpeed/100, -float.max, float.max, "%.2f", ImGuiSliderFlags_NoRoundToFormat);
            
            createLock(&node.localTransform.lockRotationZ, "rot_z");
        igPopItemWidth();

        avail.x += igGetFontSize();

        igSpacing();
        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Scale");
        igPushItemWidth((avail.x-14f-(fontSize*2f))/2f);
            igDragFloat("##scale_x", &node.localTransform.scale.vector[0], adjustSpeed/100, -float.max, float.max, "%.2f", ImGuiSliderFlags_NoRoundToFormat);
            createLock(&node.localTransform.lockScaleX, "sca_z");

            igSameLine(0, 4);
            igDragFloat("##scale_y", &node.localTransform.scale.vector[1], adjustSpeed/100, -float.max, float.max, "%.2f", ImGuiSliderFlags_NoRoundToFormat);
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

            igSliderFloat("Opacity", &partNode.opacity, 0, 1f, "%0.2f", 0);
            igSpacing();
            igSpacing();

            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Masks");
            igSpacing();

            // MASK MODE
            if (igBeginCombo("Mode", partNode.maskingMode ? "Dodge" : "Mask", 0)) {

                if (igSelectableBool("Mask", partNode.maskingMode == MaskingMode.Mask, 0, ImVec2(0, 0))) {
                    partNode.maskingMode = MaskingMode.Mask;
                }
                if (igSelectableBool("Dodge", partNode.maskingMode == MaskingMode.DodgeMask, 0, ImVec2(0, 0))) {
                    partNode.maskingMode = MaskingMode.DodgeMask;
                }
                igEndCombo();
            }

            // Sensitivity slider
            igSliderFloat("Threshold", &partNode.maskAlphaThreshold, 0.0, 1.0, "%.2f", 0);

            // MASKED BY
            if (igBeginListBox("Masked By", ImVec2(0, 128))) {
                foreach(i, masker; partNode.mask) {
                    igPushIDInt(cast(int)i);
                        if(igBeginDragDropSource(ImGuiDragDropFlags_SourceAllowNullID)) {
                            igSetDragDropPayload("_MASKITEM", cast(void*)&masker, (&masker).sizeof, ImGuiCond_Always);
                            igText(masker.name.toStringz);
                            igEndDragDropSource();
                        }
                    igPopID();
                    igText(masker.name.toStringz);
                }
                igEndListBox();
            }

            if(igBeginDragDropTarget()) {
                ImGuiPayload* payload = igAcceptDragDropPayload("_PUPPETNTREE", 0);
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
                ImGuiPayload* payload = igAcceptDragDropPayload("_MASKITEM", 0);
                if (payload !is null) {
                    if (Drawable payloadDrawable = cast(Drawable)*cast(Node*)payload.Data) {
                        if (ptrdiff_t idx = partNode.mask.countUntil(payloadDrawable) != -1) {
                            if (partNode.mask.length == 1) partNode.mask.length = 0;
                            else partNode.mask.remove(idx);
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
            igPushIDInt(node.uuid);
                igText(node.typeId().toStringz);
                igSameLine(0, 4);
                igSeparatorEx(ImGuiSeparatorFlags_Vertical);
                igSameLine(0, 8);
                incInputText("", node.name, 0);
            igPopID();
            igSeparator();

            handleTRS(node);

            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Sorting");
            float zsortV = node.relZSort;
            if (igInputFloat("ZSort", &zsortV, 0.01, 0.05, "%0.2f", 0)) {
                node.zSort = zsortV;
            }

            if (node.typeId != "Node") {

                // Padding
                igSpacing();
                igSpacing();
                igSpacing();
                igSpacing();
                handlePartNodes(node);
            }
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


