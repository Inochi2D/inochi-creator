/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
#version 330

layout(location = 0) in vec2 verts;
layout(location = 1) in vec2 uvs;
out vec2 texUVs;

uniform mat4 mvp;

void main() {
    gl_Position = mvp * vec4(verts.x, verts.y, 0, 1);
    texUVs = uvs;
}