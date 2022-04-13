module creator.utils;


/**
    Gets an icon from a Inochi2D Type ID
*/
string incTypeIdToIcon(string typeId) {
    switch(typeId) {
        case "Part": return "\ue40a\0";
        case "Composite": return "\0";
        case "Mask": return "\ue14e\0";
        case "SimplePhysics": return "\ue922\0";
        default: return "\ue97a\0"; 
    }
}

/**
    Gets an icon from a Inochi2D Type ID
*/
string incTypeIdToIconConcat(string typeId) {
    switch(typeId) {
        case "Part": return "\ue40a";
        case "Composite": return "";
        case "Mask": return "\ue14e";
        case "SimplePhysics": return "\ue922";
        default: return "\ue97a";
    }
}