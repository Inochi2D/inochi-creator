/*
    Inochi2D Part extended with layer information

    Copyright © 2020-2023, Inochi2D Project
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
import inochi2d.core.dbg;

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
        vec3 topLeft = vec3(
            tr.translation.x-vpHalfSize.x, 
            tr.translation.y-vpHalfSize.y,
            0
        );
        vec3 bottomRight = vec3(
            tr.translation.x+vpHalfSize.x, 
            tr.translation.y+vpHalfSize.y,
            0
        );

        return vec4(topLeft.xy, bottomRight.xy);
    }

    override
    void drawBounds() {
        auto tr = transform;
        auto vpHalfSize = viewport/2;

        vec3 topLeft = vec3(-vpHalfSize.x, -vpHalfSize.y, 0);
        vec3 bottomRight = vec3(+vpHalfSize.x, +vpHalfSize.y, 0);
        vec3 topRight = vec3(bottomRight.x, topLeft.y, 0);
        vec3 bottomLeft = vec3(topLeft.x, bottomRight.y, 0);

        inDbgSetBuffer([
            topLeft, topRight,
            topRight, bottomRight,
            bottomRight, bottomLeft,
            bottomLeft, topLeft
        ]);

        inDbgLineWidth(2);
        inDbgDrawLines(vec4(0, 0, 0, 1), transform.matrix);
        inDbgLineWidth(1);
        inDbgDrawLines(vec4(1, 1, 1, 1), transform.matrix);
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
        vec2 scale = transform().scale;

        Camera cam = new Camera();
        cam.position = transform().translation.xy*vec2(-1, -1);
        cam.rotation = -transform().rotation.z;
        cam.scale = vec2(1/scale.x, 1/scale.y);
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

bool incVerifyCameraSizeShowWarning(ref ExCamera selectedCamera) {
    import creator.widgets;
    import i18n;
    if (selectedCamera.getViewport().x % 2 != 0 || selectedCamera.getViewport().y % 2 != 0) {
        incTextColored(ImVec4(1, 0, 0, 1), _("Warning: Camera size must be divisible by 2"));
        return true;
    }
    return false;
}