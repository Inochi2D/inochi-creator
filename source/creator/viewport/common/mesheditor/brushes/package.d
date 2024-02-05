module creator.viewport.common.mesheditor.brushes;

public import creator.viewport.common.mesheditor.brushes.base;
public import creator.viewport.common.mesheditor.brushes.circlebrush;
public import creator.viewport.common.mesheditor.brushes.doublethreshbrush;
public import creator.viewport.common.mesheditor.brushes.rectanglebrush;

private {
    Brush[] brushes;
}

Brush[] incBrushList() {
    if (brushes.length == 0) {
        brushes ~= new CircleBrush("Circle Brush", 300);
        brushes ~= new DoubleThreshBrush("Double Threshold Circle", 300, 100);
        brushes ~= new RectangleBrush("Rectangle Brush", 300, 300, 0.0);
    }
    return brushes;
}