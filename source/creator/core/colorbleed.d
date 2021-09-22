/**
    re-implementation of the GermSerk ColorBleedingEffect texture padding algorithm
    https://github.com/gemserk/imageprocessing/blob/master/src/main/java/com/gemserk/utils/imageprocessing/ColorBleedingEffect.java

    This allows textures to be padded in such a way that there'll be no artifacts.
*/
module creator.core.colorbleed;
import inochi2d.core.texture;

/**
    Does texture bleeding on a texture.
*/
void incColorBleedPixels(ShallowTexture* texture, int maxIterations = 32) {
    int width = texture.width;
    int height = texture.height;

    union TexData {
        ubyte[] bytes;
        Pixel[] pixels;
    }

    TexData textureData = TexData(texture.data);
    Mask* mask = new Mask(textureData.bytes);

    int iterations = 0;
    int lastPending = -1;
    while (mask.getPendingSize > 0) {
        if (iterations >= maxIterations) break;

        lastPending = mask.getPendingSize();
        executeIteration(textureData.pixels, mask, width, height);
        iterations++;

        // Break on infinite loop.
        if (mask.getPendingSize == lastPending) break;
    }

    texture.data = textureData.bytes;
}

/**
    Does texture bleeding on a texture.
*/
void incColorBleedPixels(Texture texture, int maxIterations = 32) {
    int width = texture.width;
    int height = texture.height;

    union TexData {
        ubyte[] bytes;
        Pixel[] pixels;
    }

    TexData textureData = TexData(texture.getTextureData());
    Mask* mask = new Mask(textureData.bytes);

    int iterations = 0;
    int lastPending = -1;
    while (mask.getPendingSize > 0) {
        if (iterations >= maxIterations) break;

        lastPending = mask.getPendingSize();
        executeIteration(textureData.pixels, mask, width, height);
        iterations++;

        // Break on infinite loop.
        if (mask.getPendingSize == lastPending) break;
    }

    texture.setData(textureData.bytes);
}

private:
enum TOPROCESS = 0;
enum INPROCESS = 1;
enum PIXELDATA = 2;


struct Pixel {
align(1):
    ubyte r;
    ubyte g;
    ubyte b;
    ubyte a;
}

struct Mask {
    ubyte[] data;
    size_t[] pending;
    size_t[] changing;

    this(ubyte[] texture) {
        ubyte[] colorData = texture;
        data = new ubyte[colorData.length/4];

        foreach(i; 0..data.length) {
            size_t aRed = i*4;
            size_t aGreen = aRed+1;
            size_t aBlue = aRed+2;
            size_t aAlpha = aRed+3;
            Pixel data = Pixel(
                colorData[aRed],
                colorData[aGreen],
                colorData[aBlue],
                colorData[aAlpha],
            );

            if (data.a == 0) {
                this.data[i] = TOPROCESS;
                this.pending ~= i;
            } else {
                this.data[i] = PIXELDATA;
            }
        }   
    }

    int getPendingSize() {
        return cast(int)pending.length;
    }

    ubyte getMask(size_t index) {
        return data[index];
    }

    size_t removeIndex(size_t index) {
        if (index >= pending.length) {
            throw new Exception("Out of bounds write to mask");
        }

        size_t value = pending[index];
        pending[index] = pending[$-1];
        pending.length--;

        return value;
    }
}

struct MaskIterator {
    Mask* mask;
    size_t index;

    this(Mask* mask) {
        this.mask = mask;
    }

    bool hasNext() {
        return index < mask.getPendingSize;
    }

    int next() {
        return cast(int)mask.pending[index++];
    }

    void markAsInProgress() {
        index--;
        size_t removed = mask.removeIndex(index);
        mask.changing ~= removed;
    }

    void reset() {
        index = 0;
        foreach(i; 0..mask.changing.length) {
            size_t index = mask.changing[i];
            mask.data[index] = PIXELDATA;
        }
        mask.changing.length = 0;
    }
}

void executeIteration(Pixel[] rgba, Mask* mask, int width, int height) {
    int[2][8] offsets = [
        [-1, -1],
        [0, -1],
        [1, -1],
        [-1, 0],
        [1, 0],
        [-1, 1],
        [0, 1],
        [1, 1],
    ];



    MaskIterator iterator = MaskIterator(mask);
    while(iterator.hasNext) {
        int pixelIndex = iterator.next;

        int x = pixelIndex % width;
        int y = pixelIndex / width;

        int r = 0;
        int g = 0;
        int b = 0;
        int cant = 0;

        foreach(i, offset; offsets) {
            int column = x + offset[0];
            int row = y + offset[1];

            if (column < 0 || column >= width || row < 0 || row >= height) continue;

            int currentPixelIndex = row * width + column;
            Pixel pixelData = rgba[currentPixelIndex];
            if (mask.getMask(currentPixelIndex) == PIXELDATA) {
                r += pixelData.r;
                g += pixelData.g;
                b += pixelData.b;
                cant++;
            }
        }

        if (cant != 0) {
            rgba[pixelIndex] = Pixel(
                cast(ubyte)(r / cant), 
                cast(ubyte)(g / cant), 
                cast(ubyte)(b / cant), 
                0
            );
            iterator.markAsInProgress();
        }
    }

    iterator.reset();
}