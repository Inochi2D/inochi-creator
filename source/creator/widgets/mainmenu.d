/*
    Copyright © 2020-2023, Inochi2D Project
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
import creator.config;
import creator.io.autosave;
import creator;
import inochi2d;
import inochi2d.core.dbg;
import tinyfiledialogs;
import i18n;
import creator.ext;

import std.string;
import std.stdio;
import std.path;

private {
    bool dbgShowStyleEditor;
    bool dbgShowDebugger;
    bool dbgShowMetrics;
    bool dbgShowStackTool;

    void fileNew() {
        incNewProject();
    }

    void fileOpen() {
        const TFD_Filter[] filters = [
            { ["*.inx"], "Inochi Creator Project (*.inx)" }
        ];

        string file = incShowOpenDialog(filters, _("Open..."));
        if (file) incOpenProject(file);
    }

    void fileSave() {
        incPopWelcomeWindow();

        // If a projeect path is set then the user has opened or saved
        // an existing file, we should just override that
        if (incProjectPath.length > 0) {
            // TODO: do backups on every save?

            incSaveProject(incProjectPath);
        } else {
            const TFD_Filter[] filters = [
                { ["*.inx"], "Inochi Creator Project (*.inx)" }
            ];

            string file = incShowSaveDialog(filters, "", _("Save..."));
            if (file) incSaveProject(file);
        }
    }

    void fileSaveAs() {
        incPopWelcomeWindow();
        const TFD_Filter[] filters = [
            { ["*.inx"], "Inochi Creator Project (*.inx)" }
        ];

        string fname = incProjectPath().length > 0 ? incProjectPath : "";
        string file = incShowSaveDialog(filters, fname, _("Save As..."));
        if (file) incSaveProject(file);
    }
}

void incMainMenu() {
    auto io = igGetIO();
    
    // Save these for rendering popups
    auto border = igGetStyle().Colors[ImGuiCol.Border];
    auto borderShadow = igGetStyle().Colors[ImGuiCol.BorderShadow];
    auto seperator = igGetStyle().Colors[ImGuiCol.Separator];

    // Otherwise, hide borders.
    igPushStyleColor(ImGuiCol.Border, ImVec4(0, 0, 0, 0));
    igPushStyleColor(ImGuiCol.BorderShadow, ImVec4(0, 0, 0, 0));
    igPushStyleColor(ImGuiCol.Separator, ImVec4(0, 0, 0, 0));

        if (incShortcut("Ctrl+N")) fileNew();
        if (incShortcut("Ctrl+O")) fileOpen();
        if (incShortcut("Ctrl+S")) fileSave();
        if (incShortcut("Ctrl+Shift+S")) fileSaveAs();

        if (!incSettingsGet("hasDoneQuickSetup", false)) igBeginDisabled();

        if(igBeginMainMenuBar()) {
                
            ImVec2 pos;
            igGetCursorPos(&pos);
            igSetCursorPos(ImVec2(pos.x-(igGetStyle().WindowPadding.x/2), pos.y));

            ImVec2 avail;
            igGetContentRegionAvail(&avail);
            version (InBranding) {
                igImage(
                    cast(void*)incGetLogoI2D().getTextureId(), 
                    ImVec2(avail.y*2, avail.y*2), 
                    ImVec2(0, 0), ImVec2(1, 1), 
                    ImVec4(1, 1, 1, 1), 
                    ImVec4(0, 0, 0, 0)
                );
                
                import creator.core.egg : incAdaTickOne;
                if (igIsItemClicked(ImGuiMouseButton.Left)) {
                    incAdaTickOne();
                }
                igSeparator();
            }


            // We do want borders on our popup menus.
            igPushStyleColor(ImGuiCol.Border, border);
            igPushStyleColor(ImGuiCol.BorderShadow, borderShadow);
            igPushStyleColor(ImGuiCol.Separator, seperator);
                if (igBeginMenu(__("File"), true)) {
                    if(igMenuItem(__("New"), "Ctrl+N", false, true)) {
                        fileNew();
                    }

                    if (igMenuItem(__("Open"), "Ctrl+O", false, true)) {
                        fileOpen();
                    }

                    string[] prevProjects = incGetPrevProjects();
                    AutosaveRecord[] prevAutosaves = incGetPrevAutosaves();
                    if (igBeginMenu(__("Recent"), prevProjects.length > 0)) {
                        import std.path : baseName;
                        if (igBeginMenu(__("Autosaves"), prevAutosaves.length > 0)) {
                            foreach(saveRecord; prevAutosaves) {
                                auto autosavePath = saveRecord.autosavePath.baseName.toStringz;
                                if (igMenuItem(autosavePath, "", false, true)) {
                                    incOpenProject(
                                        saveRecord.mainsavePath,
                                        saveRecord.autosavePath
                                    );
                                }
                                incTooltip(saveRecord.autosavePath);
                            }
                            igEndMenu();
                        }

                        foreach(project; incGetPrevProjects) {
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
                        if(igMenuItem(__("Photoshop Document"), "", false, true)) {
                            incPopWelcomeWindow();
                            incImportShowPSDDialog();
                        }
                        incTooltip(_("Import a standard Photoshop PSD file."));
                        if(igMenuItem(__("Krita Document"), "", false, true)) {
                            incPopWelcomeWindow();
                            incImportShowKRADialog();
                        }
                        incTooltip(_("Import a standard Krita KRA file."));

                        if (igMenuItem(__("Inochi2D Puppet"), "", false, true)) {
                            const TFD_Filter[] filters = [
                                { ["*.inp"], "Inochi2D Puppet (*.inp)" }
                            ];

                            string file = incShowOpenDialog(filters, _("Import..."));
                            if (file) {
                                incImportINP(file);
                            }
                        }
                        incTooltip(_("Import existing puppet file, editing options limited"));

                        if (igMenuItem(__("Image Folder"))) {
                            string folder = incShowOpenFolderDialog(_("Select a Folder..."));
                            if (folder) {
                                incImportFolder(folder);
                            }
                        }
                        incTooltip(_("Supports PNGs, TGAs and JPEGs."));
                        igEndMenu();
                    }
                    if (igBeginMenu(__("Merge"), true)) {
                        if(igMenuItem(__("Photoshop Document"), "", false, true)) {
                            const TFD_Filter[] filters = [
                                { ["*.psd"], "Photoshop Document (*.psd)" }
                            ];

                            string file = incShowOpenDialog(filters, _("Import..."));
                            if (file) {
                                incPopWelcomeWindow();
                                incPushWindow(new PSDMergeWindow(file));
                            }
                        }
                        incTooltip(_("Merge layers from Photoshop document"));

                        if(igMenuItem(__("Krita Document"), "", false, true)) {
                            const TFD_Filter[] filters = [
                                { ["*.kra"], "Krita Document (*.kra)" }
                            ];

                            string file = incShowOpenDialog(filters, _("Import..."));
                            if (file) {
                                incPopWelcomeWindow();
                                incPushWindow(new KRAMergeWindow(file));
                            }
                        }
                        incTooltip(_("Merge layers from Krita document"));

                        if(igMenuItem(__("Image Files"), "", false, true)) {
                            const TFD_Filter[] filters = [
                                { ["*.png"], "Portable Network Graphics (*.png)" },
                                { ["*.jpeg", "*.jpg"], "JPEG Image (*.jpeg)" },
                                { ["*.tga"], "TARGA Graphics (*.tga)" }
                            ];

                            string path = incShowImportDialog(filters, _("Import..."), true);
                            if (path) {
                                try {
                                    incCreatePartsFromFiles(path.split("|"));
                                } catch (Exception ex) {
                                    incDialog(__("Error"), ex.msg);
                                }
                            }
                        }
                        incTooltip(_("Merges (adds) selected image files to project"));

                        if (igMenuItem(__("Inochi Creator Project"), "", false, true)) {
                            incPopWelcomeWindow();
                            // const TFD_Filter[] filters = [
                            //     { ["*.inp"], "Inochi2D Puppet (*.inp)" }
                            // ];

                            // c_str filename = tinyfd_openFileDialog(__("Import..."), "", filters, false);
                            // if (filename !is null) {
                            //     string file = cast(string)filename.fromStringz;
                            // }
                        }
                        incTooltip(_("Merge another Inochi Creator project in to this one"));
                        
                        igEndMenu();
                    }

                    if (igBeginMenu(__("Export"), true)) {
                        if(igMenuItem(__("Inochi2D Puppet"), "", false, true)) {
                            const TFD_Filter[] filters = [
                                { ["*.inp"], "Inochi2D Puppet (*.inp)" }
                            ];

                            string file = incShowSaveDialog(filters, "", _("Export..."));
                            if (file) incExportINP(file);
                        }
                        if (igBeginMenu(__("Image"), true)) {
                            if(igMenuItem(__("PNG (*.png)"), "", false, true)) {
                                const TFD_Filter[] filters = [
                                    { ["*.png"], "Portable Network Graphics (*.png)" }
                                ];

                                string file = incShowSaveDialog(filters, "", _("Export..."));
                                if (file) incPushWindow(new ImageExportWindow(file.setExtension("png")));
                            }

                            if(igMenuItem(__("JPEG (*.jpeg)"), "", false, true)) {
                                const TFD_Filter[] filters = [
                                    { ["*.jpeg", "*.jpg"], "JPEG Image (*.jpeg)" }
                                ];

                                string file = incShowSaveDialog(filters, "", _("Export..."));
                                if (file) incPushWindow(new ImageExportWindow(file.setExtension("jpeg")));
                            }

                            if(igMenuItem(__("TARGA (*.tga)"), "", false, true)) {
                                const TFD_Filter[] filters = [
                                    { ["*.tga"], "TARGA Graphics (*.tga)" }
                                ];

                                string file = incShowSaveDialog(filters, "", _("Export..."));
                                if (file) incPushWindow(new ImageExportWindow(file.setExtension("tga")));
                            }

                            igEndMenu();
                        }
                        if(igMenuItem(__("Video"), "", false, incVideoCanExport())) {
                            const TFD_Filter[] filters = [
                                { ["*.mp4"], "H.264 Video (*.mp4)" },
                                { ["*.avi"], "AVI Video (*.avi)" },
                                { ["*.webm"], "WebM Video (*.webm)" },
                                { ["*.png"], "PNG Sequence (*.png)" }
                            ];

                            string file = incShowSaveDialog(filters, "", _("Export..."));
                            if (file) {

                                // Fallback to .mp4
                                if (!extension(file)) file = file.setExtension("mp4");
                                incPushWindow(new VideoExportWindow(file));
                            }
                        }
                        igEndMenu();
                    }

                    // Close Project option
                    if (igMenuItem(__("Close Project"))) {

                        // TODO: Check if changes were done to project and warn before
                        // creating new project
                        incNewProject();
                        incPushWindow(new WelcomeWindow());
                    }

                    // Quit option
                    if (igMenuItem(__("Quit"), "Alt+F4", false, true)) incExit();
                    igEndMenu();
                }
                
                if (igBeginMenu(__("Edit"), true)) {
                    if(igMenuItem(__("Undo"), "Ctrl+Z", false, incActionCanUndo())) incActionUndo();
                    if(igMenuItem(__("Redo"), "Ctrl+Shift+Z", false, incActionCanRedo())) incActionRedo();
                    
                    igSeparator();
                    if(igMenuItem(__("Cut"), "Ctrl+X", false, false)) {}
                    if(igMenuItem(__("Copy"), "Ctrl+C", false, false)) {}
                    if(igMenuItem(__("Paste"), "Ctrl+V", false, false)) {}

                    igSeparator();
                    if(igMenuItem(__("Settings"), "", false, true)) {
                        if (!incIsSettingsOpen) incPushWindow(new SettingsWindow);
                    }
                    
                    debug {
                        igSpacing();
                        igSpacing();

                        igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("ImGui Debugging"));

                        igSeparator();
                        if(igMenuItem(__("Style Editor"), "", dbgShowStyleEditor, true)) dbgShowStyleEditor = !dbgShowStyleEditor;
                        if(igMenuItem(__("ImGui Debugger"), "", dbgShowDebugger, true)) dbgShowDebugger = !dbgShowDebugger;
                        if(igMenuItem(__("ImGui Metrics"), "", dbgShowMetrics, true)) dbgShowMetrics = !dbgShowMetrics;
                        if(igMenuItem(__("ImGui Stack Tool"), "", dbgShowStackTool, true)) dbgShowStackTool = !dbgShowStackTool;
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

                        if (!panel.isActive()) igBeginDisabled();

                        // Show menu item for panel
                        if(igMenuItem(panel.displayNameC, null, panel.visible, true)) {
                            panel.visible = !panel.visible;
                            incSettingsSet(panel.name~".visible", panel.visible);
                        }

                        if (!panel.isActive()) {
                            igEndDisabled();
                            incTooltip(_("Panel is not visible in current edit mode."));
                        }
                    }

                    // Spacing
                    igSpacing();
                    igSpacing();

                    igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Configuration"));

                    // Opens the directory where configuration resides in the user's file browser.
                    if (igMenuItem(__("Open Configuration Folder"), null, false, true)) {
                        incOpenLink(incGetAppConfigPath());
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
                        
                        string filename = incShowSaveDialog(filters, "", _("Save Screenshot..."));
                        if (filename) {
                            string file = filename.setExtension("png");

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
                            incResetClearColor();
                            
                            // Write to texture
                            outTexture.setData(textureData);

                            outTexture.save(file);
                        }
                    }
                    incTooltip(_("Saves screenshot as PNG of the editor framebuffer."));

                    if (igMenuItem(__("Show Stats for Nerds"), "", incShowStatsForNerds, true)) {
                        incShowStatsForNerds = !incShowStatsForNerds;
                        incSettingsSet("NerdStats", incShowStatsForNerds);
                    }


                    igEndMenu();
                }

                if (igBeginMenu(__("Tools"), true)) {
                    import creator.utils.repair : incAttemptRepairPuppet, incRegenerateNodeIDs;

                    igTextColored(ImVec4(0.7, 0.5, 0.5, 1), __("Puppet Data"));
                    igSeparator();

                    // Opens the directory where configuration resides in the user's file browser.
                    if (igMenuItem(__("Import Inochi Session Data"), null, false, true)) {
                        const TFD_Filter[] filters = [
                            { ["*.inp"], "Inochi2D Puppet (*.inp)" }
                        ];

                        if (string path = incShowImportDialog(filters, _("Import..."))) {
                            Puppet p = inLoadPuppet!ExPuppet(path);

                            if ("com.inochi2d.inochi-session.bindings" in p.extData) {
                                incActivePuppet().extData["com.inochi2d.inochi-session.bindings"] = p.extData["com.inochi2d.inochi-session.bindings"].dup;
                                incSetStatus(_("Successfully overwrote Inochi Session tracking data..."));
                            } else {
                                incDialog(__("Error"), _("There was no Inochi Session data to import!"));
                            }

                            destroy!false(p);
                        }
                    }
                    incTooltip(_("Imports tracking data from an exported Inochi2D model which has been set up in Inochi Session."));
                    

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

                    if (igMenuItem(__("Generate fake layer name info..."), "", false)) {
                        import creator.ext;
                        auto parts = incActivePuppet().getAllParts();
                        foreach(ref part; parts) {
                            auto expart = cast(ExPart)part;
                            if (expart) {
                                expart.layerPath = "/"~part.name;
                            }
                        }
                    }
                    incTooltip(_("Generates fake layer info based on node names"));

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

                    if(igMenuItem(__("Online Documentation"), "", false, true)) {
                        incOpenLink("https://github.com/Inochi2D/inochi-creator/wiki");
                    }
                    
                    if(igMenuItem(__("Inochi2D Documentation"), "", false, true)) {
                        incOpenLink("https://github.com/Inochi2D/inochi2d/wiki");
                    }
                    igSpacing();
                    igSeparator();
                    igSpacing();
                    

                    if (igMenuItem(__("Report a Bug"))) {
                        incOpenLink(INC_BUG_REPORT_URI);
                    }
                    if (igMenuItem(__("Request a Feature"))) {
                        incOpenLink(INC_FEATURE_REQ_URI);
                    }
                    igSpacing();
                    igSeparator();
                    igSpacing();


                    if(igMenuItem(__("About"), "", false, true)) {
                        incPushWindow(new AboutWindow);
                    }
                    igEndMenu();
                }
                
            igPopStyleColor();
            igPopStyleColor();
            igPopStyleColor();

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
                string fpsText = "%.0fms".format(1000f/io.Framerate);
                float textAreaDummyWidth = incMeasureString("1000ms").x-incMeasureString(fpsText).x;
                incDummy(ImVec2(textAreaDummyWidth, 0));
                incText(fpsText);
            }
            
            // Donate button
            // NOTE: Is this too obstructive in the UI?
            if(igMenuItem(__("Donate"))) {
                incOpenLink("https://www.patreon.com/clipsey");
            }
            incTooltip(_("Support development via Patreon"));
        }
        igEndMainMenuBar();

        // For quick-setup stuff
        if (!incSettingsGet("hasDoneQuickSetup", false)) igEndDisabled();

    igPopStyleColor();
    igPopStyleColor();
    igPopStyleColor();

    // ImGui Debug Stuff
    if (dbgShowStyleEditor) igShowStyleEditor(igGetStyle());
    if (dbgShowDebugger) igShowAboutWindow(&dbgShowDebugger);
    if (dbgShowStackTool) igShowStackToolWindow();
    if (dbgShowMetrics) igShowMetricsWindow();
}