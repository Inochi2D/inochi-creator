module creator.widgets.texture;
import creator.widgets;
import creator.core;
import bindbc.imgui;
import inmath;
import inochi2d;
import std.math : quantize;

/**
    Renders a texture slot with specified size
*/
void incTextureSlot(string text, Texture texture, ImVec2 size = ImVec2(92, 92), float gridSize = 32) {
    if (igBeginChildFrame(igGetID(text.ptr, text.ptr+text.length), size, ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoScrollWithMouse)) {

        igBeginGroup();
            ImVec2 startPos;
            igGetCursorPos(&startPos);
            float paddingX = igGetStyle().FramePadding.x;
            float paddingY = igGetStyle().FramePadding.y;

            float qsizex = quantize(size.x, gridSize);
            float qsizey = quantize(size.y, gridSize);

            ImVec2 screenStart;
            auto drawList = igGetWindowDrawList();
            igGetCursorScreenPos(&screenStart);

            // Draw background grid
            ImVec2 gridMin = ImVec2(screenStart.x-(paddingX/2), screenStart.y-(paddingY/2));
            ImVec2 gridMax = ImVec2(gridMin.x+size.x-paddingX, gridMin.y+size.y-paddingY);
            ImDrawList_AddImageRounded(
                drawList,
                cast(ImTextureID)incGetGrid().getTextureId(),
                gridMin,
                gridMax,
                ImVec2(0, 0),
                ImVec2(
                    clamp(quantize((qsizex/gridSize), 0.5), 1, float.max),
                    clamp(quantize((qsizey/gridSize), 0.5), 1, float.max),
                ),
                0xFFFFFFFF,
                igGetStyle().FrameRounding
            );

            igSetCursorPos(startPos);

            if (texture) {
            
                float paddedSizeX = size.x-paddingX;
                float paddedSizeY = size.y-paddingY;

                // Calculate render size
                float widthScale = paddedSizeX / cast(float)texture.width;
                float heightScale = paddedSizeY / cast(float)texture.height;
                float scale = min(widthScale, heightScale);
                
                vec4 bounds = vec4(0, 0, texture.width*scale, texture.height*scale);
                if (widthScale > heightScale) bounds.x = (paddedSizeX-bounds.z)/2;
                else if (widthScale < heightScale) bounds.y = (paddedSizeY-bounds.w)/2;

                // Draw texture preview
                igSetCursorPos(ImVec2(startPos.x+bounds.x, startPos.y+bounds.y));
                igImage(
                    cast(ImTextureID)texture.getTextureId(),
                    ImVec2(bounds.z, bounds.w)
                );
            }
        igEndGroup();
        
        auto origFrameBG = igGetStyle().Colors[ImGuiCol.FrameBg];
        igPushStyleColor(ImGuiCol.FrameBg, ImVec4(origFrameBG.x, origFrameBG.y, origFrameBG.z, 0.5));
            // Draw text
            igSetCursorPos(startPos);
            ImVec2 textSize = incMeasureString(text);
            if (igBeginChildFrame(igGetID("LABEL"), ImVec2(clamp(textSize.x+paddingX*2, 8, size.x-(paddingX*2)), textSize.y+paddingY*2), ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoScrollWithMouse)) {
                incText(text);
            }
            igEndChildFrame();
        igPopStyleColor();
    }
    igEndChildFrame();
}