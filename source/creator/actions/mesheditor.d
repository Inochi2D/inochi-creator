/*
    Copyright © 2020,2022 Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
*/
module creator.actions.mesheditor;

import creator.core.actionstack;
import creator.viewport.common.mesheditor;
import creator.viewport.common.mesh;
import creator.viewport.common.spline;
import creator.viewport.model.deform;
import creator.viewport.vertex;
import creator.viewport;
import creator.actions;
import creator;
import inochi2d;
import std.format;
import std.range;
import i18n;

/**
    Action for change of binding values at once
*/
class MeshEditorDeformationAction  : LazyBoundAction {
    alias  TSelf    = typeof(this);
    string name;
    bool dirty;
    Parameter      param;
    Drawable       target;
    DeformationParameterBinding    deform;
    bool isSet;
    vec2[] vertices;
    vec2u  keypoint;
    bool bindingAdded;
    bool undoable = true;

    this(string name, void delegate() update = null) {
        this.name   = name;
        this.bindingAdded = false;
        this.clear();

        if (update !is null) {
            update();
            this.updateNewState();
        }
    }

    auto self() {
        return incViewportModelDeformGetEditor();
    }

    void addVertex(MeshVertex* vertex) {
    }

    void markAsDirty() { dirty = true; }

    void updateNewState() {
        auto newDeform      = cast(DeformationParameterBinding)param.getBinding(this.target, "deform");
        if (deform is null && newDeform !is null)
            bindingAdded = true;
        deform = newDeform;
    }

    void clear() {
        if (self is null) {
            target       = null;
            param        = null;
            deform       = null;
            bindingAdded = false;
            dirty        = false;
            vertices     = null;
            isSet        = false;
        } else {
            target       = self.getTarget();
            param        = incArmedParameter();
            keypoint     = param.findClosestKeypoint();
            vertices     = self.getOffsets();
            deform       = cast(DeformationParameterBinding)param.getBinding(this.target, "deform");
            bindingAdded = false;
        }
        if (deform !is null) {
            isSet    = deform.isSet_[keypoint.x][keypoint.y];
        }
        this.dirty       = false;
    }

    bool isApplyable() {
        return self !is null && self.getTarget() == this.target && incArmedParameter() == this.param &&
               incArmedParameter().findClosestKeypoint() == this.keypoint;
    }

    /**
        Rollback
    */
    void rollback() {
        if (undoable) {
            if (vertices) {
                if (deform !is null) {
                    vec2[] tmpVertices = vertices;
                    bool   tmpIsSet    = isSet;
                    vertices = deform.values[keypoint.x][keypoint.y].vertexOffsets.dup;
                    isSet    = deform.isSet_[keypoint.x][keypoint.y];
                    deform.update(this.keypoint, tmpVertices);
                    deform.isSet_[keypoint.x][keypoint.y] = tmpIsSet;
                    deform.reInterpolate();
                    if (bindingAdded) {
                        param.removeBinding(deform);
                    }
                }
                if (self !is null && self.getTarget() == this.target && incArmedParameter() == this.param) {
                    self.resetMesh();
                    if (deform !is null) {
                        self.applyOffsets(deform.getValue(param.findClosestKeypoint()).vertexOffsets);            
                    }
                }
                self.getCleanDeformAction();
            }
            undoable = false;
        }
    }

    /**
        Redo
    */
    void redo() {
        if (!undoable) {
            if (vertices) {
                if (deform !is null) {
                    vec2[] tmpVertices = vertices;
                    bool   tmpIsSet    = isSet;
                    vertices = deform.values[keypoint.x][keypoint.y].vertexOffsets.dup;
                    isSet    = deform.isSet_[keypoint.x][keypoint.y];
                    deform.update(this.keypoint, tmpVertices);
                    deform.isSet_[keypoint.x][keypoint.y] = tmpIsSet;
                    deform.reInterpolate();
                    if (bindingAdded) {
                        param.addBinding(deform);
                    }
                }
                if (self !is null && self.getTarget() == this.target && incArmedParameter() == this.param) {
                    self.resetMesh();
                    if (deform !is null) {
                        self.applyOffsets(deform.getValue(param.findClosestKeypoint()).vertexOffsets);
                    }
                }
                self.getCleanDeformAction();
            }
            undoable = true;
        }
    }

    /**
        Describe the action
    */
    string describe() {
        return _("%s->Edited deformation of %s.").format("deform", name);
    }

    /**
        Describe the action
    */
    string describeUndo() {
        return _("%s->deformation of %s was edited.").format("deform", name);
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
            return true;
        }
        return false;
    }

    /**
        Gets whether this node can merge with an other
    */
    bool canMerge(Action other) {
        return false;
    }
};

class MeshEditorPathDeformAction : MeshEditorDeformationAction {
public:
//    CatmullSpline path;
    SplinePoint[] oldPathPoints;
    SplinePoint[] oldTargetPathPoints;
    SplinePoint[] newPathPoints;
    SplinePoint[] newTargetPathPoints;

    auto path() {
        return self.getPath();
    }

    this(string name, void delegate() update = null) {
        super(name, update);
        if (path !is null)
            oldPathPoints = path.points.dup;
        else
            oldPathPoints = null;
        if (this.path.target !is null)
            oldTargetPathPoints = this.path.target.points.dup;
        else
            oldTargetPathPoints = null;
    }

    override
    void updateNewState() {
        super.updateNewState();
        if (path !is null)
        newPathPoints = path.points.dup;
        if (path !is null && path.target !is null) 
            newTargetPathPoints = path.target.points.dup;
    }

    override
    void clear() {
        super.clear();
        if (path !is null)
            oldPathPoints = path.points.dup;
        else
            oldPathPoints = null;
        if (path !is null && path.target !is null)
            oldTargetPathPoints = path.target.points.dup;
        else
            oldTargetPathPoints = null;
        newPathPoints = null;
        newTargetPathPoints = null;
    }

    /**
        Rollback
    */
    override
    void rollback() {
        if (isApplyable()) {
            if (oldPathPoints !is null && oldPathPoints.length > 0 && path !is null) {
                path.points = oldPathPoints.dup;
                path.update();
            }
            if (oldTargetPathPoints !is null && oldTargetPathPoints.length > 0 && path !is null && path.target !is null) {
                path.target.points = oldTargetPathPoints.dup;
                path.target.update();
            }
        }
        super.rollback();
    }

    /**
        Redo
    */
    override
    void redo() {
         if (isApplyable()) {
            if (newPathPoints !is null && newPathPoints.length > 0) {
                this.path.points = newPathPoints.dup;
                this.path.update();
            }
            if (newTargetPathPoints !is null && newTargetPathPoints.length > 0) {
                this.path.target.points = newTargetPathPoints.dup;
                this.path.target.update();
            }
        }
        super.redo();
   }
}