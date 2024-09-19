module creator.core.i18n;
import creator.core;
import i18n.culture;
import i18n;
import i18n.tr;
import std.file;
import std.path;
import std.string;
import std.algorithm : sort;
import std.uni : icmp;

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
                entry.name,
                path
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
    string path;
}

/**
    Initialize translations
*/
void incLocaleInit() {

    // These exist for testing + user added localization
    incLocaleScan(incGetAppLocalePath());
    incLocaleScan(thisExePath().dirName);

    // For zip folder exports.
    incLocaleScan(buildPath(thisExePath().dirName, "i18n"));
    
    // On macOS we store the locale in the app bundle under the Resources subdirectory.
    version(OSX) incLocaleScan(buildPath(thisExePath().dirName, "../Resources/i18n"));
    
    // Some distribution platforms like AppImage has its own locale path
    // this is here to detect it and add it in to the scan area.
    auto extraLocalePath = incGetAppLocalePathExtra();
    if (extraLocalePath) incLocaleScan(extraLocalePath);
    
    // sort the files by human readable name
    localeFiles.sort!(compareEntries);
    //disambiguate locales with the same human name
    markDups(localeFiles);
}

bool compareEntries(TLEntry a, TLEntry b) {
    int cmp = icmp(a.humanName, b.humanName);
    if (cmp == 0) {
        return a.path < b.path;
    }
    return cmp < 0;
}

/**
    Disambiguate by source folder for TLEntrys with identical humanNames.
    Expects an array sorted by humanName
*/
void markDups(TLEntry[] entries) {

    // Skip if only one entry
    if (entries.length <= 1) return;
    
    TLEntry* prevEntry = &entries[0];
    bool prevIsDup = false;

    foreach(ref entry; entries[1 .. $]) {
        bool entryIsDup = entry.humanName == prevEntry.humanName;

        // If prevEntry has same humanName as entry before prevEntry, or as this entry,
        // disambiguate with the source folder
        if (prevIsDup || entryIsDup) {
            prevEntry.humanName ~= " (" ~ prevEntry.path ~ ")";
            prevEntry.humanNameC = prevEntry.humanName.toStringz;
        }
        prevIsDup = entryIsDup;
        prevEntry = &entry;
    }

    if (prevIsDup) {
        prevEntry.humanName ~= " (" ~ prevEntry.path ~ ")";
        prevEntry.humanNameC = prevEntry.humanName.toStringz;
    }
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
