/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
/// Extensions to Inochi2D only used in Inochi Creator
module creator.ext;
public import creator.ext.nodes;
public import creator.ext.param;
import inochi2d;

import std.algorithm.searching : countUntil;
import std.algorithm.mutation : remove;

class ExPuppet : Puppet {
private:
protected:
public:
    ExParameterGroup[] groups = [];
    this() { super(); }
    this(Node root) { super(root); }

    /**
        Returns a parameter by UUID
    */
    override
    Parameter findParameter(uint uuid) {
        foreach(ref parameter; parameters) {
            if (parameter.uuid == uuid) return parameter;
        }
        return null;
    }
    

    /**
        Returns a parameter by name
    */
    Parameter findParameter(string name) {
        foreach(ref parameter; parameters) {
            if (parameter.name == name) return parameter;
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
    

    /**
        Removes a parameter from this puppet
    */
    override
    void removeParameter(Parameter param) {

        // First attempt to remove from root
        ptrdiff_t idx = parameters.countUntil(param);
        if (idx >= 0) {
            parameters = parameters.remove(idx);
            if (auto exParam = cast(ExParameter)param)
                exParam.setParent(null);
            return;
        }

        // Next attempt to remove from groups
        foreach(ref parameter; parameters) {
            if (auto group = cast(ExParameterGroup)parameter) {
                idx = group.children.countUntil(param);
                if (idx >= 0) {
                    group.children = group.children.remove(idx);
                    return;
                }
            }
        }
    }

    ExParameterGroup findGroup(uint uuid) {
        foreach (ref group; groups) {
            if (group.uuid == uuid)
                return group;
        }
        return null;
    }

    ExParameterGroup findGroup(string name) {
        foreach (ref group; groups) {
            if (group.name == name)
                return group;
        }
        return null;
    }

    void addGroup(ExParameterGroup group) {
        groups ~= group;
    }

    void removeGroup(ExParameterGroup group) {
        auto index = groups.countUntil(group);
        if (index >= 0) {
            groups = groups.remove(index);
        }
    }

    override
    SerdeException deserializeFromFghj(Fghj data) {
        if (!data["groups"].isEmpty) {
            foreach(key; data["groups"].byElement) {
                auto group = cast(ExParameterGroup)inParameterCreate(key);
                this.groups ~= group;
            }
        }
        super.deserializeFromFghj(data);
        return null;
    }

    override
    void serializeSelf(ref InochiSerializer serializer) {
        super.serializeSelf(serializer);
        serializer.putKey("groups");
        serializer.serializeValue(groups);
    }

    override
    void reconstruct() {
        super.reconstruct();
        foreach(group; groups.dup) {
            group.reconstruct(this);
        }
    }

    override
    void finalize() {
        super.finalize();
        foreach(group; groups) {
            group.finalize(this);
        }
    }

}

void incInitExt() {
    incInitExtNodes();
    incRegisterExParameter();
}
