module creator.actions.parameter;

import creator.core.actionstack;
import creator.actions;
import creator.actions.binding;
import creator;
import inochi2d;
import std.format;
import i18n;

/**
    Action for whether a parameter is created
*/
class ParameterAddRemoveAction(bool added = true) : Action {
public:
    Parameter self;

    this(Parameter self) {
        this.self = self;
    }

    /**
        Rollback
    */
    void rollback() {
        if (!added)
            incActivePuppet().parameters ~= self;
        else
            incActivePuppet().removeParameter(self);
    }

    /**
        Redo
    */
    void redo() {
        if (added)
            incActivePuppet().parameters ~= self;
        else
            incActivePuppet().removeParameter(self);
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
    Parameter value changed action
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
    Base class for actions to change bindings at once.
*/
class AbstractParameterChangeBindingsAction(VarArg...) : GroupAction, LazyBoundAction {
public:
    alias TSelf = typeof(this);
    string name;
    Parameter self;

    this(string name, Parameter self, Action function(ParameterBinding, VarArg) bindingActionMapper, VarArg args) {
        super([]);
        this.name     = name;
        this.self     = self;
        foreach (binding; self.bindings) {
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
    Actions to add bindings at once.
*/

Action BindingAddMapper(ParameterBinding binding, Parameter parent) {
    return new ParameterBindingAddAction(parent, binding);
}
class ParameterAddBindingsAction : AbstractParameterChangeBindingsAction!(Parameter) {
    this(string name, Parameter self) {
        super(name, self, &BindingAddMapper, self);
    }
}


/**
    Actions to remove bindings at once.
*/

Action BindingRemoveMapper(ParameterBinding binding, Parameter parent) {
    return new ParameterBindingRemoveAction(parent, binding);
}
class ParameterRemoveBindingsAction : AbstractParameterChangeBindingsAction!(Parameter) {
    this(string name, Parameter self) {
        super(name, self, &BindingRemoveMapper, self);
    }
}


/**
    Actions to change value array of bindings at once.
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
    this(string name, Parameter self) {
        super(name, self, &BindingChangeMapper);
    }
}


/**
    Actions to change value array of bindings at once.
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
    this(string name, Parameter self, int pointx, int pointy) {
        super(name, self, &BindingValueChangeMapper, pointx, pointy);
    }
}