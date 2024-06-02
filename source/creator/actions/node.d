/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.actions.node;
import creator.core.actionstack;
import creator.actions;
import creator;
import inochi2d;
import std.format;
import i18n;
import std.exception;
import std.array: insertInPlace;
import std.algorithm.mutation: remove;
import std.algorithm.searching;

/**
    An action that happens when a node is changed
*/
class NodeMoveAction : Action {
public:

    /**
        Descriptive name
    */
    string descrName;
    
    /**
        Which index in to the parent the nodes should be placed
    */
    size_t parentOffset;
    float[uint] zSort;

    /**
        Previous parent of node
    */
    Node[uint] prevParents;
    size_t[uint] prevOffsets;

    /**
        Nodes that was moved
    */
    Node[] nodes;

    /**
        New parent of node
    */
    Node newParent;

    /**
        The original transform of the node
    */
    Transform[uint] originalTransform;

    /**
        The new transform of the node
    */
    Transform[uint] newTransform;

    /**
        Creates a new node change action
    */
    this(Node[] nodes, Node new_, size_t pOffset = 0) {
        this.newParent = new_;
        this.nodes = nodes;
        this.parentOffset = pOffset;

        // Enforce reparenting rules
        foreach(sn; nodes) enforce(sn.canReparent(new_), _("%s can not be reparented in to %s due to a circular dependency.").format(sn.name, new_.name));
        
        // Reparent
        foreach(ref sn; nodes) {
            
            // Store ref to prev parent
            if (sn.parent) {
                originalTransform[sn.uuid] = sn.localTransform;
                prevParents[sn.uuid] = sn.parent;
                prevOffsets[sn.uuid] = sn.getIndexInParent();
                zSort[sn.uuid] = sn.zSort;
            }

            // Set relative position
            if (new_) {
                sn.reparent(new_, pOffset);
                sn.transformChanged();
            } else sn.parent = null;
            newTransform[sn.uuid] = sn.localTransform;
        }
        incActivePuppet().rescanNodes();
    
        // Set visual name
        if (nodes.length == 1) descrName = nodes[0].name;
        else descrName = _("nodes");
    }

    /**
        Rollback
    */
    void rollback() {
        foreach(ref sn; nodes) {
            if (sn.uuid in prevParents && prevParents[sn.uuid]) {
                if (!sn.lockToRoot()) sn.setRelativeTo(prevParents[sn.uuid]);
                sn.reparent(prevParents[sn.uuid], prevOffsets[sn.uuid]);
                if (sn.uuid in zSort) {
                    sn.zSort = zSort[sn.uuid] - prevParents[sn.uuid].zSort();
                }
                sn.localTransform = originalTransform[sn.uuid];
                sn.transformChanged();
            } else sn.parent = null;
        }
        incActivePuppet().rescanNodes();
    }

    /**
        Redo
    */
    void redo() {
        foreach(sn; nodes) {
            if (newParent) {
                if (!sn.lockToRoot()) sn.setRelativeTo(newParent);
                sn.reparent(newParent, parentOffset);
                sn.localTransform = newTransform[sn.uuid];
                sn.transformChanged();
            } else sn.parent = null;
        }
        incActivePuppet().rescanNodes();
    }

    /**
        Describe the action
    */
    string describe() {
        if (prevParents.length == 0) return _("Created %s").format(descrName);
        if (newParent is null) return _("Deleted %s").format(descrName);
        return _("Moved %s to %s").format(descrName, newParent.name);
    }

    /**
        Describe the action
    */
    string describeUndo() {
        if (prevParents.length == 0) return _("Created %s").format(descrName);
        if (nodes.length == 1 && prevParents.length == 1 && prevParents.values[0]) return  _("Moved %s from %s").format(descrName, prevParents[nodes[0].uuid].name);
        return _("Moved %s from origin").format(descrName);
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
    An action that happens when a node is replaced
*/
class NodeReplaceAction : Action {
    /**
      Update the binding target of parameters.
      This function must be called after redo / undo operations are done.
     */
    void updateParameterBindings() {
        auto parent = srcNode.parent;
        auto src = toNode;
        auto to  = srcNode;
        if (toNode.parent !is null) {
            parent = toNode.parent;
            src = srcNode;
            to  = toNode;
        }
        assert(parent.puppet !is null);
        auto parameters = parent.puppet.parameters;
        foreach (param; parameters) {
            foreach (binding; param.bindings) {
                if (binding.getTarget().node == src) {
                    binding.setTarget(to, binding.getTarget().paramName);
                }
            }
        }
    }
public:

    /**
        Descriptive name
    */
    string descrName;
    
    /**
        Nodes that was moved
    */
    Node srcNode;
    Node toNode;
    Node[] children;
    bool deepCopy;

    /**
        Creates a new node change action
    */
    this(Node src, Node to, bool deepCopy) {
        srcNode = src;
        toNode = to;

        if (src.parent !is null)
            children = src.children.dup;
        else if (to.parent !is null)
            children = to.children.dup;

        if (cast(Part)toNode !is null) {
            deepCopy = false;
        }
        this.deepCopy = deepCopy;

        // Set visual name
        descrName = src.name;

        if (toNode.parent is null)
            redo();

        updateParameterBindings();
    }

    /**
        Rollback
    */
    void rollback() {
        auto parent = toNode.parent;
        assert(parent !is null);
        ulong pOffset = parent.children.countUntil(toNode);
        Transform tmpTransform = toNode.transform;
        toNode.reparent(null, 0);
        toNode.localTransform = tmpTransform;
        srcNode.reparent(parent, pOffset);
        updateParameterBindings();
        if (deepCopy) {
            foreach (i, child; children) {
                child.reparent(srcNode, i);
            }
        }
    }

    /**
        Redo
    */
    void redo() {
        auto parent = srcNode.parent;
        assert(parent !is null);
        ulong pOffset = parent.children.countUntil(srcNode);
        Transform tmpTransform = srcNode.transform;
        srcNode.reparent(null, 0);
        srcNode.localTransform = tmpTransform;
        toNode.reparent(parent, pOffset);
        updateParameterBindings();
        if (deepCopy) {
            foreach (i, child; children) {
                child.reparent(toNode, i);
            }
        }
    }

    /**
        Describe the action
    */
    string describe() {
        return _("Change type of %s to %s").format(descrName, toNode.typeId);
    }

    /**
        Describe the action
    */
    string describeUndo() {
        return _("Revert type of %s to %s").format(descrName, srcNode.typeId);
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
    An action that happens when a node is changed
*/
class PartAddRemoveMaskAction(bool addAction = false) : Action {
public:

    /**
        Previous parent of node
    */
    Part target;
    MaskingMode mode;
    size_t offset;
    Drawable maskSrc;

    /**
        Creates a new node change action
    */
    this(Drawable drawable, Part target, MaskingMode mode) {
        this.maskSrc = drawable;
        this.target = target;

        if (addAction) {
            offset = target.masks.length;
            target.masks ~= MaskBinding(maskSrc.uuid, mode, drawable);

        } else {
            foreach (i, masker; target.masks) {
                if (masker.maskSrc == maskSrc) {
                    offset = i;
                    target.masks = target.masks.remove(i);
                    break;
                }
            }
        }
        incActivePuppet().rescanNodes();
    }

    /**
        Rollback
    */
    void rollback() {
        if (addAction) {
            target.masks = target.masks.remove(offset);
        } else {
            target.masks.insertInPlace(offset, MaskBinding(maskSrc.uuid, mode, maskSrc));
        }
        incActivePuppet().rescanNodes();
    }

    /**
        Redo
    */
    void redo() {
        if (addAction) {
            target.masks.insertInPlace(offset, MaskBinding(maskSrc.uuid, mode, maskSrc));
        } else {
            target.masks = target.masks.remove(offset);
        }
        incActivePuppet().rescanNodes();
    }

    /**
        Describe the action
    */
    string describe() {
        if (addAction) return _("%s is added to mask of %s").format(maskSrc.name, target.name);
        else return _("%s is deleted from mask of %s").format(maskSrc.name, target.name);
    }

    /**
        Describe the action
    */
    string describeUndo() {
        if (addAction) return _("%s is deleted from mask of %s").format(maskSrc.name, target.name);
        else return _("%s is added to mask of %s").format(maskSrc.name, target.name);
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

alias PartAddMaskAction = PartAddRemoveMaskAction!true;
alias PartRemoveMaskAction = PartAddRemoveMaskAction!false;
/**
    An action that happens when a node is changed
*/
class DrawableAddRemoveWeldingAction(bool addAction = false) : Action {
public:

    /**
        Previous parent of node
    */
    Drawable drawable;
    size_t offset;
    Drawable target;
    ptrdiff_t[] weldedVertexIndices;
    float weight;

    /**
        Creates a new node change action
    */
    this(Drawable drawable, Drawable target, ptrdiff_t[] weldedVertexIndices = null, float weight = -1) {
        this.drawable = drawable;
        this.target = target;

        if (weldedVertexIndices is null || weight < 0) {
            auto idx = drawable.welded.countUntil!((a)=>a.target == target);
            if (idx >= 0) {
                Drawable.WeldingLink link = drawable.welded[idx];
                if (weldedVertexIndices is null) {
                    weldedVertexIndices = link.indices;
                }
                if (weight < 0) {
                    weight = link.weight;
                }
            } else {
                throw new Exception("DrawableAddRemoveWeldingAction is created without any specific parameters.");
            }
        }

        this.weight = weight;
        this.weldedVertexIndices = weldedVertexIndices;

        if (addAction) {
            offset = drawable.welded.length;
            drawable.addWeldedTarget(target, weldedVertexIndices, weight);

        } else {
            drawable.removeWeldedTarget(target);
        }
        incActivePuppet().rescanNodes();
    }

    /**
        Rollback
    */
    void rollback() {
        if (addAction) {
            drawable.removeWeldedTarget(target);
        } else {
            drawable.addWeldedTarget(target, weldedVertexIndices, weight);
        }
        incActivePuppet().rescanNodes();
    }

    /**
        Redo
    */
    void redo() {
        if (addAction) {
            drawable.addWeldedTarget(target, weldedVertexIndices, weight);
        } else {
            drawable.removeWeldedTarget(target);
        }
        incActivePuppet().rescanNodes();
    }

    /**
        Describe the action
    */
    string describe() {
        if (addAction) return _("%s is added to welded targets of %s").format(target.name, drawable.name);
        else return _("%s is deleted from welded targets of %s").format(target.name, drawable.name);
    }

    /**
        Describe the action
    */
    string describeUndo() {
        if (addAction) return _("%s is deleted from welded targets of %s").format(target.name, drawable.name);
        else return _("%s is added to welded targets of %s").format(target.name, drawable.name);
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

alias DrawableAddWeldingAction = DrawableAddRemoveWeldingAction!true;
alias DrawableRemoveWeldingAction = DrawableAddRemoveWeldingAction!false;

/**
    An action that happens when a node is changed
*/
class DrawableChangeWeldingAction : Action {
public:

    /**
        Previous parent of node
    */
    Drawable drawable;
    Drawable.WeldingLink* link;
    Drawable.WeldingLink* counterLink;
    float oldWeight;
    float newWeight;
    float oldCounterWeight;
    float newCounterWeight;
    ptrdiff_t[] oldIndices;
    ptrdiff_t[] newIndices;
    ptrdiff_t[] oldCounterIndices;
    ptrdiff_t[] newCounterIndices;

    /**
        Creates a new node change action
    */
    this(Drawable drawable, Drawable target, ptrdiff_t[] weldedVertexIndices, float weight) {
        this.drawable = drawable;
        auto index = drawable.welded.countUntil!((a)=>a.target == target)();
        auto counterIndex = target.welded.countUntil!((a)=>a.target == drawable);
        if (index >= 0 && counterIndex >= 0) {
            link = &(drawable.welded[index]);
            counterLink = &(target.welded[counterIndex]);

            ptrdiff_t[] counterWeldedVertexIndices;
            counterWeldedVertexIndices.length = target.vertices.length;
            counterWeldedVertexIndices[0..$] = -1;
            foreach (i, ind; weldedVertexIndices) {
                if (ind != -1)
                    counterWeldedVertexIndices[ind] = i;
            }

            oldWeight = link.weight;
            newWeight = weight;
            oldCounterWeight = counterLink.weight;
            newCounterWeight = 1 - weight;
            oldIndices = link.indices[];
            oldCounterIndices = counterLink.indices[];
            newIndices = weldedVertexIndices;
            newCounterIndices = counterWeldedVertexIndices;
            redo();
        }
    }

    /**
        Rollback
    */
    void rollback() {
        if (link) {
            link.weight = oldWeight;
            link.indices = oldIndices;
            counterLink.weight = oldCounterWeight;
            counterLink.indices = oldCounterIndices;
        }
    }

    /**
        Redo
    */
    void redo() {
        if (link) {
            link.weight = newWeight;
            link.indices = newIndices;
            counterLink.weight = newCounterWeight;
            counterLink.indices = newCounterIndices;
            import std.stdio;
        }
    }

    /**
        Describe the action
    */
    string describe() {
        return _("links of %s and %s are changed.").format(drawable.name, link.target.name);
    }

    /**
        Describe the action
    */
    string describeUndo() {
        return _("links of %s and %s are restored.").format(drawable.name, link.target.name);
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
        self.setEnabled(!newState);
    }

    /**
        Redo
    */
    void redo() {
        self.setEnabled(newState);
    }

    /**
        Describe the action
    */
    string describe() {
        return "%s %s".format(newState ? _("Enabled") : _("Disabled"), self.name);
    }

    /**
        Describe the action
    */
    string describeUndo() {
        return _("%s was %s").format(self.name, !newState ? _("Enabled") : _("Disabled"));
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
    Moves multiple children with history
*/
void incMoveChildrenWithHistory(Node[] n, Node to, size_t offset) {
    // Push action to stack
    incActionPush(new NodeMoveAction(
        n,
        to,
        offset
    ));
}

/**
    Moves child with history
*/
void incMoveChildWithHistory(Node n, Node to, size_t offset) {
    incMoveChildrenWithHistory([n], to, offset);
}

/**
    Adds child with history
*/
void incAddChildWithHistory(Node n, Node to, string name=null) {
    if (to is null) to = incActivePuppet().root;

    // Push action to stack
    incActionPush(new NodeMoveAction(
        [n],
        to
    ));

    n.insertInto(to, Node.OFFSET_START);
    n.localTransform.clear();
    if (name is null) n.name = _("Unnamed ")~_(n.typeId());
    else n.name = name;
    incActivePuppet().rescanNodes();
}

GroupAction incDeleteMaskOfNode(Node n, GroupAction group = null) {
    auto removedDrawables = incActivePuppet().findNodesType!Drawable(n);
    auto parts = incActivePuppet().findNodesType!Part(incActivePuppet().root);
    foreach (drawable; removedDrawables) {
        foreach (target; parts) {
            auto idx = target.getMaskIdx(drawable);
            if (idx >= 0) {
                if (group is null)
                    group = new GroupAction();
                group.addAction(new PartRemoveMaskAction(drawable, target, target.masks[idx].mode));
            }
        }
    }
    return group;
}

GroupAction incDeleteWeldedLinksOfNode(Node n, GroupAction group = null) {
    auto removedDrawables = incActivePuppet().findNodesType!Drawable(n);
    auto parts = incActivePuppet().findNodesType!Part(incActivePuppet().root);
    foreach (drawable; removedDrawables) {
        foreach (target; parts) {
            if (target.isWeldedBy(drawable)) {
                if (group is null)
                    group = new GroupAction();
                group.addAction(new DrawableRemoveWeldingAction(drawable, target));
            }
        }
    }
    return group;
}
/**
    Deletes child with history
*/
void incDeleteChildWithHistory(Node n) {
    auto group = incDeleteMaskOfNode(n);
    group = incDeleteWeldedLinksOfNode(n, group);
    if (group !is null) {
        group.addAction(new NodeMoveAction(
            [n],
            null
        ));
        incActionPush(group);
    } else {
        // Push action to stack
        incActionPush(new NodeMoveAction(
            [n],
            null
        ));
    }
    
    incActivePuppet().rescanNodes();
}

/**
    Deletes child with history
*/
void incDeleteChildrenWithHistory(Node[] ns) {
    GroupAction group = null;
    foreach (n; ns) {
        incDeleteMaskOfNode(n, group);
    }
    if (group !is null) {
        // Push action to stack
        group.addAction(new NodeMoveAction(
            ns,
            null
        ));
        incActionPush(group);
    } else {
        // Push action to stack
        incActionPush(new NodeMoveAction(
            ns,
            null
        ));
    }

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
        return _("%s->%s changed to %s").format(node.name, name, newValue);
    }

    /**
        Describe the action
    */
    string describeUndo() {
        return _("%s->%s changed from %s").format(node.name, name, oldValue);
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

class NodeRootBaseSetAction : Action {
public:
    alias TSelf = typeof(this);
    Node node;
    bool origState;
    bool state;


    this(Node n, bool state) {
        this.node = n;
        this.origState = n.lockToRoot;
        this.state = state;

        n.lockToRoot = this.state;
    }

    /**
        Rollback
    */
    void rollback() {
        this.node.lockToRoot = origState;
    }

    /**
        Redo
    */
    void redo() {
        this.node.lockToRoot = state;
    }

    /**
        Describe the action
    */
    string describe() {
        if (origState) return _("%s locked to root node").format(node.name);
        else return _("%s unlocked from root node").format(node.name);
    }

    /**
        Describe the action
    */
    string describeUndo() {
        if (state) return _("%s locked to root node").format(node.name);
        else return _("%s unlocked from root node").format(node.name);
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
            this.node.lockToRoot = !state;
            this.state = !state;
            return true;
        }
        return false;
    }

    /**
        Gets whether this node can merge with an other
    */
    bool canMerge(Action other) {
        TSelf otherChange = cast(TSelf) other;
        return otherChange && otherChange.node == this.node;
    }
}

/**
    Locks to root node
*/
void incLockToRootNode(Node n) {
    // Push action to stack
    incActionPush(new NodeRootBaseSetAction(
        n, 
        !n.lockToRoot
    ));
}