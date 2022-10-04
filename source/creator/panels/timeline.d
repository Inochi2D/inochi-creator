/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.panels.timeline;
version(InExperimental) {
    import creator.panels;
    import i18n;
    import inochi2d;
    import bindbc.imgui;
    import creator.widgets;

    /**
        The timeline panel
    */
    class TimelinePanel : Panel {
    private:
        Animation* workingAnimation;
        bool playing;

    protected:
        override
        void onBeginUpdate() {
            igPushStyleVar(ImGuiStyleVar.WindowPadding, ImVec2(0, 0));
            igPushStyleVar(ImGuiStyleVar.ChildBorderSize, 0);
            super.onBeginUpdate();
        }

        override
        void onEndUpdate() {
            super.onEndUpdate();
            igPopStyleVar(2);
        }

        override
        void onUpdate() {
    
            if (incBeginInnerToolbar(24)) {
                if (incToolbarButton(playing ? "" : "", 64)) {
                    playing = !playing;
                }
            }
            incEndInnerToolbar();
        }

    public:
        this() {
            super("Timeline", _("Timeline"), false);
        }
    }

    /**
        Generate timeline panel
    */
    mixin incPanel!TimelinePanel;
}