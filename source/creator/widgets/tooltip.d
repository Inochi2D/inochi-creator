module creator.widgets.tooltip;
import creator.widgets;
import std.string;
import creator.core;

/**
    Creates a new tooltip
*/
void incTooltip(string tip) {
    if (igIsItemHovered()) {
        igBeginTooltip();

            igPushFont(incMainFont());
                igPushTextWrapPos(igGetFontSize() * 35);
                igTextUnformatted(tip.ptr, tip.ptr+tip.length);
                igPopTextWrapPos();
            igPopFont();

        igEndTooltip();
    }
}