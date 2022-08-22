/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.core.egg;
import creator.core;
import inochi2d;
import bindbc.sdl;
import bindbc.opengl;
import std.stdio;
import std.random;

version(InBranding) {
    private {
        int logoClickCounter;
        float adaStartTime;
        float adaCurrTime;
        vec2 adaOffset;
        vec2 adaVelocity;
        enum ADA_SIZE = 396;
        enum CLICK_THRESH = 25;

        enum JUMP_SPEED_X = 500;
        enum JUMP_SPEED_Y = 700;
        bool lhs;
        Camera cam;
    }

    void incAdaTickOne() {
        logoClickCounter++;
        if (logoClickCounter == CLICK_THRESH) {
            lhs = !lhs;

            float uiScale = incGetUIScale();
            int w, h;
            SDL_GetWindowSize(incGetWindowPtr(), &w, &h);

            float adaHalf = (ADA_SIZE*uiScale)/2;
            float hws = (w/2)/uiScale;

            // Alternate jumping from left and right
            float spawnX = lhs ? uniform(-(hws+adaHalf), -adaHalf) : uniform(adaHalf, hws-adaHalf);
            float dirX = (lhs ? uniform(-JUMP_SPEED_X, -100) : uniform(100, JUMP_SPEED_X))*uiScale;
            adaVelocity = vec2(dirX, -JUMP_SPEED_Y*uiScale);
            adaOffset = vec2(spawnX, 0);
            
            cam = new Camera();
            cam.position = vec2(0, 0);
            cam.scale = vec2(1, 1);
        }
    }

    // UwU
    void incAdaUpdate() {
        if (logoClickCounter >= CLICK_THRESH) {
            adaCurrTime += deltaTime();
            float uiScale = incGetUIScale();

            int w, h;
            int ww, wh;
            inGetViewport(ww, wh);
            SDL_GetWindowSize(incGetWindowPtr(), &w, &h);

            glDisable(GL_DEPTH_TEST);
            glEnable(GL_BLEND);
            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

            float halfWidth = w/2;
            float halfHeight = h/2;

            adaOffset -= adaVelocity*deltaTime();
            adaVelocity.y += 500.0*deltaTime();

            auto c = inGetCamera();
                inSetViewport(w, h);
                inSetCamera(cam);
                inDrawTextureAtRect(
                    incGetAda(), 
                    rect(adaOffset.x, halfHeight-adaOffset.y, ADA_SIZE*uiScale, ADA_SIZE*uiScale)
                );
                inSetViewport(ww, wh);
            inSetCamera(c);

            // Animation is over
            if (adaOffset.y < -((ADA_SIZE+32)*uiScale)) {
                logoClickCounter = 0;
            }
        }
    }
}