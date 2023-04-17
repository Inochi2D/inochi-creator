/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.core.actionstack;
import creator.core.settings;
import creator.actions;
import inochi2d;

private {
    Action[][] actions;
    size_t currentLevel = 0;
    GroupAction[] currentGroup = null;
    size_t[] actionPointer;
    size_t[] actionIndex;
    size_t maxUndoHistory;
}

enum ActionStackClear {
    All, CurrentLevel
};

/**
    Initialize actions system
*/
void incActionInit() {
    maxUndoHistory = incSettingsGet!size_t("MaxUndoHistory", 100);
    actions.length = currentLevel + 1;
    actionPointer.length = currentLevel + 1;
    actionIndex.length = currentLevel + 1;
    currentGroup.length = currentLevel + 1;
}

/**
    Pushes a new action to the stack
*/
void incActionPush(Action action) {

    if (currentGroup[currentLevel] !is null) {
        currentGroup[currentLevel].addAction(action);
    } else {
    
        // Chop away entries outside undo history
        if (actionPointer[currentLevel]+1 > incActionGetUndoHistoryLength()) {
            size_t toChop = (actionPointer[currentLevel]+1)-incActionGetUndoHistoryLength();
            actions[currentLevel] = actions[currentLevel][toChop..$];
            actionPointer[currentLevel] -= toChop;
        }

        if (incActionTop() !is null && incActionTop().canMerge(action)) {
            incActionTop().merge(action);
            incActionNotifyTopChanged();
        } else {
            // Add to the history
            actions[currentLevel] = actions[currentLevel][0..actionPointer[currentLevel]]~action;
            actionPointer[currentLevel]++;
        }
    }
}

/**
    Steps back in the action stack
*/
void incActionUndo() {
    actionPointer[currentLevel]--;
    if (cast(ptrdiff_t)actionPointer[currentLevel] < 0) {
        actionPointer[currentLevel] = 0;
        return;
    }
    actions[currentLevel][actionPointer[currentLevel]].rollback();
}

/**
    Steps forward in the action stack
*/
void incActionRedo() {
    if (actionPointer[currentLevel] >= actions[currentLevel].length) {
        actionPointer[currentLevel] = actions[currentLevel].length;
        return;
    }
    actions[currentLevel][actionPointer[currentLevel]].redo();
    actionPointer[currentLevel]++;
}

/**
    Gets whether undo is possible
*/
bool incActionCanUndo() {
    return actionPointer[currentLevel] > 0;
}

/**
    Gets whether redo is possible
*/
bool incActionCanRedo() {
    return actionPointer[currentLevel] < actions[currentLevel].length;
}

/**
    Gets the action history
*/
Action[] incActionHistory() {
    return actions[currentLevel];
}

/**
    Index of the current action
*/
size_t incActionIndex() {
    return actionPointer[currentLevel];
}

/**
    Gets the "top" action
*/
Action incActionTop() {
    return actionPointer[currentLevel] > 0 && actionPointer[currentLevel] <= actions[currentLevel].length ? actions[currentLevel][actionPointer[currentLevel]-1] : null;
}

/**
    Notify that the top action has changed
*/
void incActionNotifyTopChanged() {
    actions[currentLevel].length = actionPointer[currentLevel];
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
    if (index > actions[currentLevel].length) {
        index = actions[currentLevel].length;
    }

    if (index == 0) {

        // Undo till we can't anymore
        while (incActionCanUndo()) incActionUndo();
    }

    if (index < actionPointer[currentLevel]) {
        while (index < actionPointer[currentLevel]) incActionUndo();
    } else if (cast(ptrdiff_t)index > cast(ptrdiff_t)actionPointer[currentLevel]) {
        while (cast(ptrdiff_t)index > cast(ptrdiff_t)actionPointer[currentLevel]) incActionRedo();
    }
}

/**
    Clears action history
*/
void incActionClearHistory(ActionStackClear target = ActionStackClear.All) {
    switch (target) {
    case ActionStackClear.All:
        currentLevel = 0;
        actions.length = currentLevel + 1;
        actionPointer.length = currentLevel + 1;
        actionIndex.length = currentLevel + 1;
        currentGroup.length = currentLevel + 1;
        actions[currentLevel].length = 0;
        actionPointer[currentLevel] = 0;
        currentGroup[currentLevel] = null;
        break;
    case ActionStackClear.CurrentLevel:
        actions[currentLevel].length = 0;
        actionPointer[currentLevel] = 0;
        currentGroup[currentLevel] = null;
        break;
    default:
    }
}

/**
    Push GroupAction to action stack.
    Subsequent Action is added to GroupAction.
    GroupAction is added to action stack when incActionPopGroup is called.
*/
void incActionPushGroup() {
    if (!currentGroup[currentLevel])
        currentGroup[currentLevel] = new GroupAction();
}

void incActionPopGroup() {
    if (currentGroup[currentLevel]) {
        auto group = currentGroup[currentLevel];
        currentGroup[currentLevel] = null;
        if (group !is null && !group.empty())
            incActionPush(group);
    }
}

void incActionPushStack() {
    ++ currentLevel;
    actions.length = currentLevel + 1;
    actionPointer.length = currentLevel + 1;
    actionIndex.length = currentLevel + 1;
    currentGroup.length = currentLevel + 1;
}

void incActionPopStack() {
    if (currentLevel > 0) {
        -- currentLevel;
        actions.length = currentLevel + 1;
        actionPointer.length = currentLevel + 1;
        actionIndex.length = currentLevel + 1;
        currentGroup.length = currentLevel + 1;
    }
}