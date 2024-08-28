/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.core.settings;
import std.json;
import std.file;
import std.path : buildPath;
import creator.core.path;

private {
    JSONValue settings = JSONValue(string[string].init);
}

string incSettingsPath() {
    return buildPath(incGetAppConfigPath(), "settings.json");
}

/**
    Load settings from settings file
*/
void incSettingsLoad() {
    if (exists(incSettingsPath())) {
        settings = parseJSON(readText(incSettingsPath()));

        // File Handling
        // Always ask the user whether to preserve the folder structure during import
        // also see incGetKeepLayerFolder()
        settings["KeepLayerFolder"] = "Ask";

        // Default Disable Touchpad, until ensure it works well on most devices
        settings["TouchpadEnabled"] = false;
    }
}

/**
    Saves settings from settings store
*/
void incSettingsSave() {
    // using swp prevent file corruption
    string swapPath = incSettingsPath() ~ ".swp";
    write(swapPath, settings.toString());
    rename(swapPath, incSettingsPath());
}

/**
    Sets a setting
*/
void incSettingsSet(T)(string name, T value) if (!is(T == string[]))  {
    settings[name] = value;
}

/**
    Gets a value from the settings store
*/
T incSettingsGet(T)(string name) if (!is(T == string[])) {
    if (name in settings) {
        return settings[name].get!T;
    }
    return T.init;
}

/**
    Gets a value from the settings store
*/
T incSettingsGet(T)(string name) if (is(T == string[])) {
    if (name in settings) {
        string[] values;
        foreach(value; settings[name].array) {
            values ~= value.get!string;
        }
        return values;
    }
    return T.init;
}

/**
    Sets a setting
*/
void incSettingsSet(T)(string name, T value) if (is(T == string[]))  {
    JSONValue[] data;
    foreach(i; 0..value.length) {
        data ~= JSONValue(value[i]);
    }
    settings[name] = JSONValue(data);
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
