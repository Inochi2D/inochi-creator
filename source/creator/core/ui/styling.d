module creator.core.ui.styling;
import std.math : PI;
import i2d.imgui;

__gshared ImGuiStyle DARK_MODE = ImGuiStyle(
    Alpha:                          1.0f,
    DisabledAlpha:                  0.60f,
    WindowPadding:                  ImVec2(8, 8),
    WindowRounding:                 4.0f,
    WindowBorderSize:               1.0f,
    WindowMinSize:                  ImVec2(32, 32),
    WindowTitleAlign:               ImVec2(0.0, 0.5),
    WindowMenuButtonPosition:       ImGuiDir.None,
    ChildRounding:                  0.0f,
    ChildBorderSize:                1.0f,
    PopupRounding:                  6.0f,
    PopupBorderSize:                1.0f,
    FramePadding:                   ImVec2(4, 4),
    FrameRounding:                  3.0f,
    FrameBorderSize:                1.0f,
    ItemSpacing:                    ImVec2(8, 3),
    ItemInnerSpacing:               ImVec2(4, 4),
    CellPadding:                    ImVec2(4, 2),
    TouchExtraPadding:              ImVec2(0, 0),
    IndentSpacing:                  10.0f,
    ColumnsMinSpacing:              6.0f,
    ScrollbarSize:                  14.0f,
    ScrollbarRounding:              18.0f,
    GrabMinSize:                    13.0f,
    GrabRounding:                   3.0f,
    LogSliderDeadzone:              6.0f,
    TabRounding:                    6.0f,
    TabBorderSize:                  1.0f,
    TabMinWidthForCloseButton:      -1.0f,
    TabBarBorderSize:               1.0f,
    TabBarOverlineSize:             1.0f,
    TableAngledHeadersAngle:        35.0f * (PI / 180.0f),
    TableAngledHeadersTextAlign:    ImVec2(0.5f, 0.0f),
    ColorButtonPosition:            ImGuiDir.Right,
    ButtonTextAlign:                ImVec2(0.5f, 0.5f),
    SelectableTextAlign:            ImVec2(0.0f, 0.0f),
    SeparatorTextBorderSize:        3.0f,
    SeparatorTextAlign:             ImVec2(0.0f, 0.5f),
    SeparatorTextPadding:           ImVec2(20.0f, 3.0f),
    DisplayWindowPadding:           ImVec2(19, 19),
    DisplaySafeAreaPadding:         ImVec2(3, 3),
    DockingSeparatorSize:           1.0f,
    MouseCursorScale:               1.0f,
    AntiAliasedLines:               true,
    AntiAliasedLinesUseTex:         true,
    AntiAliasedFill:                true,
    CurveTessellationTol:           1.25f,
    CircleTessellationMaxError:     0.30f,
    HoverStationaryDelay:           0.15f,
    HoverDelayShort:                0.15f,
    HoverDelayNormal:               0.40f,
    HoverFlagsForTooltipMouse:      ImGuiHoveredFlags.Stationary | ImGuiHoveredFlags.DelayShort | ImGuiHoveredFlags.AllowWhenDisabled,        
    HoverFlagsForTooltipNav:        ImGuiHoveredFlags.NoSharedDelay | ImGuiHoveredFlags.DelayNormal | ImGuiHoveredFlags.AllowWhenDisabled,        
    Colors: [
        ImVec4(1.00f, 1.00f, 1.00f, 1.00f), // Text
        ImVec4(0.50f, 0.50f, 0.50f, 1.00f), // TextDisabled
        ImVec4(0.17f, 0.17f, 0.17f, 1.00f), // WindowBg
        ImVec4(0.00f, 0.00f, 0.00f, 0.00f), // ChildBg
        ImVec4(0.08f, 0.08f, 0.08f, 0.94f), // PopupBg
        ImVec4(0.00f, 0.00f, 0.00f, 0.16f), // Border
        ImVec4(0.00f, 0.00f, 0.00f, 0.16f), // BorderShadow
        ImVec4(0.12f, 0.12f, 0.12f, 1.00f), // FrameBg
        ImVec4(0.15f, 0.15f, 0.15f, 0.40f), // FrameBgHovered
        ImVec4(0.22f, 0.22f, 0.22f, 0.67f), // FrameBgActive
        ImVec4(0.04f, 0.04f, 0.04f, 1.00f), // TitleBg
        ImVec4(0.00f, 0.00f, 0.00f, 1.00f), // TitleBgActive
        ImVec4(0.00f, 0.00f, 0.00f, 0.51f), // TitleBgCollapsed
        ImVec4(0.05f, 0.05f, 0.05f, 1.00f), // MenuBarBg
        ImVec4(0.02f, 0.02f, 0.02f, 0.53f), // ScrollbarBg
        ImVec4(0.31f, 0.31f, 0.31f, 1.00f), // ScrollbarGrab
        ImVec4(0.41f, 0.41f, 0.41f, 1.00f), // ScrollbarGrabHovered
        ImVec4(0.51f, 0.51f, 0.51f, 1.00f), // ScrollbarGrabActive
        ImVec4(0.76f, 0.76f, 0.76f, 1.00f), // CheckMark
        ImVec4(0.25f, 0.25f, 0.25f, 1.00f), // SliderGrab
        ImVec4(0.60f, 0.60f, 0.60f, 1.00f), // SliderGrabActive
        ImVec4(0.39f, 0.39f, 0.39f, 0.40f), // Button
        ImVec4(0.44f, 0.44f, 0.44f, 1.00f), // ButtonHovered
        ImVec4(0.50f, 0.50f, 0.50f, 1.00f), // ButtonActive
        ImVec4(0.25f, 0.25f, 0.25f, 1.00f), // Header
        ImVec4(0.28f, 0.28f, 0.28f, 0.80f), // HeaderHovered
        ImVec4(0.44f, 0.44f, 0.44f, 1.00f), // HeaderActive
        ImVec4(0.00f, 0.00f, 0.00f, 1.00f), // Separator
        ImVec4(0.29f, 0.29f, 0.29f, 0.78f), // SeparatorHovered
        ImVec4(0.47f, 0.47f, 0.47f, 1.00f), // SeparatorActive
        ImVec4(0.35f, 0.35f, 0.35f, 0.00f), // ResizeGrip
        ImVec4(0.40f, 0.40f, 0.40f, 0.00f), // ResizeGripHovered
        ImVec4(0.55f, 0.55f, 0.56f, 0.00f), // ResizeGripActive
        ImVec4(0.34f, 0.34f, 0.34f, 0.80f), // TabHovered
        ImVec4(0.00f, 0.00f, 0.00f, 1.00f), // Tab
        ImVec4(0.25f, 0.25f, 0.25f, 1.00f), // TabSelected
        ImVec4(0.26f, 0.59f, 0.98f, 1.00f), // TabSelectedOverline
        ImVec4(0.14f, 0.14f, 0.14f, 0.97f), // TabDimmed
        ImVec4(0.17f, 0.17f, 0.17f, 1.00f), // TabDimmedSelected
        ImVec4(0.50f, 0.50f, 0.50f, 0.00f), // TabDimmedSelectedOverline
        ImVec4(0.62f, 0.68f, 0.75f, 0.70f), // DockingPreview
        ImVec4(0.20f, 0.20f, 0.20f, 1.00f), // DockingEmptyBg
        ImVec4(0.61f, 0.61f, 0.61f, 1.00f), // PlotLines
        ImVec4(1.00f, 0.43f, 0.35f, 1.00f), // PlotLinesHovered
        ImVec4(0.90f, 0.70f, 0.00f, 1.00f), // PlotHistogram
        ImVec4(1.00f, 0.60f, 0.00f, 1.00f), // PlotHistogramHovered
        ImVec4(0.19f, 0.19f, 0.20f, 1.00f), // TableHeaderBg
        ImVec4(0.31f, 0.31f, 0.35f, 1.00f), // TableBorderStrong
        ImVec4(0.23f, 0.23f, 0.25f, 1.00f), // TableBorderLight
        ImVec4(0.310f, 0.310f, 0.310f, 0.267f), // TableRowBg
        ImVec4(0.463f, 0.463f, 0.463f, 0.267f), // TableRowBgAlt
        ImVec4(0.26f, 0.59f, 0.98f, 1.00f), // TextLink
        ImVec4(0.26f, 0.59f, 0.98f, 0.35f), // TextSelectedBg
        ImVec4(1.00f, 1.00f, 0.00f, 0.90f), // DragDropTarget
        ImVec4(0.32f, 0.32f, 0.32f, 1.00f), // NavCursor
        ImVec4(1.00f, 1.00f, 1.00f, 0.70f), // NavWindowingHighlight
        ImVec4(0.80f, 0.80f, 0.80f, 0.20f), // NavWindowingDimBg
        ImVec4(0.80f, 0.80f, 0.80f, 0.35f), // ModalWindowDimBg
    ]
);

__gshared ImGuiStyle LIGHT_MODE = ImGuiStyle(
    Alpha:                          1.0f,
    DisabledAlpha:                  0.60f,
    WindowPadding:                  ImVec2(8, 8),
    WindowRounding:                 4.0f,
    WindowBorderSize:               1.0f,
    WindowMinSize:                  ImVec2(32, 32),
    WindowTitleAlign:               ImVec2(0.0, 0.5),
    WindowMenuButtonPosition:       ImGuiDir.None,
    ChildRounding:                  0.0f,
    ChildBorderSize:                1.0f,
    PopupRounding:                  6.0f,
    PopupBorderSize:                1.0f,
    FramePadding:                   ImVec2(4, 4),
    FrameRounding:                  3.0f,
    FrameBorderSize:                1.0f,
    ItemSpacing:                    ImVec2(8, 3),
    ItemInnerSpacing:               ImVec2(4, 4),
    CellPadding:                    ImVec2(4, 2),
    TouchExtraPadding:              ImVec2(0, 0),
    IndentSpacing:                  10.0f,
    ColumnsMinSpacing:              6.0f,
    ScrollbarSize:                  14.0f,
    ScrollbarRounding:              18.0f,
    GrabMinSize:                    13.0f,
    GrabRounding:                   3.0f,
    LogSliderDeadzone:              6.0f,
    TabRounding:                    6.0f,
    TabBorderSize:                  1.0f,
    TabMinWidthForCloseButton:      -1.0f,
    TabBarBorderSize:               1.0f,
    TabBarOverlineSize:             1.0f,
    TableAngledHeadersAngle:        35.0f * (PI / 180.0f),
    TableAngledHeadersTextAlign:    ImVec2(0.5f, 0.0f),
    ColorButtonPosition:            ImGuiDir.Right,
    ButtonTextAlign:                ImVec2(0.5f, 0.5f),
    SelectableTextAlign:            ImVec2(0.0f, 0.0f),
    SeparatorTextBorderSize:        3.0f,
    SeparatorTextAlign:             ImVec2(0.0f, 0.5f),
    SeparatorTextPadding:           ImVec2(20.0f, 3.0f),
    DisplayWindowPadding:           ImVec2(19, 19),
    DisplaySafeAreaPadding:         ImVec2(3, 3),
    DockingSeparatorSize:           1.0f,
    MouseCursorScale:               1.0f,
    AntiAliasedLines:               true,
    AntiAliasedLinesUseTex:         true,
    AntiAliasedFill:                true,
    CurveTessellationTol:           1.25f,
    CircleTessellationMaxError:     0.30f,
    HoverStationaryDelay:           0.15f,
    HoverDelayShort:                0.15f,
    HoverDelayNormal:               0.40f,
    HoverFlagsForTooltipMouse:      ImGuiHoveredFlags.Stationary | ImGuiHoveredFlags.DelayShort | ImGuiHoveredFlags.AllowWhenDisabled,        
    HoverFlagsForTooltipNav:        ImGuiHoveredFlags.NoSharedDelay | ImGuiHoveredFlags.DelayNormal | ImGuiHoveredFlags.AllowWhenDisabled,        
    Colors: [
        ImVec4(0.00f, 0.00f, 0.00f, 1.00f), // Text
        ImVec4(0.60f, 0.60f, 0.60f, 1.00f), // TextDisabled
        ImVec4(0.94f, 0.94f, 0.94f, 1.00f), // WindowBg
        ImVec4(0.00f, 0.00f, 0.00f, 0.00f), // ChildBg
        ImVec4(0.941, 0.941, 0.941, 1), // PopupBg
        ImVec4(0.8, 0.8, 0.8, 0.5), // Border
        ImVec4(0, 0, 0, 0.05), // BorderShadow
        ImVec4(1, 1, 1, 1), // FrameBg
        ImVec4(0.78, 0.88, 1, 1), // FrameBgHovered
        ImVec4(0.76, 0.86, 1, 1), // FrameBgActive
        ImVec4(0.902, 0.902, 0.902, 1), // TitleBg
        ImVec4(0.98, 0.98, 0.98, 1), // TitleBgActive
        ImVec4(1.00f, 1.00f, 1.00f, 0.51f), // TitleBgCollapsed
        ImVec4(0.863, 0.863, 0.863, 1), // MenuBarBg
        ImVec4(0.98f, 0.98f, 0.98f, 0.53f), // ScrollbarBg
        ImVec4(0.68, 0.68, 0.68, 1), // ScrollbarGrab
        ImVec4(0.64, 0.64, 0.64, 1), // ScrollbarGrabHovered
        ImVec4(0.68, 0.68, 0.68, 1), // ScrollbarGrabActive
        ImVec4(0, 0, 0, 1), // CheckMark
        ImVec4(0.26f, 0.59f, 0.98f, 0.78f), // SliderGrab
        ImVec4(0.46f, 0.54f, 0.80f, 0.60f), // SliderGrabActive
        ImVec4(0.98, 0.98, 0.98, 1), // Button
        ImVec4(1, 1, 1, 1), // ButtonHovered
        ImVec4(0.8, 0.8, 0.8, 1), // ButtonActive
        ImVec4(0.990, 0.990, 0.990, 1), // Header
        ImVec4(1, 1, 1, 1), // HeaderHovered
        ImVec4(0.26f, 0.59f, 0.98f, 1.00f), // HeaderActive
        ImVec4(0.86, 0.86, 0.86, 1), // Separator
        ImVec4(0.14f, 0.44f, 0.80f, 0.78f), // SeparatorHovered
        ImVec4(0.14f, 0.44f, 0.80f, 1.00f), // SeparatorActive
        ImVec4(0.35f, 0.35f, 0.35f, 0.17f), // ResizeGrip
        ImVec4(0.26f, 0.59f, 0.98f, 0.67f), // ResizeGripHovered
        ImVec4(0.26f, 0.59f, 0.98f, 0.95f), // ResizeGripActive
        ImVec4(1, 1, 1, 1), // TabHovered
        ImVec4(0.98, 0.98, 0.98, 1), // Tab
        ImVec4(0.8, 0.8, 0.8, 1), // TabSelected
        ImVec4(0.26f, 0.59f, 0.98f, 1.00f), // TabSelectedOverline
        ImVec4(0.92, 0.92, 0.92, 1), // TabDimmed
        ImVec4(0.88, 0.88, 0.88, 1), // TabDimmedSelected
        ImVec4(0.26f, 0.59f, 1.00f, 0.00f), // TabDimmedSelectedOverline
        ImVec4(0.62f, 0.68f, 0.75f, 0.70f), // DockingPreview
        ImVec4(0.20f, 0.20f, 0.20f, 1.00f), // DockingEmptyBg
        ImVec4(0.39f, 0.39f, 0.39f, 1.00f), // PlotLines
        ImVec4(1.00f, 0.43f, 0.35f, 1.00f), // PlotLinesHovered
        ImVec4(0.90f, 0.70f, 0.00f, 1.00f), // PlotHistogram
        ImVec4(1.00f, 0.45f, 0.00f, 1.00f), // PlotHistogramHovered
        ImVec4(0.78f, 0.87f, 0.98f, 1.00f), // TableHeaderBg
        ImVec4(0.57f, 0.57f, 0.64f, 1.00f), // TableBorderStrong
        ImVec4(0.68f, 0.68f, 0.74f, 1.00f), // TableBorderLight
        ImVec4(0.00f, 0.00f, 0.00f, 0.00f), // TableRowBg
        ImVec4(0.30f, 0.30f, 0.30f, 0.09f), // TableRowBgAlt
        ImVec4(0.26f, 0.59f, 0.98f, 1.00f), // TextLink
        ImVec4(0.26f, 0.59f, 0.98f, 0.35f), // TextSelectedBg
        ImVec4(0.26f, 0.59f, 0.98f, 0.95f), // DragDropTarget
        ImVec4(0.32f, 0.32f, 0.32f, 1.00f), // NavCursor
        ImVec4(0.70f, 0.70f, 0.70f, 0.70f), // NavWindowingHighlight
        ImVec4(0.20f, 0.20f, 0.20f, 0.20f), // NavWindowingDimBg
        ImVec4(0.20f, 0.20f, 0.20f, 0.35f), // ModalWindowDimBg
    ]
);

void incPushDarkColorScheme() {
    auto ctx = igGetCurrentContext();
    ctx.Style.Colors = DARK_MODE.Colors;
}

void incPushLightColorScheme() {
    auto ctx = igGetCurrentContext();
    ctx.Style.Colors = LIGHT_MODE.Colors;
}

void incPopColorScheme() {
    auto ctx = igGetCurrentContext();
    ctx.Style.Colors = isDarkMode ? DARK_MODE.Colors : LIGHT_MODE.Colors;
}

/**
    Sets the dark mode state.
*/
void incSetDarkMode(bool darkMode) {
    auto style = igGetStyle();
    style.Colors = darkMode ? DARK_MODE.Colors : LIGHT_MODE.Colors;

    // Set Dark mode setting
    AppSettings.set("DarkMode", darkMode);
    isDarkMode = darkMode;
}

/**
    Gets whether dark mode is currently enabled.
*/
bool incGetDarkMode() {
    auto style = igGetStyle();
    return style.Colors.ptr == DARK_MODE.Colors.ptr;
}

/**
    A visual style for the application
*/
class VisualStyle {
private:
    ImGuiStyle[] imStyles;

public:

    /**
        The name of the visual style.
    */
    string styleName;

    /**
        The underlying imgui style information
    */
    @property ImGuiStyle style() => imStyle;
}

struct StyleVariant {
    
}