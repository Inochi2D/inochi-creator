module creator.io.imageexport;
import imagefmt;

/**
    Exports image from RGB(A) color data
*/
void incExportImage(string file, ubyte[] data, int width, int height, int channels = 0) {
    write_image(file, width, height, data, channels);
}