/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.utils.repair;
import inochi2d;

private {
}

/**
    Attempts to repair a corrupt puppet
*/
void incAttemptRepairPuppet(Puppet p) {

    // Attempt to repair node IDs
    incRegenerateNodeIDs(p.root);

    // Finish off by rescanning nodes.
    p.rescanNodes();
}

/**
    Attempts to repair puppet IDs
*/
void incRegenerateNodeIDs(Node n) {
    foreach(child; n.children) {
        incRegenerateNodeIDs(child);
    }

    // Force a new UUID
    n.forceSetUUID(inCreateUUID());
}