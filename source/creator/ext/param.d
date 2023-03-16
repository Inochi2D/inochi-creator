module creator.ext.param;
import inochi2d;
import inochi2d.fmt;
import inmath;
import creator;
import creator.ext;

import std.algorithm.searching;
import std.algorithm.mutation;

class ExParameterGroup : Parameter {
protected:
    override
    void serializeSelf(ref InochiSerializer serializer) {
        serializer.putKey("groupUUID");
        serializer.putValue(uuid);
        serializer.putKey("name");
        serializer.putValue(name);
        serializer.putKey("color");
        serializer.serializeValue(color.vector);
    }

public:
    vec3 color = vec3(0.15, 0.15, 0.15);
    Parameter[] children;

    this() { super(); }
    this(string name) { super(name, false); }
    this(string name, Parameter[] children) { 
        super(name, false); 
        this.children = children;    
    }

    override
    FghjException deserializeFromFghj(Fghj data) {
        data["groupUUID"].deserializeValue(this.uuid);
        if (!data["name"].isEmpty) data["name"].deserializeValue(this.name);
        if (!data["color"].isEmpty) data["color"].deserializeValue(this.color.vector);
        if (!data["children"].isEmpty)
            foreach (childData; data["children"].byElement) {
                auto child = inParameterCreate(childData);
                children ~= child;
            }
        return null;
    }

    override
    void restructure(Puppet _puppet) {
        auto puppet = cast(ExPuppet)_puppet;
        assert(puppet !is null);
        foreach (child; children) {
            if (auto exparam = cast(ExParameter)child) {
                exparam.parent = this;
                exparam.parentUUID = uuid;
            }
            if (puppet.findParameter(name) is null)
                puppet.parameters ~= child;
        }
        auto test = puppet.findParameter(uuid);
        if (test !is null) {
            puppet.removeParameter(this);
            puppet.addGroup(this);
        }
        super.restructure(_puppet);
    }

}

class ExParameter : Parameter {
    ExParameterGroup parent;
    uint parentUUID = InInvalidUUID;
public:
    this() { 
        super(); 
        parent = null; 
    }
    this(string name) { 
        super(name, false); 
        parent = null;
    }
    this(string name, ExParameterGroup parent) { 
        super(name, false); 
        this.parent = parent;
    }
    override
    FghjException deserializeFromFghj(Fghj data) {
        if (!data["parentUUID"].isEmpty)
            data["parentUUID"].deserializeValue(this.parentUUID);
        return super.deserializeFromFghj(data);
    }

    override
    void serializeSelf(ref InochiSerializer serializer) {
        if (parent !is null) {
            serializer.putKey("parentUUID");
            serializer.putValue(parent.uuid);
        }
        super.serializeSelf(serializer);
    }

    ExParameterGroup getParent() { return parent; }

    void setParent(ExParameterGroup newParent) {
        if (parent !is null && parent != newParent) {
            auto index = parent.children.countUntil(this);
            if (index > 0)
                parent.children = parent.children.remove(index);
        }
        auto oldParent = parent;
        parent = newParent;
        if (parent !is null) {
            parentUUID = parent.uuid;
            if (oldParent != parent)
                parent.children ~= this;
        } else {
            parentUUID = InInvalidUUID;
        }
    }

    override
    void finalize(Puppet _puppet) {
        auto puppet = cast(ExPuppet)_puppet;
        assert(puppet !is null);
        import std.stdio;
        if (parent is null && parentUUID != InInvalidUUID) {
            setParent(puppet.findGroup(parentUUID));
        }
        super.finalize(puppet);
    }
}

void incRegisterExParameter() {
    inParameterSetFactory((Fghj data) {
        if (!data["groupUUID"].isEmpty) {
            ExParameterGroup group = new ExParameterGroup;
            data.deserializeValue(group);
            return group;
        }

        Parameter param = new ExParameter;
        data.deserializeValue(param);
        return param;
    });
}

