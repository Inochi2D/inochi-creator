module creator.core.i18n;
import creator.core;
import i18n.culture;
import i18n;
import i18n.tr;
import std.file;
import std.path;
import std.string;

/+
    HACK: This little comment tricks genpot to generate our LANG_NAME entry.

    // The name of the language this translation is a translation to
    // in the native script of the language (for the region)
    // Eg. this would be "Dansk" for Danish and "日本語" for Japanese.
    _("LANG_NAME")
+/

private {
    TLEntry[] localeFiles;

    string incGetCultureExpression(string langcode) {

        // Most cases
        foreach(locale; localeFiles) {
            if (locale.code == langcode) {
                return locale.humanName;
            }
        }

        // Fallback
        if (langcode.length >= 5) {
            return format("%s (%s)", i18nGetCultureLanguage(langcode),
                langcode == "zh-CN" ? "Simplified" : 
                langcode == "zh-TW" ? "Traditional" :
                i18nGetCultureCountry(langcode));
        }
        return i18nGetCultureLanguage(langcode);
    }

    void incLocaleScan(string path) {

        // Skip non-existent paths
        if (!path.exists) return;

        foreach(DirEntry entry; dirEntries(path, "*.mo", SpanMode.shallow)) {
            
            // Get langcode from filename
            string langcode = baseName(stripExtension(entry.name));

            // Skip langcodes we don't know
            if (!i18nValidateCultureCode(langcode)) continue;

            string langName = i18nGetLanguageName(entry.name);
            if (langName == "<UNKNOWN LANGUAGE>") langName = incGetCultureExpression(langcode);

            // Add locale
            localeFiles ~= TLEntry(
                langName,
                langName.toStringz,
                langcode, 
                entry.name
            );
        }
    }
}

/**
    Entry in the translations table
*/
struct TLEntry {
public:
    string humanName;
    const(char)* humanNameC;
    string code;
    string file;
}

/**
    Initialize translations
*/
void incLocaleInit() {

    // These exist for testing + user added localization
    incLocaleScan(incGetAppLocalePath());
    incLocaleScan(getcwd());
    incLocaleScan(thisExePath().dirName);

    // On Windows we want to store locales next to the exe file in a i18n folder
    version(Windows) incLocaleScan(buildPath(thisExePath().dirName, "i18n"));
    
    // On macOS we store the locale in the app bundle under the Resources subdirectory.
    version(OSX) incLocaleScan(buildPath(thisExePath().dirName, "../Resources/i18n"));
    
    // Some distribution platforms like AppImage has its own locale path
    // this is here to detect it and add it in to the scan area.
    auto extraLocalePath = incGetAppLocalePathExtra();
    if (extraLocalePath) incLocaleScan(extraLocalePath);
}

/**
    Gets the current selected locale human name
*/
string incLocaleCurrentName() {
    string code = incSettingsGet("lang", "en");
    string currCode = code.length == 0 ? "en": code;
    return incGetCultureExpression(currCode);
}

/**
    Sets the locale for the application
*/
void incLocaleSet(string code) {
    incSettingsSet("lang", code);
    
    // Builtin EN has no .po file
    if (code.length == 0 || code == "en") {
        i18nClearLanguage();
        return;
    }

    // Other languages do, though.
    i18nLoadLanguage(incLocaleGetEntryFor(code).file);
}

/**
    Get locale entry for a code
*/
TLEntry* incLocaleGetEntryFor(string code) {
    foreach(ref entry; localeFiles) {
        if (entry.code == code) return &entry;
    }
    return null;
}

/**
    Returns the locale list
*/
TLEntry[] incLocaleGetEntries() {
    return localeFiles;
}