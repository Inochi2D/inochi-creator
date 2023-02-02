/*
    Copyright © 2020-2023, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.widgets.secrets;

bool isTransMonthOfVisibility;
static this() {
    import std.datetime : Date, SysTime, Clock, Month;
    auto time = Clock.currTime();

    isTransMonthOfVisibility = time.month == Month.nov;

}