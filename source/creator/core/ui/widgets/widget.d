module creator.core.ui.widgets.widget;
import nulib.string;
import std.random : uniform;
import std.format : format;

/**
    Base class for widgets.
*/
abstract
class Widget {
private:
    uint discriminator;
    string id_;
    string name_;
    nstring imName_;

    void regenImName() {
        this.imName_.clear();
        this.imName_ = "%s###%s".format(name_, id_);
    }

protected:

    /**
        Called once a frame to update the widget.
    */
    abstract void onUpdate(float delta);

    /**
        Called when the widget needs to refresh all of its 
        information.
    */
    abstract void onRefresh();
    
    /**
        The ID of the widget.
    */
    final @property void id(string value) {
        if (discriminator == 0) {
            this.id_ = value;
            this.regenImName();
            return;
        }

        this.id_ = "%s%s".format(value, discriminator);
        this.regenImName();
    }

    /**
        The name of the widget.
    */
    final @property void name(string value) {
        this.name_ = value;
        this.regenImName();
    }

public:

    /**
        The ID of the widget.
    */
    final @property string id() { return id_[]; }

    /**
        The name of the widget.
    */
    final @property string name() { return name_[]; }

    /**
        The name of the widget.
    */
    final @property string imName() { return imName[]; }

    /**
        Destructor
    */
    ~this() {
        this.id_.clear();
    }

    /**
        Constructor
    */
    this(string id, bool randomize = true) {
        this.discriminator = randomize ? uniform(1, uint.max) : 0;
        this.id = id;
    }

    /**
        Called once a frame.
    */
    final
    void update(float delta) {
        this.onUpdate(delta);
    }

    /**
        Tells the widget to refresh all of its information.
    */
    final
    void refresh() { this.onRefresh(); }
}

/**
    A widget which contains other widgets.
*/
class Container : Widget {
private:
    Widget[] children_;

protected:

    /**
        Called once a frame to update the widget.
    */
    override
    void onUpdate(float delta) {
        foreach(child; children_) {
            child.update();
        }
    }

    /**
        Called when the widget needs to refresh all of its 
        information.
    */
    override
    void onRefresh() {
        foreach(child; children_) {
            child.refresh();
        }
    }

    /**
        Finds the location of a widget within the container.
    */
    final
    ptrdiff_t findWidget(Widget widget) {
        foreach(i, child; children_) {
            if (child == widget)
                return i;
        }
        return -1;
    }

public:

    /**
        A slice of the child widgets residing within this one.
    */
    final
    @property Widget[] children() {
        return children_[0..$];
    }
    
    /**
        Adds a widget to the container.
    */
    void add(Widget widget) {
        if (findWidget(widget) == -1)
            this.children_ ~= widget;
    }
    
    /**
        Removes a widget to the container.
    */
    void remove(Widget widget) {
        import std.algorithm.mutation : remove;

        ptrdiff_t idx = findWidget(widget);
        if (idx != -1)
            children_ = children_.remove(idx);
    }

    /**
        Constructor
    */
    this(string name, bool randomize = true) {
        super(name, randomize);
    }
}