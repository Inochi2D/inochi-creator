module core.glsurface;
import core.rinit;
import core.itime;
import gtk.GLArea;
import gtk.EventBox;
import gtk.Widget;
import bindbc.opengl;
import std.stdio;
import safew;
import gtk.Widget;
import gdk.GLContext;
import gtk.EventBox;

abstract class GLSurface : EventBox {
private:
    GLArea viewport;
    int width, height;

    void onResize(int width, int height, GLArea area) {
        import inochi2d : inSetViewport;
        this.width = width;
        this.height = height;
        inSetViewport(width, height);
    }

public:

    GLArea getGLArea(){
        return viewport;
    }

    /**
        Constructor
    */
    this() {
        viewport = new GLArea();
        viewport.setAutoRender(true);

        viewport.addOnCreateContext(safeWrapCallback((GLArea area) {
            auto ctx = area.getWindow().createGlContext();

            // We want OpenGL 4.2 Compatibility profile
            // Force backwards compatibility, so that NVIDIA GPUs work.
            ctx.setForwardCompatible(false);
            ctx.setRequiredVersion(4, 2);

            return ctx;
        }));

        viewport.addOnRealize(safeWrapCallback((Widget widget) {
            this.width = widget.getAllocatedWidth();
            this.height = widget.getAllocatedHeight();

            // These are technically not needed but we're adding them anyways just in case we might need it later.
            viewport.setDoubleBuffered(true);
            viewport.setHasDepthBuffer(true);
            viewport.setHasStencilBuffer(true);
            viewport.setHasAlpha(true);

            // Make this context current, otherwise OpenGL won't init correctly
            viewport.makeCurrent();

            // Initialize OpenGL and Inochi2D renderer if needed
            initRenderer();

            this.init();
        
        }));

        // Render the viewport, with GL context
        viewport.addOnRender(safeWrapCallback((GLContext ctx, GLArea area) {

            // Clear the color buffer
            glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

            // Run our custom draw routine
            this.draw(deltaTime());
            
            // We always want to continue the frame clock
            return true;
        }));

        // TODO: make this more robust
        onUpdateDelegates ~= () {
            // Update our widget
            this.update(deltaTime());

            // Queue the widget for re-rendering, which calls onRender for the viewport
            viewport.queueDraw();
        };

        // Update viewport area on resize
        viewport.addOnResize(safeWrapCallback(&onResize));

        // Set our child widget to the viewport, this will allow us to map the events to the child
        this.add(viewport);

        // Show ourself and our children
        this.showAll();
    }

    /**
        Resource initialization function
    */
    abstract void initialize();

    /**
        Update function
    */
    abstract void update(double deltaTime);

    /**
        Draw function
    */
    abstract void draw(double delta);

    /**
        Gets the underlying GLArea viewport
    */
    GLArea getViewport() {
        return viewport;
    }
}