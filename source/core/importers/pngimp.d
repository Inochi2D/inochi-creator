module core.importers.pngimp;
import core.importers;

/**
    Importer for PNG textures
*/
class PNGImporter : Importer {

    /**
        Gets the name of the importer
    */
    string getName() {
        return "PNG";
    }

    /**
        Imports PNGs from a folder
    */
    Project import_(string path) {
        Project p = new Project;

        return p;
    }
}