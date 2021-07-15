/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.i18n;

// module i18n;
// import std.exception;

// // Translation ID
// private struct transidx {
//     string file;
//     int line;
// }

// // The language file serialization construct
// private struct LangFile {
//     string name;
//     string[string] table;
// }

// // List of languages
// private string[string] langList;

// // The translation table
// __gshared private string[transidx] transtable;

// private void genLangList() {
//     import std.path;
//     import std.file : dirEntries, SpanMode, isDir, exists, mkdir, DirEntry, readText;
//     import asdf : deserialize;

//     // Create an empty language directory if none exists already.
//     if (!exists("lang/")) mkdir("lang/");

//     // Go through every language and add them to the list
//     foreach(DirEntry trFile; dirEntries(buildPath("lang"), SpanMode.shallow, true)) {
        
//         // Skip any stray directories
//         if (trFile.isDir) continue;

//         Json jsonObject = parseJsonString(readText(trFile.name));
//         string langName = jsonObject["name"].get!string;

//         langList[langName] = trFile;
//     }
// }

// /**
//     Gets a list of the languages currently available
// */
// string[] getLanguages() {
//     string[] langs;
//     foreach(name, _; langList) {
//         langs ~= name;
//     }
//     return langs;
// }

// /**
//     Sets the current language
// */
// void language(string language) {
//     import vibe.data.json : deserializeJson;
//     import std.file : readText, exists;
//     import std.path : buildPath, setExtension;
//     import std.string : split;
//     import std.conv : to;

//     enforce(language in langList, "Language not found");

//     // Read and parse the json
//     string json = langList[language].readText();
//     LangFile table = deserializeJson!LangFile(json);
    
//     // Iterate over all the keys and build the LangFile object from it
//     foreach(idx, str; table.table) {
//         string[] components = idx.split(":");

//         // There has to be 2 components seperated by :
//         enforce(components.length == 2, "Invalid translation index \""~idx~"\"");

//         // Set the translation for the translation index parsed from the components
//         // NOTE: File is component 0, Line is component 1
//         transtable[transidx(components[0], components[1].to!int)] = str;
//     }

//     import std.stdio : writefln;
//     debug writefln("Loaded language %s...", table.name);
// }

// /**
//     Returns a translated string, defaults to the given text if no translation was found
// */
// string _(string file=__FILE__, int line = __LINE__)(string text) {

//     // No translation was loaded
//     if (transtable.length == 0) return text;

//     transidx idx = transidx(file, line);

//     // Line was not found in translation
//     if (idx !in transtable) return text;

//     // Line was found, get translation
//     return transtable[idx];
// }

// shared static this() {
//     genLangList();
//     language("English");
// }