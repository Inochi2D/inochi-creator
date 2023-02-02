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
        vec2 adaOffset;
        vec2 adaVelocity;
        enum ADA_SIZE = 396;
        enum CLICK_THRESH = 25;

        enum JUMP_SPEED_X = 500;
        enum JUMP_SPEED_Y = 700;
        bool lhs;
        Camera cam;

        Shader adaShader;
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
        }
    }

    // UwU
    void incAdaUpdate() {
        if (logoClickCounter >= CLICK_THRESH) {
            float fbScale = igGetIO().DisplayFramebufferScale.x;
            float uiScale = incGetUIScale();

            cam.scale = vec2(1*fbScale, 1*fbScale);

            int w, h;
            int ww, wh;
            inGetViewport(ww, wh);
            SDL_GetWindowSize(incGetWindowPtr(), &w, &h);

            glDisable(GL_DEPTH_TEST);
            glDisable(GL_CULL_FACE);
            glEnable(GL_BLEND);
            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

            float halfWidth = w/2;
            float halfHeight = h/2;

            adaOffset -= adaVelocity*deltaTime();
            adaVelocity.y += 500.0*deltaTime();

            inSetViewport(cast(int)(w*fbScale), cast(int)(h*fbScale));
            inDrawTextureAtRect(
                incGetAda(), 
                rect(adaOffset.x, halfHeight-adaOffset.y, ADA_SIZE*uiScale, ADA_SIZE*uiScale),
                rect(0, 0, 1, 1),
                1,
                vec3(1, 1, 1),
                vec3(0, 0, 0),
                adaShader,
                cam
            );

            inSetViewport(ww, wh);

            // Animation is over
            if (adaOffset.y < -((ADA_SIZE+32)*uiScale)) {
                logoClickCounter = 0;
            }
        }
    }

    void incInitAda() {
        adaShader = new Shader(import("shaders/ada.vert"), import("shaders/ada.frag"));
            
        cam = new Camera();
        cam.position = vec2(0, 0);
        cam.scale = vec2(1, 1);
        cam.rotation = 0;
    }
}