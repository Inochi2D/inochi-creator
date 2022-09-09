/*
    Inochi2D Part extended with layer information

    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.ext.nodes.excamera;
import inochi2d.core.nodes.part;
import inochi2d.core.nodes;
import inochi2d.core;
import inochi2d.fmt.serialize;
import std.stdio : writeln;
import inochi2d.math;

@TypeId("Camera")
class ExCamera : Node {
protected:
    vec2 viewport = vec2(1920, 1080);

    override
    void serializeSelf(ref InochiSerializer serializer) {
        super.serializeSelf(serializer);
        serializer.putKey("viewport");
        serializer.serializeValue(viewport.vector);
    }

    override
    SerdeException deserializeFromFghj(Fghj data) {
        auto err = super.deserializeFromFghj(data);
        if (err) return err;

        if (!data["viewport"].isEmpty) data["viewport"].deserializeValue(viewport.vector);
        return null;
    }

    override
    string typeId() {
        return "Camera";
    }

    /**
        Initial bounds size
    */
    override
    vec4 getInitialBoundsSize() {
        auto tr = transform;
        auto vpHalfSize = (viewport/2)*transform.scale;
        return vec4(tr.translation.x-vpHalfSize.x, tr.translation.y-vpHalfSize.y, tr.translation.x+vpHalfSize.x, tr.translation.y+vpHalfSize.y);;
    }

public:
    this() { super(); }
    this(Node parent) { super(parent); }
    this(vec2 viewport) { 
        super();
        this.viewport = viewport;
    }

    /**
        Gets Inochi2D camera for this camera
    */
    Camera getCamera() {
        Camera cam = new Camera();
        cam.position = transform().translation.xy;
        cam.scale = vec2(1, 1);
        return cam;
    }

    /**
        Gets the viewport for this camera
    */
    ref vec2 getViewport() {
        return viewport;
    }

}

void incRegisterExCamera() {
    inRegisterNodeType!ExCamera();
}