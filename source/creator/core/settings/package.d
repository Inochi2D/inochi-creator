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
    __gshared SettingsStore store;
    __gshared AppSettings instance;

    /*
        Destructor
    */
    ~this() {
        store.sync();
    }

    /**
        Constructs the settings manager.
    */
    this() {
        store = __inc_get_settings_store("com.inochi2d.inochi-creator");
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
        AppSettings.instance.store.sync();
    }

    /**
        Sets a setting.
    */
    static void set(T)(string name, T value) {
        AppSettings.instance.store.set!T(name, value);
    }

    /**
        Unsets a setting.
    */
    static bool unset(T)(string name) {
        return AppSettings.instance.store.unset(name);
    }

    /**
        Gets a setting.
    */
    static T get(T)(string name, T defaultValue = T.init) {
        return AppSettings.instance.store.get!T(name, defaultValue);
    }

    /**
        Gets whether the settings store has a setting with the given name.
    */
    static bool has(string name) {
        return AppSettings.instance.store.has(name);
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

private
SettingsStore __inc_get_settings_store(string storeId);

/**
    A settings store, implemented by a store backend.
*/
abstract
class SettingsStore {
private:
    string storeId_;

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
            return JSONValue(data);
        } else static if (isAssociativeArray!T) {
            JSONValue[string] data;
            foreach(key, value; value) {
                data[key.toString()] = this.encode(value[key]);
            }
            return JSONValue(data);
        } else {
            return JSONValue(value);
        }
    }

    /**
        Encodes values recursively.
    */
    T decode(T)(JSONValue from, T defaultValue) {
        import std.traits : isArray, isAssociativeArray, KeyType, ValueType;
        import std.range : ElementType;
        import std.exception : enforce;
        import std.conv : to;
        T retval;

        static if (is(T : string) || is(T : wstring) || is (T : dstring)) {
            return from.str().to!T;
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

protected:
    abstract long getIntImpl(string name, long defaultValue = 0);
    abstract ulong getUIntImpl(string name, ulong defaultValue = 0);
    abstract double getDoubleImpl(string name, double defaultValue = 0);
    abstract string getStringImpl(string name, string defaultValue = null);
    abstract JSONValue getJSONImpl(string name);

    abstract void setIntImpl(string name, long value);
    abstract void setUIntImpl(string name, ulong value);
    abstract void setDoubleImpl(string name, double value);
    abstract void setStringImpl(string name, string value);
    abstract void setJSONImpl(string name, JSONValue value);

public:

    /**
        Constructor
    */
    this(string storeId) {
        this.storeId_ = storeId;
    }

    /**
        ID of the data store in reverse domain notation.
    */
    final
    @property string storeId() => storeId_;

    /**
        Synchronises the settings store with the on-disk
        store.
    */
    abstract void sync();

    /**
        Un-sets a value.
    */
    abstract bool unset(string name);

    /**
        Gets whether the store has a given value.
    */
    abstract bool has(string name);

    /**
        Gets a value from the settings store.
    */
    void set(T)(string name, T value) {
        static if (is(T == string)) {
            this.setStringImpl(name, value);
        } else static if (__traits(isIntegral, T)) {
            static if (__traits(isUnsigned, T))
                this.setUIntImpl(name, cast(ulong)value);
            else
                this.setIntImpl(name, cast(long)value);
        } else static if (__traits(isFloating, T)) {
            this.setDoubleImpl(name, cast(double)value);
        } else {
            this.setJSONImpl(name, encode!T(value));
        }
    }

    /**
        Gets a value from the settings store.
    */
    T get(T)(string name, T defaultValue = T.init) {
        static if (is(T == string)) {
            return this.getStringImpl(name, defaultValue);
        } else static if (__traits(isIntegral, T)) {
            static if (__traits(isUnsigned, T))
                return cast(T)this.getUIntImpl(name, cast(ulong)defaultValue);
            else
                return cast(T)this.getIntImpl(name, cast(long)defaultValue);
        } else static if (__traits(isFloating, T)) {
            return cast(T)this.getDoubleImpl(name, cast(double)defaultValue);
        } else {
            return decode!T(this.getJSONImpl(name), defaultValue);
        }
    }
}