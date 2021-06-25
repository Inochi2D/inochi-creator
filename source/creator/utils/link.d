module creator.utils.link;
import std.process;

void openLink(string link) {
    version(Windows) {
        spawnShell("start " ~ link);
    } else version(OSX) {
        spawnShell("open " ~ link);
    } else version(Posix) {
        spawnShell("xdg-open " ~ link);
    }
}