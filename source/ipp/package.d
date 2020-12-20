/**
    Inochi Puppet Project - Project File format for Inochi Creator
*/
module ipp;
import vibe.data.json : serializeToJson, deserializeJson;

class IPP {
public:

    /**
        Name of the project
    */
    string projectName;

    /**
        Author of the project
    */
    string author;

    /**
        The texture files for each part
    */
    string[] textures;
}