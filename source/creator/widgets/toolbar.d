module creator.widgets.toolbar;
import creator.widgets;
import creator.core;
import creator;

void incToolbar() {
    auto flags = 
        ImGuiWindowFlags.NoSavedSettings |
        ImGuiWindowFlags.NoScrollbar |
        ImGuiWindowFlags.MenuBar;

    igPushStyleVar(ImGuiStyleVar.FramePadding, ImVec2(0, 10));
    if (igBeginViewportSideBar("##Toolbar", igGetMainViewport(), ImGuiDir.Up, 32, flags)) {
        
        if (igBeginMenuBar()) {
            igPopStyleVar();
            
            ImVec2 avail;
            igGetContentRegionAvail(&avail);
            
            igDummy(ImVec2(avail.x-144, 0));

            igPushStyleVar(ImGuiStyleVar.FramePadding, ImVec2(0, 0));
            igPushStyleVar(ImGuiStyleVar.FrameRounding, 0);
                igPushFont(incIconFont());

                    igPushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0));
                        if (igButton(incEditMode == EditMode.ModelEdit ? "" : "", ImVec2(32, 32))) {
                            incEditMode = EditMode.ModelEdit;
                        }
                        incTooltip("Edit Model");

                        if (igButton(incEditMode == EditMode.ParamEdit ? "" : "", ImVec2(32, 32))) {
                            incEditMode = EditMode.ParamEdit;
                        }
                        incTooltip("Edit Deformation");

                        if (igButton(incEditMode == EditMode.VertexEdit ? "" : "", ImVec2(32, 32))) {
                            incEditMode = EditMode.VertexEdit;
                        }
                        incTooltip("Edit Vertex Data");
                    igPopStyleVar();

                    igSpacing();

                    igButton("", ImVec2(32, 32));
                    incTooltip("Test Model");

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