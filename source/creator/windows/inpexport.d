/*
    Copyright © 2020-2023, Inochi2D Project
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
import creator.io.inpexport;
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
    Atlassing = "Atlassing",
    Decoration = "Decoration"
}

struct ExportOptions {
    size_t atlasResolution = 2048;
    
    bool nonLinearScaling = false;
    float resolutionScale = 1;

    int padding = 16;
}

class ExportWindow : Window {
private:
    string outFile;
    ExportOptionsPane pane = ExportOptionsPane.Atlassing;
    IncINPPreviewInfo preview;

    bool wasScaledForced;
    IncINPExportSettings settings;

    const(char)* resolutionScaleString = "100%";
    const(char)* atlasResolutionString = "2048x2048";


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
        preview = incINPExportGenPreview(incActivePuppet(), settings);
        wasScaledForced = preview.outputScale != 1;
        if (wasScaledForced) {
            settings.scale = preview.outputScale;
        }
    }

    void setBlending(BlendMode mode) {
        settings.decorateWatermarkBlendMode = mode;
        this.regenPreview();
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

                if (igSelectable(__("Decoration"), pane == ExportOptionsPane.Decoration)) {
                    pane = ExportOptionsPane.Decoration;
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
                            incTextureSlotUntitled("PREVIEW0", preview.preview, ImVec2(previewSize, previewSize), 64);
                        igIndent();

                        incText(_("Atlas Settings"));
                        igIndent();
                            if (igBeginCombo(__("Resolution"), atlasResolutionString)) {

                                size_t size = 1024;
                                foreach(i; 0..3) {
                                    size <<= 1;

                                    const(char)* sizestr = "%1$sx%1$s".format(size.text).toStringz;
                                    if (igMenuItem(sizestr, null, settings.atlasResolution == size)) {
                                        settings.atlasResolution = size;
                                        atlasResolutionString = sizestr;
                                        this.regenPreview();
                                    }
                                }
                                igEndCombo();
                            }

                            igCheckbox(__("Non-linear Scaling"), &settings.nonLinearScaling);
                            incTooltip(_("Whether too large parts should individually be scaled down instead of all parts being scaled down uniformly."));

                            int resScaleInt = cast(int)(settings.scale*100);
                            if (igInputInt(__("Texture Scale"), &resScaleInt, 1, 10)) {
                                resScaleInt = clamp(resScaleInt, 25, 200);
                                settings.scale = (cast(float)resScaleInt/100.0);
                                this.regenPreview();
                            }

                            if (igInputInt(__("Padding"), &settings.padding, 1, 10)) {
                            settings.padding = clamp(settings.padding, 0, int.max);
                            this.regenPreview();
                        }
                        igUnindent();
                        
                        incText(_("Optimizations"));
                        igIndent();
                            igCheckbox(__("Prune unused nodes"), &settings.optimizePruneUnused);
                            incTooltip(_("Prune nodes which have been disabled from the export."));
                        igUnindent();
                        break;

                    case ExportOptionsPane.Decoration:
                        float previewSize = min(avail.x/2, avail.y/2);
                        float offset = previewSize*2 >= avail.x ? 0 : avail.x/2;

                        // Funky tricks to center preview
                        igUnindent();
                            if (offset > 0) {
                                incDummy(ImVec2((avail.x/2)-previewSize, previewSize));

                                igSameLine(0, 0);
                            }

                            incTextureSlot(_("Watermark"), settings.decorateWatermark, ImVec2(previewSize, previewSize));
                            
                            // Right click menu
                            igOpenPopupOnItemClick("TEX_OPTIONS");
                            if (igBeginPopup("TEX_OPTIONS")) {

                                // Allow saving texture to file
                                if (igMenuItem(__("Load"))) {
                                    TFD_Filter[] filters = [
                                        { ["*.png"], "Portable Network Graphics (*.png)" },
                                        { ["*.jpeg", "*.jpg"], "JPEG Image (*.jpeg)" },
                                        { ["*.tga"], "TARGA Graphics (*.tga)" }
                                    ];

                                    string file = incShowImportDialog(filters, _("Import..."));
                                    if (file) {
                                        try {
                                            auto tex = ShallowTexture(file, 4);
                                            inTexPremultiply(tex.data);
                                            settings.decorateWatermark = new Texture(tex);
                                            settings.decorateWatermark.setWrapping(Wrapping.Repeat);
                                            
                                            this.regenPreview();
                                        } catch (Exception ex) {
                                            incDialog("WRONG_TEX_FMT", __("Error"), ex.msg);
                                        }
                                    }
                                }

                                if (igMenuItem(__("Remove"), null, false, settings.decorateWatermark !is null)) {
                                    settings.decorateWatermark = null;
                                    this.regenPreview();
                                }

                                igEndPopup();
                            }
                            

                            // FILE DRAG & DROP
                            if (igBeginDragDropTarget()) {
                                const(ImGuiPayload)* payload = igAcceptDragDropPayload("__PARTS_DROP");
                                if (payload !is null) {
                                    string[] files = *cast(string[]*)payload.Data;
                                    if (files.length > 0) {
                                        try {
                                            auto tex = ShallowTexture(files[0], 4);
                                            inTexPremultiply(tex.data);
                                            settings.decorateWatermark = new Texture(tex);
                                            settings.decorateWatermark.setWrapping(Wrapping.Repeat);
                                            this.regenPreview();
                                        } catch (Exception ex) {
                                            incDialog("WRONG_TEX_FMT", __("Error"), ex.msg);
                                        }
                                    }

                                    // Finish the file drag
                                    incFinishFileDrag();
                                }
                            }
                            igEndDragDropTarget();

                            igSameLine();

                            incTextureSlot(_("Preview"), preview.preview, ImVec2(previewSize, previewSize), 64);
                        igIndent();
                        

                        igBeginDisabled(settings.decorateWatermark is null);
                            incText(_("Blending"));
                            igIndent();

                                // Header for the Blending options for Parts
                                if (igBeginCombo("###Blending", __(settings.decorateWatermarkBlendMode.text))) {

                                    // Normal blending mode as used in Photoshop, generally
                                    // the default blending mode photoshop starts a layer out as.
                                    if (igSelectable(__("Normal"), settings.decorateWatermarkBlendMode == BlendMode.Normal)) this.setBlending(BlendMode.Normal);
                                    
                                    // Multiply blending mode, in which this texture's color data
                                    // will be multiplied with the color data already in the framebuffer.
                                    if (igSelectable(__("Multiply"), settings.decorateWatermarkBlendMode == BlendMode.Multiply)) this.setBlending(BlendMode.Multiply);
                                            
                                    // Color Dodge blending mode
                                    if (igSelectable(__("Color Dodge"), settings.decorateWatermarkBlendMode == BlendMode.ColorDodge)) this.setBlending(BlendMode.ColorDodge);
                                            
                                    // Linear Dodge blending mode
                                    if (igSelectable(__("Linear Dodge"), settings.decorateWatermarkBlendMode == BlendMode.LinearDodge)) this.setBlending(BlendMode.LinearDodge);
                                                    
                                    // Screen blending mode
                                    if (igSelectable(__("Screen"), settings.decorateWatermarkBlendMode == BlendMode.Screen)) this.setBlending(BlendMode.Screen);
                                                    
                                    // Clip to Lower blending mode
                                    if (igSelectable(__("Clip to Lower"), settings.decorateWatermarkBlendMode == BlendMode.ClipToLower)) this.setBlending(BlendMode.ClipToLower);
                                    incTooltip(_("Special blending mode that causes (while respecting transparency) the part to be clipped to everything underneath"));
                                                    
                                    igEndCombo();
                                }
                            igUnindent();

                            incText(_("Loops"));
                            igIndent();
                                if (igDragInt("###LOOPS", cast(int*)&settings.decorateWatermarkLoops, 1, 1, 1000)) this.regenPreview();
                            igUnindent();

                            incText(_("Opacity"));
                            igIndent();
                                if (igDragFloat("###OPACITY", &settings.decorateWatermarkOpacity, 0.01, 0, 1)) this.regenPreview();
                            igUnindent();

                        igEndDisabled();                        
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
            if (wasScaledForced) {
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
                    incINPExport(incActivePuppet(), settings, outFile);
                    incSetStatus(_("%s was exported...".format(outFile)));
                    this.close();
                } catch(Exception ex) {

                    // Write error
                    incDialog(__("Error"), ex.msg);
                    incSetStatus(_("Export failed..."));
                }
            }
        }
        igEndChild();
    }

public:
    this(string outFile) {
        super(_("Export Options"));
        this.outFile = outFile;

        this.regenPreview();
    }
}