
module creator.viewport.model.onionslice;

import inochi2d.core.texture;
import inochi2d.utils.snapshot;
import inochi2d;
import creator;
import std.stdio;

class OnionSlice {
private:
    int numHistory;
    Texture[] history;
    Snapshot  snapshot;
    int lastIndex;
    float opacity_;
    vec3 color_;
    vec2u lastKeypoint;
    this() {
        numHistory = 2;
        history.length = numHistory;
        lastIndex = 0;
        snapshot = null;
        opacity_ = 0.2f;
        color_ = vec3(1, 1, 1);
        lastKeypoint = vec2u(0, 0);
    }

    static OnionSlice instance;

public:
    static OnionSlice singleton() {
        if (instance is null) {
            instance = new OnionSlice();
        }
        return instance;
    }

    void start() {
        if (snapshot is null) {
            snapshot = Snapshot.get(incActivePuppet());
        }
    }

    void stop() {
        if (snapshot !is null) {
            snapshot.release();
            snapshot = null;
            foreach (i; 0..history.length) {
                if (history[i] !is null)
                    history[i].dispose();
                history[i] = null;
            }
        }
    }

    void toggle() {
        if (enabled()) {
            stop();
        } else {
            start();
        }
    }

    void capture(vec2u keypoint) {
        if (snapshot !is null) {
            if (keypoint == lastKeypoint) return;
            lastKeypoint = keypoint;
            if (history[lastIndex] !is null) {
                history[lastIndex].dispose();
            }
            history[lastIndex] = snapshot.capture().dup();
            lastIndex = (lastIndex + 1)%numHistory;
        }
    }

    void draw() {
        if (enabled && incArmedParameter()) {
            for (int i = 0; i < numHistory - 1; i ++) {
                auto index = (lastIndex + i)%numHistory;
                if (history[index] !is null) {
                    inDrawTextureAtPosition(history[index], snapshot.position(), opacity_ * (i+2) * (i+2) * (i+2) / numHistory / numHistory / numHistory, color_);
                }
            }
        }
    }

    bool enabled() { return snapshot !is null; }
}
