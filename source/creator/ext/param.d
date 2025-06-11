module creator.ext.param;
import inochi2d;
import inochi2d.fmt;
import inmath;
import creator;
import creator.ext;

import std.algorithm.searching;
import std.algorithm.mutation: remove;

class ExParameterGroup : Parameter {
protected:

    override
    void onSerialize(ref JSONValue object) {
        super.onSerialize(object);
        object["groupUUID"] = uuid;
        object["name"] = name;
        object["color"] = color.serialize();
    }

    override
    void onDeserialize(ref JSONValue object) {
        super.onDeserialize(object);
        object.tryGetRef(uuid, "groupUUID");
        object.tryGetRef(name, "name");
        object.tryGetRef(color, "color");
        if ("children" in object) {
            foreach(childData; object.array) {
                auto child = inParameterCreate(childData);
                children ~= child;
            }
        }
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
    void reconstruct(Puppet _puppet) {
        auto puppet = cast(ExPuppet)_puppet;
        if (puppet !is null) {
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
        }
        super.reconstruct(_puppet);
    }

}

class ExParameter : Parameter {
private:
    ExParameterGroup parent;
    uint parentUUID = InInvalidUUID;

protected:
    

    override
    void onSerialize(ref JSONValue object) {
        if (parent) {
            object["parentUUID"] = parent.uuid;
        }
        super.onSerialize(object);
    }

    override
    void onDeserialize(ref JSONValue object) {
        object.tryGetRef(parentUUID, "parentUUID");
        super.onDeserialize(object);
    }
public:
    this() { 
        super(); 
        parent = null; 
    }
    this(string name) { 
        super(name, false); 
        parent = null;
    }
    this(string name, bool isVec2) { 
        super(name, isVec2); 
        parent = null;
    }
    this(string name, ExParameterGroup parent) { 
        super(name, false); 
        this.parent = parent;
    }
    this(string name, bool isVec2, ExParameterGroup parent) { 
        super(name, isVec2); 
        this.parent = parent;
    }

    ExParameterGroup getParent() { return parent; }

    void setParent(ExParameterGroup newParent) {
        if (parent !is null && parent != newParent) {
            auto index = parent.children.countUntil(this);
            if (index >= 0) {
                parent.children = parent.children.remove(index);
            }
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
        import std.stdio;
        if (puppet !is null && parent is null && parentUUID != InInvalidUUID) {
            setParent(puppet.findGroup(parentUUID));
        }
        super.finalize(_puppet);
    }

    /**
        Clone this parameter
    */
    override
    Parameter dup() {
        Parameter newParam = new ExParameter(name ~ " (Copy)", isVec2);

        newParam.min = min;
        newParam.max = max;
        newParam.axisPoints = axisPoints.dup;

        foreach(binding; bindings) {
            ParameterBinding newBinding = newParam.createBinding(
                binding.getNode(),
                binding.getName(),
                false
            );
            newBinding.interpolateMode = binding.interpolateMode;
            foreach(x; 0..axisPointCount(0)) {
                foreach(y; 0..axisPointCount(1)) {
                    binding.copyKeypointToBinding(vec2u(x, y), newBinding, vec2u(x, y));
                }
            }
            newParam.addBinding(newBinding);
        }

        return newParam;
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

