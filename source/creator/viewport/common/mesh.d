/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors:
    - Luna Nielsen
    - Asahi Lina

    in_circle() from poly2tri, licensed under BSD-3:
        Copyright (c) 2009-2018, Poly2Tri Contributors
        https://github.com/jhasse/poly2tri
*/
module creator.viewport.common.mesh;
import creator.viewport;
import inochi2d;
import inochi2d.core.dbg;
import bindbc.opengl;
import std.algorithm.mutation;

struct MeshVertex {
    vec2 position;
    MeshVertex*[] connections;
}

void connect(MeshVertex* self, MeshVertex* other) {
    if (isConnectedTo(self, other)) return;

    self.connections ~= other;
    other.connections ~= self;
}
 
void disconnect(MeshVertex* self, MeshVertex* other) {
    import std.algorithm.searching : countUntil;
    import std.algorithm.mutation : remove;
    
    auto idx = other.connections.countUntil(self);
    if (idx != -1) other.connections = remove(other.connections, idx);

    idx = self.connections.countUntil(other);
    if (idx != -1) self.connections = remove(self.connections, idx);
}

void disconnectAll(MeshVertex* self) {
    while(self.connections.length > 0) {
        self.disconnect(self.connections[0]);
    }
}

bool isConnectedTo(MeshVertex* self, MeshVertex* other) {
    if (other == null) return false;

    foreach(conn; other.connections) {
        if (conn == self) return true;
    }
    return false;
}

class IncMesh {
private:
    MeshData* data;

    void mImport(ref MeshData data) {
        // Reset vertex length
        vertices.length = 0;

        // Iterate over flat mesh and extract it in to
        // vertices and "connections"
        MeshVertex*[] iVertices;

        iVertices.length = data.vertices.length;
        foreach(idx, vertex; data.vertices) {
            iVertices[idx] = new MeshVertex(vertex, []);
        }

        foreach(i; 0..data.indices.length/3) {
            auto index = data.indices[i*3];
            auto nindex = data.indices[(i*3)+1];
            auto nnindex = data.indices[(i*3)+2];

            if (!iVertices[index].isConnectedTo(iVertices[nindex])) iVertices[index].connect(iVertices[nindex]);
            if (!iVertices[nindex].isConnectedTo(iVertices[nnindex])) iVertices[nindex].connect(iVertices[nnindex]);
            if (!iVertices[nnindex].isConnectedTo(iVertices[index])) iVertices[nnindex].connect(iVertices[index]);
        }
        
        void printConnections(MeshVertex* v) {
            import std.stdio;
            ushort[] conns;
            vec2[] coords;
            foreach(conn; v.connections) {
                foreach(key, value; iVertices) {
                    if (value == conn) {
                        conns ~= cast(ushort)key;
                        coords ~= value.position;
                        break;
                    }
                }
            }
        }

        foreach(i, vertex; iVertices) {
            printConnections(vertex);
            vertices ~= vertex;
        }

        refresh();
    }

    MeshData mExport() {
        import std.algorithm.searching : canFind;
        MeshData* newData = new MeshData;

        ushort[MeshVertex*] indices;
        ushort indiceIdx = 0;
        foreach(vertex; vertices) {
            newData.vertices ~= vertex.position;
            newData.uvs ~= vertex.position;
            indices[vertex] = indiceIdx++;
        }

        bool goesBackToRoot(MeshVertex* root, MeshVertex* vert) {
            foreach(MeshVertex* conn; vert.connections) {
                if (conn == root) return true;
            }
            return false;
        }

        bool hasIndiceSeq(ushort a, ushort b, ushort c) {
            foreach(i; 0..newData.indices.length/3) {
                int score = 0;

                if (newData.indices[(i*3)+0] == a || newData.indices[(i*3)+0] == b || newData.indices[(i*3)+0] == c) score++;
                if (newData.indices[(i*3)+1] == a || newData.indices[(i*3)+1] == b || newData.indices[(i*3)+1] == c) score++;
                if (newData.indices[(i*3)+2] == a || newData.indices[(i*3)+2] == b || newData.indices[(i*3)+2] == c) score++;

                if (score == 3) return true;
            }
            return false;
        }

        bool isAnyEdgeIntersecting(vec2[3] t1, vec2[3] t2) {
            vec2 t1p1, t1p2, t2p1, t2p2;
            static foreach(i; 0..3) {
                static foreach(j; 0..3) {
                    t1p1 = t1[i];
                    t1p2 = t1[(i+1)%3];
                    t2p1 = t2[j];
                    t2p2 = t2[(j+1)%3];

                    if (areLineSegmentsIntersecting(t1p1, t1p2, t2p1, t2p2)) return true;
                }
            }
            return false;
        }

        bool isIntersectingWithTris(vec2[3] t1) {
            foreach(i; 0..newData.indices.length/3) {
                vec2[3] verts = [
                    newData.vertices[newData.indices[(i*3)+0]],
                    newData.vertices[newData.indices[(i*3)+0]],
                    newData.vertices[newData.indices[(i*3)+0]]
                ];
                if (isAnyEdgeIntersecting(t1, verts)) return true;
            }
            return false;
        }

        MeshVertex*[] visited;
        void mExportVisit(MeshVertex* v) {
            visited ~= v;

            MeshVertex* findFreeIndice() {
                foreach (key; indices.keys) {
                    if (indices[key] != newData.indices[$-1] && 
                        indices[key] != newData.indices[$-2] && 
                        indices[key] != newData.indices[$-3] && 
                        !visited.canFind(key)) return cast(MeshVertex*)key;
                }
                return null;
            }

            // Second vertex
            foreach(MeshVertex* conn; v.connections) {
                if (conn == v) continue;

                // Third vertex
                foreach(MeshVertex* conn2; conn.connections) {
                    if (goesBackToRoot(v, conn2)) {

                        // Skip repeat sequences
                        if (hasIndiceSeq(indices[v], indices[conn], indices[conn2])) continue;
                        if (isIntersectingWithTris([v.position, conn.position, conn2.position])) continue;
                        

                        // Add new indices
                        newData.indices ~= [
                            indices[v],
                            indices[conn],
                            indices[conn2]
                        ];
                        break;
                    }
                }
            }

            foreach(MeshVertex* conn; v.connections) {
                if (!visited.canFind(conn)) mExportVisit(conn);
            }
        }

        // Run the export
        foreach(ref vert; vertices) {
            if (!visited.canFind(vert)) {
                mExportVisit(vert);
            }
        }

        // Save the data as the new data and refresh
        data = newData;
        reset();
        return *newData;
    }

    vec3[] points;
    vec3[] lines;
    vec3[] wlines;
    void regen() {
        points.length = 0;
        
        // Updates all point positions
        foreach(i, vert; vertices) {
            points ~= vec3(vert.position, 0);
        }
    }

    void regenConnections() {
        import std.algorithm.searching : canFind;

        // setup
        lines.length = 0;
        wlines.length = 0;
        MeshVertex*[] visited;
        
        // our crazy recursive func
        void recurseLines(MeshVertex* cur) {
            visited ~= cur;

            // First add the lines
            foreach(conn; cur.connections) {

                // Skip already scanned connections
                if (!visited.canFind(conn)) {
                    lines ~= [vec3(cur.position, 0), vec3(conn.position, 0)];
                }
            }
            // Then scan the next unvisited point
            foreach(conn; cur.connections) {

                // Skip already scanned connections
                if (!visited.canFind(conn)) {
                    recurseLines(conn);
                }
            }
        }

        foreach(ref vert; vertices) {
            if (!visited.canFind(vert)) {
                recurseLines(vert);
            }
        }
    }

public:
    float selectRadius = 16f;
    MeshVertex*[] vertices;
    bool changed;

    /**
        Constructs a new IncMesh
    */
    this(ref MeshData mesh) {
        import_(mesh);
    }

    final
    void import_(ref MeshData mesh) {
        data = &mesh;
        mImport(mesh);
    }
    
    /**
        Exports the working mesh to a MeshData object.
    */
    final
    MeshData export_() {
        return mExport();
    }

    /**
        Resets mesh to prior state
    */
    void reset() {
        mImport(*data);
        refresh();
        changed = true;
    }

    /**
        Clears the mesh of everything
    */
    void clear() {
        vertices.length = 0;
        refresh();
        changed = true;
    }

    /**
        Refreshes graphical portion of the mesh
    */
    void refresh() {
        regen();
        regenConnections();
    }

    /**
        Draws the mesh
    */
    void drawLines(mat4 trans = mat4.identity, vec4 color = vec4(0.7, 0.7, 0.7, 1)) {
        if (lines.length > 0) {
            inDbgSetBuffer(lines);
            inDbgDrawLines(color, trans);
        }

        if (wlines.length > 0) {
            inDbgSetBuffer(wlines);
            inDbgDrawLines(vec4(0.7, 0.2, 0.2, 1), trans);
        }
    }

    void drawPoints(mat4 trans = mat4.identity) {
        if (points.length > 0) {
            inDbgSetBuffer(points);
            inDbgPointsSize(10);
            inDbgDrawPoints(vec4(0, 0, 0, 1), trans);
            inDbgPointsSize(6);
            inDbgDrawPoints(vec4(1, 1, 1, 1), trans);
        }
    }

    void drawPointSubset(MeshVertex*[] subset, vec4 color, mat4 trans = mat4.identity, float size=6) {
        vec3[] subPoints;

        if (subset.length == 0) return;

        // Updates all point positions
        foreach(vtx; subset) {
            subPoints ~= vec3(vtx.position, 0);
        }
        inDbgSetBuffer(subPoints);
        inDbgPointsSize(size);
        inDbgDrawPoints(color, trans);
    }

    void draw(mat4 trans = mat4.identity) {
        drawLines(trans);
        drawPoints(trans);
    }

    bool isPointOverVertex(vec2 point) {
        foreach(vert; vertices) {
            if (abs(vert.position.distance(point)) < selectRadius/incViewportZoom) return true;
        }
        return false;
    }

    void removeVertexAt(vec2 point) {
        foreach(i; 0..vertices.length) {
            if (abs(vertices[i].position.distance(point)) < selectRadius/incViewportZoom) {
                this.remove(vertices[i]);
                return;
            }
        }
    }

    MeshVertex* getVertexFromPoint(vec2 point) {
        foreach(ref vert; vertices) {
            if (abs(vert.position.distance(point)) < selectRadius/incViewportZoom) return vert;
        }
        return null;
    }

    void remove(MeshVertex* vert) {
        import std.algorithm.searching : countUntil;
        import std.algorithm.mutation : remove;
        
        auto idx = vertices.countUntil(vert);
        if (idx != -1) {
            disconnectAll(vert);
            vertices = vertices.remove(idx);
        }
        changed = true;
    }

    vec2[] getOffsets() {
        vec2[] offsets;

        offsets.length = vertices.length;
        foreach(idx, vertex; vertices) {
            offsets[idx] = vertex.position - data.vertices[idx];
        }
        return offsets;
    }

    void applyOffsets(vec2[] offsets) {
        foreach(idx, vertex; vertices) {
            vertex.position += offsets[idx];
        }
        regen();
        regenConnections();
        changed = true;
    }

    /**
        Flips all vertices horizontally
    */
    void flipHorz() {
        foreach(ref vert; vertices) {
            vert.position.x *= -1;
        }
        refresh();
        changed = true;
    }

    /**
        Flips all vertices vertically
    */
    void flipVert() {
        foreach(ref vert; vertices) {
            vert.position.y *= -1;
        }
        refresh();
        changed = true;
    }

    void getBounds(out vec2 min, out vec2 max) {
        min = vec2(float.infinity, float.infinity);
        max = vec2(-float.infinity, -float.infinity);

        foreach(idx, vertex; vertices) {
            if (min.x > vertex.position.x) min.x = vertex.position.x;
            if (min.y > vertex.position.y) min.y = vertex.position.y;
            if (max.x < vertex.position.x) max.x = vertex.position.x;
            if (max.y < vertex.position.y) max.y = vertex.position.y;
        }
    }

    MeshVertex*[] getInRect(vec2 min, vec2 max) {
        if (min.x > max.x) swap(min.x, max.x);
        if (min.y > max.y) swap(min.y, max.y);

        MeshVertex*[] matching;
        foreach(idx, vertex; vertices) {
            if (min.x > vertex.position.x) continue;
            if (min.y > vertex.position.y) continue;
            if (max.x < vertex.position.x) continue;
            if (max.y < vertex.position.y) continue;
            matching ~= vertex;
        }

        return matching;
    }

    IncMesh autoTriangulate() {
        import std.stdio;
        debug(delaunay) writeln("==== autoTriangulate ====");
        if (vertices.length < 3) return new IncMesh(*data);

        IncMesh newMesh = new IncMesh(*data);
        newMesh.changed = true;

        vec2 min, max;
        getBounds(min, max);

        // Pad (fudge factors are a hack to work around contains() instability, TODO: fix)
        vec2 range = max - min;
        min -= range + vec2(range.y, range.x) + vec2(0.123, 0.125);
        max += range + vec2(range.y, range.x) + vec2(0.127, 0.129);

        vec3u[] tris;
        vec3u[] tri2edge;
        vec2u[] edge2tri;

        vec2[] vtx;
        vtx.length = 4;

        // Define initial state (two tris)
        vtx[0] = vec2(min.x, min.y);
        vtx[1] = vec2(min.x, max.y);
        vtx[2] = vec2(max.x, max.y);
        vtx[3] = vec2(max.x, min.y);
        tris ~= vec3u(0, 1, 3);
        tris ~= vec3u(1, 2, 3);
        tri2edge ~= vec3u(0, 1, 2);
        tri2edge ~= vec3u(3, 4, 1);
        edge2tri ~= vec2u(0, 0);
        edge2tri ~= vec2u(0, 1);
        edge2tri ~= vec2u(0, 0);
        edge2tri ~= vec2u(1, 1);
        edge2tri ~= vec2u(1, 1);

        // Helpers
        float sign(vec2 p1, vec2 p2, vec2 p3) {
            return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
        }

        bool contains(vec3u tri, vec2 pt) {
            float d1, d2, d3;
            bool hasNeg, hasPos;

            d1 = sign(pt, vtx[tri.x], vtx[tri.y]);
            d2 = sign(pt, vtx[tri.y], vtx[tri.z]);
            d3 = sign(pt, vtx[tri.z], vtx[tri.x]);

            hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0);
            hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0);

            return !(hasNeg && hasPos);
        }

        void replaceE2T(ref vec2u e2t, uint from, uint to) {
            if (e2t.x == from) {
                e2t.x = to;
                if (e2t.y == from) e2t.y = to;
            } else if (e2t.y == from) {
                e2t.y = to;
            } else assert(false, "edge mismatch");
        }

        void orientTri(uint tri, uint edge) {
            vec3u t2e = tri2edge[tri];
            vec3u pt = tris[tri];
            if (t2e.x == edge) {
                return;
            } else if (t2e.y == edge) {
                tri2edge[tri] = vec3u(t2e.y, t2e.z, t2e.x);
                tris[tri] = vec3u(pt.y, pt.z, pt.x);
            } else if (t2e.z == edge) {
                tri2edge[tri] = vec3u(t2e.z, t2e.x, t2e.y);
                tris[tri] = vec3u(pt.z, pt.x, pt.y);
            } else {
                assert(false, "triangle does not own edge");
            }
        }

        void splitEdges() {
            uint edgeCnt = cast(uint)edge2tri.length;
            for(uint e = 0; e < edgeCnt; e++) {
                vec2u tr = edge2tri[e];

                if (tr.x != tr.y) continue; // Only handle outer edges

                orientTri(tr.x, e);

                uint t1 = tr.x;
                uint t2 = cast(uint)tris.length;
                uint l = tris[t1].x;
                uint r = tris[t1].y;
                uint z = tris[t1].z;
                uint m = cast(uint)vtx.length;
                vtx ~= (vtx[l] + vtx[r]) / 2;

                uint xe = cast(uint)edge2tri.length;
                uint me = xe + 1;
                uint re = tri2edge[t1].y;

                tris[t1].y = m;
                tri2edge[t1].y = me;
                tris ~= vec3u(m, r, z);
                tri2edge ~= vec3u(xe, re, me);
                edge2tri ~= vec2u(t2, t2);
                edge2tri ~= vec2u(t1, t2);
                replaceE2T(edge2tri[re], t1, t2);
            }
        }

        bool inCircle(vec2 pa, vec2 pb, vec2 pc, vec2 pd) {
            debug(delaunay) writefln("in_circle(%s, %s, %s, %s)", pa, pb, pc, pd);
            float adx = pa.x - pd.x;
            float ady = pa.y - pd.y;
            float bdx = pb.x - pd.x;
            float bdy = pb.y - pd.y;

            float adxbdy = adx * bdy;
            float bdxady = bdx * ady;
            float oabd = adxbdy - bdxady;

            if (oabd <= 0) return false;

            float cdx = pc.x - pd.x;
            float cdy = pc.y - pd.y;

            float cdxady = cdx * ady;
            float adxcdy = adx * cdy;
            float ocad = cdxady - adxcdy;

            if (ocad <= 0) return false;

            float bdxcdy = bdx * cdy;
            float cdxbdy = cdx * bdy;

            float alift = adx * adx + ady * ady;
            float blift = bdx * bdx + bdy * bdy;
            float clift = cdx * cdx + cdy * cdy;

            float det = alift * (bdxcdy - cdxbdy) + blift * ocad + clift * oabd;

            debug(delaunay) writefln("det=%s", det);
            return det > 0;
        }

        splitEdges();
        splitEdges();
        splitEdges();
        splitEdges();

        uint dropVertices = cast(uint)vtx.length;

        // Add vertices, preserving Delaunay condition
        foreach(orig_i, vertex; vertices) {
            uint i = cast(uint)orig_i + dropVertices;
            debug(delaunay) writefln("Add @%d: %s", i, vertex.position);
            vtx ~= vertex.position;
            bool found = false;

            uint[] affectedEdges;

            foreach(a_, tri; tris) {
                if (!contains(tri, vertex.position)) continue;

                /*
                           x
                  Y-----------------X
                   \`,            '/    XYZ = original vertices
                    \ `q   a   p' /     a = original triangle
                     \  `,    '  /      bc = new triangles
                      \   `i'   /       xyz = original edges
                     y \ b | c / z      pqr = new edges
                        \  r  /
                         \ | /
                          \|/
                           Z
                */

                // Subdivide containing triangle
                // New triangles
                uint a = cast(uint)a_;
                uint b = cast(uint)tris.length;
                uint c = b + 1;
                tris[a] = vec3u(tri.x, tri.y, i);
                tris ~= vec3u(tri.y, tri.z, i); // b
                tris ~= vec3u(tri.z, tri.x, i); // c

                debug(delaunay) writefln("*** Tri %d: %s Edges: %s", a, tris[a], tri2edge[a]);

                // New inner edges
                uint p = cast(uint)edge2tri.length;
                uint q = p + 1;
                uint r = q + 1;

                // Get outer edges
                uint x = tri2edge[a].x;
                uint y = tri2edge[a].y;
                uint z = tri2edge[a].z;

                // Update triangle to edge mappings
                tri2edge[a] = vec3u(x, q, p);
                tri2edge ~= vec3u(y, r, q);
                tri2edge ~= vec3u(z, p, r);

                debug(delaunay) writefln("  * Tri a %d: %s Edges: %s", a, tris[a], tri2edge[a]);
                debug(delaunay) writefln("  + Tri b %d: %s Edges: %s", b, tris[b], tri2edge[b]);
                debug(delaunay) writefln("  + Tri c %d: %s Edges: %s", c, tris[c], tri2edge[c]);

                // Save new edges
                edge2tri ~= vec2u(c, a);
                edge2tri ~= vec2u(a, b);
                edge2tri ~= vec2u(b, c);
                debug(delaunay) writefln("  + Edg p %d: Tris %s", p, edge2tri[p]);
                debug(delaunay) writefln("  + Edg q %d: Tris %s", q, edge2tri[q]);
                debug(delaunay) writefln("  + Edg r %d: Tris %s", r, edge2tri[r]);

                // Update two outer edges
                debug(delaunay) writefln("  - Edg y %d: Tris %s", y, edge2tri[y]);
                replaceE2T(edge2tri[y], a, b);
                debug(delaunay) writefln("  + Edg y %d: Tris %s", y, edge2tri[y]);
                debug(delaunay) writefln("  - Edg z %d: Tris %s", y, edge2tri[z]);
                replaceE2T(edge2tri[z], a, c);
                debug(delaunay) writefln("  + Edg z %d: Tris %s", z, edge2tri[z]);

                // Keep track of what edges we have to look at
                affectedEdges ~= [x, y, z, p, q, r];

                found = true;
                break;
            }
            if (!found) {
                debug(delaunay) writeln("FAILED!");
                break;
            }

            bool[] checked;
            checked.length = edge2tri.length;

            for (uint j = 0; j < affectedEdges.length; j++) {
                uint e = affectedEdges[j];
                vec2u t = edge2tri[e];

                debug(delaunay) writefln(" ## Edge %d: T %s: %s %s", e, t, tris[t.x], tris[t.y]);

                if (t.x == t.y) {
                    debug(delaunay) writefln("  + Outer edge");
                    continue; // Outer edge
                }

                // Orient triangles so 1st edge is shared
                orientTri(t.x, e);
                orientTri(t.y, e);

                assert(tris[t.x].x == tris[t.y].y, "triangles do not share edge");
                assert(tris[t.y].x == tris[t.x].y, "triangles do not share edge");

                uint a = tris[t.x].x;
                uint c = tris[t.x].y;
                uint d = tris[t.x].z;
                uint b = tris[t.y].z;

                // Delaunay check
                if (!inCircle(vtx[b], vtx[a], vtx[c], vtx[d])) {
                    // We're good
                    debug(delaunay) writefln("  + Meets condition");
                    continue;
                }

                debug(delaunay) writefln("  - Flip!");

                // Flip edge
                /*
                   c          c
                  /|\      r / \ q
                 / | \      / x \
                d x|y b -> d-----b
                 \ | /      \ y /
                  \|/      s \ / p
                   a          a
                */
                uint r = tri2edge[t.x].y;
                uint s = tri2edge[t.x].z;
                uint p = tri2edge[t.y].y;
                uint q = tri2edge[t.y].z;

                tris[t.x] = vec3u(d, b, c);
                tris[t.t] = vec3u(b, d, a);
                tri2edge[t.x] = vec3u(e, q, r);
                tri2edge[t.y] = vec3u(e, s, p);
                replaceE2T(edge2tri[q], t.y, t.x);
                replaceE2T(edge2tri[s], t.x, t.y);

                // Mark it as checked
                checked[e] = true;

                // Check the neighboring edges
                if (!checked[p]) affectedEdges ~= p;
                if (!checked[q]) affectedEdges ~= q;
                if (!checked[r]) affectedEdges ~= r;
                if (!checked[s]) affectedEdges ~= s;
            }
        }

        // Copy vertices
        newMesh.vertices.length = 0;
        foreach(v; vtx) {
            newMesh.vertices ~= new MeshVertex(v, []);
        }

        // Extract tris into connections
        foreach(tri; tris) {
            connect(newMesh.vertices[tri.x], newMesh.vertices[tri.y]);
            connect(newMesh.vertices[tri.y], newMesh.vertices[tri.z]);
            connect(newMesh.vertices[tri.z], newMesh.vertices[tri.x]);
        }

        // Get rid of corners
        foreach(i; 0..dropVertices)
            newMesh.remove(newMesh.vertices[0]);

        newMesh.refresh();
        debug(delaunay) writeln("==== autoTriangulate done ====");
        return newMesh;
    }
}