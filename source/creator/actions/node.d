/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
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
    this(Node prev, Node self, Node new_, Transform prevPos, Transform newPos) {
        this.prevParent = prev;
        this.self = self;
        this.newParent = new_;
        this.originalTransform = prevPos;
        this.newTransform = newPos;
    }
    
    /**
        Creates a new node change action
    */
    this(Node prev, Node self, Node new_) {
        this.prevParent = prev;
        this.self = self;
        this.newParent = new_;

        this.originalTransform = self.localTransform;
        this.newTransform = self.localTransform;
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
        The original transform of the node
    */
    Transform originalTransform;

    /**
        The new transform of the node
    */
    Transform newTransform;

    /**
        Rollback
    */
    void rollback() {
        self.parent = prevParent;
        self.localTransform = originalTransform;
        incActivePuppet().rescanNodes();
    }

    /**
        Redo
    */
    void redo() {
        self.parent = newParent;
        self.localTransform = newTransform;
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

    /**
        Gets name of this action
    */
    string getName() {
        return this.stringof;
    }
    
    bool merge(Action other) { return false; }
    bool canMerge(Action other) { return false; }
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

    /**
        Gets name of this action
    */
    string getName() {
        return this.stringof;
    }
    
    bool merge(Action other) { return false; }
    bool canMerge(Action other) { return false; }
}

/**
    Moves child with history
*/
void incMoveChildWithHistory(Node n, Node to) {

    // Calculate transforms
    Transform currentLocal = n.localTransform;

    vec3 worldPosition = n.transform.translation;
    vec3 newParentWorldPosition = to.transform.translation;
    vec3 newPosition = worldPosition-newParentWorldPosition;

    // Push action to stack
    incActionPush(new NodeChangeAction(
        n.parent,
        n,
        to,
        currentLocal,
        Transform(newPosition)
    ));

    n.localTransform.translation = newPosition;
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

    n.insert(to, Node.OFFSET_START);
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

/**
    Node value changed action
*/
class NodeValueChangeAction(TNode, T) : Action if (is(TNode : Node)) {
public:
    alias TSelf = typeof(this);
    TNode node;
    T oldValue;
    T newValue;
    T* valuePtr;
    string name;

    this(string name, TNode node, T oldValue, T newValue, T* valuePtr) {
        this.name = name;
        this.node = node;
        this.oldValue = oldValue;
        this.newValue = newValue;
        this.valuePtr = valuePtr;
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
        return "%s->%s changed to %s".format(node.name, name, newValue);
    }

    /**
        Describe the action
    */
    string describeUndo() {
        return "%s->%s changed from %s".format(node.name, name, oldValue);
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
        return (otherChange !is null && otherChange.getName() == this.getName());
    }
}