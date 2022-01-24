module creator.medit;
import creator.core;
import inochi2d;
import std.exception;
import bindbc.opengl;
public import creator.medit.mesh;

private {
    Drawable target;
    MeshData editingData;
    bool hasEdited;

    GLuint vboPoints;
    GLuint vboSegments;

    IncMesh editingMesh;
}

void incMeshEditSetTarget(Drawable target_) {
    target = target_;
    editingMesh = new IncMesh(target_.getMesh());
}

void incMeshEditReset() {
    editingData = target.getMesh.copy();
}

/**
    Maps UV coordinates from world-space to texture space
*/
void incMeshEditMapUV(ref vec2 uv) {
    uv -= vec2(incMeshEditWorldPos());
    if (Part part = cast(Part)target) {

        // Texture 0 is always albedo texture
        auto tex = part.textures[0];

        // By dividing by width and height we should get the values in UV coordinate space.
        uv.x /= cast(float)tex.width;
        uv.y /= cast(float)tex.height;
    }
}

void incMeshEditBarrier() {
    //if ()
}

void incMeshEditDbg() {
    editingData.dbg();
}

bool incMeshEditCanTriangulate() {
    return false;
}

bool incMeshEditCanApply() {
    return editingData.isReady();
}

void incMeshEditApply() {
    enforce(editingData.isReady(), "Mesh is incomplete and cannot be applied.");
    hasEdited = false;

    // Fix winding order
    editingData.fixWinding();
    target.getMesh() = editingData;
}

bool incMeshEditIsEdited() {
    return hasEdited;
}

vec3 incMeshEditWorldPos() {
    return vec3(target.transform.matrix() * vec4(1, 1, 1, 1));
}