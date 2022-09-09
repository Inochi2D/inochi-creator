/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
/// Extensions to Inochi2D only used in Inochi Creator
module creator.ext;
public import creator.ext.nodes;
public import creator.ext.param;

void incInitExt() {
    incInitExtNodes();
    incRegisterExParameter();
}
