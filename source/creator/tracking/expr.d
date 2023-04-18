/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.tracking.expr;
import creator.tracking;
import ft;
import inochi2d;
import std.format;
import i18n;
import inmath.noise;
import std.random : uniform;


struct Expression {
private:
    // expression function name
    string exprName_;

    // source
    string expressionSource_;

    // last error
    string lastError_;

public:

    /**
        Constructs an expression
    */
    this(string signature, string source) {
        this.exprName_ = signature;
        this.expressionSource_ = source;
    }

    this(uint uuid, uint axis, string source) {
        this.exprName_ = "p%s_%s".format(uuid, axis);
        this.expressionSource_ = source;
    }

    /**
        Gets the expression to evaluate
    */
    string signature() {
        return exprName_;
    }

    /**
        Gets the expression to evaluate
    */
    string expression() {
        return expressionSource_;
    }

    /**
        Sets the expression to evaluate
    */
    bool expression(string value) {
        expressionSource_ = value;
        // hack
        return true;
    }

    /**
        Gets the last error encounted for the expression
    */
    string lastError() {
        return lastError_;
    }

}
