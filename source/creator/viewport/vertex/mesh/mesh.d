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

    bool isConnectedTo(MeshVertex* other) {
        if (other == null) return false;

        foreach(conn; other.connections) {
            if (*conn == this) return true;
        }
        return false;
    }

    void connect(MeshVertex* other) {
        this.connections ~= other;
        other.connections ~= &this;
    }
}

class IncMesh {
private:
    MeshData* data;
    MeshVertex*[] vertices;
    bool changed;

    vec3[] pData;
    vec3[] pDataSel; // TODO: selection
    void pRegen() {
        pData = new vec3[vertices.length];
        foreach(i, point; vertices) {
            pData[i] = vec3(point.position, 0);
        }
        inDbgSetBuffer(pData);
    }

    vec3[] lData;
    ushort[] lIndices;
    void lRegen() {

    }

    void mImport(ref MeshData data) {
        // Reset vertex length
        vertices.length = 0;

        // Iterate over flat mesh and extract it in to
        // vertices and "connections"
        MeshVertex*[ushort] iVertices;
        foreach(i; 0..data.indices.length/3) {
            auto index = data.indices[i*3];
            auto nindex = data.indices[(i*3)+1];
            auto nnindex = data.indices[(i*3)+2];
            if (nnindex !in iVertices) iVertices[nnindex] = new MeshVertex(data.vertices[nnindex], []);
            if (nindex !in iVertices) iVertices[nindex] = new MeshVertex(data.vertices[nindex], []);
            if (index !in iVertices) iVertices[index] = new MeshVertex(data.vertices[index], []);

            if (!iVertices[index].isConnectedTo(iVertices[nindex])) iVertices[index].connect(iVertices[nindex]);
            if (!iVertices[nindex].isConnectedTo(iVertices[nnindex])) iVertices[nindex].connect(iVertices[nnindex]);
            if (!iVertices[index].isConnectedTo(iVertices[nnindex])) iVertices[index].connect(iVertices[nnindex]);
        }

        foreach(vertex; iVertices) {
            vertices ~= vertex;
        }

        pRegen();
        lRegen();
    }

    MeshData mExport() {

        return *data;
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
    }

    /**
        Removes all vertices from the mesh
    */
    void clear() {
        vertices.length = 0;
    }
}