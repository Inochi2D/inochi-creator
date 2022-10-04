/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
#version 330
in vec2 texUVs;

layout(location = 0) out vec4 outAlbedo;
uniform sampler2D albedo;

void main() {

    // Throw ada out there
    outAlbedo = texture(albedo, texUVs);
}