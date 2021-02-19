module creator.widgets.controller;
import inochi2d.math;
import inochi2d.core;
import gtk.DrawingArea;
import gdk.DrawingContext;
import cairo.Context;
import gtk.Widget;
import gdk.Event;
import std.format;

/**
    Controller modes

    More might be added later
*/
enum ControllerMode {
    X = 0x00,
    XY = 0x01
}

/**
    1 axis controller
*/
class Controller : DrawingArea {
private:
    enum P_RADIUS = 6;

    vec2 values = vec2(0);

    void updateValues() {

        // Mask out other modes
        auto mm = cast(ControllerMode)(mode & 0x01);

        switch(mm) {
            
            case ControllerMode.X:
                foreach(binding; bindings) {
                    binding.update(values.x);
                }
                break;
            
            case ControllerMode.XY:
                for(int i = 0; i < bindings.length; i += 2) {
                    // Update the X binding
                    bindings[i].update(values.x);

                    // Y binding *could* exist, if it doesn't
                    // we skip it.
                    if (i+1 < bindings.length) {
                        bindings[i+1].update(values.y);
                    }
                }
                break;
            
            // This should never be hit
            default: assert(0);
        }

        // Queue a redraw
        this.queueDraw();
    }


    bool isDragging;
    double mouseX, mouseY;
    void update(Event event) {
        switch(event.type) {

            case EventType.MOTION_NOTIFY:
                
                // We don't want to drag when we aren't in a dragging state
                if (!isDragging) break;

                int w = this.getAllocatedWidth();
                int h = this.getAllocatedHeight();
                event.getCoords(mouseX, mouseY);

                // Mask out other modes
                auto mm = cast(ControllerMode)(mode & 0x01);

                switch(mm) {
                    
                    case ControllerMode.X:
                        
                        double a = w-(P_RADIUS*2);
                        double p = clamp(mouseX-P_RADIUS, 0, a)/a;

                        values.x = p;
                        values.x = clamp(values.x, 0, 1);

                        this.updateValues();
                        break;
                    
                    case ControllerMode.XY:
                        
                        vec2 axy = vec2(
                            w-(P_RADIUS*2),
                            h-(P_RADIUS*2)
                        );

                        vec2 pxy = vec2(
                            clamp(mouseX-P_RADIUS, 0, axy.x)/axy.x,
                            clamp(mouseY-P_RADIUS, 0, axy.y)/axy.y
                        );

                        values = pxy;
                        values = vec2(
                            clamp(values.x, 0, 1),
                            clamp(values.y, 0, 1),
                        );

                        this.updateValues();
                        break;
                
                    // This should never be hit
                    default: assert(0);
                }
                break;
                

            case EventType.BUTTON_PRESS:
                isDragging = true;
                this.queueDraw();
                break;
                

            case EventType.BUTTON_RELEASE:
                isDragging = false;
                this.queueDraw();
                break;

            default: break;
        }
    }

    void render(Context ctx) {
        int w = this.getAllocatedWidth();
        int h = this.getAllocatedHeight();


        // Mask out other modes
        auto mm = cast(ControllerMode)(mode & 0x01);

        ctx.setFontSize(14);

        switch(mm) {
            
            case ControllerMode.X:

                // This draws the base line for the slider
                ctx.setLineCap(cairo_line_cap_t.ROUND);
                ctx.setSourceRgb(0.7, 0.7, 0.7);
                ctx.setLineWidth(P_RADIUS/2);
                ctx.moveTo(P_RADIUS, h/2);
                ctx.lineTo(w-P_RADIUS, h/2);
                ctx.stroke();

                // the position of the head based on length of the widget
                double p = cast(double)(w-(P_RADIUS*2))*values.x;

                ctx.setSourceRgb(1, 0, 0);
                ctx.arc(P_RADIUS+p, h/2, P_RADIUS, 0, 2.0*PI);
                ctx.fill();

                foreach(binding; bindings) {
                    
                    // TODO: Draw breakpoints for bindings
                }


                debug {
                    if (isDragging) {
                        string str = "%.2f".format(values.x);
                        cairo_text_extents_t extents;
                        ctx.textExtents(str, &extents);

                        ctx.setSourceRgb(1, 1, 1);
                        ctx.moveTo((P_RADIUS+p)-(extents.width/2), (h/2)-(extents.height/2));
                        ctx.showText(str);
                    }
                }
                break;

            case ControllerMode.XY:

                // Draw the midlines
                ctx.setSourceRgb(0.5, 0.5, 0.5);
                ctx.setLineWidth(P_RADIUS/2);
                ctx.moveTo(w/2,             P_RADIUS);
                ctx.lineTo(w/2,             h-(P_RADIUS));
                ctx.stroke();
                ctx.moveTo(P_RADIUS,        h/2);
                ctx.lineTo(w-(P_RADIUS),    h/2);
                ctx.stroke();

                // This draws the base line for the slider
                ctx.setLineCap(cairo_line_cap_t.ROUND);
                ctx.setLineJoin(cairo_line_join_t.ROUND);
                ctx.setSourceRgb(0.7, 0.7, 0.7);
                ctx.setLineWidth(P_RADIUS/2);
                ctx.moveTo(P_RADIUS, P_RADIUS);
                ctx.lineTo(w-P_RADIUS, P_RADIUS);
                ctx.lineTo(w-P_RADIUS, h-P_RADIUS);
                ctx.lineTo(P_RADIUS, h-P_RADIUS);
                ctx.closePath();
                ctx.stroke();

                // the position of the head based on length of the widget
                vec2 pxy = vec2(
                    cast(double)(w-(P_RADIUS*2))*values.x,
                    cast(double)(h-(P_RADIUS*2))*values.y
                );

                ctx.setSourceRgb(1, 0, 0);
                ctx.arc(P_RADIUS+pxy.x, P_RADIUS+pxy.y, P_RADIUS, 0, 2.0*PI);
                ctx.fill();


                debug {
                    if (isDragging) {
                        string str = "%.2f, %.2f".format(values.x, values.y);
                        cairo_text_extents_t extents;
                        ctx.textExtents(str, &extents);

                        ctx.setSourceRgb(1, 1, 1);
                        ctx.moveTo((P_RADIUS+pxy.x)-(extents.width/2), (P_RADIUS+pxy.y)-(extents.height/2));
                        ctx.showText(str);
                    }
                }
                break;
            
            // This should never be hit
            default: assert(0);
        }
    }

public:
    /**
        Mode for the controller
    */
    ControllerMode mode;

    /**
        Bindings to parameters
    */
    ParameterBinding[] bindings;

    /**
        Constructor
    */
    this() {
        this.addOnDraw((Scoped!Context ctx, Widget _) { this.render(ctx); return false; });
        this.addOnMotionNotify((Event ev, Widget) { this.update(ev); return false; });
        this.addOnButtonPress((Event ev, Widget) { this.update(ev); return false; });
        this.addOnButtonRelease((Event ev, Widget) { this.update(ev); return false; });

        // Make sure values are actually in range
        if (isNaN(values.x)) values.x = 0;
        if (isNaN(values.y)) values.y = 0;
    }

    /**
        Constructor
    */
    this(ControllerMode mode) {
        this.mode = mode;
        this();
    }

    /**
        Constructor
    */
    this(ControllerMode mode, ParameterBinding[] bindings) {
        this.bindings = bindings;
        this(mode);
    }

    /**
        Sets the value of the controller
    */
    float getValue() {
        return values.x;
    }
    
    /**
        Gets the X/Y value pair for this controller
    */
    vec2 getValues() {
        return values;
    }

    /**
        Sets the value of the controller
    */
    void setValue(float val) {
        values.x = val;
        this.updateValues();
    }

    /**
        Sets the value for the controller
    */
    void setValue(vec2 vals) {
        values = vals;
        this.updateValues();
    }
}