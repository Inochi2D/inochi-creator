module creator.core.taskstack;
import core.thread.fiber;

private {
__gshared:
    Task[] tasks;
    string status_ = "No pending tasks...";
}

public:
/**
    A task
*/
struct Task {
    /**
        The name of the task
    */
    string name;

    /**
        The task's worker
    */
    Fiber worker;
}

/**
    Adds task to the list
*/
void incTaskAdd(string name, void delegate() worker) {
    tasks ~= Task(name, new Fiber(worker));
}

/**
    Sets the status of task
*/
void incTaskStatus(string status) {
    status_ = status;
}

/**
    Gets the curently posted status
*/
string incTaskGetStatus() {
    return status_;
}

/**
    Yields a task/fiber
*/
void incTaskYield() {
    Fiber.yield();
}

/**
    Updates tasks
*/
void incTaskUpdate() {
    if (tasks.length > 0) {
        if (tasks[0].worker.state != Fiber.State.TERM) {
            tasks[0].worker.call();
        } else {
            tasks = tasks[1..$];
        }

        if (tasks.length == 0) {
            incTaskStatus("No pending tasks...");
        }
    }
}