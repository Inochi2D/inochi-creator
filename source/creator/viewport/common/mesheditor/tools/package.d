module creator.viewport.common.mesheditor.tools;

public import creator.viewport.common.mesheditor.tools.enums;
public import creator.viewport.common.mesheditor.tools.base;
public import creator.viewport.common.mesheditor.tools.select;
public import creator.viewport.common.mesheditor.tools.point;
public import creator.viewport.common.mesheditor.tools.connect;
public import creator.viewport.common.mesheditor.tools.pathdeform;
public import creator.viewport.common.mesheditor.tools.grid;
public import creator.viewport.common.mesheditor.tools.brush;
public import creator.viewport.common.mesheditor.tools.lasso;

private {
    ToolInfo[] infoList;
}

ToolInfo[] incGetToolInfo() {
    if (infoList.length == 0) {
        infoList ~= new PointToolInfo;
        infoList ~= new ConnectToolInfo;
        infoList ~= new PathDeformToolInfo;
        infoList ~= new GridToolInfo;
        infoList ~= new BrushToolInfo;
        infoList ~= new LassoToolInfo;
    }
    return infoList;
}
