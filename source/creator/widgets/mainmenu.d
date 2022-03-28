/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets.mainmenu;
import creator.windows;
import creator.widgets;
import creator.panels;
import creator.core;
import creator.core.input;
import creator.utils.link;
import creator;
import inochi2d;
import inochi2d.core.dbg;
import tinyfiledialogs;
import i18n;

import std.string;
import std.stdio;

private {
    bool dbgShowStyleEditor;
    bool dbgShowDebugger;

    void fileNew() {
        incNewProject();
    }

    void fileOpen() {
        const TFD_Filter[] filters = [
            { ["*.inx"], "Inochi Creator Project (*.inx)" }
        ];

        c_str filename = tinyfd_openFileDialog(__("Open..."), "", filters, false);
        if (filename !is null) {
            string file = cast(string)filename.fromStringz;
            incOpenProject(file);
        }
    }

    void fileSave() {
        // If a projeect path is set then the user has opened or saved
        // an existing file, we should just override that
        if (incProjectPath.length > 0) {
            // TODO: do backups on every save?

            incSaveProject(incProjectPath);
        } else {
            const TFD_Filter[] filters = [
                { ["*.inx"], "Inochi Creator Project (*.inx)" }
            ];

            c_str filename = tinyfd_saveFileDialog(__("Save..."), "", filters);
            if (filename !is null) {
                string file = cast(string)filename.fromStringz;
                incSaveProject(file);
            }
        }
    }

    void fileSaveAs() {
        const TFD_Filter[] filters = [
            { ["*.inx"], "Inochi Creator Project (*.inx)" }
        ];

        c_str filename = tinyfd_saveFileDialog(__("Save As..."), "", filters);
        if (filename !is null) {
            string file = cast(string)filename.fromStringz;
            incSaveProject(file);
        }
    }
}

void incMainMenu() {
    auto io = igGetIO();

    if (incShortcut("Ctrl+N")) fileNew();
    if (incShortcut("Ctrl+O")) fileOpen();
    if (incShortcut("Ctrl+S")) fileSave();
    if (incShortcut("Ctrl+Shift+S")) fileSaveAs();

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

        if (igBeginMenu(__("File"), true)) {
            if(igMenuItem(__("New"), "Ctrl+N", false, true)) {
                fileNew();
            }

            if (igMenuItem(__("Open"), "Ctrl+O", false, true)) {
                fileOpen();
            }

            string[] prevProjects = incGetPrevProjects();
            if (igBeginMenu(__("Recent"), prevProjects.length > 0)) {
                foreach(project; incGetPrevProjects) {
                    import std.path : baseName;
                    if (igMenuItem(project.baseName.toStringz, "", false, true)) {
                        incOpenProject(project);
                    }
                    incTooltip(project);
                }
                igEndMenu();
            }
            
            if(igMenuItem(__("Save"), "Ctrl+S", false, true)) {
                fileSave();
            }
            
            if(igMenuItem(__("Save As..."), "Ctrl+Shift+S", false, true)) {
                fileSaveAs();
            }

            if (igBeginMenu(__("Import"), true)) {
                if(igMenuItem_Bool(__("Photoshop Document"), "", false, true)) {
                    const TFD_Filter[] filters = [
                        { ["*.psd"], "Photoshop Document (*.psd)" }
                    ];

                    c_str filename = tinyfd_openFileDialog(__("Import..."), "", filters, false);
                    if (filename !is null) {
                        string file = cast(string)filename.fromStringz;
                        incImportPSD(file);
                    }
                }
                incTooltip(_("Import a standard Photoshop PSD file."));

                if (igMenuItem_Bool(__("Inochi2D Puppet"), "", false, true)) {
                    const TFD_Filter[] filters = [
                        { ["*.inp"], "Inochi2D Puppet (*.inp)" }
                    ];

                    c_str filename = tinyfd_openFileDialog(__("Import..."), "", filters, false);
                    if (filename !is null) {
                        string file = cast(string)filename.fromStringz;
                        incImportINP(file);
                    }
                }
                incTooltip(_("Import existing puppet file, editing options limited"));

                if (igMenuItem_Bool(__("Image Folder"))) {
                    c_str folder = tinyfd_selectFolderDialog(__("Select a Folder..."), null);
                    if (folder !is null) {
                        incImportFolder(cast(string)folder.fromStringz);
                    }
                }
                incTooltip(_("Supports PNGs, TGAs and JPEGs."));
                igEndMenu();
            }

            if (igBeginMenu(__("Export"), true)) {
                if(igMenuItem_Bool(__("Inochi Puppet"), "", false, true)) {
                    const TFD_Filter[] filters = [
                        { ["*.inp"], "Inochi2D Puppet (*.inp)" }
                    ];

                    import std.path : setExtension;

                    c_str filename = tinyfd_saveFileDialog(__("Export..."), "", filters);
                    if (filename !is null) {
                        string file = cast(string)filename.fromStringz;

                        incExportINP(file);
                    }
                }
                igEndMenu();
            }

            if(igMenuItem_Bool(__("Quit"), "Alt+F4", false, true)) incExit();
            igEndMenu();
        }
        
        if (igBeginMenu(__("Edit"), true)) {
            if(igMenuItem_Bool(__("Undo"), "Ctrl+Z", false, incActionCanUndo())) incActionUndo();
            if(igMenuItem_Bool(__("Redo"), "Ctrl+Shift+Z", false, incActionCanRedo())) incActionRedo();
            
            igSeparator();
            if(igMenuItem_Bool(__("Cut"), "Ctrl+X", false, false)) {}
            if(igMenuItem_Bool(__("Copy"), "Ctrl+C", false, false)) {}
            if(igMenuItem_Bool(__("Paste"), "Ctrl+V", false, false)) {}

            igSeparator();
            if(igMenuItem_Bool(__("Settings"), "", false, true)) {
                if (!incIsSettingsOpen) incPushWindow(new SettingsWindow);
            }
            
            debug {
                igSpacing();
                igSpacing();

                igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("ImGui Debugging"));

                igSeparator();
                if(igMenuItem_Bool(__("Style Editor"), "", false, true)) dbgShowStyleEditor = !dbgShowStyleEditor;
                if(igMenuItem_Bool(__("ImGui Debugger"), "", false, true)) dbgShowDebugger = !dbgShowDebugger;
            }
            igEndMenu();
        }

        if (igBeginMenu(__("View"), true)) {
            if (igMenuItem(__("Reset Layout"), null, false, true)) {
                incSetDefaultLayout();
            }
            igSeparator();

            // Spacing
            igSpacing();
            igSpacing();

            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Panels"));
            igSeparator();

            foreach(panel; incPanels) {

                // Skip panels that'll always be visible
                if (panel.alwaysVisible) continue;

                // Show menu item for panel
                if(igMenuItem_Bool(panel.displayNameC, null, panel.visible, true)) {
                    panel.visible = !panel.visible;
                    incSettingsSet(panel.name~".visible", panel.visible);
                }
            }

            // Spacing
            igSpacing();
            igSpacing();
            
            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Extras"));

            igSeparator();
            
            if (igMenuItem(__("Save Screenshot"), "", false, true)) {
                const TFD_Filter[] filters = [
                    { ["*.png"], "PNG Image (*.png)" }
                ];

                import std.path : setExtension;
                c_str filename = tinyfd_saveFileDialog(__("Save Screenshot..."), "", filters);
                if (filename !is null) {
                    string file = (cast(string)filename.fromStringz).setExtension("png");

                    // Dump viewport to RGBA byte array
                    int width, height;
                    inGetViewport(width, height);
                    Texture outTexture = new Texture(null, width, height);

                    // Texture data
                    inSetClearColor(0, 0, 0, 0);
                    inBeginScene();
                        incActivePuppet().update();
                        incActivePuppet().draw();
                    inEndScene();
                    ubyte[] textureData = new ubyte[inViewportDataLength()];
                    inDumpViewport(textureData);
                    inTexUnPremuliply(textureData);
                    
                    // Write to texture
                    outTexture.setData(textureData);

                    outTexture.save(file);
                }
            }
            incTooltip(_("Saves screenshot as PNG of the editor framebuffer."));

            if (igMenuItem_Bool(__("Show Stats for Nerds"), "", incShowStatsForNerds, true)) {
                incShowStatsForNerds = !incShowStatsForNerds;
                incSettingsSet("NerdStats", incShowStatsForNerds);
            }

            igEndMenu();
        }

        if (igBeginMenu(__("Tools"), true)) {
            import creator.utils.repair : incAttemptRepairPuppet, incRegenerateNodeIDs;

            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Puppet Texturing"));
            igSeparator();

            // Premultiply textures, causing every pixel value in every texture to
            // be multiplied by their Alpha (transparency) component
            if (igMenuItem(__("Premultiply textures"), "", false)) {
                import creator.utils.repair : incPremultTextures;
                incPremultTextures(incActivePuppet());
            }
            incTooltip(_("Premultiplies textures by their alpha component.\n\nOnly use this if your textures look garbled after importing files from an older version of Inochi Creator."));
            
            if (igMenuItem(__("Bleed textures..."), "", false)) {
                incRebleedTextures();
            }
            incTooltip(_("Causes color to bleed out in to fully transparent pixels, this solves outlines on straight alpha compositing.\n\nOnly use this if your game engine can't use premultiplied alpha."));

            if (igMenuItem(__("Generate Mipmaps..."), "", false)) {
                incRegenerateMipmaps();
            }
            incTooltip(_("Regenerates the puppet's mipmaps."));

            // Spacing
            igSpacing();
            igSpacing();

            igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Puppet Recovery"));
            igSeparator();

            // FULL REPAIR
            if (igMenuItem(__("Attempt full repair..."), "", false)) {
                incAttemptRepairPuppet(incActivePuppet());
            }
            incTooltip(_("Attempts all the recovery and repair methods below on the currently loaded model"));

            // REGEN NODE IDs
            if (igMenuItem(__("Regenerate Node IDs"), "", false)) {
                import creator.utils.repair : incAttemptRepairPuppet;
                incRegenerateNodeIDs(incActivePuppet().root);
            }
            incTooltip(_("Regenerates all the unique IDs for the model"));

            // Spacing
            igSpacing();
            igSpacing();
            igSeparator();
            if (igMenuItem(__("Verify INP File..."), "", false)) {
                incAttemptRepairPuppet(incActivePuppet());
            }
            incTooltip(_("Attempts to verify and repair INP files"));

            igEndMenu();
        }

        if (igBeginMenu(__("Help"), true)) {

            if(igMenuItem_Bool(__("Tutorial"), "(TODO)", false, false)) { }
            igSeparator();
            
            if(igMenuItem_Bool(__("Online Documentation"), "", false, true)) {
                incOpenLink("https://github.com/Inochi2D/inochi-creator/wiki");
            }
            
            if(igMenuItem_Bool(__("Inochi2D Documentation"), "", false, true)) {
                incOpenLink("https://github.com/Inochi2D/inochi2d/wiki");
            }
            igSeparator();

            if(igMenuItem_Bool(__("About"), "", false, true)) {
                incPushWindow(new AboutWindow);
            }
            igEndMenu();
        }

        // We need to pre-calculate the size of the right adjusted section
        // This code is very ugly because imgui doesn't really exactly understand this
        // stuff natively.
        ImVec2 secondSectionLength = ImVec2(0, 0);
        secondSectionLength.x += incMeasureString(_("Donate")).x+16; // Add 16 px padding
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
        if(igMenuItem(__("Donate"))) {
            incOpenLink("https://www.patreon.com/clipsey");
        }
        incTooltip(_("Support development via Patreon"));

        igEndMainMenuBar();

        if (dbgShowStyleEditor) igShowStyleEditor(igGetStyle());
        if (dbgShowDebugger) igShowAboutWindow(&dbgShowDebugger);
    }
}