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
}