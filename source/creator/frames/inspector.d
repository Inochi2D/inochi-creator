module creator.frames.inspector;
import creator.frames;
import creator;
import inochi2d;
import bindbc.imgui;
import std.string;
import std.algorithm.searching;
import std.algorithm.mutation;
import std.conv;

/**
    The inspector frame
*/
class InspectorFrame : Frame {
private:
    void handlePartNodes(Node node) {
        if (Part partNode = cast(Part)node) {
            igText("Part");
            igSeparator();

            igSliderFloat("Opacity", &partNode.opacity, 0, 1f, "%0.2f", 0);

            // MASK MODE
            if (igBeginCombo("Masking Mode", partNode.maskingMode ? "Dodge" : "Mask", 0)) {

                if (igSelectableBool("Mask", partNode.maskingMode == MaskingMode.Mask, 0, ImVec2(0, 0))) {
                    partNode.maskingMode = MaskingMode.Mask;
                }
                if (igSelectableBool("Dodge", partNode.maskingMode == MaskingMode.DodgeMask, 0, ImVec2(0, 0))) {
                    partNode.maskingMode = MaskingMode.DodgeMask;
                }

                igEndCombo();
            }

            // Sensitivity slider
            igSliderFloat("Mask Sensitivity", &partNode.maskAlphaThreshold, 0.0, 1.0, "%.2f", 0);

            // MASKED BY
            igBeginListBox("Masked By", ImVec2(0, 128));
                foreach(masker; partNode.mask) {
                    
                    if(igBeginDragDropSource(0)) {
                        igSetDragDropPayload("_MASKITEM", cast(void*)&masker, (&masker).sizeof, ImGuiCond_Always);
                        igText(masker.name.toStringz);
                        igEndDragDropSource();
                    }
                    igText(masker.name.toStringz);
                }
            igEndListBox();

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

        }
    }

protected:
    override
    void onUpdate() {
        Node node = incSelectedNode();
        if (node !is null) {
            igText(node.typeId().toStringz);
            igSameLine(0, 4);
            igSeparatorEx(ImGuiSeparatorFlags_Vertical);
            igSameLine(0, 8);
            igText(node.name.toStringz);
            igSeparator();

            igCheckbox("Enabled", &node.enabled);

            float zsortV = node.relZSort;
            if (igInputFloat("ZSort", &zsortV, 0.01, 0.05, "%0.2f", 0)) {
                node.zSort = zsortV;
            }

            handlePartNodes(node);
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


