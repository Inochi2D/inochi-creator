module creator.io.imageexport;
import creator.core.tasks;
import imagefmt;
import i18n;
import std.format;

/**
    Exports image from RGB(A) color data
*/
void incExportImage(string file, ubyte[] data, int width, int height, int channels = 0) {
    ubyte e = write_image(file, width, height, data, channels);
    if (e == 0) {
        incSetStatus(_("%s was exported...".format(file)));
    } else {
        incSetStatus(_("%s failed to export with error (%s)...".format(file, IF_ERROR[e])));
    }
}