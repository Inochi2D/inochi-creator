module core.utils;
import gtk.CssProvider;

/**
    Returns a CSS provider from a string of css data.
*/
CssProvider styleFromString(string styleSheet) {
    CssProvider provider = new CssProvider();
    provider.loadFromData(styleSheet);
    return provider;
}