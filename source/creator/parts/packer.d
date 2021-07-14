/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.parts.packer;
import gl3n.linalg;
import gl3n.math;
import std.exception;
import std.format;
import std.algorithm.mutation : remove;

/**
    Check if a proto "rectangle" contains an other rectangle
*/
private bool contains(vec4i a, vec4i b) {
    return  a.x >= b.x && 
            a.y >= b.y &&
            a.x+a.z <= b.x+b.z &&
            a.y+a.w <= b.y+b.w;
}

/**
    A bin
*/
private struct Bin {
private:
    vec2i size;
    vec4i[] usedRectangles;
    vec4i[] freeRectangles;

    vec4i scoreRect(vec2i size, out int score1, out int score2) {
        vec4i newNode;

        // Find the best place to put the rectangle
        score1 = int.max;
        score2 = int.max;
        newNode = findNewNodeFit(size, score1, score2);

        // reset score
        if (newNode.w == 0) {
            score1 = int.max;
            score2 = int.max;
        }
        return newNode;
    }

    vec4i scoreRect(vec2i size) {
        vec4i newNode;

        // Find the best place to put the rectangle
        int score1 = int.max;
        int score2 = int.max;
        newNode = findNewNodeFit(size, score1, score2);

        return newNode;
    }

    void place(ref vec4i newNode) {

        // Rectangles to process
        size_t rectanglesToProcess = freeRectangles.length;

        // Run through all rectangles
        for(int i; i < rectanglesToProcess; ++i) {

            // Try splitting them up
            if (splitFree(freeRectangles[i], newNode)) {
                freeRectangles.remove(i);
                --i;
                --rectanglesToProcess;
            }
        }

        prune();
        usedRectangles ~= newNode;
    }
    
    vec4i findNewNodeFit(vec2i size, int score1, int score2) {
        vec4i bestNode = vec4i.init;

        int bestShortFit = int.max;
        int bestLongFit = int.max;

        foreach(freeRect; freeRectangles) {
            
            // Try placing the rectangle in upright orientation
            if (freeRect.z >= size.x && freeRect.w >= size.y) {
                int leftoverH = abs(freeRect.z - size.x);
                int leftoverV = abs(freeRect.w - size.y);
                int shortSideFit = min(leftoverH, leftoverV);
                int longSideFit = max(leftoverH, leftoverV);

                if (shortSideFit < bestShortFit || (shortSideFit == bestShortFit && longSideFit < bestLongFit)) {
                    bestNode.x = freeRect.x;
                    bestNode.y = freeRect.y;
                    bestNode.z = size.x;
                    bestNode.w = size.y;
                    bestShortFit = shortSideFit;
                    bestLongFit = longSideFit;
                }
            }
        }

        return bestNode;
    }

    bool splitFree(vec4i freeNode, ref vec4i usedNode) {
        if (usedNode.x >= freeNode.x + freeNode.z || usedNode.x + usedNode.z <= freeNode.x ||
            usedNode.y >= freeNode.y + freeNode.w || usedNode.y + usedNode.w <= freeNode.y) 
            return false;

        // Vertical Splitting
        if (usedNode.x < freeNode.x + freeNode.z && usedNode.x + usedNode.z > freeNode.x) {

            // New node at top of used
            if (usedNode.y > freeNode.y && usedNode.y < freeNode.y + freeNode.w) {
                vec4i newNode = freeNode;
                newNode.w = usedNode.y - newNode.y;
                freeRectangles ~= newNode;
            }

            // New node at bottom of used
            if (usedNode.y + usedNode.w < freeNode.y + freeNode.w) {
                vec4i newNode = freeNode;
                newNode.y = usedNode.y + usedNode.w;
                newNode.w = freeNode.y + freeNode.w - (usedNode.y + usedNode.w);
                freeRectangles ~= newNode;
            }
        }

        // Horizontal Splitting
        if (usedNode.y < freeNode.y + freeNode.w && usedNode.y + usedNode.w > freeNode.y) {

            // New node at left of used
            if (usedNode.x > freeNode.x && usedNode.x < freeNode.x + freeNode.z) {
                vec4i newNode = freeNode;
                newNode.z = usedNode.x - newNode.x;
                freeRectangles ~= newNode;
            }

            // New node at right of used
            if (usedNode.x + usedNode.z < freeNode.x + freeNode.z) {
                vec4i newNode = freeNode;
                newNode.x = usedNode.x + usedNode.z;
                newNode.z = freeNode.x + freeNode.z - (usedNode.x + usedNode.z);
                freeRectangles ~= newNode;
            }
        }
        return true;
    }

    void prune() {
        for(int i; i < freeRectangles.length; ++i) {
            for(int j = i+1; j < freeRectangles.length; ++j) {


                if (freeRectangles[i].contains(freeRectangles[j])) {
                    freeRectangles = freeRectangles.remove(i);
                    --i;
                    break;
                }

                if (freeRectangles[j].contains(freeRectangles[i])) {
                    freeRectangles = freeRectangles.remove(j);
                    --j;
                }
            }
        }
    }

public:
    this(vec2i size) {
        this.size = size;
        freeRectangles = [vec4i(0, 0, size.x, size.y)];
    }

    /**
        Inserts a new rectangle in to the bin
    */
    vec4i insert(vec2i size) {
        int score1;
        int score2;
        vec4i newNode = scoreRect(size, score1, score2);

        // Place rectangle in to bin
        place(newNode);
        return newNode;
    }

    /**
        Removes the area from the packing
    */
    void remove(vec4i area) {
        foreach(i, rect; usedRectangles) {
            if (rect == area) {
                usedRectangles = usedRectangles.remove(i);
                break;
            }
        }
        freeRectangles ~= area;
    }

    void clear() {
        freeRectangles = [vec4i(0, 0, size.x, size.y)];
        usedRectangles = [];
    }

    /**
        Gets ratio of surface area used
    */
    float occupancy() {
        ulong surfaceArea = 0;
        foreach(rect; usedRectangles) {
            surfaceArea += rect.z*rect.w;
        }
        return surfaceArea / (size.x*size.y);
    }
}

/**
    The texture packer
*/
class TexturePacker {
private:
    Bin bin;

public:

    /**
        Max size of texture packer
    */
    this(vec2i textureSize = vec2i(1024, 1024)) {
        bin = Bin(textureSize);
    }

    /**
        Packs a texture in to the bin

        Returns a vec4i(0, 0, 0, 0) on packing failure
    */
    vec4i packTexture(vec2i size) {
        return bin.insert(size);
    }

    /**
        Remove an area from the texture packer
    */
    void remove(vec4i area) {
        bin.remove(area);
    }

    /**
        Clear the texture packer
    */
    void clear() {
        bin.clear();
    }
}