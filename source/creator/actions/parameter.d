/*
    Copyright © 2020-2023,2022 Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
*/
module creator.actions.parameter;

import creator.core.actionstack;
import creator.actions;
import creator.ext;
import creator.actions.binding;
import creator;
import inochi2d;
import std.format;
import i18n;
import std.algorithm.searching: countUntil;

/**
    Action to add parameter to active puppet.
*/
class ParameterAddRemoveAction(bool added = true) : Action {
public:
    Parameter self;
    Driver[] drivers;
    Parameter[]* parentList;
    ExParameterGroup originalParent;
    long indexInGroup;

    this(Parameter self, Parameter[]* parentList) {
        this.self = self;
        this.parentList = parentList;

        auto exParam = cast(ExParameter)self;
        originalParent = (exParam !is null)? exParam.getParent(): null;
        indexInGroup = -1;

        // Find drivers
        foreach(ref driver; incActivePuppet().getDrivers()) {
            if (SimplePhysics sf = cast(SimplePhysics)driver) {
                if (sf.param !is null && sf.param.uuid == self.uuid) {
                    drivers ~= driver;
                }
            }
        }

        // Empty drivers
        foreach(ref driver; drivers) {
            if (SimplePhysics sf = cast(SimplePhysics)driver) {
                sf.param = null;
            }
        }
        incActivePuppet().root.notifyChange(incActivePuppet().root, NotifyReason.StructureChanged);
    }

    import std.stdio;
    /**
        Rollback
    */
    void rollback() {
        auto newParent = originalParent;
        auto newIndex = indexInGroup;
        auto exParam = cast(ExParameter)self;
        if (exParam !is null) {
            originalParent = exParam.getParent();
            indexInGroup = originalParent? originalParent.children.countUntil(exParam): -1;
        }
        if (!added) {
            incActivePuppet().parameters ~= self;
            if (exParam !is null)
                exParam.setParent(newParent);
        } else {

            incActivePuppet().removeParameter(self);
        }
            
        // Re-apply drivers
        foreach(ref driver; drivers) {
            if (SimplePhysics sf = cast(SimplePhysics)driver) {
                sf.param = self;
            }
        }
        incActivePuppet().root.notifyChange(incActivePuppet().root, NotifyReason.StructureChanged);
    }

    /**
        Redo
    */
    void redo() {
        auto newParent = originalParent;
        auto newIndex = indexInGroup;
        auto exParam = cast(ExParameter)self;
        if (exParam !is null) {
            originalParent = exParam.getParent();
            indexInGroup = originalParent? originalParent.children.countUntil(exParam): -1;
        }
        if (added) {
            incActivePuppet().parameters ~= self;
            if (exParam !is null)
                exParam.setParent(newParent);
        } else {
            incActivePuppet().removeParameter(self);
        }
            
        // Empty drivers
        foreach(ref driver; drivers) {
            if (SimplePhysics sf = cast(SimplePhysics)driver) {
                sf.param = null;
            }
        }
        incActivePuppet().root.notifyChange(incActivePuppet().root, NotifyReason.StructureChanged);
    }

    /**
        Describe the action
    */
    string describe() {
        if (added)
            return _("Added parameter %s").format(self.name);
        else
            return _("Removed parameter %s").format(self.name);
    }

    /**
        Describe the action
    */
    string describeUndo() {
        if (added)
            return _("Parameter %s was removed").format(self.name);
        else
            return _("Parameter %s was added").format(self.name);
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

alias ParameterAddAction = ParameterAddRemoveAction!true;
alias ParameterRemoveAction = ParameterAddRemoveAction!false;


/**
    Action to remove parameter from active puppet.
*/
class ParameterValueChangeAction(T) : LazyBoundAction {
public:
    alias TSelf = typeof(this);
    string name;
    Parameter self;
    T oldValue;
    T newValue;
    T* valuePtr;

    this(string name, Parameter self, T oldValue, T newValue, T* valuePtr) {
        this.name     = name;
        this.self     = self;
        this.oldValue = oldValue;
        this.newValue = newValue;
        this.valuePtr = valuePtr;
    }

    this(string name, Parameter self, T* valuePtr, void delegate() update = null) {
        this.name     = name;
        this.self     = self;
        this.valuePtr = valuePtr;
        this.oldValue = *valuePtr;
        if (update !is null) {
            update();
            updateNewState();
        }
    }

    void updateNewState() {
        this.newValue = *valuePtr;
    }

    void clear() { }

    /**
        Rollback
    */
    void rollback() {
        *valuePtr = oldValue;
    }

    /**
        Redo
    */
    void redo() {
        *valuePtr = newValue;
    }

    /**
        Describe the action
    */
    string describe() {
        if (name == "axis points")
            return _("%s->%s changed").format(self.name, name);
        else
            return _("%s->%s changed to %s").format(self.name, name, newValue);
    }

    /**
        Describe the action
    */
    string describeUndo() {
        if (name == "axis points")
            return _("%s->%s change cancelled").format(self.name, name);
        else
            return _("%s->%s changed from %s").format(self.name, name, oldValue);
    }

    /**
        Gets name of this action
    */
    string getName() {
        return name;
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
        return (otherChange !is null && this.name == otherChange.name);
    }
}

/**
    Base class for actions to change multiple bindings of the same parameter at once.
*/
class AbstractParameterChangeBindingsAction(VarArg...) : GroupAction, LazyBoundAction {
public:
    alias TSelf = typeof(this);
    string name;
    Parameter self;

    this(string name, Parameter self, ParameterBinding[] bindings, Action function(ParameterBinding, VarArg) bindingActionMapper, VarArg args) {
        super([]);
        this.name     = name;
        this.self     = self;
        foreach (binding; (bindings !is null)? bindings: self.bindings) {
            Action action = bindingActionMapper(binding, args);
            if (action !is null) 
                addAction(action);
        }
    }

    override
    void updateNewState() {
        foreach (action; actions) {
            LazyBoundAction lazyAction = cast(LazyBoundAction)action;
            if (lazyAction !is null) 
                lazyAction.updateNewState();
        }
    }

    override
    void clear() {}

    /**
        Describe the action
    */
    override
    string describe() {
        return _("%s->%s changed").format(self.name, name);
    }

    /**
        Describe the action
    */
    override
    string describeUndo() {
        return _("%s->%s change cancelled").format(self.name, name);
    }

    /**
        Gets name of this action
    */
    override
    string getName() {
        return name;
    }
}


/**
    Actions to add bindings to parameter at once.
*/

Action BindingAddMapper(ParameterBinding binding, Parameter parent) {
    return new ParameterBindingAddAction(parent, binding);
}
class ParameterAddBindingsAction : AbstractParameterChangeBindingsAction!(Parameter) {
    this(string name, Parameter self, ParameterBinding[] bindings) {
        super(name, self, bindings, &BindingAddMapper, self);
    }
}


/**
    Actions to remove bindings from parameter at once.
*/

Action BindingRemoveMapper(ParameterBinding binding, Parameter parent) {
    return new ParameterBindingRemoveAction(parent, binding);
}
class ParameterRemoveBindingsAction : AbstractParameterChangeBindingsAction!(Parameter) {
    this(string name, Parameter self, ParameterBinding[] bindings) {
        super(name, self, bindings, &BindingRemoveMapper, self);
    }
}


/**
    Actions to change all binding values at once.
*/

Action BindingChangeMapper(ParameterBinding binding) {
    if (auto typedBinding = cast(ParameterBindingImpl!float)binding) {
        return new ParameterBindingAllValueChangeAction!(float)(typedBinding.getName(), typedBinding);
    } else if (auto typedBinding = cast(ParameterBindingImpl!Deformation)binding) {
        return new ParameterBindingAllValueChangeAction!(Deformation)(typedBinding.getName(), typedBinding);
    } else {
        return null;
    }
}
class ParameterChangeBindingsAction : AbstractParameterChangeBindingsAction!() {
    this(string name, Parameter self, ParameterBinding[] bindings) {
        super(name, self, bindings, &BindingChangeMapper);
    }
}


/**
    Actions to change binding value of specified keypoints at once.
*/

Action BindingValueChangeMapper(ParameterBinding binding, int pointx, int pointy) {
    if (auto typedBinding = cast(ParameterBindingImpl!float)binding) {
        return new ParameterBindingValueChangeAction!(float)(typedBinding.getName(), typedBinding, pointx, pointy);
    } else if (auto typedBinding = cast(ParameterBindingImpl!Deformation)binding) {
        return new ParameterBindingValueChangeAction!(Deformation)(typedBinding.getName(), typedBinding, pointx, pointy);
    } else {
        return null;
    }
}
class ParameterChangeBindingsValueAction : AbstractParameterChangeBindingsAction!(int, int) {
    this(string name, Parameter self, ParameterBinding[] bindings, int pointx, int pointy) {
        super(name, self, bindings, &BindingValueChangeMapper, pointx, pointy);
    }
}