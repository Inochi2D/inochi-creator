module core.itime;
import core.time;
import gtk.Widget;

/// Alias for a fast monotonic time clock
alias FastMonoTime = MonoTimeImpl!(ClockType.coarse);

private {
    double startTime_;
    double prevTime_;
    double currTime_;
    double deltaTime_;

    double currHwTime() {

        // Get the current Monotonic time using MonoTimeImpl!(ClockType.coarse), as aliased above
        auto time = FastMonoTime.currTime();
        
        //     | total msecs casted to double    | Initialize Duration with hnsecs function because Duration's constructor is private
        return cast(double)                      hnsecs(

            //            | time      | ticks per sec      | 1 second in hecto-nanoseconds
            convClockFreq(time.ticks, time.ticksPerSecond, 10_000_000)
        
        //                | We want the format to be (seconds).(milliseconds), convert it to that format.
        ).total!"msecs" / 1000.0;
    }
}

/**
    Register time update tick on a widget

    This should be registered to the root window.
*/
void registerUpdateTick(Widget window) {

    // Reset time so that we have a time reference based on app start
    resetTime();

    // Our tick callback that updates the time
    window.addTickCallback((widget, fclock) {

        updateTime();

        // We want to continue calling this tick callback
        return G_SOURCE_CONTINUE;
    });
}

/**
    Time updater function, updates delta time
*/
void updateTime() {
    currTime_ = currHwTime() - startTime_;
    deltaTime_ = currTime_-prevTime_;
    prevTime_ = currTime_;
}

/**
    Gets the current time since app start
*/
double currTime() {
    return currTime_;
}

/**
    Gets amount of time since last frame clock update
*/
double deltaTime() {
    return deltaTime_;
}

void resetTime() {
    import core.time;
    prevTime_ = 0;
    currTime_ = 0;
    startTime_ = currHwTime();
}