module creator.widgets.shadow;
import bindbc.imgui;
import std.stdio : writeln;

/**
    Creates drawlist
*/
ImDrawList* incCreateWindowDrawList() {
    return ImDrawList_ImDrawList(igGetDrawListSharedData());
}

/**
    destroys drawlist
*/
void incDestroyWindowDrawList(ImDrawList* drawList) {
    ImDrawList_destroy(drawList);
}

private {
    T* prepend(T)(ref ImVector!T vec, ref ImVector!T other) {
        import core.stdc.string : memcpy;
        if (other.Size == 0) return &vec.Data[vec.Size];

        // First reserve space to make sure the data will fit.
        // NOTE: We need to *reserve* space, not resize
        // If we used resize, vec.Size would be wrong and we would
        // Get garbage data likely to crash the app.
        int newSize = vec.Size+other.Size;
        if (newSize > vec.Capacity) vec.reserve(vec._grow_capacity(newSize));

        memcpy(vec.Data+other.Size,     vec.Data,   vec.Size*T.sizeof);
        memcpy(vec.Data,                other.Data, other.Size*T.sizeof);

        // Apply the new size based on the previous sizes.
        vec.Size = newSize;
        return &vec.Data[vec.Size];
    }

    void prepend(ImDrawList* self, ImDrawList* other) {

        // Offset draw buffer
        ImDrawCmd* cmd = &self.CmdBuffer.Data[0];
        cmd.VtxOffset += other.VtxBuffer.size;
        cmd.IdxOffset += other.IdxBuffer.size;

        // Copy state from origin
        ImDrawCmd* ocmd = &other.CmdBuffer.Data[0];
        ocmd.TextureId = cmd.TextureId;
        ocmd.ClipRect = cmd.ClipRect;

        // Prepend
        self.CmdBuffer.prepend(other.CmdBuffer);
        self._VtxWritePtr = self.VtxBuffer.prepend(other.VtxBuffer);
        self._IdxWritePtr = self.IdxBuffer.prepend(other.IdxBuffer);
        self._VtxCurrentIdx = other.VtxBuffer.Size;
        self._Path.prepend(other._Path);
        self._TextureIdStack.prepend(other._TextureIdStack);
        self._ClipRectStack.prepend(other._ClipRectStack);
    }
}

/**
    Renders a shadow at the specified spot
*/
void incRenderWindowShadow(ImDrawList* drawList, ImRect area, float falloff=16, float startShade=0.25) {
    ImDrawList__ResetForNewFrame(drawList);
    auto outDrawList = igGetWindowDrawList();
    auto style = igGetStyle();

    float inset = style.WindowRounding;
    uint iColor = igGetColorU32(ImVec4(0, 0, 0, startShade));
    uint oColor = igGetColorU32(ImVec4(0, 0, 0, 0));

    ImVec2 shadowInnerMin = ImVec2(area.Min.x-inset, area.Min.y-inset);
    ImVec2 shadowInnerMax = ImVec2(area.Max.x+inset, area.Max.y+inset);
    ImVec2 realMin = ImVec2(shadowInnerMin.x+falloff, shadowInnerMin.y+falloff);
    ImVec2 realMax = ImVec2(shadowInnerMax.x-falloff, shadowInnerMax.y-falloff);

    igPushClipRect(realMin, realMax, false);

        // CENTER
        ImDrawList_AddRectFilled(
            drawList,
            shadowInnerMin,
            shadowInnerMax,
            iColor
        );

        // CORNERS

        // LEFT TOP
        // XX
        // XO
        ImDrawList_AddRectFilledMultiColor(
            drawList,
            ImVec2(realMax.x, realMax.y),
            ImVec2(shadowInnerMax.x, shadowInnerMax.y),
            oColor,
            oColor,
            iColor,
            oColor,
        );

        // RIGHT TOP
        // XX
        // OX
        ImDrawList_AddRectFilledMultiColor(
            drawList,
            ImVec2(realMin.x, realMax.y),
            ImVec2(shadowInnerMin.x, shadowInnerMax.y),
            oColor,
            oColor,
            iColor,
            oColor,
        );

        // LEFT BOTTOM
        // XO
        // XX
        ImDrawList_AddRectFilledMultiColor(
            drawList,
            ImVec2(realMax.x, realMin.y),
            ImVec2(shadowInnerMax.x, shadowInnerMin.y),
            oColor,
            oColor,
            iColor,
            oColor,
        );

        // RIGHT BOTTOM
        // OX
        // XX
        ImDrawList_AddRectFilledMultiColor(
            drawList,
            ImVec2(realMin.x, realMin.y),
            ImVec2(shadowInnerMin.x, shadowInnerMin.y),
            oColor,
            oColor,
            iColor,
            oColor,
        );


        // CAPS

        // LEFT
        // XO
        // XO
        ImDrawList_AddRectFilledMultiColor(
            drawList,
            ImVec2(realMax.x, shadowInnerMin.y),
            ImVec2(shadowInnerMax.x, shadowInnerMax.y),
            oColor,
            iColor,
            iColor,
            oColor,
        );

        // RIGHT
        // OX
        // OX
        ImDrawList_AddRectFilledMultiColor(
            drawList,
            ImVec2(shadowInnerMin.x, shadowInnerMin.y),
            ImVec2(realMin.x, shadowInnerMax.y),
            iColor,
            oColor,
            oColor,
            iColor,
        );

        // TOP
        // XX
        // OO
        ImDrawList_AddRectFilledMultiColor(
            drawList,
            ImVec2(shadowInnerMin.x, realMax.y),
            ImVec2(shadowInnerMax.x, shadowInnerMax.y),
            oColor,
            oColor,
            iColor,
            iColor,
        );

        // BOTTOM
        // OO
        // XX
        ImDrawList_AddRectFilledMultiColor(
            drawList,
            ImVec2(shadowInnerMin.x, shadowInnerMin.y),
            ImVec2(shadowInnerMax.x, realMin.y),
            iColor,
            iColor,
            oColor,
            oColor,
        );

    igPopClipRect();

    outDrawList.prepend(drawList);
}