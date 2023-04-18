/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.tracking;
import creator.tracking.expr;
import inochi2d;
import inochi2d.math.serialization;
import fghj;
import i18n;
import std.format;
import std.math.rounding : quantize;
import std.math : isFinite;

/**
    Binding Type
*/
enum BindingType {
    /**
        A binding where the base source is blended via
        in/out ratios
    */
    RatioBinding,

    /**
        A binding in which math expressions are used to
        blend between the sources in the VirtualSpace zone.
    */
    ExpressionBinding,

    /**
        Binding controlled from an external source.
        Eg. over the internet or from a plugin.
    */
    External
}

/**
    Source type
*/
enum SourceType {
    /**
        The source is a blendshape
    */
    Blendshape,

    /**
        Source is the X position of a bone
    */
    BonePosX,

    /**
        Source is the Y position of a bone
    */
    BonePosY,

    /**
        Source is the Y position of a bone
    */
    BonePosZ,

    /**
        Source is the roll of a bone
    */
    BoneRotRoll,

    /**
        Source is the pitch of a bone
    */
    BoneRotPitch,

    /**
        Source is the yaw of a bone
    */
    BoneRotYaw,
}

/**
    Tracking Binding 
*/
class TrackingBinding {
private:
    // UUID of param to map to
    uint paramUUID;

    // Sum of weighted plugin values
    float sum = 0;

    // Combined value of weights
    float weights = 0;

public:
    /**
        Display name for the binding
    */
    string name;

    /**
        Name of the source blendshape or bone
    */
    string sourceName;

    /**
        Display Name of the source blendshape or bone
    */
    string sourceDisplayName;

    /**
        The type of the binding
    */
    BindingType type;

    /**
        The type of the tracking source
    */
    SourceType sourceType;

    /**
        The Inochi2D parameter it should apply to
    */
    Parameter param;

    /**
        Expression (if in ExpressionBinding mode)
    */
    Expression* expr;

    /// Ratio for input
    vec2 inRange = vec2(0, 1);

    /// Ratio for output
    vec2 outRange = vec2(0, 1);

    /// Last input value
    float inVal = 0;

    /// Last output value
    float outVal = 0;

    /**
        Weights the user has set for each plugin
    */
    float[string] pluginWeights;

    /**
        The axis to apply the binding to
    */
    int axis = 0;

    /**
        Dampening level
    */
    int dampenLevel = 0;

    /**
        Whether to inverse the binding
    */
    bool inverse;

    void serialize(S)(ref S serializer) {
        auto state = serializer.objectBegin;
            serializer.putKey("name");
            serializer.putValue(name);
            serializer.putKey("sourceName");
            serializer.putValue(sourceName);
            serializer.putKey("sourceDisplayName");
            serializer.putValue(sourceDisplayName);
            serializer.putKey("sourceType");
            serializer.serializeValue(sourceType);
            serializer.putKey("bindingType");
            serializer.serializeValue(type);
            serializer.putKey("param");
            serializer.serializeValue(param.uuid);
            serializer.putKey("axis");
            serializer.putValue(axis);
            serializer.putKey("dampenLevel");
            serializer.putValue(dampenLevel);

            switch(type) {
                case BindingType.RatioBinding:
                    serializer.putKey("inverse");
                    serializer.putValue(inverse);

                    serializer.putKey("inRange");
                    inRange.serialize(serializer);
                    serializer.putKey("outRange");
                    outRange.serialize(serializer);
                    break;
                case BindingType.ExpressionBinding:
                    serializer.putKey("expression");
                    serializer.putValue(expr.expression());
                    break;
                default: break;
            }

        serializer.objectEnd(state);
    }
    
    SerdeException deserializeFromFghj(Fghj data) {
        data["name"].deserializeValue(name);
        data["sourceName"].deserializeValue(sourceName);
        data["sourceType"].deserializeValue(sourceType);
        data["bindingType"].deserializeValue(type);
        data["param"].deserializeValue(paramUUID);
        if (!data["axis"].isEmpty) data["axis"].deserializeValue(axis);
        if (!data["dampenLevel"].isEmpty) data["dampenLevel"].deserializeValue(dampenLevel);

        switch(type) {
            case BindingType.RatioBinding:
                data["inverse"].deserializeValue(inverse);
                inRange.deserialize(data["inRange"]);
                outRange.deserialize(data["outRange"]);
                break;
            case BindingType.ExpressionBinding:
                string exprStr;
                data["expression"].deserializeValue(exprStr);
                expr = new Expression(cast(int)this.hashOf(), axis, exprStr);
                break;
            default: break;
        }
        
        this.createSourceDisplayName();
        
        return null;
    }

    /**
        Sets the parameter out range to the default for the axis
    */
    void outRangeToDefault() {
        outRange = vec2(param.min.vector[axis], param.max.vector[axis]);
    }

    /**
        Finalizes the tracking binding, if possible.
        Returns true on success.
        Returns false if the parameter does not exist.
    */
    bool finalize(ref Puppet puppet) {
        param = puppet.findParameter(paramUUID);
        return param !is null;
    }

    void createSourceDisplayName() {
        switch(sourceType) {
            case SourceType.Blendshape:
                sourceDisplayName = sourceName;
                break;
            case SourceType.BonePosX:
                sourceDisplayName = _("%s (X)").format(sourceName);
                break;
            case SourceType.BonePosY:
                sourceDisplayName = _("%s (Y)").format(sourceName);
                break;
            case SourceType.BonePosZ:
                sourceDisplayName = _("%s (Z)").format(sourceName);
                break;
            case SourceType.BoneRotRoll:
                sourceDisplayName = _("%s (Roll)").format(sourceName);
                break;
            case SourceType.BoneRotPitch:
                sourceDisplayName = _("%s (Pitch)").format(sourceName);
                break;
            case SourceType.BoneRotYaw:
                sourceDisplayName = _("%s (Yaw)").format(sourceName);
                break;
            default: assert(0);    
        }
    }
}

