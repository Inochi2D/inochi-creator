/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets.mainmenu;
import creator.windows;
import creator.widgets;
import creator.frames;
import creator.core;
import creator.utils.link;
import creator;
import inochi2d;
import inochi2d.core.dbg;
import tinyfiledialogs;

import std.string;

private {
    bool dbgShowStyleEditor;
    bool dbgShowDebugger;
}

void incMainMenu() {
    auto io = igGetIO();

    if(igBeginMainMenuBar()) {
        ImVec2 avail;
        igGetContentRegionAvail(&avail);
        if (incGetUseNativeTitlebar()) {
            igImage(
                cast(void*)incGetLogo(), 
                ImVec2(avail.y*2, avail.y*2), 
                ImVec2(0, 0), ImVec2(1, 1), 
                ImVec4(1, 1, 1, 1), 
                ImVec4(0, 0, 0, 0)
            );

            igSeparator();
        }

        if (igBeginMenu("File", true)) {
            if(igMenuItem("New", "Ctrl+N", false, true)) {
                incNewProject();
            }

            if (igBeginMenu("Open", true)) {
                igEndMenu();
            }
            
            if(igMenuItem("Save", "Ctrl+S", false, true)) {
            }
            
            if(igMenuItem("Save As...", "Ctrl+Shift+S", false, true)) {
            }

            if (igBeginMenu("Import", true)) {
                if(igMenuItem_Bool("Photoshop Document", "", false, true)) {
                    const TFD_Filter[] filters = [
                        { ["*.psd"], "Photoshop Document (*.psd)" }
                    ];

                    c_str filename = tinyfd_openFileDialog("Import...", "", filters, false);
                    if (filename !is null) {
                        string file = cast(string)filename.fromStringz;
                        incImportPSD(file);
                    }
                }
                igEndMenu();
            }
            if (igBeginMenu("Export", true)) {
                if(igMenuItem_Bool("Inochi Puppet", "", false, true)) {
                    const TFD_Filter[] filters = [
                        { ["*.inp"], "Inochi2D Puppet (*.inp)" }
                    ];

                    import std.path : setExtension;

                    c_str filename = tinyfd_saveFileDialog("Export...", "", filters);
                    if (filename !is null) {
                        string file = cast(string)filename.fromStringz;

                        // Remember to populate texture slots otherwise things will break real bad!
                        incActivePuppet().populateTextureSlots();

                        // Write the puppet to file
                        inWriteINPPuppet(incActivePuppet(), file.setExtension(".inp"));
                    }
                }
                igEndMenu();
            }

            if(igMenuItem_Bool("Quit", "Alt+F4", false, true)) incExit();
            igEndMenu();
        }
        
        if (igBeginMenu("Edit", true)) {
            if(igMenuItem_Bool("Undo", "Ctrl+Z", false, incActionCanUndo())) incActionUndo();
            if(igMenuItem_Bool("Redo", "Ctrl+Shift+Z", false, incActionCanRedo())) incActionRedo();
            
            igSeparator();
            if(igMenuItem_Bool("Cut", "Ctrl+X", false, false)) {}
            if(igMenuItem_Bool("Copy", "Ctrl+C", false, false)) {}
            if(igMenuItem_Bool("Paste", "Ctrl+V", false, false)) {}

            igSeparator();
            if(igMenuItem_Bool("Settings", "", false, true)) {
                if (!incIsSettingsOpen) incPushWindow(new SettingsWindow);
            }
            
            debug {
                igSpacing();
                igSpacing();

                igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "ImGui Debugging");

                igSeparator();
                if(igMenuItem_Bool("Style Editor", "", false, true)) dbgShowStyleEditor = !dbgShowStyleEditor;
                if(igMenuItem_Bool("ImGui Debugger", "", false, true)) dbgShowDebugger = !dbgShowDebugger;
            }
            igEndMenu();
        }

        if (igBeginMenu("View", true)) {
            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Frames");
            igSeparator();

            foreach(frame; incFrames) {

                // Skip frames that'll always be visible
                if (frame.alwaysVisible) continue;

                // Show menu item for frame
                if(igMenuItem_Bool(frame.name.ptr, null, frame.visible, true)) {
                    frame.visible = !frame.visible;
                    incSettingsSet(frame.name~".visible", frame.visible);
                }
            }

            // Spacing
            igSpacing();
            igSpacing();
            
            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Extras");

            igSeparator();
            if (igMenuItem_Bool("Show Stats for Nerds", "", incShowStatsForNerds, true)) {
                incShowStatsForNerds = !incShowStatsForNerds;
                incSettingsSet("NerdStats", incShowStatsForNerds);
            }

            igEndMenu();
        }

        if (igBeginMenu("Tools", true)) {
            import creator.utils.repair : incAttemptRepairPuppet, incRegenerateNodeIDs;

            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), "Puppet Recovery");
            igSeparator();

            // FULL REPAIR
            if (igMenuItem("Attempt full repair...", "", false)) {
                incAttemptRepairPuppet(incActivePuppet());
            }
            incTooltip("Attempts all the recovery and repair methods below on the currently loaded model");

            // REGEN NODE IDs
            if (igMenuItem("Regenerate Node IDs", "", false)) {
                import creator.utils.repair : incAttemptRepairPuppet;
                incRegenerateNodeIDs(incActivePuppet().root);
            }
            incTooltip("Regenerates all the unique IDs for the model");

            // Spacing
            igSpacing();
            igSpacing();
            igSeparator();
            if (igMenuItem("Verify INP File...", "", false)) {
                incAttemptRepairPuppet(incActivePuppet());
            }
            incTooltip("Attempts to verify and repair INP files");

            igEndMenu();
        }

        if (igBeginMenu("Help", true)) {

            if(igMenuItem_Bool("Tutorial", "(TODO)", false, false)) { }
            igSeparator();
            
            if(igMenuItem_Bool("Online Documentation", "", false, true)) {
                incOpenLink("https://github.com/Inochi2D/inochi-creator/wiki");
            }
            
            if(igMenuItem_Bool("Inochi2D Documentation", "", false, true)) {
                incOpenLink("https://github.com/Inochi2D/inochi2d/wiki");
            }
            igSeparator();

            if(igMenuItem_Bool("About", "", false, true)) {
                incPushWindow(new AboutWindow);
            }
            igEndMenu();
        }

        // We need to pre-calculate the size of the right adjusted section
        // This code is very ugly because imgui doesn't really exactly understand this
        // stuff natively.
        ImVec2 secondSectionLength = ImVec2(0, 0);
        secondSectionLength.x += incMeasureString("Donate").x+16; // Add 16 px padding
        if (incShowStatsForNerds) { // Extra padding I guess
            secondSectionLength.x += igGetStyle().ItemSpacing.x;
            secondSectionLength.x += incMeasureString("1000ms").x;
        }
        incDummy(ImVec2(-secondSectionLength.x, 0));

        if (incShowStatsForNerds) {
            string fpsText = "%.0fms\0".format(1000f/io.Framerate);
            float textAreaDummyWidth = incMeasureString("1000ms").x-incMeasureString(fpsText).x;
            incDummy(ImVec2(textAreaDummyWidth, 0));
            igText(fpsText.ptr);
        }
        
        // Donate button
        // NOTE: Is this too obstructive in the UI?
        if(igMenuItem("Donate")) {
            incOpenLink("https://www.patreon.com/clipsey");
        }
        incTooltip("Support development via Patreon");

        igEndMainMenuBar();

        if (dbgShowStyleEditor) igShowStyleEditor(igGetStyle());
        if (dbgShowDebugger) igShowAboutWindow(&dbgShowDebugger);
    }
}