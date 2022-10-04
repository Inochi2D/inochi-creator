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

/**
    Begins fake drag/drop context
*/
void incBeginDragDropFake() {
    auto storage = igGetStateStorage();
    auto ctx = igGetCurrentContext();
    ImGuiStorage_SetBool(storage, igGetID("DRAG_DROP_ACTIVE"), ctx.DragDropActive);
    ImGuiStorage_SetInt(storage, igGetID("DRAG_DROP_FRAME_COUNT"), ctx.DragDropPayload.DataFrameCount);
    ctx.DragDropActive = true;
    ctx.DragDropPayload.DataFrameCount = ctx.FrameCount;
}

/**
    Ends fake drag/drop context
*/
void incEndDragDropFake() {
    auto storage = igGetStateStorage();
    auto ctx = igGetCurrentContext();
    bool active = ImGuiStorage_GetBool(storage, igGetID("DRAG_DROP_ACTIVE"), false);
    int frameCount = ImGuiStorage_GetInt(storage, igGetID("DRAG_DROP_FRAME_COUNT"), -1);
    ctx.DragDropActive = active;
    ctx.DragDropPayload.DataFrameCount = frameCount;
}