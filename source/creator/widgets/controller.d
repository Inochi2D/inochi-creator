module creator.widgets.controller;
import creator.widgets;
import inochi2d;

bool incController(string str_id, ref Parameter param, ImVec2 size) {
    ImGuiWindow* window = igGetCurrentWindow();
    if (window.SkipItems) return false;

    ImVec2 avail;
    igGetContentRegionAvail(&avail);
    if (size.x <= 0) size.x = avail.x-size.x;
    if (!param.isVec2) size.y = 32;
    else if (size.y <= 0) size.y = avail.y-size.y;

    ImGuiContext* ctx = igGetCurrentContext();
    ImGuiStyle style = ctx.Style;
    ImGuiID id = ImGuiWindow_GetID_Str(window, str_id.ptr, str_id.ptr+str_id.length);
    ImGuiStorage* storage = igGetStateStorage();
    
    // Handle padding
    ImVec2 pos = window.DC.CursorPos;
    size.x -= style.FramePadding.x*2;

    // Apply size to "canvas"
    ImRect bb = ImRect(pos, ImVec2(pos.x+size.x, pos.y+size.y));
    ImRect inner_bb = ImRect(ImVec2(pos.x+8, pos.y+8), ImVec2(pos.x+size.x-8, pos.y+size.y-8));
    ImRect clamp_bb = ImRect(
        ImVec2(inner_bb.Min.x+4, inner_bb.Min.y+4),
        ImVec2(inner_bb.Max.x-4, inner_bb.Max.y-4)
    );
    igItemSize_Rect(bb, style.FramePadding.y);
    if (!igItemAdd(bb, id, null))
        return false;
    ImDrawList* drawList = igGetWindowDrawList();

    if (igIsItemHovered()) {
        if (igIsMouseClicked(ImGuiMouseButton.Left, false)) {
            ImGuiStorage_SetBool(storage, id, true);
        }
    }
    
    if (!igIsMouseDown(ImGuiMouseButton.Left)) {
        ImGuiStorage_SetBool(storage, id, false);
    }

    // Get clamped mouse position
    ImVec2 mpos;
    igGetMousePos(&mpos);
    mpos.x = clamp(mpos.x, clamp_bb.Min.x, clamp_bb.Max.x);
    mpos.y = clamp(mpos.y, clamp_bb.Min.y, clamp_bb.Max.y);

    if (param.isVec2) {
        float oldSize = style.FrameBorderSize;
        igPushStyleVar_Float(ImGuiStyleVar.FrameBorderSize, 1);
            igRenderFrameBorder(inner_bb.Min, inner_bb.Max, style.FrameRounding);
        igPopStyleVar(1);

        if (ImGuiStorage_GetBool(storage, id, false)) {

                // Calculate the proper value
                param.handle.x = (((mpos.x-clamp_bb.Min.x)/clamp_bb.Max.x)*2);
                param.handle.y = (((mpos.y-clamp_bb.Min.y)/clamp_bb.Max.y)*2);
                param.handle = clamp(param.handle, vec2(-1, -1), vec2(1, 1));
        }

        // Draw our selector circle
        ImDrawList_AddCircleFilled(
            drawList, 
            ImVec2(
                clamp_bb.Min.x + (clamp_bb.Max.x*((param.handle.x+1)/2)), 
                clamp_bb.Min.y + (clamp_bb.Max.y*((param.handle.y+1)/2))
            ), 
            4, 
            igGetColorU32_Vec4(ImVec4(1, 0, 0, 1)), 
            12
        );
    } else {
        ImDrawList_AddLine(
            drawList, 
            ImVec2(
                inner_bb.Min.x,
                inner_bb.Min.y
            ),
            ImVec2(
                inner_bb.Min.x,
                inner_bb.Max.y
            ),
            igGetColorU32_Col(ImGuiCol.Border, 1),
            2
        );

        ImDrawList_AddLine(
            drawList, 
            ImVec2(
                inner_bb.Min.x,
                pos.y+(size.y/2)
            ),
            ImVec2(
                inner_bb.Max.x,
                pos.y+(size.y/2)
            ),
            igGetColorU32_Col(ImGuiCol.Border, 1),
            2
        );

        ImDrawList_AddLine(
            drawList, 
            ImVec2(
                inner_bb.Max.x,
                inner_bb.Min.y
            ),
            ImVec2(
                inner_bb.Max.x,
                inner_bb.Max.y
            ),
            igGetColorU32_Col(ImGuiCol.Border, 1),
            2
        );

        if (ImGuiStorage_GetBool(storage, id, false)) {
            
            // Calculate the proper value
            param.handle.x = (
                (
                    (mpos.x-clamp_bb.Min.x)/clamp_bb.Max.x
                )*2)-1;
            param.handle = clamp(param.handle, vec2(-1, -1), vec2(1, 1));
        }

        // Draw our selector circle
        ImDrawList_AddCircleFilled(
            drawList, 
            ImVec2(
                clamp_bb.Min.x + (clamp_bb.Max.x*((param.handle.x+1)/2)), 
                pos.y+(size.y/2)
            ), 
            4, 
            igGetColorU32_Vec4(ImVec4(1, 0, 0, 1)), 
            12
        );
    }
    return true;
}