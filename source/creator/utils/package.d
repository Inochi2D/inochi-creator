module creator.utils;


/**
    Gets an icon from a Inochi2D Type ID
*/
string incTypeIdToIcon(string typeId) {
    switch(typeId) {
        case "Part": return "\ue40a";
        case "Composite": return "";
        case "Mask": return "\ue14e";
        case "SimplePhysics": return "";
        case "Camera": return "";
        case "MeshGroup": return "";
        case "DynamicComposite": return "";
        case "Parameter": return "";
        case "Binding": return "";
        default: return "\ue97a"; 
    }
}