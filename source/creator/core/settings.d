module creator.core.settings;
import std.json;
import std.file;

private {
    JSONValue settings = JSONValue(string[string].init);
}

/**
    Load settings from settings file
*/
void incSettingsLoad() {
    if (exists("settings.json")) {
        settings = parseJSON(readText("settings.json"));
    }
}

/**
    Saves settings from settings store
*/
void incSettingsSave() {
    write("settings.json", settings.toString());
}

/**
    Sets a setting
*/
void incSettingsSet(T)(string name, T value) {
    settings[name] = value;
}

/**
    Gets a value from the settings store
*/
T incSettingsGet(T)(string name) {
    if (name in settings) {
        return settings[name].get!T;
    }
    return T.init;
}

/**
    Gets a value from the settings store, with custom default value
*/
T incSettingsGet(T)(string name, T default_) {
    if (name in settings) {
        return settings[name].get!T;
    }
    return default_;
}

/**
    Gets whether a setting is obtainable
*/
bool incSettingsCanGet(string name) {
    return (name in settings) !is null;
}