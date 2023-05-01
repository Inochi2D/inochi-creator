/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors:
        PanzerKern
        Luna Nielsen
*/
module creator.io.autosave;

import creator.windows.autosave;
import creator.core;
import creator;
import i18n;
import inmath : clamp;

import std.file;
import std.path;
import std.datetime;
import std.datetime.stopwatch : benchmark, StopWatch;
import std.conv;

private {
    StopWatch autosaveTimer;
    enum InProjectLockfile = "creator-project.lock";
}

public void startAutosaveTimer() {
    autosaveTimer.start();
}

/**
    The time in minutes between autosaves.
*/
int incGetAutosaveInterval() {
    int interval = incSettingsGet!int("AutosaveInterval", 5);
    return interval;
}

void incSetAutosaveInterval(int interval) {
    // Limit the setting to 24 hours.
    interval = clamp(interval, 1, 1440);
    incSettingsSet("AutosaveInterval", interval);
}

int incGetAutosaveFileLimit() {
    int fileLimit = incSettingsGet!int("AutosaveFileLimit", 3);
    return fileLimit;
}

void incSetAutosaveFileLimit(int fileLimit) {
    // Limit the setting to 1000 files.
    fileLimit = clamp(fileLimit, 1, 1000);
    incSettingsSet("AutosaveFileLimit", fileLimit);
}

bool incGetAutosaveEnabled() {
    bool enabled = incSettingsGet!bool("AutosaveEnabled", true);
    return enabled;
}

void incSetAutosaveEnabled(bool enabled) {
    incSettingsSet("AutosaveEnabled", enabled);
}

struct AutosaveRecord {
    string autosavePath;
    string mainsavePath;
}

AutosaveRecord[] incGetPrevAutosaves() {
    AutosaveRecord[] saveRecords;
    string[] autosavePaths = incSettingsGet!(string[])("prev_autosaves");
    string[] mainsavePaths = incSettingsGet!(string[])("prev_autosave_mainpaths");
    foreach (i, autosavePath; autosavePaths) {
        string mainsavePath = "";
        if (i < mainsavePaths.length) {
            mainsavePath = mainsavePaths[i];
        }
        saveRecords ~= AutosaveRecord(autosavePath, mainsavePath);
    }
    return saveRecords;
}

void incAddPrevAutosave(string autosavePath) {
    import std.algorithm.searching : countUntil;
    import std.algorithm.mutation : remove;
    AutosaveRecord[] saveRecords = incGetPrevAutosaves();

    ptrdiff_t idx = saveRecords.countUntil!"a.autosavePath == b"(autosavePath);
    if (idx >= 0) {
        saveRecords = saveRecords.remove(idx);
    }

    // Put project to the start of the "previous" list and
    // limit to 10 elements
    saveRecords = AutosaveRecord(autosavePath, incProjectPath()) ~ saveRecords;
    if(saveRecords.length > 10) saveRecords.length = 10;

    // Then save.
    string[] autosavePaths;
    string[] mainsavePaths;
    foreach (saveRecord; saveRecords) {
        autosavePaths ~= saveRecord.autosavePath;
        mainsavePaths ~= saveRecord.mainsavePath;
    }
    incSettingsSet("prev_autosaves", autosavePaths);
    incSettingsSet("prev_autosave_mainpaths", mainsavePaths);
    incSettingsSave();
}

/**
    Autosave the project if enough time has passed since last autosave.
*/
void incCheckAutosave() {
    if (incProjectPath.length == 0) {
        // Do nothing, there's nothing to autosave.
        return;
    }

    if (false == incGetAutosaveEnabled()) {
        // User has disabled autosaving.
        return;
    }
    
    long interval = incGetAutosaveInterval();
    long elapsedMinutes = autosaveTimer.peek().total!"minutes";
    if (elapsedMinutes >= interval) {
        incAutosaveProject(incProjectPath);
        autosaveTimer.reset();
    }
}

/**
    Save the project as a rolling backup.
    Doesn't overwrite the main save file.
*/
void incAutosaveProject(string path) {
    string lockpath = path;

    // We'll add the extension back later when we need it.
    path = path.stripExtension;

    string pathBaseName = path.baseName;

    string backupDir = getAutosaveDir(path);
    mkdirRecurse(backupDir);
    path = buildPath(backupDir, pathBaseName);

    auto entries = currentBackups(backupDir);
    int fileLimit = incGetAutosaveFileLimit();
    while (entries.length >= fileLimit) {
        std.file.remove(entries[0]);
        entries = currentBackups(backupDir);
    }

    // Prune autosave list
    incPruneAutosaveList();

    // Leave off the .inx extension because it's added by incSaveProject.
    incSaveProject(path, bakStampString());
    incCreateLockfile(lockpath);
}

void incPruneAutosaveList() {
    AutosaveRecord[] saveRecords = incGetPrevAutosaves();
    AutosaveRecord[] newRecords;
    
    import std.algorithm.mutation : remove;

    // Remove save records for invalid indices
    foreach(i; 0..saveRecords.length) {
        if (saveRecords[i].autosavePath.exists()) newRecords ~= saveRecords[i];
    }

    // Then save.
    string[] autosavePaths;
    string[] mainsavePaths;
    foreach (saveRecord; newRecords) {
        autosavePaths ~= saveRecord.autosavePath;
        mainsavePaths ~= saveRecord.mainsavePath;
    }

    incSettingsSet("prev_autosaves", autosavePaths);
    incSettingsSet("prev_autosave_mainpaths", mainsavePaths);
    incSettingsSave();
}

/**
    Create a backup save path string.
*/
string bakStampString() {
    string bakName = Clock.currTime.toUnixTime.text();
    return bakName;
}

/**
    Finds the appropriate directory for storing autosaves that corresponds
    to the given project.
*/
string getAutosaveDir(string projectPath) {
    string pathBaseName = projectPath.baseName;
    string autosaveDir = buildPath(incGetAppConfigPath(), "autosaves", pathBaseName);
    return autosaveDir;
}

auto currentBackups(string projectAutosaveDir) {
    import std.algorithm;
    import std.array;
    auto entries = dirEntries(projectAutosaveDir, "*.inx", SpanMode.shallow)
        .filter!(a => a.isFile)
        .array;
    return entries;
}

/**
    Create the project session's lockfile.
    Does nothing if there already is one for the project.
    This should be called after we have created a backup file which can be
    used to recover from a crash.
*/
void incCreateLockfile(string projectPath) {
    projectPath = projectPath.stripExtension;
    string lockfileDir = getAutosaveDir(projectPath);
    string lockfile = buildPath(lockfileDir, InProjectLockfile);
    mkdirRecurse(lockfileDir);
    write(lockfile, "");
}

/**
    Remove the project session's lockfile, if there is one.
    This should be called during normal app/project close procedure,
    and when manually saving (it will return on next autosave).
*/
void incReleaseLockfile() {
    string projectPath = incProjectPath.stripExtension;
    if (projectPath.length == 0) return;
    string lockfileDir = getAutosaveDir(projectPath);
    string lockfile = buildPath(lockfileDir, InProjectLockfile);
    if (lockfile.exists) {
        lockfile.remove;
    }

    // If the lockfile doesn't exist, it was probably too soon to create anyway.
}

/**
    Check to see if a project session's lockfile exists.
    The presence of this lockfile indicates an autosave may be more recent
    than the main save file.
*/
bool incCheckLockfile(string projectPath) {
    projectPath = projectPath.stripExtension;
    string lockfileDir = getAutosaveDir(projectPath);
    string lockfile = buildPath(lockfileDir, InProjectLockfile);
    return lockfile.exists;
}
