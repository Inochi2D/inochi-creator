module core.glsurface;
import core.rinit;
import core.itime;
import gtk.GLArea;
import gtk.EventBox;
import gtk.Widget;
import bindbc.opengl;
import std.stdio;

abstract class GLSurface : EventBox {
private:
    GLArea viewport;
    int width, height;

    void onResize(int width, int height, GLArea area) {
        import inochi2d;
        inSetViewport(width, height);
    }

public:

    this() {
        
        // Set up viewport with GL 3.3 requirement
        viewport = new GLArea();
        viewport.setRequiredVersion(3, 3);

        viewport.addOnRealize((Widget widget) {
            this.width = widget.getAllocatedWidth();
            this.height = widget.getAllocatedHeight();

            viewport.setDoubleBuffered(true);

            // These are technically not needed but we're adding them anyways just in case we might need it later.
            viewport.setHasDepthBuffer(true);
            viewport.setHasStencilBuffer(true);

            // Make this context current, otherwise OpenGL won't init correctly
            viewport.makeCurrent();

            // Initialize OpenGL and Inochi2D renderer if needed
            initRenderer();

            this.init();

            // Make sure that we update this widget every timer tick
            viewport.addTickCallback((widget, fclock) {
                
                // Update our widget
                this.update(deltaTime());

                // Queue the widget for re-rendering, which calls onRender for the viewport
                widget.queueDraw();
                return G_SOURCE_CONTINUE;
            });
        });

        // Render the viewport, with GL context
        viewport.addOnRender((ctx, area) {
            
            // Clear the color buffer
            glClear(GL_COLOR_BUFFER_BIT);

            // Run our custom draw routine
            this.draw(deltaTime());
            
            // We always want to continue the frame clock
            return G_SOURCE_CONTINUE;
        });

        // Update viewport area on resize
        viewport.addOnResize(&onResize);

        // Set our child widget to the viewport, this will allow us to map the events to the child
        this.add(viewport);

        // Show ourself and our children
        this.showAll();
    }

    /**
        Resource initialization function
    */
    abstract void init();

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