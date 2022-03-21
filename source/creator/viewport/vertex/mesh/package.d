/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.viewport.vertex.mesh;
import creator.core;
import inochi2d;
import std.exception;
import bindbc.opengl;
public import creator.viewport.vertex.mesh.mesh;

private {
    Drawable target;
    bool hasEdited;
    IncMesh editingMesh;
}

Drawable incVertexEditGetTarget() {
    return target;
}

void incVertexEditSetTarget(Drawable target_) {
    target = target_;
    editingMesh = new IncMesh(target_.getMesh());
    editingMesh.refresh();
}

void incMeshEditDraw() {
    editingMesh.draw();
}

/**
    Applies the mesh edits
*/
void incMeshEditApply() {
    import std.stdio : writeln;

    // Export mesh
    MeshData data = editingMesh.export_();
    writeln(data);
    data.fixWinding();

    // Fix UVs
    foreach(i; 0..data.uvs.length) {
        if (Part part = cast(Part)target) {

            // Texture 0 is always albedo texture
            auto tex = part.textures[0];

            // By dividing by width and height we should get the values in UV coordinate space.
            data.uvs[i].x /= cast(float)tex.width;
            data.uvs[i].y /= cast(float)tex.height;
            data.uvs[i] += vec2(0.5, 0.5);
        }
    }

    writeln(data);

    // Apply the model
    target.rebuffer(data);
}

/**
    Resets the mesh edits
*/
void incMeshEditReset() {
    editingMesh.reset();
}

bool incMeshEditIsEdited() {
    return hasEdited;
}

vec3 incMeshEditWorldPos() {
    return vec3(target.transform.matrix() * vec4(1, 1, 1, 1));
}