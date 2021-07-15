/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.actions;
public import creator.actions.node;

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