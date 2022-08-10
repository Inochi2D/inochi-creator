/*
    Copyright © 2020,2022 Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
*/
module creator.actions.mesheditor;

import creator.core.actionstack;
import creator.viewport.common.mesheditor;
import creator.viewport.common.mesh;
import creator.viewport.vertex;
import creator.viewport.common.spline;
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
    IncMeshEditor  self;
    Parameter      param;
    Drawable       target;
    DeformationParameterBinding    deform;
    bool oldIsSet;
    bool newIsSet;
    vec2[] oldVertices;
    vec2[] newVertices;
    vec2u  keypoint;

    this(string name, IncMeshEditor self, void delegate() update = null) {
        this.name   = name;
        this.self   = self;
        this.clear();

        if (update !is null) {
            update();
            this.updateNewState();
        }
    }

    void addVertex(MeshVertex* vertex) {
    }

    void markAsDirty() { dirty = true; }

    void updateNewState() {
        newVertices = self.getOffsets();
        this.newIsSet    = deform.isSet_[keypoint.x][keypoint.y];
    }

    void clear() {
        this.target      = self.getTarget();
        this.param       = incArmedParameter();
        this.keypoint    = param.findClosestKeypoint();
        this.oldVertices = self.getOffsets();
        this.newVertices = null;
        this.deform      = cast(DeformationParameterBinding)param.getOrAddBinding(this.target, "deform");
        this.oldIsSet    = deform.isSet_[keypoint.x][keypoint.y];
        this.dirty       = false;
    }

    bool isApplyable() {
        return self.getTarget() == this.target && incArmedParameter() == this.param &&
               incArmedParameter().findClosestKeypoint() == this.keypoint;
    }

    /**
        Rollback
    */
    void rollback() {
        deform.update(this.keypoint, oldVertices);
        deform.isSet_[keypoint.x][keypoint.y] = oldIsSet;
        deform.reInterpolate();
        if (isApplyable() && self.getOffsets().length == this.oldVertices.length) {
            self.mesh.setBackOffsets(oldVertices);
        }
        self.getCleanDeformAction();
    }

    /**
        Redo
    */
    void redo() {
        if (newVertices) {
            deform.update(this.keypoint, newVertices);
            deform.isSet_[keypoint.x][keypoint.y] = newIsSet;
            deform.reInterpolate();
            if (isApplyable() && self.getOffsets().length == this.newVertices.length) {
                self.mesh.setBackOffsets(newVertices);
            }
            self.getCleanDeformAction();
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
    CatmullSpline path;
    SplinePoint[] oldPathPoints;
    SplinePoint[] oldTargetPathPoints;
    SplinePoint[] newPathPoints;
    SplinePoint[] newTargetPathPoints;

    this(string name, IncMeshEditor self, CatmullSpline path, void delegate() update = null) {
        this.path = path;
        super(name, self, update);
        oldPathPoints = this.path.points.dup;
        if (this.path.target !is null)
            oldTargetPathPoints = this.path.target.points.dup;
    }

    override
    void updateNewState() {
        super.updateNewState();
        newPathPoints = this.path.points.dup;
        if (this.path.target !is null) 
            newTargetPathPoints = this.path.target.points.dup;
    }

    override
    void clear() {
        super.clear();
        oldPathPoints = this.path.points.dup;
        if (this.path.target !is null)
            oldTargetPathPoints = this.path.target.points.dup;
        newPathPoints = null;
        newTargetPathPoints = null;
    }

    /**
        Rollback
    */
    override
    void rollback() {
        if (self.getTarget() == this.target && incArmedParameter() == this.param &&
            incArmedParameter().findClosestKeypoint() == this.keypoint) {
            if (oldPathPoints !is null && oldPathPoints.length > 0) {
                this.path.points = oldPathPoints.dup;
                this.path.update();
            }
            if (oldTargetPathPoints !is null && oldTargetPathPoints.length > 0) {
                this.path.target.points = oldTargetPathPoints.dup;
                this.path.target.update();
                this.path.target.updateTarget(self.mesh);
            }
            this.self.refreshMesh();
        }
        super.rollback();
    }

    /**
        Redo
    */
    override
    void redo() {
         if (self.getTarget() == this.target && incArmedParameter() == this.param &&
            incArmedParameter().findClosestKeypoint() == this.keypoint) {
            if (newPathPoints !is null && newPathPoints.length > 0) {
                this.path.points = newPathPoints.dup;
                this.path.update();
            }
            if (newTargetPathPoints !is null && newTargetPathPoints.length > 0) {
                this.path.target.points = newTargetPathPoints.dup;
                this.path.target.update();
                this.path.updateTarget(self.mesh);
            }
            this.self.refreshMesh();
        }
        super.redo();
   }
}