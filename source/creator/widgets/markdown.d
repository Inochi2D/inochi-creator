/**
    Markdown support

    This is a port of https://github.com/juliettef/imgui_markdown which is under the zlib license!

    Copyright (c) 2019 Juliette Foucaut and Doug Binks

    This software is provided 'as-is', without any express or implied
    warranty. In no event will the authors be held liable for any damages
    arising from the use of this software.

    Permission is granted to anyone to use this software for any purpose,
    including commercial applications, and to alter it and redistribute it
    freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgement in the product documentation would be
    appreciated but is not required.
    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.
    3. This notice may not be removed or altered from any source distribution.
*/
module creator.widgets.markdown;
import creator.widgets.dummy;
import bindbc.imgui;

struct MarkdownLinkCallbackData {
    string text;
    string link;
    void* userData;
    bool isImage;
}

struct MarkdownTooltipCallbackData {
    MarkdownLinkCallbackData linkData;
    string linkIcon;
}

struct MarkdownImageData {
    bool                    isValid = false;                    // if true, will draw the image
    bool                    useLinkCallback = false;            // if true, linkCallback will be called when image is clicked
    ImTextureID             userTextureId = null;                  // see ImGui::Image
    ImVec2                  size = ImVec2( 100.0f, 100.0f );    // see ImGui::Image
    ImVec2                  uv0 = ImVec2( 0, 0 );               // see ImGui::Image
    ImVec2                  uv1 = ImVec2( 1, 1 );               // see ImGui::Image
    ImVec4                  tint_col = ImVec4( 1, 1, 1, 1 );    // see ImGui::Image
    ImVec4                  border_col = ImVec4( 0, 0, 0, 0 );  // see ImGui::Image
}

enum MarkdownFormatType {
        NormalText,
        Heading,
        UnorderedList,
        Link,
        Emphasis,
}

struct MarkdownFormatInfo {
    MarkdownFormatType      type    = MarkdownFormatType.NormalText;
    int                     level   = 0;                               // Set for headings: 1 for H1, 2 for H2 etc.
    bool                    itemHovered = false;                       // Currently only set for links when mouse hovered, only valid when start_ == false
    MarkdownConfig          config;
}

struct MarkdownHeadingFormat
{   
    float                   scale     = 1;                      // ImGui font
    bool                    separator = true;                   // if true, an underlined separator is drawn after the header
}

// Configuration struct for Markdown
// - linkCallback is called when a link is clicked on
// - linkIcon is a string which encode a "Link" icon, if available in the current font (e.g. linkIcon = ICON_FA_LINK with FontAwesome + IconFontCppHeaders https://github.com/juliettef/IconFontCppHeaders)
// - headingFormats controls the format of heading H1 to H3, those above H3 use H3 format
struct MarkdownConfig
{
    enum NUMHEADINGS = 3;

    incMarkdownLinkCallback              linkCallback;
    incMarkdownTooltipCallback           tooltipCallback;
    incMarkdownImageCallback             imageCallback;
    string                               linkIcon = "";     // icon displayd in link tooltip
    MarkdownHeadingFormat[NUMHEADINGS]   headingFormats;
    void*                                userData;
    incMarkdownFormatCallback            formatCallback = &markdownFmtDefault;
}

/**
    Global callback for opening links
*/
alias incMarkdownLinkCallback = void function(MarkdownLinkCallbackData data);

/**
    Global callback for opening image links
*/
alias incMarkdownImageCallback = MarkdownImageData function(MarkdownLinkCallbackData data) ;

/**
    Global callback for displaying tooltips
*/
alias incMarkdownTooltipCallback = void function(MarkdownTooltipCallbackData data);

/**
    Global callback for displaying tooltips
*/
alias incMarkdownFormatCallback = void function(ref MarkdownFormatInfo info, bool start);

private {
    void markdownFmtDefault(ref MarkdownFormatInfo info, bool start) {
        switch(info.type) {
            case MarkdownFormatType.Heading:
                MarkdownHeadingFormat fmt;

                if (info.level > MarkdownConfig.NUMHEADINGS) fmt = info.config.headingFormats[MarkdownConfig.NUMHEADINGS-1];
                else fmt = info.config.headingFormats[info.level-1];
        
                if (start) {
                    igSetWindowFontScale(fmt.scale);
                    // igNewLine();
                } else {
                    if(fmt.separator) igSeparator();
                    // igNewLine();
                    igSetWindowFontScale(1);
                }
                break;
            case MarkdownFormatType.Link:
                if(start)
                {
                    igPushStyleColor(ImGuiCol.Text, igGetStyle().Colors[ImGuiCol.ButtonHovered]);
                }
                else
                {
                    igPopStyleColor();
                    if(info.itemHovered)
                    {
                        incUnderLine(igGetStyle().Colors[ImGuiCol.ButtonHovered]);
                    }
                    else
                    {
                        incUnderLine(igGetStyle().Colors[ImGuiCol.Button]);
                    }
                }
                break;
            default:
                break;
        }
    }

    // Text that starts after a new line (or at beginning) and ends with a newline (or at end)
    struct Line {
        bool isHeading = false;
        bool isEmphasis = false;
        bool isUnorderedListStart = false;
        bool isLeadingSpace = true;     // spaces at start of line
        int  leadSpaceCount = 0;
        int  headingCount = 0;
        int  emphasisCount = 0;
        int  lineStart = 0;
        int  lineEnd   = 0;
        int  lastRenderPosition = 0;     // lines may get rendered in multiple pieces
    }

    // struct TextBlock {                  // subset of line
    //     int start = 0;
    //     int stop  = 0;
    //     int size() const{
    //         return stop - start;
    //     }
    // }

    struct Link {
        enum LinkState {
            NoLink,
            HasSquareBracketOpen,
            HasSquareBrackets,
            HasSquareBracketsRoundBracketOpen,
        }
        LinkState state = LinkState.NoLink;
        string text;
        string url;
        bool isImage = false;
        int numBracketsOpen = 0;
    }

	struct Emphasis {
		enum EmphasisState {
			None,
			Left,
			Middle,
			Right,
		}
        EmphasisState state = EmphasisState.None;
        string text;
        char sym;
	}

    struct TextRegion {
    private:
        float indentX = 0;

    public:
        void renderTextWrapped(string textSlice, bool indentToHere) {
            const(char)* sliceStart = textSlice.ptr;
            const(char)* sliceEnd = textSlice.ptr+textSlice.length;

            float scale = igGetIO().FontGlobalScale;
            float widthLeft = incAvailableSpace().x;
            ImFont_CalcWordWrapPositionA(igGetFont(), scale, sliceStart, sliceEnd, widthLeft);
            igTextUnformatted(sliceStart, sliceEnd);
            
            // Handle indenting
            if(indentToHere) {
                float indentNeeded = incAvailableSpace().x - widthLeft;
                if (indentNeeded) {
                    igIndent(indentNeeded);
                    indentX += indentNeeded;
                }
            }

            widthLeft = incAvailableSpace().x;
            while(sliceEnd < textSlice.ptr+textSlice.length) {
                sliceStart = sliceEnd;
                sliceEnd = textSlice.ptr+textSlice.length;

                if (*sliceStart == ' ' ) ++sliceStart;
                ImFont_CalcWordWrapPositionA(igGetFont(), scale, sliceStart, sliceEnd, widthLeft);
                if (sliceStart == sliceEnd) sliceEnd++;
                igTextUnformatted(sliceStart, sliceEnd);
            }
        }

        void renderListTextWrapped(string textSlice) {
            igBullet();
            igSameLine();
            renderTextWrapped(textSlice, true);
        }

        void renderLinkTextWrapped(string textSlice, ref Link link, string markdown, ref MarkdownConfig cfg, out string linkHoverStart, bool indentToHere) {
            const(char)* sliceStart = textSlice.ptr;
            const(char)* sliceEnd = textSlice.ptr+textSlice.length;

            float scale = igGetIO().FontGlobalScale;
            float widthLeft = incAvailableSpace().x;
            ImFont_CalcWordWrapPositionA(igGetFont(), scale, sliceStart, sliceEnd, widthLeft);
            bool bHovered = renderLinkText(textSlice, link, markdown, cfg, linkHoverStart);
            if (indentToHere) {
                float indentNeeded = incAvailableSpace().x - widthLeft;
                if (indentNeeded) {
                    igIndent(indentNeeded);
                    indentX += indentNeeded;
                }
            }
            
            widthLeft = incAvailableSpace().x;
            while(sliceEnd < textSlice.ptr+textSlice.length) {
                sliceStart = sliceEnd;
                sliceEnd = textSlice.ptr+textSlice.length;

                if (*sliceStart == ' ' ) ++sliceStart;
                ImFont_CalcWordWrapPositionA(igGetFont(), scale, sliceStart, sliceEnd, widthLeft);
                
                if (sliceStart == sliceEnd) sliceEnd++;
                
                bool bThisLineHovered = renderLinkText(textSlice, link, markdown, cfg, linkHoverStart);
                bHovered = bHovered || bThisLineHovered;
            }
            if (bHovered) igSetMouseCursor(ImGuiMouseCursor.Hand);

            if (!bHovered && linkHoverStart == link.text) {
                linkHoverStart = null;
            }
        }

        bool renderLinkText(string textSlice, ref Link link, string markdown, ref MarkdownConfig cfg, out string linkHoverStart) {
            MarkdownFormatInfo formatInfo;
            formatInfo.config = cfg;
            formatInfo.type = MarkdownFormatType.Link;
            cfg.formatCallback(formatInfo, true);

            igPushTextWrapPos(-1);
            igTextUnformatted(textSlice.ptr, textSlice.ptr+textSlice.length);
            igPopTextWrapPos();

            bool bIsHovered = igIsItemHovered();
            if (bIsHovered) {
                linkHoverStart = link.text;
            }
            bool bHovered = bIsHovered || (linkHoverStart == link.text);

            formatInfo.itemHovered = bHovered;
            cfg.formatCallback(formatInfo, false);
            
            if (bHovered) {
                igSetMouseCursor(ImGuiMouseCursor.Hand);
                
                if (igIsMouseReleased(ImGuiMouseButton.Left) && cfg.linkCallback) {
                    cfg.linkCallback(MarkdownLinkCallbackData(link.text, link.url, cfg.userData, false));
                }

                if (cfg.tooltipCallback) {
                    cfg.tooltipCallback(MarkdownTooltipCallbackData(
                        MarkdownLinkCallbackData(
                            link.text, link.url, cfg.userData, false
                        ),
                        cfg.linkIcon
                    ));
                }
            }

            return bIsHovered;
        }

        void resetIndent() {
            if (indentX > 0) {
                igUnindent(indentX);
            }
            indentX = 0;
        }
    }

    void incUnderLine(ImVec4 color) {
        ImVec2 min, max;
        igGetItemRectMin(&min);
        igGetItemRectMax(&max);
        min.y = max.y;
        ImDrawList_AddLine(igGetWindowDrawList(), min, max, igGetColorU32(color), 1);
    }

    void incRenderLine(string markdown, ref Line line, ref TextRegion textRegion, ref MarkdownConfig cfg) {
        int indentStart = 0;
        if (line.isUnorderedListStart) indentStart = 1;
        for(int j = indentStart; j < line.leadSpaceCount / 2; ++j) igIndent();
        import std.stdio : writeln;

        MarkdownFormatInfo formatInfo;
        formatInfo.config = cfg;
        int textStart = line.lastRenderPosition+1;
        int textSize = line.lineEnd - textStart;
        if (line.isUnorderedListStart) {
            formatInfo.type = MarkdownFormatType.UnorderedList;
            cfg.formatCallback(formatInfo, true);
            string text = markdown[textStart+1..textStart+textSize];
            textRegion.renderListTextWrapped(text);
        } else if (line.isHeading) {
            formatInfo.level = line.headingCount;
            formatInfo.type = MarkdownFormatType.Heading;
            cfg.formatCallback(formatInfo, true);
            string text = markdown[textStart+1..textStart+textSize];
            textRegion.renderTextWrapped(text, false);
        } else if (line.isEmphasis) {
            formatInfo.level = line.emphasisCount;
            formatInfo.type = MarkdownFormatType.Emphasis;
            cfg.formatCallback(formatInfo, true);
            string text = markdown[textStart+1..textStart+textSize];
            textRegion.renderTextWrapped(text, false);
        } else {
            formatInfo.type = MarkdownFormatType.NormalText;
            cfg.formatCallback(formatInfo, true);
            string text = markdown[textStart..textStart+textSize];
            textRegion.renderTextWrapped(text, false);
        }
        cfg.formatCallback(formatInfo, false);

        for(int j = indentStart; j < line.leadSpaceCount / 2; ++j) igUnindent();
    }
}

void incMarkdown(string markdown, ref MarkdownConfig cfg) {
    static string linkHoverStart;
    ImGuiStyle* style = igGetStyle();
    Line line;
    Link link;
    Emphasis em;
    TextRegion textRegion;

    char c;
    for(int i; i < markdown.length; ++i) {
        c = markdown[i];
        
        if (line.isLeadingSpace) {
            if (c == ' ') {
                ++line.leadSpaceCount;
                continue;
            }

            line.isLeadingSpace = false;
            line.lastRenderPosition = i - 1;
            if (c == '*' && line.leadSpaceCount >= 1) {
                if (markdown.length > i+1 && markdown[i+1] == ' ') {
                    line.isUnorderedListStart = true;
                    ++i;
                    ++line.lastRenderPosition;
                }
            } else if (c == '#') {
                line.headingCount++;
                bool bContinueChecking = true;
                
                int j = i;
                while (++j < markdown.length && bContinueChecking) {
                    c = markdown[j];
                    switch(c) {
                        case '#':
                            line.headingCount++;
                            break;
                        case ' ':
                            line.lastRenderPosition = j-1;
                            i = j;
                            line.isHeading = true;
                            bContinueChecking = false;
                            break;
                        default:
                            line.isHeading = false;
                            bContinueChecking = false;
                            break;
                    }
                }

                if (line.isHeading) {
                    em = Emphasis();
                    continue;
                }
            }
        }

        switch(link.state) {
            default:
                break;
            case Link.LinkState.NoLink:
                if (c == '[' && !line.isHeading) {
                    link.state = Link.LinkState.HasSquareBracketOpen;
                    link.text = markdown[i+1..$];
                    if (i > 0 && markdown[i-1] == '!') {
                        link.isImage = true;
                    }
                }
                break;
            case Link.LinkState.HasSquareBracketOpen:
                if (c == ']') {
                    link.state = Link.LinkState.HasSquareBrackets;
                    link.text = markdown[link.text.ptr-markdown.ptr..i];
                }
                break;
            case Link.LinkState.HasSquareBrackets:
                if (c == '(') {
                    link.state = Link.LinkState.HasSquareBracketsRoundBracketOpen;
                    link.url = markdown[i+1..$];
                    link.numBracketsOpen = 1;
                }
                break;
            case Link.LinkState.HasSquareBracketsRoundBracketOpen:
                if (c == '(') ++link.numBracketsOpen;
                else if (c == ')') --link.numBracketsOpen;

                if (link.numBracketsOpen == 0) { 
                    em = Emphasis();

                    line.lineEnd = cast(int)(link.text.ptr-markdown.ptr) - (link.isImage ? 2 : 1);
                    
                    incRenderLine(markdown, line, textRegion, cfg);

                    line.leadSpaceCount = 0;
                    link.url = markdown[link.url.ptr-markdown.ptr..i];
                    line.isUnorderedListStart = false;
                    igSameLine(0, 0);
                    if (link.isImage) {
                        bool drawnImage = false;
                        bool useLinkCallback = false;
                        if (cfg.imageCallback) {
                            MarkdownImageData imageData = cfg.imageCallback(MarkdownLinkCallbackData(
                                link.text, link.url, cfg.userData, true
                            ));
                            useLinkCallback = imageData.useLinkCallback;
                            if (imageData.isValid) {
                                igImage(imageData.userTextureId, imageData.size, imageData.uv0, imageData.uv1, imageData.tint_col, imageData.border_col);
                                drawnImage = true;
                            }
                        }
                        if (!drawnImage) {
                            igText("\ubeef");
                        }
                        if (igIsItemHovered()) {
                            if (igIsMouseReleased(ImGuiMouseButton.Left) && cfg.linkCallback) {
                                cfg.linkCallback(MarkdownLinkCallbackData(link.text, link.url, cfg.userData, true));
                            }

                            if (cfg.tooltipCallback) {
                                cfg.tooltipCallback(MarkdownTooltipCallbackData(
                                    MarkdownLinkCallbackData(
                                        link.text, link.url, cfg.userData, true
                                    ),
                                    cfg.linkIcon
                                ));
                            }
                        }
                    } else textRegion.renderLinkTextWrapped(link.text, link, markdown, cfg, linkHoverStart, false);
                    igSameLine();
                    link = Link();
                    line.lastRenderPosition = i;
                } 
                break;
        }

        switch(em.state) {
            default:
                break;
        }

        if (c == '\n') {
            line.lineEnd = i;
            if (em.state == Emphasis.EmphasisState.Middle && line.emphasisCount >= 3 && (line.lineStart + line.emphasisCount) == i) {
                igSeparator();
            } else {
                incRenderLine(markdown, line, textRegion, cfg);
            }

            line = Line();
            em = Emphasis();

            line.lineStart = i+1;
            line.lastRenderPosition = i;
            textRegion.resetIndent();

            link = Link();
        }
    }

    if (em.state == Emphasis.EmphasisState.Left && line.emphasisCount >= 3) {
        igSeparator();
    } else {
        if (markdown.length && line.lineStart < markdown.length && markdown[line.lineStart] != 0) {
            line.lineEnd = cast(int)markdown.length;
            if (0 == markdown[line.lineEnd-1]) --line.lineEnd;
            incRenderLine(markdown, line, textRegion, cfg);
        }
    }
}