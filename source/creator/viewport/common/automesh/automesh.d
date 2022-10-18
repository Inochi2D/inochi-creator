module creator.viewport.common.automesh.automesh;

import creator.viewport.common.mesh;
import inochi2d.core;

class AutoMeshProcessor {
public:
    abstract IncMesh autoMesh(Drawable targets, IncMesh meshData, bool mirrorHoriz = false, float axisHoriz = 0, bool mirrorVert = false, float axisVert = 0);
    abstract void configure();
};