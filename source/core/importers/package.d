module core.importers;
public import core.project;

/**
    An importer
*/
interface Importer {

    /**
        Gets the name of the importer
    */
    string getName();

    /**
        The importer function
    */
    Project import_(string path);
}