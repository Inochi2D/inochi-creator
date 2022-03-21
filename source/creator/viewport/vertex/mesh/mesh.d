/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.viewport.vertex.mesh.mesh;
import inochi2d;
import inochi2d.core.dbg;
import bindbc.opengl;
    
struct MeshVertex {
    vec2 position;
    MeshVertex*[] connections;
    bool selected;

    void connect(MeshVertex* other) {
        this.connections ~= other;
        other.connections ~= &this;
    }
}

private
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
    MeshVertex*[] vertices;
    bool changed;

    void mImport(ref MeshData data) {
        import std.stdio;
        // Reset vertex length
        vertices.length = 0;

        // Iterate over flat mesh and extract it in to
        // vertices and "connections"
        MeshVertex*[ushort] iVertices;
        foreach(indice; data.indices) {
            if (indice !in iVertices) iVertices[indice] = new MeshVertex(data.vertices[indice], []);
        }

        foreach(i; 0..data.indices.length/3) {
            auto index = data.indices[i*3];
            auto nindex = data.indices[(i*3)+1];
            auto nnindex = data.indices[(i*3)+2];

            if (!iVertices[index].isConnectedTo(iVertices[nindex])) iVertices[index].connect(iVertices[nindex]);
            if (!iVertices[nindex].isConnectedTo(iVertices[nnindex])) iVertices[nindex].connect(iVertices[nnindex]);
            if (!iVertices[nnindex].isConnectedTo(iVertices[index])) iVertices[nnindex].connect(iVertices[index]);
        }
        
        void printConnections(ushort i, MeshVertex* v) {
            import std.stdio;
            ushort[] conns;
            vec2[] coords;
            foreach(conn; v.connections) {
                foreach(key, value; iVertices) {
                    if (value == conn) {
                        conns ~= key;
                        coords ~= value.position;
                        break;
                    }
                }
            }

            writeln(i, ": ", conns, " ", coords);
        }

        foreach(i, vertex; iVertices) {
            printConnections(i, vertex);
            vertices ~= vertex;
        }
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
        
        void printConnections(ushort i, MeshVertex* v) {
            import std.stdio;
            ushort[] conns;
            foreach(conn; v.connections) {
                conns ~= indices[conn];
            }

            writeln(i, ": ", conns);
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

        bool areLineSegmentsIntersecting(vec2 p1, vec2 p2, vec2 p3, vec2 p4) {
            float epsilon = 0.00001f;
            float demoninator = (p4.y - p3.y) * (p2.x - p1.x) - (p4.x - p3.x) * (p2.y - p1.y);
            if (demoninator == 0) return false;

            float uA = ((p4.x - p3.x) * (p1.y - p3.y) - (p4.y - p3.y) * (p1.x - p3.x)) / demoninator;
            float uB = ((p2.x - p1.x) * (p1.y - p3.y) - (p2.y - p1.y) * (p1.x - p3.x)) / demoninator;
            return (uA > 0+epsilon && uA < 1-epsilon && uB > 0+epsilon && uB < 1-epsilon);
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
            import std.stdio : writefln;

            visited ~= v;
            printConnections(indices[v], v);

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

        mExportVisit(vertices[0]);
        data = newData;
        refresh();

        return *newData;
    }

    vec3[] points;
    vec3[] selpoints;
    vec3[] lines;
    void regen() {
        points.length = vertices.length;
        
        // Updates all point positions
        foreach(i, vert; vertices) {
            if (vert.selected) selpoints ~= vec3(vert.position, 0);
            else points ~= vec3(vert.position, 0);
        }
    }

    void regenConnections() {
        import std.algorithm.searching : canFind;

        // setup
        lines.length = 0;
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

        recurseLines(vertices[0]);
    }

public:

    /**
        Constructs a new IncMesh
    */
    this(ref MeshData mesh) {
        data = &mesh;
        mImport(mesh);
    }
    
    /**
        Exports the working mesh to a MeshData object.
    */
    MeshData export_() {
        return mExport();
    }

    /**
        Resets mesh to prior state
    */
    void reset() {
        mImport(*data);
        refresh();
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
    void draw() {
        if (lines.length > 0) {
            inDbgSetBuffer(lines);
            inDbgDrawLines(vec4(0.7, 0.7, 0.7, 1));
        }

        if (points.length > 0) {
            inDbgSetBuffer(points);
            inDbgPointsSize(8);
            inDbgDrawPoints(vec4(0, 0, 0, 1));
            inDbgPointsSize(6);
            inDbgDrawPoints(vec4(1, 1, 1, 1));
        }

        if (selpoints.length > 0) {
            inDbgSetBuffer(selpoints);
            inDbgPointsSize(8);
            inDbgDrawPoints(vec4(0, 0, 0, 1));
            inDbgPointsSize(6);
            inDbgDrawPoints(vec4(1, 0, 0, 1));
        }
    }

    /**
        Removes all vertices from the mesh
    */
    void clear() {
        vertices.length = 0;
    }
}