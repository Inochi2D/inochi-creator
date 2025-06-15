module creator.core.i18n;
import creator.core;
import i18n.culture;
import i18n.tr : i18nLoadLanguage, i18nClearLanguage, i18nGetLanguageName;
import std.file;
import std.path;
import std.string;
import std.algorithm : sort;
import std.uni : icmp;
import nulib.string;

/+
    HACK: This little comment tricks genpot to generate our LANG_NAME entry.

    // The name of the language this translation is a translation to
    // in the native script of the language (for the region)
    // Eg. this would be "Dansk" for Danish and "日本語" for Japanese.
    _("LANG_NAME")
+/

/**
    A localized string instance.
*/
struct LocalizedString {
    alias text this;

    string key;
    nstring text;
}

/**
    Wraps i18n-d with a LocalizedString
*/
LocalizedString _(string toTranslate) {
    import tr = i18n.tr;
    return LocalizedString(toTranslate, tr._(toTranslate));
}

/**
    Wraps i18n-d with a LocalizedString
*/
LocalizedString __(string toTranslate) {
    import tr = i18n.tr;
    return LocalizedString(toTranslate, tr._(toTranslate));
}

/**
    An entry within the locale store.
*/
struct LocaleEntry {
public:
    nstring humanName;
    string code;
    string file;
    string path;
}

/**
    The locale store.
*/
struct LocaleStore {
private:
    size_t active;
    LocaleEntry[] entries;

    void scan(string path) {
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
            entries ~= TLEntry(
                langName,
                langName.toStringz,
                langcode, 
                entry.name,
                path
            );
        }
    }

    void markDuplicates() {

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
            }

            prevIsDup = entryIsDup;
            prevEntry = &entry;
        }

        if (prevIsDup) {
            prevEntry.humanName ~= " (" ~ prevEntry.path ~ ")";
        }
    }
    
    bool compareEntries(LocaleEntry a, LocaleEntry b) {
        int cmp = icmp(a.humanName, b.humanName);
        if (cmp == 0) {
            return a.path < b.path;
        }
        return cmp < 0;
    }

    LocaleEntry* getEntryFor(string code) {
        foreach(ref entry; entries) {
            if (entry.code == code)
                return &entry;
        }

        return null;
    }

public:

    /**
        The current selected locale human name
    */
    @property string currentLocaleName() {
        return this.getCultureExpression(currentLocale);
    }

    /**
        The currently selected locale
    */
    @property string currentLocale() {
        string code = AppSettings.get("lang", "en");
        return code.length == 0 ? "en" : code;
    }
    
    @property void currentLocale(string code) {
        AppSettings.set("lang", code);
        
        // Builtin EN has no .po file
        if (code.length == 0 || code == "en") {
            i18nClearLanguage();
            return;
        }

        // Other languages do, though.
        i18nLoadLanguage(this.getEntryFor(code).file);
    }

    /**
        List of locales loaded.
    */
    @property LocaleEntry[] locales() {
        return entries[0..$];
    }

    /**
        Gets the culture expression for the given language
        code.
    */
    string getCultureExpression(string langcode) {

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

    /**
        Rescans all of the locales.    
    */
    void rescan() {
        entries.length = 0;

        // These exist for testing + user added localization
        foreach(localePath; AppSettings.localePaths)
            this.scan(localePath);
        this.scan(thisExePath().dirName);

        // For zip folder exports.
        this.scan(buildPath(thisExePath().dirName, "i18n"));
        
        // On macOS we store the locale in the app bundle under the Resources subdirectory.
        version(OSX) this.scan(buildPath(thisExePath().dirName, "../Resources/i18n"));
        
        // sort the files by human readable name
        entries.sort!(compareEntries);
        
        //disambiguate locales with the same human name
        this.markDuplicates();
    }
}