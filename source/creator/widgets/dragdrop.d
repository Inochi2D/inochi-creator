module creator.widgets.dragdrop;
import creator.widgets;
import bindbc.imgui;
import inochi2d;

void incDragdropNodeList(Node node) {
    enum ENTRY_SIZE = 48;
    igPushID(node.uuid);
        if (Part part = cast(Part)node) {
            incTextureSlotUntitled("ICON", part.textures[0], ImVec2(ENTRY_SIZE-4, ENTRY_SIZE-4), 24, ImGuiWindowFlags.NoInputs);
        } else {
            incText(node.name);
        }
    igPopID();
}

void incDragdropNodeList(Node[] nodes) {
    enum ENTRY_SIZE = 48;

    int i = 0;
    int f = 0;
    foreach(Node node; nodes) {
        if (Part part = cast(Part)node) {
            f++;
            if (i++ != 0 && i%4 != 1) {
                igSameLine(0, 4);
            }

            igPushID(part.uuid);
                incTextureSlotUntitled("ICON", part.textures[0], ImVec2(ENTRY_SIZE-4, ENTRY_SIZE-4), 24, ImGuiWindowFlags.NoInputs);
            igPopID();
        }
    }

    if (i < nodes.length) {
        if (f > 0) igDummy(ImVec2(0, 4));

        foreach(Node node; nodes) {
            if (Part part = cast(Part)node) continue;
            incText(node.name);
        }
    }
}