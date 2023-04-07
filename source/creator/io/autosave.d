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
    immutable string projectLockfile = "creator-project.lock";
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

string[] incGetPrevAutosaves() {
    return incSettingsGet!(string[])("prev_autosaves");
}

void incAddPrevAutosave(string path) {
    import std.algorithm.searching : countUntil;
    import std.algorithm.mutation : remove;
    string[] autosaves = incGetPrevAutosaves();

    ptrdiff_t idx = autosaves.countUntil(path);
    if (idx >= 0) {
        autosaves = autosaves.remove(idx);
    }

    // Put project to the start of the "previous" list and
    // limit to 10 elements
    autosaves = path.dup ~ autosaves;
    //(currProjectPath)
    if(autosaves.length > 10) autosaves.length = 10;

    // Then save.
    incSettingsSet("prev_autosaves", autosaves);
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

    // Leave off the .inx extension because it's added by incSaveProject.
    incSaveProject(path, bakStampString());
    incCreateLockfile(path);
}

/**
    Create a backup save path string.
*/
string bakStampString() {
    string bakName = Clock.currTime.toISOExtString();
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
    string lockfile = buildPath(lockfileDir, projectLockfile);
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
    string lockfile = buildPath(lockfileDir, projectLockfile);
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
    string lockfile = buildPath(lockfileDir, projectLockfile);
    return lockfile.exists;
}
