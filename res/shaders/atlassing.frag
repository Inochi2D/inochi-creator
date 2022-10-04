/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
#version 330
in vec2 texUVs;
out vec4 outAlbedo;

uniform sampler2D albedo;

void main() {
    outAlbedo = texture(albedo, texUVs);
}