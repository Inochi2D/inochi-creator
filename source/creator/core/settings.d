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
import i18n;

private {
    JSONValue settings = JSONValue(string[string].init);
}

string incSettingsPath() {
    return buildPath(incGetAppConfigPath(), "settings.json");
}

string incSettingsMoveCorruptedFile(string path) {
    import std.datetime;
    // move the corrupted settings file to a new location
    string backupPath = path ~ "." ~ Clock.currTime().toISOString();
    rename(path, backupPath);
    return backupPath;
}

void incSettingsErrorDialog(Exception ex, string backupPath) {
    import creator.widgets.dialog;
    string error = _("Oops! Your settings.json file is corrupted. inochi2d creator will load the default settings.\n");
    error ~= _("The corrupted settings file has been moved to ") ~ backupPath ~ ".\n";
    error ~= _("If you always see this message, please report this issue to inochi2d creator\n");
    error ~= _("\nError message: ") ~ ex.msg;
    incDialog(__("Error"), error);
}

/**
    Load settings from settings file
*/
void incSettingsLoad() {
    if (exists(incSettingsPath())) {
        try {
            settings = parseJSON(readText(incSettingsPath()));

            // check settings is not empty
            if (settings.object.length == 0)
                throw new JSONException("Settings file is empty");
            return;
        } catch (JSONException ex) {
            string backupPath = incSettingsMoveCorruptedFile(incSettingsPath());
            incSettingsErrorDialog(ex, backupPath);
        }
    }

    // This code is used to configure default values for new users
    // New users use MousePosition, old users keep ScreenCenter

    // File Handling
    // Always ask the user whether to preserve the folder structure during import
    // also see incGetKeepLayerFolder()
    settings["KeepLayerFolder"] = "Ask";
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
    Removes a setting
*/
void incSettingsRemove(string name) {
    settings.object.remove(name);
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
