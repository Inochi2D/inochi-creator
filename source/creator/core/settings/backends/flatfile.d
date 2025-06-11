/**
    Flat file settings store.

    Copyright:
        Copyright © 2025, Kitsunebi Games
        Copyright © 2025, Inochi2D Project
    
    License:   $(LINK2 https://opensource.org/license/bsd-2-clause, BSD 2-clause)
    Authors:   Luna Nielsen
*/
module creator.core.settings.backends.flatfile;
import creator.core.settings;
import std.json;
version(linux):

/**
    Creates a new settings store.
*/
SettingsStore __inc_get_settings_store(string storeId) {
    return new FlatFileSettingsStore(storeId);
}

class FlatFileSettingsStore : SettingsStore {
private:
    __gshared JSONValue settingsStore;

    string moveCorruptedFile() {
        import std.datetime;

        // move the corrupted settings file to a new location
        string backupPath = AppSettings.settingsFile ~ "." ~ Clock.currTime().toISOString();
        rename(this.settingsFile, backupPath);
        return backupPath;
    }

    void load() {
        try {
            if (settingsFile.exists()) {
                settingsStore = parseJSON(readText(settingsFile));
            }
        } catch (Exception ex) {
            MessageBox.show(MessageType.error, _("Error"), _(APP_LOAD_ERROR_STRING).format(this.moveCorruptedFile(), ex.msg()));
        }

        // This code is used to configure default values for new users
        // New users use MousePosition, old users keep ScreenCenter

        // File Handling
        // Always ask the user whether to preserve the folder structure during import
        // also see incGetKeepLayerFolder()
        settings["KeepLayerFolder"] = "Ask";
    }

    void save() {

        // using swp prevent file corruption
        string swapPath = AppSettings.settingsFile ~ ".swp";
        write(swapPath, settingsStore.toString());
        rename(swapPath, AppSettings.settingsFile);
    }

protected:

    override
    long getIntImpl(string name, long defaultValue = 0) {
        if (name !in settingsStore)
            return defaultValue;
        
        if (settingsStore[name].type != JSONType.integer)
            return defaultValue;
        
        return settingsStore[name].integer();
    }
    
    override
    ulong getUIntImpl(string name, ulong defaultValue = 0) {
        if (name !in settingsStore)
            return defaultValue;
        
        if (settingsStore[name].type != JSONType.integer)
            return defaultValue;
        
        long v = settingsStore[name].integer();
        return *(cast(ulong*)&v);
    }
    
    override
    double getDoubleImpl(string name, double defaultValue = 0) {
        if (name !in settingsStore)
            return defaultValue;
        
        if (settingsStore[name].type != JSONType.float_)
            return defaultValue;
        
        return settingsStore[name].floating();
    }
    
    override
    string getStringImpl(string name, string defaultValue = null) {
        if (name !in settingsStore)
            return defaultValue;
        
        if (settingsStore[name].type != JSONType.string)
            return defaultValue;
        
        return settingsStore[name].str();
    }
    
    override
    JSONValue getJSONImpl(string name) {
        if (name !in settingsStore)
            return defaultValue;
        
        return settingsStore[name];
    }

    
    override
    void setIntImpl(string name, long value)  {
        settingsStore[name] = value;
    }
    
    override
    void setUIntImpl(string name, ulong value)  {
        settingsStore[name] = value;
    }
    
    override
    void setDoubleImpl(string name, double value)  {
        settingsStore[name] = value;
    }
    
    override
    void setStringImpl(string name, string value)  {
        settingsStore[name] = value;
    }
    
    override
    void setJSONImpl(string name, JSONValue value)  {
        settingsStore[name] = value;
    }

public:

    /**
        Constructor
    */
    this(string storeId) {
        super(storeId);
        this.load();
    }

    /**
        Synchronises the settings store with the on-disk
        store.
    */
    override
    void sync() {
        this.save();
        this.load();
    }

    /**
        Un-sets a value.
    */
    override
    bool unset(string name) {
        settingsStore[name] = null;
    }

    /**
        Gets whether the store has a given value.
    */
    override
    bool has(string name) {
        return name in settingsStore;
    }
}