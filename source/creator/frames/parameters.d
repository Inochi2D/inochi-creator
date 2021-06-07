module creator.frames.parameters;
import creator.frames;
import creator.widgets;
import creator;
import std.string;
import inochi2d;

/**
    Generates a parameter view
*/
void incParameterView(Parameter param) {

    igPushIDInt(param.uuid);
        incInputText("", param.name, 0);
    igPopID();
    igSeparator();
    
    // Each param vec mode needs to be rendered individually
    final switch(param.isVec2) {
        case true:
        case false:
            break;
    }
}

/**
    The logger frame
*/
class ParametersFrame : Frame {
private:

protected:
    override
    void onUpdate() {
        auto parameters = incActivePuppet().parameters;

        igBeginChildStr("ParametersList", ImVec2(0, -32), false, 0);
            foreach(param; parameters) {
                incParameterView(param);
            }
        igEndChild();
        if (igButton("+", ImVec2(32, 32))) {
            incActivePuppet().parameters ~= new Parameter(
                "New Parameter %d\0".format(parameters.length)
            );
        }

    }

public:
    this() {
        super("Parameters", true);
    }
}

/**
    Generate logger frame
*/
mixin incFrame!ParametersFrame;


