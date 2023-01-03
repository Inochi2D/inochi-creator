/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.actions;
public import creator.actions.node;
public import creator.actions.parameter;
public import creator.actions.binding;
public import creator.actions.mesheditor;
public import creator.actions.drawable;

/**
    An undo/redo-able action
*/
interface Action {
    /**
        Roll back the action that was done
    */
    void rollback();

    /**
        Redo the action that was done
    */
    void redo();

    /**
        Describes the action
    */
    string describe();

    /**
        Describes the action
    */
    string describeUndo();

    /**
        Gets the name of the action
    */
    string getName();

    /**
        Merge action with other action (if possible)

        returns true if merge was successful
    */
    bool merge(Action other);

    /**
        Gets whether this action can merge with an other
    */
    bool canMerge(Action other);
}

/**
   Special case of actions which captures the status of the target to implement undo/redo.
   Action is instantiated before executing any change to the target. status is captured by
   Action implementation. Later, updateState is called after change is applied to the target.
   New status is captured by Action implementation then.
*/
interface LazyBoundAction : Action {
    /** 
     * Confirm 'redo' state from the current status of the target.
     */
    void updateNewState();
}



/**
    Grouping several actions into one undo/redo action.
*/
class GroupAction : Action {
public:
    Action[] actions;

    this(Action[] actions = []) {
        this.actions = actions;
    }

    void addAction(Action action) {
        this.actions ~= action;
    }

    /**
        Rollback
    */
    void rollback() {
        foreach_reverse (action; actions) {
            action.rollback();
        }
    }

    /**
        Redo
    */
    void redo() {
        foreach (action; actions) {
            action.redo();
        }
    }

    /**
        Describe the action
    */
    string describe() {
        string result;
        foreach (action; actions) {
            result ~= action.describe();
        }
        return result;
    }

    /**
        Describe the action
    */
    string describeUndo() {
        string result;
        foreach_reverse (action; actions) {
            result ~= action.describeUndo();
        }
        return result;
    }

    /**
        Gets name of this action
    */
    string getName() {
        return this.stringof;
    }
    
    bool merge(Action other) { return false; }
    bool canMerge(Action other) { return false; }

    bool empty() { return actions.length == 0; }
}