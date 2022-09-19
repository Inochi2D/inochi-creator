/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
/// Extensions to Inochi2D only used in Inochi Creator
module creator.ext;
public import creator.ext.nodes;
public import creator.ext.param;
import inochi2d;

class ExPuppet : Puppet {
private:

public:
    this() { super(); }
    this(Node root) { super(root); }

    /**
        Returns a parameter by UUID
    */
    override
    Parameter findParameter(uint uuid) {
        foreach(ref parameter; parameters) {
            if (auto group = cast(ExParameterGroup)parameter) {
                foreach(ref child; group.children) {
                    if (child.uuid == uuid) return child;
                }
            } else if (parameter.uuid == uuid) return parameter;
        }
        return null;
    }
    

    /**
        Gets if a node is bound to ANY parameter.
    */
    override
    bool getIsNodeBound(Node n) {
        foreach(ref parameter; parameters) {
            if (auto group = cast(ExParameterGroup)parameter) {
                foreach(ref child; group.children) {
                    if (child.hasAnyBinding(n)) return true;
                }
            } else if (parameter.hasAnyBinding(n)) return true;
        }
        return false;
    }
}

void incInitExt() {
    incInitExtNodes();
    incRegisterExParameter();
}
