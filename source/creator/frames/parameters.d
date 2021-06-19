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

    igPushID_Int(param.uuid);
        incInputText("", param.name, ImGuiInputTextFlags.None);
    igPopID();
    igNewLine();
    incController("Test", param, ImVec2(0, 128));
    param.isVec2 = true;
    igText("%.2f %.2f", param.handle.x, param.handle.y);
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

        igBeginChild_Str("ParametersList", ImVec2(0, -32), false);
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


