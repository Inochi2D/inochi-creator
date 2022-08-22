module creator.widgets.texture;
import creator.widgets;
import bindbc.imgui;
import inmath;
import inochi2d;

/**
    Renders a texture slot with specified size
*/
void incTextureSlot(string text, Texture texture, ImVec2 size = ImVec2(92, 92)) {
    if (igBeginChildFrame(igGetID(text.ptr, text.ptr+text.length), size, ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoScrollWithMouse)) {

        ImVec2 startPos;
        igGetCursorPos(&startPos);
        float paddingX = igGetStyle().FramePadding.x;
        float paddingY = igGetStyle().FramePadding.y;

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

        // Draw text
        igSetCursorPos(startPos);
        ImVec2 textSize = incMeasureString(text);
        if (igBeginChildFrame(igGetID("LABEL"), ImVec2(textSize.x+paddingX*2, textSize.y+paddingY*2), ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoScrollWithMouse)) {
            incText(text);
        }
        igEndChildFrame();
    }
    igEndChildFrame();
}