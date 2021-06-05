module creator.utils.link;
import std.process;

void openLink(string link) {
    version(Windows) {
        spawnShell("start "~link);
    }
    version(OSX) {
        spawnShell("open "~link);
    }
    version(Posix) {
        spawnShell("xdf-open "~link);
    }
}