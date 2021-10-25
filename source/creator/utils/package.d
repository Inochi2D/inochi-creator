module creator.utils;


/**
    Gets an icon from a Inochi2D Type ID
*/
string incTypeIdToIcon(string typeId) {
    switch(typeId) {
        case "Part": return "\ue40a\0";
        case "Mask": return "\ue14e\0";
        case "PathDeform": return "\ue922\0";
        default: return "\ue97a\0"; 
    }
}