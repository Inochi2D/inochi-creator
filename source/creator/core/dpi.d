module creator.core.dpi;
import creator.core.settings;
import i18n;

version (NoUIScaling) { }
else version(UseUIScaling) {
    private {
        float uiScale;
    } 

    void incInitDPIScaling() {
        
        // Load UI scale
        uiScale = incSettingsGet!float("UIScale", 1.0);
    }
}

/**
    Sets the UI scale for fonts
*/
void incSetUIScale(float scale) {
    version (UseUIScaling) {
        incSettingsSet("UIScale", scale);
        uiScale = scale;
    }
}

/**
    Get the UI scale in terms of font size
*/
float incGetUIScaleFont() {
    // allow user to force the feature to be off
    version (NoUIScaling) return 0.5; 
    else version (UseUIScaling) return incGetUIScale()/2;
    else return 0.5;
}

/**
    Returns the UI Scale
*/
float incGetUIScale() {
    version (NoUIScaling) return 1; 
    else version (UseUIScaling) {
        version (OSX) return 1;
        else return uiScale;
    }
    else return 1;
}

/**
    Gets the UI scale in text form
*/
string incGetUIScaleText() {
    version (NoUIScaling) return _("100% (Locked)"); // UI scaling being locked due to being compiled in multi-window mode.
    else version (UseUIScaling) {
        import std.format : format;
        return "%s%%".format(cast(int)(uiScale*100));
    } else return _("100% (Locked)");
}