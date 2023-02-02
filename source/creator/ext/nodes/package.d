/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.ext.nodes;

public import creator.ext.nodes.expart;
public import creator.ext.nodes.excamera;

void incInitExtNodes() {
    incRegisterExPart();
    incRegisterExCamera();
}