module creator.actions.binding;

import creator.core.actionstack;
import creator.actions;
import creator;
import inochi2d;
import std.format;
import std.stdio;
import std.range;
import i18n;


/**
    Action for add / remove of binding
*/
class ParameterBindingAddRemoveAction(bool added = true) : Action {
public:
    Parameter        parent;
    ParameterBinding self;

    this(Parameter parent, ParameterBinding self) {
        this.parent = parent;
        this.self   = self;
    }

    /**
        Rollback
    */
    void rollback() {
        if (!added)
            parent.bindings ~= self;
        else
            parent.removeBinding(self);
    }

    /**
        Redo
    */
    void redo() {
        if (added)
            parent.bindings ~= self;
        else
            parent.removeBinding(self);
    }

    /**
        Describe the action
    */
    string describe() {
        if (added)
            return _("Added binding %s").format(self.getName());
        else
            return _("Removed binding %s").format(self.getName());
    }

    /**
        Describe the action
    */
    string describeUndo() {
        if (added)
            return _("Binding %s was removed").format(self.getName());
        else
            return _("Binding %s was added").format(self.getName());
    }

    /**
        Gets name of this action
    */
    string getName() {
        return this.stringof;
    }
    
    bool merge(Action other) { return false; }
    bool canMerge(Action other) { return false; }
}

alias ParameterBindingAddAction    = ParameterBindingAddRemoveAction!true;
alias ParameterBindingRemoveAction = ParameterBindingAddRemoveAction!false;

T[][] duplicate(T)(ref T[][] source) {
    T[][] target = source.dup;
    foreach (i, s; source) {
        target[i] = s.dup;
    }
    return target;
}

void copy(T)(ref T[][] source, ref T[][] target) {
    foreach (sarray, tarray; zip(source, target)) {
        foreach (i, s; sarray) {
            tarray[i] = s;
        }
    }
}

/**
    Action for change of binding values at once
*/
class ParameterBindingAllValueChangeAction(T)  : LazyBoundAction {
    alias TSelf    = typeof(this);
    alias TBinding = ParameterBindingImpl!(T);
    string   name;
    TBinding self;
    T[][]    oldValues;
    bool[][] oldIsSet;
    T[][]    newValues;
    bool[][] newIsSet;

    this(string name, TBinding self, void delegate() update = null) {
        this.name = name;
        this.self = self;
        oldValues = duplicate!T(self.values);
        oldIsSet  = duplicate!bool(self.isSet_);
        if (update !is null) {
            update();
            updateNewState();
        }
    }

    void updateNewState() {
        newValues = duplicate!T(self.values);
        newIsSet  = duplicate!bool(self.isSet_);
    }

    /**
        Rollback
    */
    void rollback() {
        copy(oldValues, self.values);
        copy(oldIsSet, self.isSet_);
    }

    /**
        Redo
    */
    void redo() {
        copy(newValues, self.values);
        copy(newIsSet, self.isSet_);
    }

    /**
        Describe the action
    */
    string describe() {
        return _("%s->%s changed").format(self.getName(), name);
    }

    /**
        Describe the action
    */
    string describeUndo() {
        return _("%s->%s chang cancelled").format(self.getName(), name);
    }

    /**
        Gets name of this action
    */
    string getName() {
        return this.stringof;
    }
    
    /**
        Merge
    */
    bool merge(Action other) {
        if (this.canMerge(other)) {
            this.newValues = (cast(TSelf)other).newValues;
            return true;
        }
        return false;
    }

    /**
        Gets whether this node can merge with an other
    */
    bool canMerge(Action other) {
        TSelf otherChange = cast(TSelf) other;
        return (otherChange !is null && this.name == otherChange.name);
    }
};


/**
    Action for change of binding values at specified position
*/
class ParameterBindingValueChangeAction(T)  : LazyBoundAction {
    alias TSelf    = typeof(this);
    string name;
    alias TBinding = ParameterBindingImpl!(T);
    TBinding self;
    int  pointx;
    int  pointy;
    T    oldValue;
    bool oldIsSet;
    T    newValue;
    bool newIsSet;

    this(string name, TBinding self, int pointx, int pointy, void delegate() update = null) {
        this.name  = name;
        this.self  = self;
        this.pointx = pointx;
        this.pointy = pointy;
        oldValue  = self.values[pointx][pointy];
        oldIsSet  = self.isSet_[pointx][pointy];
        if (update !is null) {
            update();
            updateNewState();
        }
    }

    void updateNewState() {
        newValue = self.values[pointx][pointy];
        newIsSet = self.isSet_[pointx][pointy];
    }

    /**
        Rollback
    */
    void rollback() {
        self.values[pointx][pointy] = oldValue;
        self.isSet_[pointx][pointy] = oldIsSet;
        self.reInterpolate();
    }

    /**
        Redo
    */
    void redo() {
        self.values[pointx][pointy] = newValue;
        self.isSet_[pointx][pointy] = newIsSet;
        self.reInterpolate();
    }

    /**
        Describe the action
    */
    string describe() {
        return _("%s->%s changed").format(self.getName(), name);
    }

    /**
        Describe the action
    */
    string describeUndo() {
        return _("%s->%s chang cancelled").format(self.getName(), name);
    }

    /**
        Gets name of this action
    */
    string getName() {
        return this.stringof;
    }
    
    /**
        Merge
    */
    bool merge(Action other) {
        if (this.canMerge(other)) {
            this.newValue = (cast(TSelf)other).newValue;
            return true;
        }
        return false;
    }

    /**
        Gets whether this node can merge with an other
    */
    bool canMerge(Action other) {
        TSelf otherChange = cast(TSelf) other;
        return (otherChange !is null && this.name == otherChange.name && this.pointx == otherChange.pointx && this.pointy == otherChange.pointy);
    }
};