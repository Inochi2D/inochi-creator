module creator.widgets.secrets;

bool isTransMonthOfVisibility;
static this() {
    import std.datetime : Date, SysTime, Clock, Month;
    auto time = Clock.currTime();

    isTransMonthOfVisibility = time.month == Month.nov;

}