module creator.core.settings;
import std.json;
import std.file;
import creator.core.ui.msgbox;

public import creator.core.settings.cfg;

enum APP_LOAD_ERROR_STRING = "Oops! Your settings.json file is corrupted. Inochi Creator will load the default settings.
The corrupted settings file has been moved to '%s'.

If you see this message repeatedly, please report it on the issue tracker.
Error Message: %s";

/**
    Application settings manager.
*/
class AppSettings {
private:
    __gshared JSONValue settingsStore;

    /**
        Encodes values recursively.
    */
    JSONValue encode(T)(T value) {
        import std.traits : isArray, isAssociativeArray;

        static if (isArray!T) {
            JSONValue[] data;
            foreach(i; 0..value.length) {
                data ~= this.encode(value[i]);
            }
            src = data;
        } else static if (isAssociativeArray!T) {
            JSONValue[string] data;
            foreach(key, value; value) {
                data[key.toString()] = this.encode(value[key]);
            }
        } else {
            return JSONValue(value);
        }
    }

    /**
        Encodes values recursively.
    */
    JSONValue decode(T)(JSONValue from, T defaultValue) {
        import std.traits : isArray, isAssociativeArray, KeyType, ValueType;
        import std.range : ElementType;
        import std.exception : enforce;
        import std.conv : to;
        T retval;

        static if (is(T : string) || is(T : wstring) || is (T : dstring)) {
            return from.str.to!T;
        } else static if (isArray!T) {
            if (!from.array)
                return defaultValue;

            alias ET = ElementType!T;
            
            retval.length = from.array.length;
            foreach(i, ref JSONValue element; retval) {
                retval = this.decode!ET(element, ET.init);
            }
        } else static if (isAssociativeArray!T) {
            if (!from.object)
                return defaultValue;
            
            alias KT = KeyType!T;
            alias VT = ValueType!T;
            foreach(key, value; from.object) {
                try {
                    retval[key.to!KT] = this.decode!VT(value, VT.init);
                } catch(Exception ex) {
                    // Ignore.
                }
            }
        } else {
            return from.get!T();
        }

        return retval;
    }

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

    __gshared AppSettings instance;

    /*
        Destructor
    */
    ~this() {
        this.save();
    }

    /**
        Constructs the settings manager.
    */
    this() {
        if (!AppSettings.instance) {

            this.load();
            AppSettings.instance = this;
        }
    }

public:
    
    /**
        The path where app configuration is stored.
    */
    static @property string appConfigPath() { return uiGetAppConfigPath(); }
    
    /**
        The path which custom fonts are read from.
    */
    static @property string fontsPath() { return uiGetAppFontsPath(); }
    
    /**
        The paths which locales are read from.
    */
    static @property string[] localePaths() { return [uiGetAppLocalePath(), uiGetAppLocalePathExtra()]; }

    /**
        The path of the settings file.
    */
    static @property string settingsFile() { return buildPath(incGetAppConfigPath(), "settings.json"); }
    
    /**
        The path of the imgui config file.
    */
    static @property string imguiConfigFile() { return uiGetAppImguiConfigFile(); }

    /**
        Saves the app settings.
    */
    static void save() {

        // using swp prevent file corruption
        string swapPath = AppSettings.settingsFile ~ ".swp";
        write(swapPath, settingsStore.toString());
        rename(swapPath, AppSettings.settingsFile);
    }

    /**
        Sets a setting.
    */
    static void set(T)(string name, T value) {
        AppSettings.instance.settingsStore[name] = this.encode(value);
    }

    /**
        Unsets a setting.
    */
    static void unset(T)(string name) {
        if (name in AppSettings.instance.settingsStore) {
            AppSettings.instance.settingsStore.object.remove(name);
        }
    }

    /**
        Gets a setting.
    */
    static T get(T)(string name, T defaultValue = T.init) {
        return AppSettings.instance.decode!T(settingsStore[name], defaultValue);
    }

    /**
        Gets whether the settings store has a setting with the given name.
    */
    static bool has(string name) {
        return (name in AppSettings.instance.settingsStore) !is null;
    }
}

// Intializes the app settings.
shared static this() {
    new AppSettings();
}

// Saves the app settings.
shared static ~this() {
    destroy(AppSettings.instance);
}