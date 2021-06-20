module creator.actions.node;
import creator.core.actionstack;
import creator.actions;
import creator;
import inochi2d;
import std.format;

/**
    An action that happens when a node is changed
*/
class NodeChangeAction : Action {
public:
    /**
        Creates a new node change action
    */
    this(Node prev, Node self, Node new_) {
        this.prevParent = prev;
        this.self = self;
        this.newParent = new_;
    }

    /**
        Previous parent of node
    */
    Node prevParent;

    /**
        Node itself
    */
    Node self;

    /**
        New parent of node
    */
    Node newParent;

    /**
        Rollback
    */
    void rollback() {
        self.parent = prevParent;
        incActivePuppet().rescanNodes();
    }

    /**
        Redo
    */
    void redo() {
        self.parent = newParent;
        incActivePuppet().rescanNodes();
    }

    /**
        Describe the action
    */
    string describe() {
        if (prevParent is null) return "Created %s".format(self.name);
        if (newParent is null) return "Deleted %s".format(self.name);
        return "Moved %s to %s".format(self.name, newParent.name);
    }

    /**
        Describe the action
    */
    string describeUndo() {
        if (prevParent is null) return "Created %s".format(self.name);
        return "Moved %s from %s".format(self.name, prevParent.name);
    }
}

/**
    Action for whether a node was activated or deactivated
*/
class NodeActiveAction : Action {
public:
    Node self;
    bool newState;

    /**
        Rollback
    */
    void rollback() {
        self.enabled = !newState;
    }

    /**
        Redo
    */
    void redo() {
        self.enabled = newState;
    }

    /**
        Describe the action
    */
    string describe() {
        return "%s %s".format(newState ? "Enabled" : "Disabled", self.name);
    }

    /**
        Describe the action
    */
    string describeUndo() {
        return "%s was %s".format(self.name, !newState ? "Enabled" : "Disabled");
    }
}


/**
    Moves child with history
*/
void incMoveChildWithHistory(Node n, Node to) {
    // Push action to stack
    incActionPush(new NodeChangeAction(
        n.parent,
        n,
        to
    ));
    n.parent = to;
    incActivePuppet().rescanNodes();
}

/**
    Adds child with history
*/
void incAddChildWithHistory(Node n, Node to, string name=null) {
    if (to is null) to = incActivePuppet().root;

    // Push action to stack
    incActionPush(new NodeChangeAction(
        null,
        n,
        to
    ));

    n.parent = to;
    if (name is null) n.name = "Unnamed "~n.typeId();
    else n.name = name;
    incActivePuppet().rescanNodes();
}

/**
    Deletes child with history
*/
void incDeleteChildWithHistory(Node n) {
    // Push action to stack
    incActionPush(new NodeChangeAction(
        n.parent,
        n,
        null
    ));

    n.parent = null;
    incActivePuppet().rescanNodes();
}