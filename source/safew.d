module safew;
import std.traits;
import std.format;
version(Windows) {
    import crashdump : crashdump;
    import core.stdc.stdlib : exit, EXIT_FAILURE;

    private void terminate(Throwable t) {
        crashdump(t, state);
        exit(EXIT_FAILURE);
    }
}

/**
    Safely wraps callbacks

    On Windows any uncaught exceptions caught will instantly print a crashdump and exit the application
*/
auto safeWrapCallback(T, string file = __FILE__, int line = __LINE__)(T func) {

    version(Windows) {

        // Let the dev know that a safe wrapper has been applied
        pragma(msg, "[SafeWrapCallback %s:%s] Wrapped %s in a safe delegate wrapper".format(file, line, T.stringof));

        // Windows wrapper
        return cast(ReturnType!T delegate(Parameters!T))(Parameters!T args) {
            try { 
                static if (is(ReturnType!T == void)) {
                    func(args);
                } else return func(args);
            } 
            catch (Throwable t) { terminate(t); assert(0); }
        };

    } else {
        // Other platforms don't need wrappers yet
        return func;
    }
}

/**
    Safely executes code from a C delegate

    On Windows any uncaught exceptions caught will instantly print a crashdump and exit the application
*/
void safeExec(void delegate() dg) {
    try {
        dg();
    } catch(Throwable t) {
        
        // Early terminate if needed with crashdump
        version(Windows) terminate(t);
        else throw t;
    }
}