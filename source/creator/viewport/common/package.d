/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Author: Asahi Lina
*/
module creator.viewport.common;
import inochi2d;

vec3[] incCreateCircleBuffer(vec2 origin, vec2 radii, uint segments)
{
    vec3[] lines;

    void addPoint(ulong i) {
        float theta = i * 2 * PI / segments;
        vec2 pt = origin + vec2(radii.x * sin(theta), radii.y * cos(theta));
        lines ~= vec3(pt.x, pt.y, 0);
    }
    foreach(i; 0..segments) {
        addPoint(i);
        addPoint(i + 1);
    }

    return lines;
}

vec3[] incCreateRectBuffer(vec2 from, vec2 to) {
    return [
        vec3(from.x, from.y, 0),
        vec3(to.x, from.y, 0),
        vec3(to.x, from.y, 0),
        vec3(to.x, to.y, 0),
        vec3(to.x, to.y, 0),
        vec3(from.x, to.y, 0),
        vec3(from.x, to.y, 0),
        vec3(from.x, from.y, 0),
    ];
}

vec3[] incCreateLineBuffer(vec2 from, vec2 to) {
    return [
        vec3(from.x, from.y, 0),
        vec3(to.x, to.y, 0),
    ];
}