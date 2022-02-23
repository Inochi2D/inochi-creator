module creator.core.i18n;
import creator.core;
import i18n.culture;
import i18n;
import std.file;
import std.path;
import std.string;

private {
    TLEntry[] localeFiles;

    void incLocaleScan(string path) {
        foreach(DirEntry entry; dirEntries(path, "*.mo", SpanMode.shallow)) {
            
            // Get langcode from filename
            string langcode = baseName(stripExtension(entry.name));

            // Skip langcodes we don't know
            if (!i18nValidateCultureCode(langcode)) continue;

            // Add locale
            localeFiles ~= TLEntry(
                i18nGetCultureLanguage(langcode),
                i18nGetCultureLanguage(langcode).toStringz,
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
    incLocaleScan(incGetAppLocalePath());
    incLocaleScan(getcwd());
    incLocaleScan(thisExePath().rootName);
}

/**
    Gets the current selected locale human name
*/
string incLocaleCurrentName() {
    string code = incSettingsGet("lang", "en");
    return i18nGetCultureLanguage(code is null ? "en" : code);
}

/**
    Sets the locale for the application
*/
void incLocaleSet(string code) {
    incSettingsSet("lang", code);
}

/**
    Returns the locale list
*/
TLEntry[] incLocaleGetEntries() {
    return localeFiles;
}