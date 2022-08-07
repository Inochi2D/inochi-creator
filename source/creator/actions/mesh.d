module creator.actions.mesh;

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
    }

    void clear() {
        this.target      = self.getTarget();
        this.param       = incArmedParameter();
        this.keypoint    = param.findClosestKeypoint();
        this.oldVertices = self.getOffsets();
        this.newVertices = null;
        this.deform      = cast(DeformationParameterBinding)param.getOrAddBinding(this.target, "deform");
        this.dirty       = false;
    }

    /**
        Rollback
    */
    void rollback() {
        deform.update(this.keypoint, oldVertices);
        if (self.getTarget() == this.target && incArmedParameter() == this.param &&
            incArmedParameter().findClosestKeypoint() == this.keypoint &&
            self.getOffsets().length == this.oldVertices.length) {

            self.mesh.setBackOffsets(oldVertices);
        }
    }

    /**
        Redo
    */
    void redo() {
        if (newVertices) {
            deform.update(this.keypoint, newVertices);
            if (self.getTarget() == this.target && incArmedParameter() == this.param &&
                incArmedParameter().findClosestKeypoint() == this.keypoint &&
                self.getOffsets().length == this.newVertices.length) {

                self.mesh.setBackOffsets(newVertices);
            }
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
