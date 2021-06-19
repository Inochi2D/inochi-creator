module creator.widgets.toolbar;
import creator.widgets;
import creator.core;

void incToolbar() {
    auto flags = 
        ImGuiWindowFlags.NoSavedSettings |
        ImGuiWindowFlags.NoScrollbar |
        ImGuiWindowFlags.MenuBar;

    igPushStyleVar(ImGuiStyleVar.FramePadding, ImVec2(0, 10));
    if (igBeginViewportSideBar("##Toolbar", igGetMainViewport(), ImGuiDir.Up, 32, flags)) {
        
        if (igBeginMenuBar()) {
            igPopStyleVar();
            
            igPushStyleVar(ImGuiStyleVar.FramePadding, ImVec2(0, 0));
            igPushStyleVar(ImGuiStyleVar.FrameRounding, 0);
                igPushFont(incIconFont());
                    igButton("", ImVec2(32, 32));
                    igButton("", ImVec2(32, 32));
                    igButton("", ImVec2(32, 32));
                igPopFont();
            igPopStyleVar(2);

            igEndMenuBar();
        } else {
            igPopStyleVar();
        }

        igEnd();
    } else {
        igPopStyleVar();
    }
}