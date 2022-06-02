module creator.core.i18n;
import creator.core;
import i18n.culture;
import i18n;
import std.file;
import std.path;
import std.string;

private {
    TLEntry[] localeFiles;

    string incGetCultureExpression(string langcode) {
        if (langcode.length >= 5) {
            return format("%s (%s)", i18nGetCultureLanguage(langcode),
                langcode == "zh-CN" ? "Simplified" : 
                langcode == "zh-TW" ? "Traditional" :
                i18nGetCultureCountry(langcode));
        }
        return i18nGetCultureLanguage(langcode);
    }

    void incLocaleScan(string path) {
        foreach(DirEntry entry; dirEntries(path, "*.mo", SpanMode.shallow)) {
            
            // Get langcode from filename
            string langcode = baseName(stripExtension(entry.name));

            // Skip langcodes we don't know
            if (!i18nValidateCultureCode(langcode)) continue;

            // Add locale
            localeFiles ~= TLEntry(
                incGetCultureExpression(langcode),
                incGetCultureExpression(langcode).toStringz,
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
    string currCode = code.length == 0 ? "en": code;
    return incGetCultureExpression(currCode);
}

/**
    Sets the locale for the application
*/
void incLocaleSet(string code) {
    incSettingsSet("lang", code);
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