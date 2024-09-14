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
        infoList ~= new ToolInfoImpl!(PointTool);
        infoList ~= new ToolInfoImpl!(ConnectTool);
        infoList ~= new ToolInfoImpl!(PathDeformTool);
        infoList ~= new ToolInfoImpl!(GridTool);
        infoList ~= new ToolInfoImpl!(BrushTool);
        infoList ~= new ToolInfoImpl!(LassoTool);
    }
    return infoList;
}
