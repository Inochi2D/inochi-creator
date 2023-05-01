/*
    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.io.videoexport;
import std.process;
import std.string;
import std.array;
import std.uni;
import std.stdio : writeln;
import i18n;
import std.path;

private {
    bool hasffmpeg;
    VideoCodec[] codecs;

    bool parseEncoders(string output) {
        enum LIST_START_TAG = " -------";
        enum TAG_NAME_START = 7;

        // First we want to find where the encoding list starts
        // FFMPEG conveniently puts " -------" at the start of the list
        import std.algorithm.searching : countUntil;
        ptrdiff_t start = output.countUntil(LIST_START_TAG);

        // To prevent crashes due to ffmpeg changing the format they present the data in
        // We check whether we could even find our little tag.
        // Otherwise we'll just assume ffmpeg isn't there for now.
        if (start == -1) return false;

        // Then we get every line with the starting and ending whitespace from
        // out earlier operation stripped out.
        // This prevents us from getting empty entries.
        string[] lines = splitLines(strip(output[start+LIST_START_TAG.length..$]));
        foreach(line; lines) {
            string sline = strip(line);
            bool isVideoFormat = sline[2] == 'V';
            bool supportsEncoding = sline[1] == 'E';

            if (isVideoFormat && supportsEncoding) {

                VideoCodec codec;
                sline = sline[TAG_NAME_START..$];

                // Fetch the tag
                int i = 0;
                while(i < sline.length && !isWhite(sline[i])) codec.tag ~= sline[i++];
                
                // This line was for some reason invalidly formatted, we're skipping it.
                if (i >= sline.length) continue;

                // Fetch the name, it'll be the remaining text with all the leading
                // and ending whitespace stripped out
                codec.name = strip(sline[i..$]);
                codecs ~= codec;
            }
        }

        import std.algorithm.sorting;
        sort!((a, b) => a.name < b.name)(codecs);

        codecs = VideoCodec("auto", _("Automatic"))~codecs;

        return true;
    }

    string[] incBuildFFmpegCommand(VideoExportSettings settings) {
        import std.conv : text;
        import std.format : format;
        string[] out_;
        string file = settings.file;
        switch(settings.codec) {
            case "png":
            case "jpeg":
            case "jpg":
            case "tga":
                file = stripExtension(settings.file)~"-%d"~extension(settings.file);
                break;
            default: 
                file = settings.file;
            break;
        }

        if (settings.codec == "auto") {
            out_ = [
                // Command
                "ffmpeg", 

                // Auto replace files
                "-y",

                // Accept RGBA encoded image data
                "-f", "rawvideo",
                "-vcodec", "rawvideo",
                "-pix_fmt", "rgba",

                // Video resolution 
                "-s", "%sx%s".format(settings.width, settings.height),

                // Framerate
                "-r", settings.framerate.text,
                
                // Piped from stdin
                "-i", "-", 

                // Amount of frames to export (should be auto calculated)
                "-vframes", settings.frames.text,

                // No audio
                "-an",

                // Pixel format
                "-pix_fmt", settings.transparency ? "yuva420p" : "yuv420p",

                // Output file
                file
            ];
        } else {
            out_ = [
                // Command
                "ffmpeg", 

                // Auto replace files
                "-y",

                // Accept RGBA encoded image data
                "-f", "rawvideo",
                "-vcodec", "rawvideo",
                "-pix_fmt", "rgba",

                // Video resolution 
                "-s", "%sx%s".format(settings.width, settings.height),
                
                // Framerate
                "-r", settings.framerate.text,
                
                // Piped from stdin
                "-i", "-", 

                // Amount of frames to export (should be auto calculated)
                "-vframes", settings.frames.text,

                // No audio
                "-an",

                "-pix_fmt", settings.transparency ? "yuva420p" : "yuv420p",
                
                // Video codec
                "-vcodec", settings.codec,

                // Output file
                file
            ];
        }

        // Adds additional user specified options if any
        string ffoptions = strip(settings.ffmpegOptions);
        if (ffoptions.length > 0) {
            out_ = out_[0..$-1]~ffoptions.split(" ")~out_[$-1]; 
        }
        
        return out_;
    }
}

class VideoEncodingContext {
private:
    VideoExportSettings settings;
    string[] ffmpegLaunchOptions;
    ProcessPipes ffmpegPipes;
    
    bool isAlive;
    string errors_;
    int encoded;

public:
    this(VideoExportSettings settings) {
        this.settings = settings;
        this.ffmpegLaunchOptions = incBuildFFmpegCommand(settings);
        try {
            this.ffmpegPipes = pipeProcess(
                this.ffmpegLaunchOptions, 
                Redirect.stdin, 
                null,
                Config(Config.Flags.suppressConsole)
            );
            isAlive = true;
        } catch (Exception ex) {
            errors_ ~= ex.msg;
            isAlive = false;
        }
    }

    /**
        Gets whatever errors FFMPEG reported
    */
    string errors() {
        return errors_;
    }

    /**
        Gets whether ffmpeg is in a good state
    */
    bool checkState() {
        return isAlive && !ffmpegPipes.stdin.error;
    }

    /**
        Encodes a frame
    */
    void encodeFrame(ubyte[] rgbadata) {
        try {

            // Discard stdout
            this.ffmpegPipes.stdin.rawWrite(rgbadata);
            this.ffmpegPipes.stdin.flush();
            encoded++;
        } catch(Exception ex) {
            errors_ ~= ex.msg;
            isAlive = false;
        }
    }

    /**
        Closes pipes
    */
    void end() {
        this.ffmpegPipes.stdin.close();
    }

    /**
        Encoding progress
    */
    float progress() {
        return cast(float)encoded/cast(float)settings.frames;
    }
}

struct VideoCodec {
    string tag;
    string name;
}

struct VideoExportSettings {
    string codec;
    int framerate;
    string file;

    int frames;

    float width;
    float height;

    bool transparency = false;

    string ffmpegOptions;
}

/**

*/
VideoEncodingContext incVideoExport(VideoExportSettings settings) {
    return new VideoEncodingContext(settings);
}

/**
    Whether we can export video
*/
bool incVideoCanExport() {
    return hasffmpeg && codecs.length > 0;
}

/**
    Gets the list of supported encoders
*/
ref VideoCodec[] incVideoCodecs() {
    return codecs;
}


/**
    Initlializes video export
*/
void incInitVideoExport() {
    try {
        auto output = execute(["ffmpeg", "-codecs"]);
        if (output.status == 0) {
            hasffmpeg = parseEncoders(output.output);
        }
    } catch (Exception ex) {
        hasffmpeg = false;
    }
}

