/*
    Copyright © 2020,2022 Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
*/
module creator.actions.binding;

import creator.core.actionstack;
import creator.actions;
import creator;
import inochi2d;
import std.format;
import std.stdio;
import std.range;
import std.algorithm.mutation;
import i18n;

private {
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

}

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

/**
    Action for change of all of binding values (and isSet value) at once
*/
class ParameterBindingAllValueChangeAction(T)  : LazyBoundAction {
    alias TSelf    = typeof(this);
    alias TBinding = ParameterBindingImpl!(T);
    string   name;
    TBinding self;
    T[][] values;
    bool[][] isSet;
    bool undoable = true;

    this(string name, TBinding self, void delegate() update = null) {
        this.name = name;
        this.self = self;
        values = duplicate!T(self.values);
        isSet  = duplicate!bool(self.isSet_);
        if (update !is null) {
            update();
            updateNewState();
        }
    }

    void updateNewState() {
    }

    /**
        Rollback
    */
    void rollback() {
        if (undoable) {
            swap(values, self.values);
            swap(isSet, self.isSet_);
            undoable = false;
        }
    }

    /**
        Redo
    */
    void redo() {
        if (!undoable) {
            swap(values, self.values);
            swap(isSet, self.isSet_);
            undoable = true;
        }
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
    Action to change binding value (and isSet) of specified keypoint.
*/
class ParameterBindingValueChangeAction(T)  : LazyBoundAction {
    alias TSelf    = typeof(this);
    string name;
    alias TBinding = ParameterBindingImpl!(T);
    TBinding self;
    int  pointx;
    int  pointy;
    T    value;
    bool isSet;
    bool undoable;

    this(string name, TBinding self, int pointx, int pointy, void delegate() update = null) {
        this.name  = name;
        this.self  = self;
        this.pointx = pointx;
        this.pointy = pointy;
        this.value  = self.values[pointx][pointy];
        this.isSet  = self.isSet_[pointx][pointy];
        this.undoable = true;
        if (update !is null) {
            update();
            updateNewState();
        }
    }

    void updateNewState() {
    }

    /**
        Rollback
    */
    void rollback() {
        if (undoable) {
            swap(self.values[pointx][pointy], value);
            swap(self.isSet_[pointx][pointy], isSet);
            import std.stdio;
            self.reInterpolate();
            undoable = false;
        }
    }

    /**
        Redo
    */
    void redo() {
        if (!undoable) {
            swap(self.values[pointx][pointy], value);
            swap(self.isSet_[pointx][pointy], isSet);
            self.reInterpolate();
            undoable = true;
        }
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