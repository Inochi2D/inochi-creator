module creator.core.path;
import std.path;
import std.process;
import std.file : getcwd, mkdirRecurse, exists;

private {
    string cachedConfigDir;
    string cachedImguiFileDir;
    string cachedFontDir;
    string cachedLocaleDir;
    string inForcedConfigDir;
}

/**
    The name of the folder inochi creator config gets thrown in to.
*/
enum APP_FOLDER_NAME = "inochi-creator";

/**
    Name of environment variable to force a configuration path
*/
enum ENV_CONFIG_PATH = "INOCHI_CONFIG_PATH";

/**
    Returns the app configuration directory for the platform
*/
string incGetAppConfigPath() {
    if (cachedConfigDir) return cachedConfigDir;
    if (inForcedConfigDir) return inForcedConfigDir;
    string appDataDir;

    // Once this function has completed cache the result.
    scope(success) {
        
        if (inForcedConfigDir) {
            
            // Also make sure the folder exists
            if (!exists(inForcedConfigDir)) {
                mkdirRecurse(inForcedConfigDir);
            }
        } else {
            cachedConfigDir = appDataDir;

            // Also make sure the folder exists
            if (!exists(cachedConfigDir)) {
                mkdirRecurse(cachedConfigDir);
            }
        }
    }

    // On Windows %AppData% is used.
    // Example: C:/Users/USERNAME/AppData/Roaming/.inochi-creatorS
    version(Windows) {
        appDataDir = environment.get("AppData");
    }

    // On Linux the app data dir is in $XDG_CONFIG_DIR, $HOME/.config or $HOME
    // Example: /home/USERNAME/.inochi-creator
    else version(linux) {
        appDataDir = environment.get("XDG_CONFIG_HOME");
        if (!appDataDir) appDataDir = buildPath(environment.get("HOME"), ".config");
    }

    // On macOS things are thrown in to $HOME/Library/Application Support
    // Example: /home/USERNAME/Library/Application Support/.inochi-creator
    else version(OSX) {
        appDataDir = environment.get("HOME");
        if (appDataDir) appDataDir = buildPath(appDataDir, "Library", "Application Support");
    }

    // On other POSIX platforms just assume $HOME exists.
    // Example: /home/USERNAME/.inochi-creator
    else version(posix) {
        appDataDir = environment.get("HOME");
    }

    // Allow packagers, etc. to specify a forced config directory.
    inForcedConfigDir = environment.get(ENV_CONFIG_PATH);
    if (inForcedConfigDir) return inForcedConfigDir;
    

    if (!appDataDir) appDataDir = getcwd();

    version(linux) {

        // On linux we're using standard XDG dirs, prior we
        // used .inochi-creator there, but that's not correct
        // This code will ensure we still use old config if it's there.
        // Otherwise we create config for the *correct* path
        string fdir = buildPath(appDataDir, "."~APP_FOLDER_NAME);
        if (!exists(fdir)) fdir = buildPath(appDataDir, APP_FOLDER_NAME);
        appDataDir = fdir;
        return appDataDir;
    } else {

        // On other platforms we go for .(app name)
        appDataDir = buildPath(appDataDir, "."~APP_FOLDER_NAME);
        return appDataDir;
    }
}

/**
    Gets the directory for an imgui config file.
*/
string incGetAppImguiConfigFile() {
    if (cachedImguiFileDir) return cachedImguiFileDir;
    cachedImguiFileDir = buildPath(incGetAppConfigPath(), "imgui.ini");
    return cachedImguiFileDir;
}

/**
    Gets directory for custom fonts
*/
string incGetAppFontsPath() {
    if (cachedFontDir) return cachedFontDir;
    cachedFontDir = buildPath(incGetAppConfigPath(), "fonts");
    if (!exists(cachedFontDir)) {
        
        // Create our font directory
        mkdirRecurse(cachedFontDir);

        // Create our font dir and install our fonts
        import std.file : write;

        write(buildPath(cachedFontDir, "OpenDyslexic.otf"), import("OpenDyslexic.otf"));
        // TODO: Write a license file for OpenDyslexic?
    }
    return cachedFontDir;
}

/**
    Gets directory for custom fonts
*/
string incGetAppLocalePath() {
    if (cachedLocaleDir) return cachedLocaleDir;
    cachedLocaleDir = buildPath(incGetAppConfigPath(), "i18n");
    if (!exists(cachedLocaleDir)) {
        
        // Create our font directory
        mkdirRecurse(cachedLocaleDir);
    }
    return cachedLocaleDir;
}