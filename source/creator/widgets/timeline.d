module creator.widgets.timeline;
import inochi2d;
import creator.widgets;
import bindbc.imgui;

enum MIN_TRACK_HEIGHT = 32;
enum MIN_HEADER_WIDTH = 256;
enum DRAG_SIZE = 4;

void incAnimationLaneHeader(ref AnimationLane lane, ref float width, ref float height) {

    bool isNode = lane.target == AnimationLaneTarget.Node;
    igPushID(isNode ? cast(void*)lane.nodeRef : cast(void*)lane.paramRef);
    igPushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(4, 0));
    igPushStyleColor(ImGuiCol.ChildBg, ImVec4(0, 0, 0, 0.15));
        if (igBeginChild("HEADER", ImVec2(width, height), true)) {

            incDummy(ImVec2(0, 8));
            igIndent();
                switch(lane.target) {
                    
                    case AnimationLaneTarget.Node:
                        incText(lane.nodeRef.targetNode.name);
                        igSameLine(0, 4);
                        incTextLabel(lane.nodeRef.targetName);
                        break;
                    
                    case AnimationLaneTarget.Parameter:
                        incText(lane.paramRef.targetParam.name);
                        igSameLine(0, 4);
                        incTextLabel(lane.paramRef.targetAxis == 0 ? "X" : "Y");
                        break;
                    
                    default: assert(0);
                }
            igUnindent();

            incHeaderResizer(width, height, true);
            incHeaderResizer(width, height, false);
        }
        igEndChild();
    igPopStyleColor();
    igPopStyleVar();
    igPopID();
}

/**
    Draws resizer for header
*/
void incHeaderResizer(ref float width, ref float height, bool side = false) {
    igPushID(side ? "LEFT_RESIZE" : "RIGHT_RESIZE");
        auto window = igGetCurrentWindow();
        auto drawList = igGetWindowDrawList();
        auto io = igGetIO();
        auto storage = igGetStateStorage();
        auto isResizingID = igGetID("IsResizing");
        auto resizeDirectionID = igGetID("ResizeDirection");

        auto isResizing = ImGuiStorage_GetBool(storage, isResizingID, false);
        auto resizeDir = ImGuiStorage_GetBool(storage, resizeDirectionID, false);
        ImVec2 start = ImVec2(
            window.OuterRectClipped.Max.x,
            window.OuterRectClipped.Max.y,
        );

        ImVec2 mousePos;
        igGetMousePos(&mousePos);

        ImVec2 size = ImVec2(
            window.WorkRect.Min.x-window.WorkRect.Max.x,
            window.WorkRect.Min.y-window.WorkRect.Max.y,
        );

        ImVec2 dragViewStart;
        ImVec2 dragViewEnd;
        bool isHovered;

        // Get data for the relevant side.
        if (side) {
            isHovered = mousePos.y > start.y+size.y-DRAG_SIZE && 
                        mousePos.y < start.y+size.y+DRAG_SIZE &&
                        mousePos.x > start.x && 
                        mousePos.x < start.x+size.x;
            dragViewStart = ImVec2(start.x, start.y+height);
            dragViewEnd = ImVec2(start.x+width, start.y+height);
            
        } else {
            isHovered = mousePos.y > start.y && 
                        mousePos.y < start.y+size.y &&
                        mousePos.x > start.x+size.x-DRAG_SIZE && 
                        mousePos.x < start.x+size.x+DRAG_SIZE;
            dragViewStart = ImVec2(start.x+width, start.y);
            dragViewEnd = ImVec2(start.x+width, start.y+height);
        }

        if (isResizing) {
            ImDrawList_AddLine(drawList, 
                dragViewStart,
                dragViewEnd,
                igGetColorU32(ImGuiCol.SeparatorActive, 0.5),
                DRAG_SIZE
            );

            // We're no longer resizing if the mouse button is up
            if (!io.MouseDown[ImGuiMouseButton.Left]) ImGuiStorage_SetBool(storage, isResizingID, false);

            if (resizeDir) {
                height = clamp(mousePos.y-start.y, MIN_TRACK_HEIGHT, float.max);
                igSetMouseCursor(ImGuiMouseCursor.ResizeNS);
            } else {
                width = clamp(mousePos.x-start.x, MIN_HEADER_WIDTH, float.max);
                igSetMouseCursor(ImGuiMouseCursor.ResizeEW);
            }
        } else {
            if (isHovered) {
                ImDrawList_AddLine(drawList, 
                    dragViewStart,
                    dragViewEnd,
                    igGetColorU32(ImGuiCol.SeparatorHovered, 0.5),
                    DRAG_SIZE
                );

                // Set cursors
                if (side) igSetMouseCursor(ImGuiMouseCursor.ResizeNS);
                else igSetMouseCursor(ImGuiMouseCursor.ResizeEW);
                
                if (igIsMouseClicked(ImGuiMouseButton.Left)) {
                    ImGuiStorage_SetBool(storage, isResizingID, true);
                    ImGuiStorage_SetBool(storage, resizeDirectionID, side);
                }
            } else {
                ImDrawList_AddLine(drawList, 
                    dragViewStart,
                    dragViewEnd,
                    igGetColorU32(ImGuiCol.Separator, 0.5),
                    DRAG_SIZE
                );
            }
        }
    igPopID();
}