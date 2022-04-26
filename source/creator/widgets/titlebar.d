/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets.titlebar;
import bindbc.sdl;
import bindbc.imgui;
import creator.core;
import creator.widgets;
import creator.utils.link;
import std.string;
import app : incUpdateNoEv;
import i18n;

private {
    bool incUseNativeTitlebar;

    extern(C) SDL_HitTestResult _incHitTestCallback(SDL_Window* win, const(SDL_Point)* area, void* data) nothrow {
        int winWidth, winHeight;
        SDL_GetWindowSize(win, &winWidth, &winHeight);
        
        // GET PROPER RESIZE AREA
        enum RESIZE_AREA = 4;
        enum RESIZE_AREAC = RESIZE_AREA*2;

        // Resize top
        if (area.x < RESIZE_AREAC && area.y < RESIZE_AREAC) return SDL_HitTestResult.SDL_HITTEST_RESIZE_TOPLEFT;
        if (area.x > winWidth-RESIZE_AREAC && area.y < RESIZE_AREAC) return SDL_HitTestResult.SDL_HITTEST_RESIZE_TOPRIGHT;
        if (area.x < RESIZE_AREA) return SDL_HitTestResult.SDL_HITTEST_RESIZE_LEFT;
        if (area.y < RESIZE_AREA) return SDL_HitTestResult.SDL_HITTEST_RESIZE_TOP;

        // Title bar
        if (area.y < 22 && area.x < winWidth-128) return SDL_HitTestResult.SDL_HITTEST_DRAGGABLE;

        if (area.x < RESIZE_AREAC && area.y > winHeight-RESIZE_AREAC) return SDL_HitTestResult.SDL_HITTEST_RESIZE_BOTTOMLEFT;
        if (area.x > winWidth-RESIZE_AREAC && area.y > winHeight-RESIZE_AREAC) return SDL_HitTestResult.SDL_HITTEST_RESIZE_BOTTOMRIGHT;
        if (area.x > winWidth-RESIZE_AREA) return SDL_HitTestResult.SDL_HITTEST_RESIZE_RIGHT;
        if (area.y > winHeight-RESIZE_AREA) return SDL_HitTestResult.SDL_HITTEST_RESIZE_BOTTOM;

        return SDL_HitTestResult.SDL_HITTEST_NORMAL;
    }
}

/**
    Whether the native titlebar can be used
*/
bool incCanUseAppTitlebar = true;

/**
    Gets whether to use the native titlebar
*/
bool incGetUseNativeTitlebar() {
    return incCanUseAppTitlebar && incUseNativeTitlebar;
}

/**
    Set whether to use the native titlebar
*/
void incSetUseNativeTitlebar(bool value) {
    if (!incCanUseAppTitlebar) return;
    incUseNativeTitlebar = value;
    incApplyTitlebar(incGetWindowPtr());
}

/**
    Applies titlebar settings to a window
*/
void incApplyTitlebar(void* window) {
    if (!incUseNativeTitlebar) {
        SDL_SetWindowBordered(cast(SDL_Window*)window, cast(SDL_bool)false);
        SDL_SetWindowHitTest(cast(SDL_Window*)window, &_incHitTestCallback, null);
    } else {
        SDL_SetWindowBordered(cast(SDL_Window*)window, cast(SDL_bool)true);
        SDL_SetWindowHitTest(cast(SDL_Window*)window, null, null);
    }
}

/**
    Draws the custom titlebar
*/
void incTitlebar(string title) {
    auto flags = 
        ImGuiWindowFlags.NoSavedSettings |
        ImGuiWindowFlags.NoScrollbar |
        ImGuiWindowFlags.MenuBar;
    
    SDL_Window* window = incGetWindowPtr();

    if (incGetDarkMode()) igPushStyleColor(ImGuiCol.MenuBarBg, ImVec4(0.1, 0.1, 0.1, 1));
    else  igPushStyleColor(ImGuiCol.MenuBarBg, ImVec4(0.9, 0.9, 0.9, 1));
    igPushStyleVar(ImGuiStyleVar.FramePadding, ImVec2(0, 4*incGetUIScale()));
        if (igBeginViewportSideBar("##Titlebar", igGetMainViewport(), ImGuiDir.Up, 22*incGetUIScale(), flags)) {
            if (igBeginMenuBar()) {
                ImVec2 avail;
                igGetContentRegionAvail(&avail);

                version (InBranding) {
                    igImage(
                        cast(void*)incGetLogo(), 
                        ImVec2(avail.y*2, avail.y*2), 
                        ImVec2(0, 0), ImVec2(1, 1), 
                        ImVec4(1, 1, 1, 1), 
                        ImVec4(0, 0, 0, 0)
                    );

                    debug {
                        igText((title~_(" (Debug Mode)")).toStringz);
                    } else {
                        igText(title.toStringz);
                    }
                } else {
                    igText((title~_(" (Unsupported)")).toStringz);
                }

                // :)
                if (isTransMonthOfVisibility) {
                    igSeparator();
                    ImVec4 a = ImVec4(85.0/255.0, 205.0/255.0, 252.0/255.0, 255);
                    ImVec4 b;
                    ImVec4 c;
                    igColorConvertU32ToFloat4(&b, 0xF7A8B8FF);
                    igColorConvertU32ToFloat4(&c, 0xFFFFFFFF);
                    ImVec4[] transColors = [a, b, c, b];
                    
                    // A call for the human rights of transgender people to be respected
                    // it is shown in the custom titlebar every transgender awareness month.
                    foreach(i, ic; _("Trans Rights!")) {
                        igTextColored(transColors[i%transColors.length], [ic, '\0'].ptr);
                        igSameLine(0, 0);
                    }
                }
                
                incDummy(ImVec2(-((16*4*incGetUIScale())+8), 0));
                igPushFont(incIconFont());
                    auto state = igGetStateStorage();

                    igTextColored(
                        ImGuiStorage_GetBool(state, igGetID("##MINIMIZE")) ? 
                            (incGetDarkMode() ? ImVec4(1, 1, 1, 1) : ImVec4(.3, .3, .3, 1)) : 
                            ImVec4(.5, .5, .5, 1), 
                        ""
                    );
                    if (igIsItemClicked()) {
                        SDL_MinimizeWindow(window);
                    }
                    if(igIsItemHovered()) {
                        ImGuiStorage_SetBool(state, igGetID("##MINIMIZE"), true);
                    } else {
                        ImGuiStorage_SetBool(state, igGetID("##MINIMIZE"), false);
                    }

                    bool isMaximized = (SDL_GetWindowFlags(window) & SDL_WINDOW_MAXIMIZED) > 0;
                    
                    igTextColored(
                        ImGuiStorage_GetBool(state, igGetID("##MAXIMIZE")) ? 
                            (incGetDarkMode() ? ImVec4(1, 1, 1, 1) : ImVec4(.3, .3, .3, 1)) : 
                            ImVec4(.5, .5, .5, 1), 
                        isMaximized ? "" : ""
                    );
                    if (igIsItemClicked()) {
                        if (!isMaximized) SDL_MaximizeWindow(window);
                        else SDL_RestoreWindow(window);
                    }
                    if(igIsItemHovered()) {
                        ImGuiStorage_SetBool(state, igGetID("##MAXIMIZE"), true);
                    } else {
                        ImGuiStorage_SetBool(state, igGetID("##MAXIMIZE"), false);
                    }
                    
                    igTextColored(
                        ImGuiStorage_GetBool(state, igGetID("##EXIT")) ? 
                            ImVec4(1, .1, .1, 1) : 
                            ImVec4(.5, .5, .5, 1), 
                        ""
                    );
                    if (igIsItemClicked()) {
                        incExit();
                    }
                    if(igIsItemHovered()) {
                        ImGuiStorage_SetBool(state, igGetID("##EXIT"), true);
                    } else {
                        ImGuiStorage_SetBool(state, igGetID("##EXIT"), false);
                    }
                igPopFont();

                igEndMenuBar();
            }
                
            igEnd();
        }
    igPopStyleColor();
    igPopStyleVar();
}