module core.rinit;
import bindbc.opengl;
import core.itime;
import inochi2d;

private bool glInit;

void initRenderer() {

    // We don't need to re-init OpenGL or Inochi2D
    if (glInit) return;
    glInit = true;

    // Load OpenGL and ensure that OpenGL 3.3 was supported, AT LEAST.
    auto support = loadOpenGL();
    if (support < GLSupport.gl33) {
        throw new Error("OpenGL 3.3 is not supported on this device. Inochi Creator and Inochi2D requires at least OpenGL 3.3 support.");
    }

    glEnable(GL_LINE_SMOOTH);
    glEnable(GL_MULTISAMPLE);
    glEnable(GL_CULL_FACE);

    // This needs to be run after GL initialization once
    inInit(&currTime);
}