/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Author: Asahi Lina
*/
module creator.viewport.common.spline;
import creator.viewport.common.mesh;
import creator.viewport;
import creator.actions;
import creator.core.actionstack;
import creator.core;
import creator;
import inochi2d;
import inochi2d.core.dbg;
import bindbc.opengl;
import std.algorithm.mutation;
import std.array;
import std.math : isFinite, PI, atan2;
import std.stdio;
import std.algorithm.searching;

private {
    float nearestLine(vec2 a, vec2 b, vec2 c)
    {
        return ((c.x - a.x) * (b.x - a.x) + (c.y - a.y) * (b.y - a.y)) / ((b.x - a.x) ^^ 2 + (b.y - a.y) ^^ 2);
    }

    BezierSegment catmullToBezier(SplinePoint *p0, SplinePoint *p1, SplinePoint *p2, SplinePoint *p3, float tension = 1.0) {
        BezierSegment res;

        res.p[0] = p1.position;
        res.p[1] = p1.position + (p2.position - p0.position) / (6 * tension);
        res.p[2] = p2.position - (p3.position - p1.position) / (6 * tension);
        res.p[3] = p2.position;

        return res;
    }
}

struct SplinePoint {
    vec2 position;
    float weightL;
    float weightR;
}

struct BezierSegment {
    vec2[4] p;

    void split(float t, out BezierSegment left, out BezierSegment right) {
        float s = 1 - t;

        vec2 mc = p[1] * s + p[2] * t;
        vec2 a1 = p[0] * s + p[1] * t;
        vec2 a2 = a1 * s + mc * t;
        vec2 b2 = p[2] * s + p[3] * t;
        vec2 b1 = b2 * t + mc * s;
        vec2 m = a2 * s + b1 * t;

        left = BezierSegment([p[0], a1, a2, m]);
        right = BezierSegment([m, b1, b2, p[3]]);
    }

    vec2 eval(float t) {
        BezierSegment left, right;
        split(t, left, right);
        return left.p[3];
    }
}

class CatmullSpline {
private:
    vec2[] interpolated;
    vec3[] drawLines;
    vec3[] drawPoints;

public:
    uint resolution = 40;
    float selectRadius = 16f;
    SplinePoint[] points;
    vec2[] refMesh;
    vec2[] initTangents;
    CatmullSpline target;
    vec3[] refOffsets;

    float origX, origY, origRotZ;

    void createTarget(T)(T reference, mat4 trans, vec2[] vertices = null) {
        target = new CatmullSpline;
        target.resolution = resolution;
        target.selectRadius = selectRadius;
        target.points = points.dup;
        target.interpolate();

        remapTarget(reference, trans, vertices);
    }

    void remapTarget(T)(T reference, mat4 trans = mat4.identity, vec2[] vertices = null) {}

    void remapTarget(IncMesh reference, mat4 trans = mat4.identity, vec2[] vertices = null) {
        if (target !is null) {
            refMesh.length = 0;
            if (vertices !is null) {
                foreach(vertex; vertices) {
                    refMesh ~= (trans * vec4(vertex, 0, 1)).xy;
                }
            } else {
                foreach(ref MeshVertex* vtx; reference.vertices) {
                    refMesh ~= (trans * vec4(vtx.position, 0, 1)).xy;
                }
            }
            mapReference();
        }
    }

    void remapTarget(Node node, mat4 trans = mat4.identity, vec2[] vertices = null) {
        if (target !is null) {
            refMesh.length = 0;
            vec2 local = vec2(node.getValue("transform.t.x"), node.getValue("transform.t.y"));
            refMesh ~= (trans * vec4(local, 0, 1)).xy;
            mapReference();

            float getParameter(Node node, Parameter param, string paramName, vec2u index) {
                ValueParameterBinding b = cast(ValueParameterBinding)param.getBinding(node, paramName);
                if (b is null) {
                    return 0;
                }
                float result = b.getValue(index);
                return result;
            }
            Parameter armedParam = incArmedParameter();
            vec2u index = armedParam? armedParam.findClosestKeypoint() : vec2u(0, 0);
            origX = getParameter(node, armedParam, "transform.t.x", index);
            origY = getParameter(node, armedParam, "transform.t.x", index);
            origRotZ = getParameter(node, armedParam, "transform.r.z", index);
        }
    }

    void mapReference() {
        if (points.length < 2) {
            refOffsets.length = 0;
            initTangents.length = 0;
            return;
        }
        refOffsets.length = 0;
        initTangents.length = 0;

        float epsilon = 0.0001;
        foreach(i, vtx; refMesh) {
            float off = findClosestPointOffset(vtx);
            // FIXME: calculate tangent properly
            vec2 pt = target.eval(off);
            vec2 pt2 = target.eval(off + epsilon);
            vec2 tangent = pt2 - pt;
            tangent.normalize();

            // FIXME: extrapolation...
            if (off <= 0 || off >= (points.length - 1)) {
                refOffsets ~= vec3(0, 0, float());
                initTangents ~= tangent;
                continue;
            }
            vtx = vtx - pt;
            vec3 rel = vec3(
                vtx.x * tangent.x + vtx.y * tangent.y,
                vtx.y * tangent.x - vtx.x * tangent.y,
                off,
            );
            refOffsets ~= rel;
            initTangents ~= tangent;
        }
    }

    mat4 exportTarget(T)(ref T mesh, size_t i, ref vec2 vtx, vec2 tangent, vec2 initTangent, mat4 invert, vec2 deformation) {
        return mat4.identity();
    }

    mat4 exportTarget(ref IncMesh mesh, size_t i, ref vec2 vtx, vec2 tangent, vec2 initTangent, mat4 invert, vec2 deformation) {
        mesh.vertices[i].position = (invert * vec4(vtx, 0, 1)).xy - deformation;
        return mat4.identity();
    }

    mat4 exportTarget(ref Node node, size_t i, ref vec2 vtx, vec2 tangent, vec2 initTangent) {
        
        auto curAngle = atan2(tangent.y, tangent.x);
        auto origAngle = atan2(initTangent.y, initTangent.x);
        auto angle = curAngle - origAngle + origRotZ;
        float prevAngle;

        float changeParameter(Node node, Parameter param, string paramName, vec2u index, float newValue) {
            if (newValue == 0)
                return newValue;
            ValueParameterBinding b = cast(ValueParameterBinding)param.getBinding(node, paramName);
            if (b is null) {
                b = cast(ValueParameterBinding)param.createBinding(node, paramName);
                param.addBinding(b);
//                incActionPush(new ParameterBindingAddAction(param, b));
            }
            // Push action
//            incActionPush(new ParameterBindingValueChangeAction!(float)(b.getName(), b, index.x, index.y));
            float result = b.getValue(index);
            b.setValue(index, newValue);
            return result;
        }

        Parameter armedParam = incArmedParameter();
        vec2u index = armedParam? armedParam.findClosestKeypoint() : vec2u(0, 0);
        float old_x = 0; 
        float old_y = 0;
        if (armedParam) {
            old_x = changeParameter(node, armedParam, "transform.t.x", index, vtx.x);
            old_y = changeParameter(node, armedParam, "transform.t.y", index, vtx.y);
            prevAngle = changeParameter(node, armedParam, "transform.r.z", index, angle);
        } else {
            old_x = node.getValue("transform.t.x");
            old_y = node.getValue("transform.t.y");
            prevAngle = node.getValue("transform.r.z");
            node.setValue("transform.t.x", vtx.x);
            node.setValue("transform.t.y", vtx.y);
            node.setValue("transform.r.z", angle);
        }
        return mat4.identity;
    }


    void resetTarget(T)(T mesh) {
        foreach(i, vtx; refMesh) {
            exportTarget(mesh, i, vtx, vec2(0, 1), vec2(0, 1), mat4.identity, vec2(0, 0));
        }
    }

    mat4 updateTarget(T)(T mesh, ulong[] selected = null, mat4 invert = mat4.identity, vec2[] deformations = null) {
        if (points.length < 2) {
            resetTarget(mesh);
            return mat4.identity;
        }

        float epsilon = 0.0001;
        mat4 result;
        foreach(i, rel; refOffsets) {
            if (!isFinite(rel.z)) continue;
            if (selected && selected.countUntil(i) < 0) continue;

            // FIXME: calculate tangent properly
            vec2 pt = target.eval(rel.z);
            vec2 pt2 = target.eval(rel.z + epsilon);
            vec2 tangent = pt2 - pt;
            tangent = tangent / abs(tangent.distance(vec2(0, 0)));

            vec2 vtx = vec2(
                pt.x + rel.x * tangent.x - rel.y * tangent.y,
                pt.y + rel.y * tangent.x + rel.x * tangent.y
            );
//             writefln("%s %s %s", vtx, rel, tangent);
            result = exportTarget(mesh, i, vtx, tangent, initTangents.length > i ? initTangents[i]: tangent, invert, deformations[i]);
        }
        return result;
    }

    void update() {
        interpolate();
    }

    void interpolate() {
        interpolated.length = 0;
        drawLines.length = 0;

        if (points.length == 0) return;

        vec2 last;
        foreach(pos; 0..(resolution * (points.length - 1) + 1)) {
            vec2 p = eval(pos / cast(float)(resolution));
            interpolated ~= p;
            if (pos > 0) drawLines ~= [vec3(last.x, last.y, 0), vec3(p.x, p.y, 0)];
            last = p;
        }

        drawPoints.length = 0;
        foreach(p; points) {
            drawPoints ~= vec3(p.position.x, p.position.y, 0);
        }
    }

    vec2 eval(float off) {
        if (off <= 0) return points[0].position;
        if (off >= (points.length - 1)) return points[$ - 1].position;

        uint ioff = cast(uint)off;
        float t = off - ioff;
        float s = 1 - t;

        SplinePoint *p1 = &points[ioff];
        SplinePoint *p2 = &points[ioff + 1];

        // Two points, linear
        if (points.length == 2) return p1.position * s + p2.position * t;

        vec2 evalEdge(vec2 p0, vec2 p1, vec2 p2, float t) {
            float t2 = t ^^ 2;
            float t3 = t ^^ 3;

            float h00 = 2 * t3 - 3 * t2 + 1;
            float h10 = t3 - 2 * t2 + t;
            float h01 = -2 * t3 + 3 * t2;
            float h11 = t3 - t2;

            vec2 slope = (p2 - p0) / 2;
            return h11 * slope + h01 * p1 + h00 * p0;
        }

        // Edge segment, do the hermite spline thing
        if (ioff == 0)
            return evalEdge(p1.position, p2.position, points[ioff + 2].position, t);
        else if (ioff == points.length - 2)
            return evalEdge(p2.position, p1.position, points[ioff - 1].position, s);

        // Middle segment, do Catmull-Rom
        SplinePoint *p0 = &points[ioff - 1];
        SplinePoint *p3 = &points[ioff + 2];

        // By first converting it to Bezier
        float tension = 1;
        BezierSegment bezier = catmullToBezier(p0, p1, p2, p3);
        return bezier.eval(t);
    }

    float findClosestPointOffset(vec2 point) {
        vec2 tangent;
        return findClosestPointOffset(point, tangent);
    }

    float findClosestPointOffset(vec2 point, out vec2 tangent) {
        tangent = vec2(0, 0);

        if (points.length == 0) return 0;
        if (points.length == 1) {
            return 0;
        }

        uint bestIdx = 0;
        float bestDist = float.infinity;
        // Find closest interpolated point
        foreach(pos; 0..(resolution * (points.length - 1) + 1)) {
            float dist = interpolated[pos].distance(point);
            if (dist < bestDist) {
                bestDist = dist;
                bestIdx = cast(uint)pos;
            }
        }
//         writefln("best %s %s", bestIdx, bestDist);

        float left = max(0, (bestIdx - 1) / cast(float)resolution);
        float right = min(points.length - 1, (bestIdx + 1) / cast(float)resolution);
        vec2 leftPoint = eval(left);
        vec2 rightPoint = eval(right);
        float leftDist = abs(point.distance(leftPoint));
        float rightDist = abs(point.distance(rightPoint));

        float epsilon = 0.0001;

        while ((right - left) > epsilon * 2) {
//             writefln("left %s right %s", left, right);
            float mid = (left + right) / 2;
            vec2 midLPoint = eval(mid - epsilon);
            vec2 midRPoint = eval(mid + epsilon);
            if (abs(point.distance(midLPoint)) < abs(point.distance(midRPoint))) {
                right = mid;
                rightPoint = eval(right);
                rightDist = abs(point.distance(rightPoint));
            } else {
                left = mid;
                leftPoint = eval(left);
                leftDist = abs(point.distance(leftPoint));
            }
        }
        tangent = rightPoint - leftPoint;
        tangent = tangent / abs(tangent.distance(vec2(0, 0)));

        if (left == 0) return 0;
        if (right == points.length - 1) return points.length - 1;

//         writefln("left %s right %s", left, right);

        // Linearly interpolate within the range
        float t = nearestLine(leftPoint, rightPoint, point);
        return left * (1 - t) + right * t;
    }

    void splitAt(float off) {
        vec2 pos = eval(off);
        points.insertInPlace(1 + cast(uint)off, SplinePoint(pos, 1, 1));
        interpolate();
        if (target) target.splitAt(off);
    }

    void prependPoint(vec2 point) {
        points.insertInPlace(0, SplinePoint(point, 1, 1));
        interpolate();
        if (target) target.prependPoint(point);
    }

    void appendPoint(vec2 point) {
        points ~= SplinePoint(point, 1, 1);
        interpolate();
        if (target) target.appendPoint(point);
    }

    int findPoint(vec2 point) {
        uint bestIdx = 0;
        float bestDist = float.infinity;
        foreach(idx, pt; points) {
            float dist = pt.position.distance(point);
            if (dist < bestDist) {
                bestDist = dist;
                bestIdx = cast(uint)idx;
            }
        }

        if (bestDist > selectRadius/incViewportZoom) return -1;
        return bestIdx;
    }

    int addPoint(vec2 point) {
        if (points.length < 2) {
            appendPoint(point);
            return cast(int)points.length - 1;
        }

        float off = findClosestPointOffset(point);
//         writefln("Found off %s", off);
        if (off <= 0) {
            prependPoint(point);
            return 0;
        } else if (off >= (points.length - 1)) {
            appendPoint(point);
            return cast(int)points.length - 1;
        }
        vec2 onCurve = eval(off);
        if (abs(point.distance(onCurve)) < selectRadius/incViewportZoom) {
            splitAt(off);
            return 1 + cast(int)off;
        }
        return -1;
    }

    void removePoint(uint idx) {
        points = points.remove(idx);
        if (target) target.removePoint(idx);
        interpolate();
    }

    void draw(mat4 trans, vec4 color, uint lockedPoint = -1) {
        if (drawLines.length > 0) {
            inDbgSetBuffer(drawLines);
            inDbgDrawLines(color, trans);
        }
        if (drawPoints.length > 0) {
            inDbgSetBuffer(drawPoints);
            inDbgPointsSize(10);
            inDbgDrawPoints(vec4(0, 0, 0, 1), trans);
            inDbgPointsSize(6);
            inDbgDrawPoints(color, trans);
        }
        if (lockedPoint >= 0 && lockedPoint < drawPoints.length) {
            inDbgSetBuffer([drawPoints[lockedPoint]]);
            inDbgPointsSize(6);
            inDbgDrawPoints(vec4(1, 0, 0, 1), trans);
        }
    }

    void resetFloating() {
        foreach (i, p; points) {
            points[i].position = (vec4(p.position, 0, 1)).xy;
        }
        update();
    }
}
