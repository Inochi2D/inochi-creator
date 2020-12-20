/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets.viewport;
import core.project;
import core.glsurface;
import bindbc.opengl;

/**
    The viewport
*/
class Viewport : GLSurface {
private:
    Project project;

public:
    this(Project project) {
        this.project = project;
    }

    override void init() {

    }

    override void update(double deltaTime) {

    }

    override void draw(double deltaTime) {
        glClearColor(0, 0, 0, 0);
    }
}
