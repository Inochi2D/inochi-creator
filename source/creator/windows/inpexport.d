/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.windows.inpexport;
import creator.widgets.dummy;
import creator.widgets.tooltip;
import creator.widgets.label;
import creator.widgets.dialog;
import creator.widgets.texture;
import creator.windows;
import creator.core;
import creator.io;
import creator;
import std.string;
import creator.utils.link;
import inochi2d;
import i18n;
import std.stdio;
import std.conv;
import std.algorithm.sorting;
import std.algorithm.mutation;

enum ExportOptionsPane {
    Atlassing = "Atlassing"
}

struct ExportOptions {
    size_t atlasResolution = 2048;
    const(char)* atlasResolutionString = "2048x2048";
    
    float resolutionScale = 1;
    const(char)* resolutionScaleString = "100%";

    int padding = 16;
}

class ExportWindow : Window {
private:
    string outFile;
    ExportOptionsPane pane = ExportOptionsPane.Atlassing;
    ExportOptions options;
    
    Atlas preview;

    bool forcedScale;

    void beginSection(string title) {
        incText(title);
        incDummy(ImVec2(0, 4));
        igIndent();
    }
    
    void endSection() {
        igUnindent();
        igNewLine();
    }

    void regenPreview() {
        Part[] parts = incActivePuppet().getAllParts();

        // Force things to fit.
        foreach(part; parts) {
            vec2 size = vec2(
                (part.bounds.z-part.bounds.x)+preview.padding, 
                (part.bounds.w-part.bounds.y)+preview.padding
            );
            float xRatio = ((size.x*options.resolutionScale)/cast(float)options.atlasResolution)+0.01;
            float yRatio = ((size.y*options.resolutionScale)/cast(float)options.atlasResolution)+0.01;
            if (xRatio > 1.0) options.resolutionScale = cast(float)(options.atlasResolution/size.x)-0.01;
            if (yRatio > 1.0) options.resolutionScale = cast(float)(options.atlasResolution/size.y)-0.01;

            forcedScale = true;
        }

        preview.scale = options.resolutionScale;
        preview.padding = options.padding;

        preview.resize(options.atlasResolution);
        preview.clear();

        int i = 0;
        while (i < parts.length && preview.pack(parts[i++])) { }
        preview.finalize();
    }

    Atlas[] generateAtlasses() {
        Atlas[] atlasses = [new Atlas(options.atlasResolution, options.padding, options.resolutionScale)];

        Part[] parts = incActivePuppet().getAllParts();
        size_t partsLeft = parts.length;
        bool[Part] taken;

        bool failed = false;

        // Fill out taken list
        foreach(part; parts) taken[part] = false;

        // Sort parts by size
        import std.math : cmp;
        parts.sort!(
            (a, b) => a.textures[0].width+a.textures[0].height > b.textures[0].width+b.textures[0].height, 
            SwapStrategy.stable
        )();

        mwhile: while(partsLeft > 0) {
            foreach(part; parts) {
                if (taken[part] == true) continue;

                if (atlasses[$-1].pack(part)) {
                    taken[part] = true;
                    partsLeft--;
                    failed = false;
                    continue mwhile;
                }
            }

            // Prevent memory leak
            if (failed) throw new Exception("A texture is too big for the atlas.");

            // Failed putting elements in to atlas, create new empty atlas
            failed = true;
            atlasses[$-1].finalize();
            atlasses ~= new Atlas(options.atlasResolution, options.padding, options.resolutionScale);
        }

        return atlasses;
    }
    
protected:

    override
    void onBeginUpdate() {
        flags |= ImGuiWindowFlags.NoSavedSettings;
        
        ImVec2 wpos = ImVec2(
            igGetMainViewport().Pos.x+(igGetMainViewport().Size.x/2),
            igGetMainViewport().Pos.y+(igGetMainViewport().Size.y/2),
        );

        ImVec2 uiSize = ImVec2(
            512, 
            256+128
        );

        igSetNextWindowPos(wpos, ImGuiCond.Appearing, ImVec2(0.5, 0.5));
        igSetNextWindowSize(uiSize, ImGuiCond.Appearing);
        igSetNextWindowSizeConstraints(uiSize, ImVec2(float.max, float.max));
        super.onBeginUpdate();
    }

    override
    void onUpdate() {
        float availX = incAvailableSpace().x;

        // Sidebar
        if (igBeginChild("SettingsSidebar", ImVec2(availX/3.5, -28), true)) {
            igPushTextWrapPos(128);
                if (igSelectable(__("Atlassing"), pane == ExportOptionsPane.Atlassing)) {
                    pane = ExportOptionsPane.Atlassing;
                }
            igPopTextWrapPos();
        }
        igEndChild();
        
        // Nice spacing
        igSameLine(0, 4);

        // Contents
        if (igBeginChild("SettingsContent", ImVec2(0, -28), true)) {
            ImVec2 avail = incAvailableSpace();

            // Begins section, REMEMBER TO END IT
            beginSection(_(cast(string)pane));

            // Start settings panel elements
            igPushItemWidth(avail.x/2);
                switch(pane) {
                    case ExportOptionsPane.Atlassing:
                        float previewSize = avail.y/2;

                        // Funky tricks to center preview
                        igUnindent();
                            incDummy(ImVec2((avail.x/2)-(previewSize/2), previewSize));
                            igSameLine();
                            incTextureSlotUntitled("PREVIEW0", preview.textures[0], ImVec2(previewSize, previewSize), 64);
                        igIndent();

                        if (igBeginCombo(__("Resolution"), options.atlasResolutionString)) {

                            size_t size = 1024;
                            foreach(i; 0..3) {
                                size <<= 1;

                                const(char)* sizestr = "%1$sx%1$s".format(size.text).toStringz;
                                if (igMenuItem(sizestr, null, options.atlasResolution == size)) {
                                    options.atlasResolution = size;
                                    options.atlasResolutionString = sizestr;
                                    this.regenPreview();
                                }
                            }
                            igEndCombo();
                        }
                        
                        int resScaleInt = cast(int)(options.resolutionScale*100);
                        if (igInputInt(__("Texture Scale"), &resScaleInt, 1, 10)) {
                            if (resScaleInt < 25) resScaleInt = 25;
                            if (resScaleInt > 200) resScaleInt = 200;
                            options.resolutionScale = (cast(float)resScaleInt/100.0);
                            this.regenPreview();
                        }

                        if (igInputInt(__("Padding"), &options.padding, 1, 10)) {
                            if (options.padding < 0) options.padding = 0;
                            this.regenPreview();
                        }
                        break;
                    default:
                        incText(_("No settings for this category."));
                        break;
                }
            igPopItemWidth();
        }
        igEndChild();

        // Bottom buttons
        if (igBeginChild("SettingsButtons", ImVec2(0, 0), false, ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoScrollWithMouse)) {
            availX = incAvailableSpace().x;
            if (forcedScale) {
                igPushTextWrapPos(availX-128);
                    incTextColored(
                        ImVec4(0.8, 0.2, 0.2, 1), 
                        _("A texture was too large to fit the texture atlas, the textures have been scaled down.")
                    );
                igPopTextWrapPos();
            }
            igSameLine(0, 0);
            incDummy(ImVec2(-64, 0));
            igSameLine(0, 0);

            if (igButton(__("Export"), ImVec2(64, 24))) {
                try {
                    // Write the puppet to file
                    incExportINP(incActivePuppet(), generateAtlasses(), outFile);
                    incSetStatus(_("%s was exported...".format(outFile)));
                } catch(Exception ex) {
                    incDialog(__("Error"), ex.msg);
                    incSetStatus(_("Export failed..."));
                }

                // TODO: Show error in export window?
                this.close();
            }
        }
        igEndChild();
    }

public:
    this(string outFile) {
        super(_("Export Options"));
        this.outFile = outFile;

        preview = new Atlas(2048, 16, 1);
        this.regenPreview();
    }
}