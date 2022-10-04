module creator.ext.param;
import inochi2d;
import inochi2d.fmt;
import inmath;
import creator;

class ExParameterGroup : Parameter {
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
    void update() {
        // This only gets called as the initiap part of the update step, and it should
        // skip driven parameters, which are updated later.
        auto enableDrivers = incActivePuppet().enableDrivers;
        auto parameterDrivers = incActivePuppet().getParameterDrivers();
        foreach(ref child; children) {
            if (!enableDrivers || child !in parameterDrivers)
                child.update();
        }
    }

    override
    FghjException deserializeFromFghj(Fghj data) {
        data["groupUUID"].deserializeValue(this.uuid);
        if (!data["name"].isEmpty) data["name"].deserializeValue(this.name);
        if (!data["color"].isEmpty) data["color"].deserializeValue(this.color.vector);
        if (!data["children"].isEmpty) data["children"].deserializeValue(this.children);
        return null;
    }

    override
    void serialize(ref InochiSerializer serializer) {
        auto state = serializer.objectBegin;
            serializer.putKey("groupUUID");
            serializer.putValue(uuid);
            serializer.putKey("name");
            serializer.putValue(name);
            serializer.putKey("color");
            serializer.serializeValue(color.vector);
            serializer.putKey("children");
            serializer.serializeValue(children);
        serializer.objectEnd(state);
    }

    override
    void finalize(Puppet puppet) {
        foreach(child; children) {
            child.finalize(puppet);
        }
    }
}

void incRegisterExParameter() {
    inParameterSetFactory((Fghj data) {
        if (!data["groupUUID"].isEmpty) {
            ExParameterGroup group = new ExParameterGroup;
            data.deserializeValue(group);
            return group;
        }

        Parameter param = new Parameter;
        data.deserializeValue(param);
        return param;
    });
}