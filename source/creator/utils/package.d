module creator.utils;


/**
    Gets an icon from a Inochi2D Type ID
*/
string incTypeIdToIcon(string typeId) {
    switch(typeId) {
        case "Part": return "\ue40a";
        case "Composite": return "";
        case "Mask": return "\ue14e";
        case "SimplePhysics": return "\ue922";
        default: return "\ue97a"; 
    }
}