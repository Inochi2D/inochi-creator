module creator.core.actionstack;
import creator.core.settings;
import creator.actions;
import inochi2d;

private {
    Action[] actions;
    size_t actionPointer;
    size_t actionIndex;
    size_t maxUndoHistory;
}

/**
    Initialize actions system
*/
void incActionInit() {
    maxUndoHistory = incSettingsGet!size_t("MaxUndoHistory", 100);
}

/**
    Pushes a new action to the stack
*/
void incActionPush(Action action) {
    
    // Chop away entries outside undo history
    if (actions.length > incActionGetUndoHistoryLength()) {
        size_t toChop = actions.length-incActionGetUndoHistoryLength();
        actions = actions[toChop..$];
    }

    if (incActionTop() !is null && incActionTop().canMerge(action)) {
        incActionTop().merge(action);
        incActionNotifyTopChanged();
    } else {
        // Add to the history
        actions = actions[0..actionPointer]~action;
        actionPointer++;
    }
}

/**
    Steps back in the action stack
*/
void incActionUndo() {
    actionPointer--;
    if (cast(ptrdiff_t)actionPointer < 0) {
        actionPointer = 0;
        return;
    }
    actions[actionPointer].rollback();
}

/**
    Steps forward in the action stack
*/
void incActionRedo() {
    if (actionPointer >= actions.length) {
        actionPointer = actions.length-1;
        return;
    }
    actions[actionPointer].redo();
    actionPointer++;
}

/**
    Gets whether undo is possible
*/
bool incActionCanUndo() {
    return actionPointer > 0;
}

/**
    Gets whether redo is possible
*/
bool incActionCanRedo() {
    return actionPointer < actions.length;
}

/**
    Gets the action history
*/
Action[] incActionHistory() {
    return actions;
}

/**
    Index of the current action
*/
size_t incActionIndex() {
    return actionPointer;
}

/**
    Gets the "top" action
*/
Action incActionTop() {
    return actionPointer > 0 && actionPointer <= actions.length ? actions[actionPointer-1] : null;
}

/**
    Notify that the top action has changed
*/
void incActionNotifyTopChanged() {
    actions.length = actionPointer;
}

/**
    Sets max undo history length
*/
void incActionSetUndoHistoryLength(size_t length) {
    length = clamp(length, 0, 1000);
    maxUndoHistory = length;
    incSettingsSet("MaxUndoHistory", maxUndoHistory);
}

/**
    Gets max undo history
*/
size_t incActionGetUndoHistoryLength() {
    return maxUndoHistory;
}

/**
    Sets the action index
    Indexes start at 1, 0 is reserved for the INTIAL index
*/
void incActionSetIndex(size_t index) {
    if (index > actions.length) {
        index = actions.length;
    }

    if (index == 0) {

        // Undo till we can't anymore
        while (incActionCanUndo()) incActionUndo();
    }

    if (index < actionPointer) {
        while (index < actionPointer) incActionUndo();
    } else if (cast(ptrdiff_t)index > cast(ptrdiff_t)actionPointer) {
        while (cast(ptrdiff_t)index > cast(ptrdiff_t)actionPointer) incActionRedo();
    }
}

/**
    Clears action history
*/
void incActionClearHistory() {
    actions.length = 0;
    actionPointer = 0;
}