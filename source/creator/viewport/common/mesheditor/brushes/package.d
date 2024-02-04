module creator.viewport.common.mesheditor.brushes;

public import creator.viewport.common.mesheditor.brushes.base;
public import creator.viewport.common.mesheditor.brushes.circlebrush;
public import creator.viewport.common.mesheditor.brushes.doublethreshbrush;

private {
    Brush[] brushes;
}

Brush[] incBrushList() {
    if (brushes.length == 0) {
        brushes ~= new CircleBrush("Circle Brush", 300);
        brushes ~= new DoubleThreshBrush("Double Threshold Circle", 300, 100);
    }
    return brushes;
}