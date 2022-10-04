/*
    Copyright © 2020, ImGui & Inochi2D Project
    Distributed under the MIT, see ImGui LICENSE file.
    
    Authors: Luna Nielsen
*/
module creator.backend.gl;
import creator.core.dpi;
import bindbc.opengl;
import bindbc.imgui;
import core.stdc.stdio;
import inmath;
import bindbc.sdl;

private {
    // OpenGL Data
    GLuint       g_GlVersion = 0;                // Extracted at runtime using GL_MAJOR_VERSION, GL_MINOR_VERSION queries (e.g. 320 for GL 3.2)

    version(OSX) char[32] g_GlslVersionString = "#version 330";   // Specified by user or detected based on compile time GL settings.
    else char[32] g_GlslVersionString = "#version 130";   // Specified by user or detected based on compile time GL settings.
    GLuint g_FontTexture = 0;
    GLuint g_ShaderHandle = 0, g_VertHandle = 0, g_FragHandle = 0;
    GLint g_AttribLocationTex = 0, g_AttribLocationProjMtx = 0;                                // Uniforms location
    GLuint g_AttribLocationVtxPos = 0, g_AttribLocationVtxUV = 0, g_AttribLocationVtxColor = 0; // Vertex attributes location
    uint g_VboHandle = 0, g_ElementsHandle = 0;
}

// Functions
bool incGLBackendInit(const (char)* glsl_version) {
    // Query for GL version (e.g. 320 for GL 3.2)
    const GLint major = 4, minor = 2;
    //glGetIntegerv(GL_MAJOR_VERSION, &major);
    //glGetIntegerv(GL_MINOR_VERSION, &minor);
    g_GlVersion = cast(GLuint)(major * 100 + minor * 10);

    // Setup back-end capabilities flags
    ImGuiIO* io = igGetIO();
    //io.BackendRendererName = "imgui_impl_opengl3";

    if (g_GlVersion >= 320)
    {
        io.BackendFlags |= cast(int)ImGuiBackendFlags.RendererHasVtxOffset;  // We can honor the ImDrawCmd::VtxOffset field, allowing for large meshes.
    }
    
    io.BackendFlags |= cast(int)ImGuiBackendFlags.RendererHasViewports;  // We can create multi-viewports on the Renderer side (optional)

    // Make an arbitrary GL call (we don't actually need the result)
    // IF YOU GET A CRASH HERE: it probably means that you haven't initialized the OpenGL function loader used by this code.
    // Desktop OpenGL 3/4 need a function loader. See the IMGUI_IMPL_OPENGL_LOADER_xxx explanation above.
    GLint current_texture;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &current_texture);

    if (io.ConfigFlags & ImGuiConfigFlags.ViewportsEnable) incGLBackendPlatformInterfaceInit();
    return true;
}

void incGLBackendShutdown() {
    incGLBackendPlatformInterfaceShutdown();
    incGLBackendDestroyDeviceObjects();
}

void incGLBackendNewFrame() {
    if (!g_ShaderHandle) incGLBackendCreateDeviceObjects();
}

void incGLBackendBeginRender() {
    version (UseUIScaling) {
        version (OSX) {
            // macOS handles the UI scaling automatically, as such we don't need to do as much cursed shit(TM) there.
            
        } else {
            float uiScale = incGetUIScale();
            auto io = igGetIO();
            auto vp = igGetMainViewport();

            vp.WorkSize.x = ceil(cast(double)vp.WorkSize.x/cast(double)uiScale);
            vp.WorkSize.y = ceil(cast(double)vp.WorkSize.y/cast(double)uiScale);
            vp.Size.x = ceil(cast(double)vp.Size.x/cast(double)uiScale);
            vp.Size.y = ceil(cast(double)vp.Size.y/cast(double)uiScale);

            // NOTE:
            // For some reason there's this weird offset added during scaling
            // This magic number SOMEHOW works, and I don't know why
            // I hate computers
            //
            // This only works with scaling up to 200%, after which it breaks
            vp.WorkSize.y -= (26+10)*(uiScale-1);
            
            int mx, my;
            version(UseUIScaling) {
                SDL_GetMouseState(&mx, &my);
                io.MousePos.x = (cast(float)mx)/uiScale;
                io.MousePos.y = (cast(float)my)/uiScale;
            } else {
                int wx, wy;
                SDL_GetGlobalMouseState(&mx, &my);
                SDL_GetWindowPosition(cast(SDL_Window*)vp.PlatformHandle, &wx, &wy);
                io.MousePos.x = cast(float)(mx-wx)/uiScale;
                io.MousePos.y = cast(float)(my-wy)/uiScale;
            }
        }
    }
}

bool incGLBackendProcessEvent(const(SDL_Event)* event) {
    version (UseUIScaling) {
        switch(event.type) {

            // For UI Scaling we want to send in our own scaled UI inputs
            case SDL_EventType.SDL_MOUSEMOTION:
                float uiScale = incGetUIScale();
                ImGuiIO_AddMousePosEvent(
                    igGetIO(), 
                    cast(float)event.motion.x/uiScale, 
                    cast(float)event.motion.y/uiScale
                );
                return true;
            
            default:
                return ImGui_ImplSDL2_ProcessEvent(event);
        }

    } else {
        return ImGui_ImplSDL2_ProcessEvent(event);
    }

}

static void incGLBackendSetupRenderState(ImDrawData* draw_data, float fb_width, float fb_height, GLuint vertex_array_object) {
    float uiScale = incGetUIScale();

    // Setup render state: alpha-blending enabled, no face culling, no depth testing, scissor enabled, polygon fill
    glEnable(GL_BLEND);
    glBlendEquation(GL_FUNC_ADD);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_SCISSOR_TEST);

    // Support for GL 4.5 rarely used glClipControl(GL_UPPER_LEFT)
    bool clip_origin_lower_left = true;

    // Setup viewport, orthographic projection matrix
    // Our visible imgui space lies from draw_data.DisplayPos (top left) to draw_data.DisplayPos+data_data.DisplaySize (bottom right). DisplayPos is (0,0) for single viewport apps.
    glViewport(0, 0, cast(GLsizei)(fb_width), cast(GLsizei)(fb_height));
    mat4 mvp = mat4.orthographic(
        draw_data.DisplayPos.x,
        draw_data.DisplayPos.x + draw_data.DisplaySize.x,
        draw_data.DisplayPos.y + draw_data.DisplaySize.y,
        draw_data.DisplayPos.y,
        -1, 1
    );

    glUseProgram(g_ShaderHandle);
    glUniform1i(g_AttribLocationTex, 0);
    glUniformMatrix4fv(g_AttribLocationProjMtx, 1, GL_TRUE, mvp.ptr);
    
    if (g_GlVersion >= 330)
        glBindSampler(0, 0); // We use combined texture/sampler state. Applications using GL 3.3 may set that otherwise.
    
    glBindVertexArray(vertex_array_object);

    // Bind vertex/index buffers and setup attributes for ImDrawVert
    glBindBuffer(GL_ARRAY_BUFFER, g_VboHandle);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, g_ElementsHandle);
    glEnableVertexAttribArray(g_AttribLocationVtxPos);
    glEnableVertexAttribArray(g_AttribLocationVtxUV);
    glEnableVertexAttribArray(g_AttribLocationVtxColor);
    glVertexAttribPointer(g_AttribLocationVtxPos,   2, GL_FLOAT,         GL_FALSE, ImDrawVert.sizeof, cast(GLvoid*)ImDrawVert.pos.offsetof);
    glVertexAttribPointer(g_AttribLocationVtxUV,    2, GL_FLOAT,         GL_FALSE, ImDrawVert.sizeof, cast(GLvoid*)ImDrawVert.uv.offsetof);
    glVertexAttribPointer(g_AttribLocationVtxColor, 4, GL_UNSIGNED_BYTE, GL_TRUE,  ImDrawVert.sizeof, cast(GLvoid*)ImDrawVert.col.offsetof);
}

// OpenGL3 Render function.
// (this used to be set in io.RenderDrawListsFn and called by ImGui::Render(), but you can now call this directly from your main loop)
// Note that this implementation is little overcomplicated because we are saving/setting up/restoring every OpenGL state explicitly, in order to be able to run within any OpenGL engine that doesn't do so.
void incGLBackendRenderDrawData(ImDrawData* draw_data) {
    float uiScale = incGetUIScale();

    // Avoid rendering when minimized, scale coordinates for retina displays (screen coordinates != framebuffer coordinates)
    float fb_width = draw_data.DisplaySize.x * draw_data.FramebufferScale.x * uiScale;
    float fb_height = draw_data.DisplaySize.y * draw_data.FramebufferScale.y * uiScale;
    if (fb_width <= 0 || fb_height <= 0)
        return;

    // Backup GL state
    GLenum last_active_texture; glGetIntegerv(GL_ACTIVE_TEXTURE, cast(GLint*)&last_active_texture);
    glActiveTexture(GL_TEXTURE0);
    GLuint last_program; glGetIntegerv(GL_CURRENT_PROGRAM, cast(GLint*)&last_program);
    GLuint last_texture; glGetIntegerv(GL_TEXTURE_BINDING_2D, cast(GLint*)&last_texture);
    GLuint last_sampler; if (g_GlVersion >= 330) { glGetIntegerv(GL_SAMPLER_BINDING, cast(GLint*)&last_sampler); } else { last_sampler = 0; }
    GLuint last_array_buffer; glGetIntegerv(GL_ARRAY_BUFFER_BINDING, cast(GLint*)&last_array_buffer);
    GLuint last_vertex_array_object; glGetIntegerv(GL_VERTEX_ARRAY_BINDING, cast(GLint*)&last_vertex_array_object);
    GLint[4] last_viewport; glGetIntegerv(GL_VIEWPORT, last_viewport.ptr);
    GLint[4] last_scissor_box; glGetIntegerv(GL_SCISSOR_BOX, last_scissor_box.ptr);
    GLenum last_blend_src_rgb; glGetIntegerv(GL_BLEND_SRC_RGB, cast(GLint*)&last_blend_src_rgb);
    GLenum last_blend_dst_rgb; glGetIntegerv(GL_BLEND_DST_RGB, cast(GLint*)&last_blend_dst_rgb);
    GLenum last_blend_src_alpha; glGetIntegerv(GL_BLEND_SRC_ALPHA, cast(GLint*)&last_blend_src_alpha);
    GLenum last_blend_dst_alpha; glGetIntegerv(GL_BLEND_DST_ALPHA, cast(GLint*)&last_blend_dst_alpha);
    GLenum last_blend_equation_rgb; glGetIntegerv(GL_BLEND_EQUATION_RGB, cast(GLint*)&last_blend_equation_rgb);
    GLenum last_blend_equation_alpha; glGetIntegerv(GL_BLEND_EQUATION_ALPHA, cast(GLint*)&last_blend_equation_alpha);
    const GLboolean last_enable_blend = glIsEnabled(GL_BLEND);
    const GLboolean last_enable_cull_face = glIsEnabled(GL_CULL_FACE);
    const GLboolean last_enable_depth_test = glIsEnabled(GL_DEPTH_TEST);
    const GLboolean last_enable_scissor_test = glIsEnabled(GL_SCISSOR_TEST);

    // Setup desired GL state
    // Recreate the VAO every time (this is to easily allow multiple GL contexts to be rendered to. VAO are not shared among GL contexts)
    // The renderer would actually work without any VAO bound, but then our VertexAttrib calls would overwrite the default one currently bound.
    GLuint vertex_array_object = 0;
    glGenVertexArrays(1, &vertex_array_object);
    incGLBackendSetupRenderState(draw_data, fb_width, fb_height, vertex_array_object);

    // Will project scissor/clipping rectangles into framebuffer space
    ImVec2 clip_off = ImVec2(
        draw_data.DisplayPos.x,
        draw_data.DisplayPos.y
    ); // (0,0) unless using multi-viewports

    ImVec2 clip_scale = ImVec2(
        draw_data.FramebufferScale.x * uiScale, 
        draw_data.FramebufferScale.y * uiScale
    ); // (1,1) unless using retina display which are often (2,2)
    

    // Render command lists
    for (int n = 0; n < draw_data.CmdListsCount; n++)
    {
        const ImDrawList* cmd_list = draw_data.CmdLists[n];

        // Upload vertex/index buffers
        glBufferData(GL_ARRAY_BUFFER, cast(GLsizeiptr)cmd_list.VtxBuffer.Size * cast(int)(ImDrawVert.sizeof), cast(const GLvoid*)cmd_list.VtxBuffer.Data, GL_STREAM_DRAW);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, cast(GLsizeiptr)cmd_list.IdxBuffer.Size * cast(int)(ImDrawIdx.sizeof), cast(const GLvoid*)cmd_list.IdxBuffer.Data, GL_STREAM_DRAW);

        for (int cmd_i = 0; cmd_i < cmd_list.CmdBuffer.Size; cmd_i++)
        {
            const (ImDrawCmd)* pcmd = &cmd_list.CmdBuffer.Data[cmd_i];
            if (pcmd.UserCallback != null)
            {
                // User callback, registered via ImDrawList::AddCallback()
                // (ImDrawCallback_ResetRenderState is a special callback value used by the user to request the renderer to reset render state.)
                if (pcmd.UserCallback == cast(ImDrawCallback)(-1))
                    incGLBackendSetupRenderState(draw_data, fb_width, fb_height, vertex_array_object);
                else
                    pcmd.UserCallback(cmd_list, pcmd);
            }
            else
            {
                // Project scissor/clipping rectangles into framebuffer space
                ImVec4 clip_rect;
                clip_rect.x = (pcmd.ClipRect.x - clip_off.x) * clip_scale.x;
                clip_rect.y = (pcmd.ClipRect.y - clip_off.y) * clip_scale.y;
                clip_rect.z = (pcmd.ClipRect.z - clip_off.x) * clip_scale.x;
                clip_rect.w = (pcmd.ClipRect.w - clip_off.y) * clip_scale.y;

                if (clip_rect.x < fb_width && clip_rect.y < fb_height && clip_rect.z >= 0.0f && clip_rect.w >= 0.0f)
                {
                    // Apply scissor/clipping rectangle
                    glScissor(cast(int)clip_rect.x, cast(int)(fb_height - clip_rect.w), cast(int)(clip_rect.z - clip_rect.x), cast(int)(clip_rect.w - clip_rect.y));

                    // Bind texture, Draw
                    glBindTexture(GL_TEXTURE_2D, cast(GLuint)(cast(int*)(pcmd.TextureId)));
                    if (g_GlVersion >= 320)
                        glDrawElementsBaseVertex(GL_TRIANGLES, cast(GLsizei)pcmd.ElemCount, (ImDrawIdx.sizeof) == 2 ? GL_UNSIGNED_SHORT : GL_UNSIGNED_INT, cast(void*)cast(int*)(pcmd.IdxOffset * (ImDrawIdx.sizeof)), cast(GLint)pcmd.VtxOffset);
                    else
                        glDrawElements(GL_TRIANGLES, cast(GLsizei)pcmd.ElemCount, (ImDrawIdx.sizeof) == 2 ? GL_UNSIGNED_SHORT : GL_UNSIGNED_INT, cast(void*)cast(int*)(pcmd.IdxOffset * (ImDrawIdx.sizeof)));
                }
            }
        }
    }

    // Destroy the temporary VAO
    glDeleteVertexArrays(1, &vertex_array_object);

    // Restore modified GL state
    glUseProgram(last_program);
    glBindTexture(GL_TEXTURE_2D, last_texture);
    if (g_GlVersion >= 330)
        glBindSampler(0, last_sampler);
    glActiveTexture(last_active_texture);
    glBindVertexArray(last_vertex_array_object);
    glBindBuffer(GL_ARRAY_BUFFER, last_array_buffer);
    glBlendEquationSeparate(last_blend_equation_rgb, last_blend_equation_alpha);
    glBlendFuncSeparate(last_blend_src_rgb, last_blend_dst_rgb, last_blend_src_alpha, last_blend_dst_alpha);
    if (last_enable_blend) glEnable(GL_BLEND); else glDisable(GL_BLEND);
    if (last_enable_cull_face) glEnable(GL_CULL_FACE); else glDisable(GL_CULL_FACE);
    if (last_enable_depth_test) glEnable(GL_DEPTH_TEST); else glDisable(GL_DEPTH_TEST);
    if (last_enable_scissor_test) glEnable(GL_SCISSOR_TEST); else glDisable(GL_SCISSOR_TEST);
    glViewport(last_viewport[0], last_viewport[1], cast(GLsizei)(last_viewport[2]), cast(GLsizei)(last_viewport[3]));
    glScissor(last_scissor_box[0], last_scissor_box[1], cast(GLsizei)(last_scissor_box[2]), cast(GLsizei)(last_scissor_box[3]));
}

bool incGLBackendCreateFontsTexture() {
    // Build texture atlas
    ImGuiIO* io = igGetIO();
    char* pixels;
    int width, height;

    ImFontAtlas_GetTexDataAsRGBA32(io.Fonts, &pixels, &width, &height, null); // Load as RGBA 32-bit (75% of the memory is wasted, but default font is so small) because it is more likely to be compatible with user's existing shaders. If your ImTextureId represent a higher-level concept than just a GL texture id, consider calling GetTexDataAsAlpha8() instead to save on GPU memory.

    // Upload texture to graphics system
    GLint last_texture;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &last_texture);
    glGenTextures(1, &g_FontTexture);
    glBindTexture(GL_TEXTURE_2D, g_FontTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);

    // Store our identifier
    io.Fonts.TexID = cast(ImTextureID)cast(int*)g_FontTexture;

    // Restore state
    glBindTexture(GL_TEXTURE_2D, last_texture);

    return true;
}

void incGLBackendDestroyFontsTexture() {
    if (g_FontTexture)
    {
        ImGuiIO* io = igGetIO();
        glDeleteTextures(1, &g_FontTexture);
        io.Fonts.TexID = cast(ImTextureID)0;
        g_FontTexture = 0;
    }
}

// If you get an error please report on github. You may try different GL context version or GLSL version. See GL<>GLSL version table at the top of this file.
bool incGLBackendCheckShader(GLuint handle, const (char)* desc) {
    GLint status = 0, log_length = 0;
    glGetShaderiv(handle, GL_COMPILE_STATUS, &status);
    glGetShaderiv(handle, GL_INFO_LOG_LENGTH, &log_length);
    if (cast(GLboolean)status == GL_FALSE)
        fprintf(stderr, "ERROR: ImGui_ImplOpenGL3_CreateDeviceObjects: failed to compile %s!\n", desc);
    if (log_length > 1)
    {
        char[] buf;
        buf.length = log_length + 1;
        glGetShaderInfoLog(handle, log_length, null, cast(GLchar*)buf.ptr);
        fprintf(stderr, "%s\n", buf.ptr);
    }
    return cast(GLboolean)status == GL_TRUE;
}

// If you get an error please report on GitHub. You may try different GL context version or GLSL version.
bool incGLBackendCheckProgram(GLuint handle, const char* desc) {
    GLint status = 0, log_length = 0;
    glGetProgramiv(handle, GL_LINK_STATUS, &status);
    glGetProgramiv(handle, GL_INFO_LOG_LENGTH, &log_length);
    if (cast(GLboolean)status == GL_FALSE)
        fprintf(stderr, "ERROR: create_device_objects: failed to link %s! (with GLSL '%s')\n", desc, g_GlslVersionString.ptr);
    if (log_length > 1)
    {
        char[] buf;
        buf.length = log_length + 1;
        glGetProgramInfoLog(handle, log_length, null, cast(GLchar*)buf.ptr);
        fprintf(stderr, "%s\n", buf.ptr);
    }
    return cast(GLboolean)status == GL_TRUE;
}

bool incGLBackendCreateDeviceObjects() {
    // Backup GL state
    GLint last_texture, last_array_buffer;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &last_texture);
    glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &last_array_buffer);
    GLint last_vertex_array;
    glGetIntegerv(GL_VERTEX_ARRAY_BINDING, &last_vertex_array);

    // Parse GLSL version string
    int glsl_version = 130;
    sscanf(g_GlslVersionString.ptr, "#version %d", &glsl_version);

    const GLchar* vertex_shader_glsl_120 =
        "uniform mat4 ProjMtx;\n"
    ~ "attribute vec2 Position;\n"
    ~ "attribute vec2 UV;\n"
    ~ "attribute vec4 Color;\n"
    ~ "varying vec2 Frag_UV;\n"
    ~ "varying vec4 Frag_Color;\n"
    ~ "void main()\n"
    ~ "{\n"
    ~ "    Frag_UV = UV;\n"
    ~ "    Frag_Color = Color;\n"
    ~ "    gl_Position = ProjMtx * vec4(Position.xy,0,1);\n"
    ~ "}\n";

    const GLchar* vertex_shader_glsl_130 = `
    uniform mat4 ProjMtx;
    in vec2 Position;
    in vec2 UV;
    in vec4 Color;
    out vec2 Frag_UV;
    out vec4 Frag_Color;
    void main()
    {
        Frag_UV = UV;
        Frag_Color = Color;
        gl_Position = ProjMtx * vec4(Position.xy,0,1);
    }
    `;

    const GLchar* vertex_shader_glsl_300_es =
        "precision mediump float;\n"
    ~ "layout (location = 0) in vec2 Position;\n"
    ~ "layout (location = 1) in vec2 UV;\n"
    ~ "layout (location = 2) in vec4 Color;\n"
    ~ "uniform mat4 ProjMtx;\n"
    ~ "out vec2 Frag_UV;\n"
    ~ "out vec4 Frag_Color;\n"
    ~ "void main()\n"
    ~ "{\n"
    ~ "    Frag_UV = UV;\n"
    ~ "    Frag_Color = Color;\n"
    ~ "    gl_Position = ProjMtx * vec4(Position.xy,0,1);\n"
    ~ "}\n";

    const GLchar* vertex_shader_glsl_410_core =
        "layout (location = 0) in vec2 Position;\n"
    ~ "layout (location = 1) in vec2 UV;\n"
    ~ "layout (location = 2) in vec4 Color;\n"
    ~ "uniform mat4 ProjMtx;\n"
    ~ "out vec2 Frag_UV;\n"
    ~ "out vec4 Frag_Color;\n"
    ~ "void main()\n"
    ~ "{\n"
    ~ "    Frag_UV = UV;\n"
    ~ "    Frag_Color = Color;\n"
    ~ "    gl_Position = ProjMtx * vec4(Position.xy,0,1);\n"
    ~ "}\n";

    const GLchar* fragment_shader_glsl_120 =
        "#ifdef GL_ES\n"
    ~ "    precision mediump float;\n"
    ~ "#endif\n"
    ~ "uniform sampler2D Texture;\n"
    ~ "varying vec2 Frag_UV;\n"
    ~ "varying vec4 Frag_Color;\n"
    ~ "void main()\n"
    ~ "{\n"
    ~ "    gl_FragColor = Frag_Color * texture2D(Texture, Frag_UV.st);\n"
    ~ "}\n";

    const GLchar* fragment_shader_glsl_130 = `
    uniform sampler2D Texture;
    in vec2 Frag_UV;
    in vec4 Frag_Color;
    out vec4 Out_Color;
    void main()
    {
        Out_Color = Frag_Color * texture(Texture, Frag_UV.st);
    }
    `;

    const GLchar* fragment_shader_glsl_300_es =
        "precision mediump float;\n"
    ~ "uniform sampler2D Texture;\n"
    ~ "in vec2 Frag_UV;\n"
    ~ "in vec4 Frag_Color;\n"
    ~ "layout (location = 0) out vec4 Out_Color;\n"
    ~ "void main()\n"
    ~ "{\n"
    ~ "    Out_Color = Frag_Color * texture(Texture, Frag_UV.st);\n"
    ~ "}\n";

    const GLchar* fragment_shader_glsl_410_core =
        "in vec2 Frag_UV;\n"
    ~ "in vec4 Frag_Color;\n"
    ~ "uniform sampler2D Texture;\n"
    ~ "layout (location = 0) out vec4 Out_Color;\n"
    ~ "void main()\n"
    ~ "{\n"
    ~ "    Out_Color = Frag_Color * texture(Texture, Frag_UV.st);\n"
    ~ "}\n";

    // Select shaders matching our GLSL versions
    const (GLchar)* vertex_shader = null;
    const (GLchar)* fragment_shader = null;
    if (glsl_version < 130)
    {
        vertex_shader = vertex_shader_glsl_120;
        fragment_shader = fragment_shader_glsl_120;
    }
    else if (glsl_version >= 410)
    {
        vertex_shader = vertex_shader_glsl_410_core;
        fragment_shader = fragment_shader_glsl_410_core;
    }
    else if (glsl_version == 300)
    {
        vertex_shader = vertex_shader_glsl_300_es;
        fragment_shader = fragment_shader_glsl_300_es;
    }
    else
    {
        vertex_shader = vertex_shader_glsl_130;
        fragment_shader = fragment_shader_glsl_130;
    }

    // Create shaders
    const (GLchar)*[2] vertex_shader_with_version = [ g_GlslVersionString.ptr, vertex_shader ];
    g_VertHandle = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(g_VertHandle, 2, vertex_shader_with_version.ptr, null);
    glCompileShader(g_VertHandle);
    incGLBackendCheckShader(g_VertHandle, "vertex shader");

    const (GLchar)*[2] fragment_shader_with_version = [ g_GlslVersionString.ptr, fragment_shader ];
    g_FragHandle = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(g_FragHandle, 2, fragment_shader_with_version.ptr, null);
    glCompileShader(g_FragHandle);
    incGLBackendCheckShader(g_FragHandle, "fragment shader");

    g_ShaderHandle = glCreateProgram();
    glAttachShader(g_ShaderHandle, g_VertHandle);
    glAttachShader(g_ShaderHandle, g_FragHandle);
    glLinkProgram(g_ShaderHandle);
    incGLBackendCheckProgram(g_ShaderHandle, "shader program");

    g_AttribLocationTex = glGetUniformLocation(g_ShaderHandle, "Texture");
    g_AttribLocationProjMtx = glGetUniformLocation(g_ShaderHandle, "ProjMtx");
    g_AttribLocationVtxPos = cast(GLuint)glGetAttribLocation(g_ShaderHandle, "Position");
    g_AttribLocationVtxUV = cast(GLuint)glGetAttribLocation(g_ShaderHandle, "UV");
    g_AttribLocationVtxColor = cast(GLuint)glGetAttribLocation(g_ShaderHandle, "Color");

    // Create buffers
    glGenBuffers(1, &g_VboHandle);
    glGenBuffers(1, &g_ElementsHandle);

    incGLBackendCreateFontsTexture();

    // Restore modified GL state
    glBindTexture(GL_TEXTURE_2D, last_texture);
    glBindBuffer(GL_ARRAY_BUFFER, last_array_buffer);
    glBindVertexArray(last_vertex_array);

    return true;
}

void incGLBackendDestroyDeviceObjects() {
    if (g_VboHandle)        { glDeleteBuffers(1, &g_VboHandle); g_VboHandle = 0; }
    if (g_ElementsHandle)   { glDeleteBuffers(1, &g_ElementsHandle); g_ElementsHandle = 0; }
    if (g_ShaderHandle && g_VertHandle) { glDetachShader(g_ShaderHandle, g_VertHandle); }
    if (g_ShaderHandle && g_FragHandle) { glDetachShader(g_ShaderHandle, g_FragHandle); }
    if (g_VertHandle)       { glDeleteShader(g_VertHandle); g_VertHandle = 0; }
    if (g_FragHandle)       { glDeleteShader(g_FragHandle); g_FragHandle = 0; }
    if (g_ShaderHandle)     { glDeleteProgram(g_ShaderHandle); g_ShaderHandle = 0; }

    incGLBackendDestroyFontsTexture();
}

//--------------------------------------------------------------------------------------------------------
// MULTI-VIEWPORT / PLATFORM INTERFACE SUPPORT
// This is an _advanced_ and _optional_ feature, allowing the back-end to create and handle multiple viewports simultaneously.
// If you are new to dear imgui or creating a new binding for dear imgui, it is recommended that you completely ignore this section first..
//--------------------------------------------------------------------------------------------------------
extern (C) {
    version (NoUIScaling) {
        void incGLBackendPlatformRenderWindow(ImGuiViewport* viewport, void*) {
            if (!(viewport.Flags & ImGuiViewportFlags.NoRendererClear)) {
                ImVec4 clear_color = ImVec4(0.0f, 0.0f, 0.0f, 1.0f);
                glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
                glClear(GL_COLOR_BUFFER_BIT);
            }
            incGLBackendRenderDrawData(viewport.DrawData);
        }
    }
}

void incGLBackendPlatformInterfaceInit() {
    version (NoUIScaling) {
        ImGuiPlatformIO* platform_io = igGetPlatformIO();
        platform_io.Renderer_RenderWindow = &incGLBackendPlatformRenderWindow;
    }
}

void incGLBackendPlatformInterfaceShutdown() {
    igDestroyPlatformWindows();
}