protocol GLESCommands: AnyObject {
    func unimplemented()
    func glActiveShaderProgramEXT(_ pipeline: GLuint, _ program: GLuint)
    func glActiveTexture(_ texture: GLenum)
    func glAlphaFunc(_ `func`: GLenum, _ ref: GLclampf)
    func glAlphaFuncx(_ `func`: GLenum, _ ref: GLclampx)
    func glAttachShader(_ program: GLuint, _ shader: GLuint)
    func glBeginQuery(_ target: GLenum, _ id: GLuint)
    func glBeginQueryEXT(_ target: GLenum, _ id: GLuint)
    func glBeginTransformFeedback(_ primitiveMode: GLenum)
    func glBindAttribLocation(_ program: GLuint, _ index: GLuint, _ name: UnsafePointer<GLchar>!)
    func glBindBuffer(_ target: GLenum, _ buffer: GLuint)
    func glBindBufferBase(_ target: GLenum, _ index: GLuint, _ buffer: GLuint)
    func glBindBufferRange(_ target: GLenum, _ index: GLuint, _ buffer: GLuint, _ offset: GLintptr, _ size: GLsizeiptr)
    func glBindFramebuffer(_ target: GLenum, _ framebuffer: GLuint)
    func glBindFramebufferOES(_ target: GLenum, _ framebuffer: GLuint)
    func glBindProgramPipelineEXT(_ pipeline: GLuint)
    func glBindRenderbuffer(_ target: GLenum, _ renderbuffer: GLuint)
    func glBindRenderbufferOES(_ target: GLenum, _ renderbuffer: GLuint)
    func glBindSampler(_ unit: GLuint, _ sampler: GLuint)
    func glBindTexture(_ target: GLenum, _ texture: GLuint)
    func glBindTransformFeedback(_ target: GLenum, _ id: GLuint)
    func glBindVertexArray(_ array: GLuint)
    func glBindVertexArrayOES(_ array: GLuint)
    func glBlendColor(_ red: GLfloat, _ green: GLfloat, _ blue: GLfloat, _ alpha: GLfloat)
    func glBlendEquation(_ mode: GLenum)
    func glBlendEquationOES(_ mode: GLenum)
    func glBlendEquationSeparate(_ modeRGB: GLenum, _ modeAlpha: GLenum)
    func glBlendEquationSeparateOES(_ modeRGB: GLenum, _ modeAlpha: GLenum)
    func glBlendFunc(_ sfactor: GLenum, _ dfactor: GLenum)
    func glBlendFuncSeparate(_ srcRGB: GLenum, _ dstRGB: GLenum, _ srcAlpha: GLenum, _ dstAlpha: GLenum)
    func glBlendFuncSeparateOES(_ srcRGB: GLenum, _ dstRGB: GLenum, _ srcAlpha: GLenum, _ dstAlpha: GLenum)
    func glBlitFramebuffer(_ srcX0: GLint, _ srcY0: GLint, _ srcX1: GLint, _ srcY1: GLint, _ dstX0: GLint, _ dstY0: GLint, _ dstX1: GLint, _ dstY1: GLint, _ mask: GLbitfield, _ filter: GLenum)
    func glBufferData(_ target: GLenum, _ size: GLsizeiptr, _ data: UnsafeRawPointer!, _ usage: GLenum)
    func glBufferSubData(_ target: GLenum, _ offset: GLintptr, _ size: GLsizeiptr, _ data: UnsafeRawPointer!)
    func glCheckFramebufferStatus(_ target: GLenum) -> GLenum
    func glCheckFramebufferStatusOES(_ target: GLenum) -> GLenum
    func glClear(_ mask: GLbitfield)
    func glClearBufferfi(_ buffer: GLenum, _ drawbuffer: GLint, _ depth: GLfloat, _ stencil: GLint)
    func glClearBufferfv(_ buffer: GLenum, _ drawbuffer: GLint, _ value: UnsafePointer<GLfloat>!)
    func glClearBufferiv(_ buffer: GLenum, _ drawbuffer: GLint, _ value: UnsafePointer<GLint>!)
    func glClearBufferuiv(_ buffer: GLenum, _ drawbuffer: GLint, _ value: UnsafePointer<GLuint>!)
    func glClearColor(_ red: GLfloat, _ green: GLfloat, _ blue: GLfloat, _ alpha: GLfloat)
    func glClearColorx(_ red: GLclampx, _ green: GLclampx, _ blue: GLclampx, _ alpha: GLclampx)
    func glClearDepthf(_ depth: GLclampf)
    func glClearDepthx(_ depth: GLclampx)
    func glClearStencil(_ s: GLint)
    func glClientActiveTexture(_ texture: GLenum)
    func glClientWaitSync(_ sync: GLsync!, _ flags: GLbitfield, _ timeout: GLuint64) -> GLenum
    func glClientWaitSyncAPPLE(_ sync: GLsync!, _ flags: GLbitfield, _ timeout: GLuint64) -> GLenum
    func glClipPlanef(_ plane: GLenum, _ equation: UnsafePointer<GLfloat>!)
    func glClipPlanex(_ plane: GLenum, _ equation: UnsafePointer<GLfixed>!)
    func glColor4f(_ red: GLfloat, _ green: GLfloat, _ blue: GLfloat, _ alpha: GLfloat)
    func glColor4ub(_ red: GLubyte, _ green: GLubyte, _ blue: GLubyte, _ alpha: GLubyte)
    func glColor4x(_ red: GLfixed, _ green: GLfixed, _ blue: GLfixed, _ alpha: GLfixed)
    func glColorMask(_ red: GLboolean, _ green: GLboolean, _ blue: GLboolean, _ alpha: GLboolean)
    func glColorPointer(_ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!)
    func glCompileShader(_ shader: GLuint)
    func glCompressedTexImage2D(_ target: GLenum, _ level: GLint, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei, _ border: GLint, _ imageSize: GLsizei, _ data: UnsafeRawPointer!)
    func glCompressedTexImage3D(_ target: GLenum, _ level: GLint, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei, _ depth: GLsizei, _ border: GLint, _ imageSize: GLsizei, _ data: UnsafeRawPointer!)
    func glCompressedTexSubImage2D(_ target: GLenum, _ level: GLint, _ xoffset: GLint, _ yoffset: GLint, _ width: GLsizei, _ height: GLsizei, _ format: GLenum, _ imageSize: GLsizei, _ data: UnsafeRawPointer!)
    func glCompressedTexSubImage3D(_ target: GLenum, _ level: GLint, _ xoffset: GLint, _ yoffset: GLint, _ zoffset: GLint, _ width: GLsizei, _ height: GLsizei, _ depth: GLsizei, _ format: GLenum, _ imageSize: GLsizei, _ data: UnsafeRawPointer!)
    func glCopyBufferSubData(_ readTarget: GLenum, _ writeTarget: GLenum, _ readOffset: GLintptr, _ writeOffset: GLintptr, _ size: GLsizeiptr)
    func glCopyTexImage2D(_ target: GLenum, _ level: GLint, _ internalformat: GLenum, _ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei, _ border: GLint)
    func glCopyTexSubImage2D(_ target: GLenum, _ level: GLint, _ xoffset: GLint, _ yoffset: GLint, _ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei)
    func glCopyTexSubImage3D(_ target: GLenum, _ level: GLint, _ xoffset: GLint, _ yoffset: GLint, _ zoffset: GLint, _ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei)
    func glCopyTextureLevelsAPPLE(_ destinationTexture: GLuint, _ sourceTexture: GLuint, _ sourceBaseLevel: GLint, _ sourceLevelCount: GLsizei)
    func glCreateProgram() -> GLuint
    func glCreateShader(_ type: GLenum) -> GLuint
    func glCreateShaderProgramvEXT(_ type: GLenum, _ count: GLsizei, _ strings: UnsafePointer<UnsafePointer<GLchar>?>!) -> GLuint
    func glCullFace(_ mode: GLenum)
    func glCurrentPaletteMatrixOES(_ matrixpaletteindex: GLuint)
    func glDeleteBuffers(_ n: GLsizei, _ buffers: UnsafePointer<GLuint>!)
    func glDeleteFramebuffers(_ n: GLsizei, _ framebuffers: UnsafePointer<GLuint>!)
    func glDeleteFramebuffersOES(_ n: GLsizei, _ framebuffers: UnsafePointer<GLuint>!)
    func glDeleteProgram(_ program: GLuint)
    func glDeleteProgramPipelinesEXT(_ n: GLsizei, _ pipelines: UnsafePointer<GLuint>!)
    func glDeleteQueries(_ n: GLsizei, _ ids: UnsafePointer<GLuint>!)
    func glDeleteQueriesEXT(_ n: GLsizei, _ ids: UnsafePointer<GLuint>!)
    func glDeleteRenderbuffers(_ n: GLsizei, _ renderbuffers: UnsafePointer<GLuint>!)
    func glDeleteRenderbuffersOES(_ n: GLsizei, _ renderbuffers: UnsafePointer<GLuint>!)
    func glDeleteSamplers(_ count: GLsizei, _ samplers: UnsafePointer<GLuint>!)
    func glDeleteShader(_ shader: GLuint)
    func glDeleteSync(_ sync: GLsync!)
    func glDeleteSyncAPPLE(_ sync: GLsync!)
    func glDeleteTextures(_ n: GLsizei, _ textures: UnsafePointer<GLuint>!)
    func glDeleteTransformFeedbacks(_ n: GLsizei, _ ids: UnsafePointer<GLuint>!)
    func glDeleteVertexArrays(_ n: GLsizei, _ arrays: UnsafePointer<GLuint>!)
    func glDeleteVertexArraysOES(_ n: GLsizei, _ arrays: UnsafePointer<GLuint>!)
    func glDepthFunc(_ `func`: GLenum)
    func glDepthMask(_ flag: GLboolean)
    func glDepthRangef(_ zNear: GLclampf, _ zFar: GLclampf)
    func glDepthRangex(_ zNear: GLclampx, _ zFar: GLclampx)
    func glDetachShader(_ program: GLuint, _ shader: GLuint)
    func glDisable(_ cap: GLenum)
    func glDisableClientState(_ array: GLenum)
    func glDisableVertexAttribArray(_ index: GLuint)
    func glDiscardFramebufferEXT(_ target: GLenum, _ numAttachments: GLsizei, _ attachments: UnsafePointer<GLenum>!)
    func glDrawArrays(_ mode: GLenum, _ first: GLint, _ count: GLsizei)
    func glDrawArraysInstanced(_ mode: GLenum, _ first: GLint, _ count: GLsizei, _ instancecount: GLsizei)
    func glDrawArraysInstancedEXT(_ mode: GLenum, _ first: GLint, _ count: GLsizei, _ instanceCount: GLsizei)
    func glDrawBuffers(_ n: GLsizei, _ bufs: UnsafePointer<GLenum>!)
    func glDrawElements(_ mode: GLenum, _ count: GLsizei, _ type: GLenum, _ indices: UnsafeRawPointer!)
    func glDrawElementsInstanced(_ mode: GLenum, _ count: GLsizei, _ type: GLenum, _ indices: UnsafeRawPointer!, _ instancecount: GLsizei)
    func glDrawElementsInstancedEXT(_ mode: GLenum, _ count: GLsizei, _ type: GLenum, _ indices: UnsafeRawPointer!, _ instanceCount: GLsizei)
    func glDrawRangeElements(_ mode: GLenum, _ start: GLuint, _ end: GLuint, _ count: GLsizei, _ type: GLenum, _ indices: UnsafeRawPointer!)
    func glDrawTexfOES(_ x: GLfloat, _ y: GLfloat, _ z: GLfloat, _ width: GLfloat, _ height: GLfloat)
    func glDrawTexfvOES(_ coords: UnsafePointer<GLfloat>!)
    func glDrawTexiOES(_ x: GLint, _ y: GLint, _ z: GLint, _ width: GLint, _ height: GLint)
    func glDrawTexivOES(_ coords: UnsafePointer<GLint>!)
    func glDrawTexsOES(_ x: GLshort, _ y: GLshort, _ z: GLshort, _ width: GLshort, _ height: GLshort)
    func glDrawTexsvOES(_ coords: UnsafePointer<GLshort>!)
    func glDrawTexxOES(_ x: GLfixed, _ y: GLfixed, _ z: GLfixed, _ width: GLfixed, _ height: GLfixed)
    func glDrawTexxvOES(_ coords: UnsafePointer<GLfixed>!)
    func glEnable(_ cap: GLenum)
    func glEnableClientState(_ array: GLenum)
    func glEnableVertexAttribArray(_ index: GLuint)
    func glEndQuery(_ target: GLenum)
    func glEndQueryEXT(_ target: GLenum)
    func glEndTransformFeedback()
    func glFenceSync(_ condition: GLenum, _ flags: GLbitfield) -> GLsync!
    func glFenceSyncAPPLE(_ condition: GLenum, _ flags: GLbitfield) -> GLsync!
    func glFinish()
    func glFlush()
    func glFlushMappedBufferRange(_ target: GLenum, _ offset: GLintptr, _ length: GLsizeiptr)
    func glFlushMappedBufferRangeEXT(_ target: GLenum, _ offset: GLintptr, _ length: GLsizeiptr)
    func glFogf(_ pname: GLenum, _ param: GLfloat)
    func glFogfv(_ pname: GLenum, _ params: UnsafePointer<GLfloat>!)
    func glFogx(_ pname: GLenum, _ param: GLfixed)
    func glFogxv(_ pname: GLenum, _ params: UnsafePointer<GLfixed>!)
    func glFramebufferRenderbuffer(_ target: GLenum, _ attachment: GLenum, _ renderbuffertarget: GLenum, _ renderbuffer: GLuint)
    func glFramebufferRenderbufferOES(_ target: GLenum, _ attachment: GLenum, _ renderbuffertarget: GLenum, _ renderbuffer: GLuint)
    func glFramebufferTexture2D(_ target: GLenum, _ attachment: GLenum, _ textarget: GLenum, _ texture: GLuint, _ level: GLint)
    func glFramebufferTexture2DOES(_ target: GLenum, _ attachment: GLenum, _ textarget: GLenum, _ texture: GLuint, _ level: GLint)
    func glFramebufferTextureLayer(_ target: GLenum, _ attachment: GLenum, _ texture: GLuint, _ level: GLint, _ layer: GLint)
    func glFrontFace(_ mode: GLenum)
    func glFrustumf(_ left: GLfloat, _ right: GLfloat, _ bottom: GLfloat, _ top: GLfloat, _ zNear: GLfloat, _ zFar: GLfloat)
    func glFrustumx(_ left: GLfixed, _ right: GLfixed, _ bottom: GLfixed, _ top: GLfixed, _ zNear: GLfixed, _ zFar: GLfixed)
    func glGenBuffers(_ n: GLsizei, _ buffers: UnsafeMutablePointer<GLuint>!)
    func glGenFramebuffers(_ n: GLsizei, _ framebuffers: UnsafeMutablePointer<GLuint>!)
    func glGenFramebuffersOES(_ n: GLsizei, _ framebuffers: UnsafeMutablePointer<GLuint>!)
    func glGenProgramPipelinesEXT(_ n: GLsizei, _ pipelines: UnsafeMutablePointer<GLuint>!)
    func glGenQueries(_ n: GLsizei, _ ids: UnsafeMutablePointer<GLuint>!)
    func glGenQueriesEXT(_ n: GLsizei, _ ids: UnsafeMutablePointer<GLuint>!)
    func glGenRenderbuffers(_ n: GLsizei, _ renderbuffers: UnsafeMutablePointer<GLuint>!)
    func glGenRenderbuffersOES(_ n: GLsizei, _ renderbuffers: UnsafeMutablePointer<GLuint>!)
    func glGenSamplers(_ count: GLsizei, _ samplers: UnsafeMutablePointer<GLuint>!)
    func glGenTextures(_ n: GLsizei, _ textures: UnsafeMutablePointer<GLuint>!)
    func glGenTransformFeedbacks(_ n: GLsizei, _ ids: UnsafeMutablePointer<GLuint>!)
    func glGenVertexArrays(_ n: GLsizei, _ arrays: UnsafeMutablePointer<GLuint>!)
    func glGenVertexArraysOES(_ n: GLsizei, _ arrays: UnsafeMutablePointer<GLuint>!)
    func glGenerateMipmap(_ target: GLenum)
    func glGenerateMipmapOES(_ target: GLenum)
    func glGetActiveAttrib(_ program: GLuint, _ index: GLuint, _ bufsize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ size: UnsafeMutablePointer<GLint>!, _ type: UnsafeMutablePointer<GLenum>!, _ name: UnsafeMutablePointer<GLchar>!)
    func glGetActiveUniform(_ program: GLuint, _ index: GLuint, _ bufsize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ size: UnsafeMutablePointer<GLint>!, _ type: UnsafeMutablePointer<GLenum>!, _ name: UnsafeMutablePointer<GLchar>!)
    func glGetActiveUniformBlockName(_ program: GLuint, _ uniformBlockIndex: GLuint, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ uniformBlockName: UnsafeMutablePointer<GLchar>!)
    func glGetActiveUniformBlockiv(_ program: GLuint, _ uniformBlockIndex: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!)
    func glGetActiveUniformsiv(_ program: GLuint, _ uniformCount: GLsizei, _ uniformIndices: UnsafePointer<GLuint>!, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!)
    func glGetAttachedShaders(_ program: GLuint, _ maxcount: GLsizei, _ count: UnsafeMutablePointer<GLsizei>!, _ shaders: UnsafeMutablePointer<GLuint>!)
    func glGetAttribLocation(_ program: GLuint, _ name: UnsafePointer<GLchar>!) -> Int32
    func glGetBooleanv(_ pname: GLenum, _ params: UnsafeMutablePointer<GLboolean>!)
    func glGetBufferParameteri64v(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint64>!)
    func glGetBufferParameteriv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!)
    func glGetBufferPointerv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<UnsafeMutableRawPointer?>!)
    func glGetBufferPointervOES(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<UnsafeMutableRawPointer?>!)
    func glGetClipPlanef(_ pname: GLenum, _ equation: UnsafeMutablePointer<GLfloat>!)
    func glGetClipPlanex(_ pname: GLenum, _ eqn: UnsafeMutablePointer<GLfixed>!)
    func glGetFixedv(_ pname: GLenum, _ params: UnsafeMutablePointer<GLfixed>!)
    func glGetFloatv(_ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!)
    func glGetFragDataLocation(_ program: GLuint, _ name: UnsafePointer<GLchar>!) -> GLint
    func glGetFramebufferAttachmentParameteriv(_ target: GLenum, _ attachment: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!)
    func glGetFramebufferAttachmentParameterivOES(_ target: GLenum, _ attachment: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!)
    func glGetInteger64i_v(_ target: GLenum, _ index: GLuint, _ data: UnsafeMutablePointer<GLint64>!)
    func glGetInteger64v(_ pname: GLenum, _ params: UnsafeMutablePointer<GLint64>!)
    func glGetInteger64vAPPLE(_ pname: GLenum, _ params: UnsafeMutablePointer<GLint64>!)
    func glGetIntegeri_v(_ target: GLenum, _ index: GLuint, _ data: UnsafeMutablePointer<GLint>!)
    func glGetIntegerv(_ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!)
    func glGetInternalformativ(_ target: GLenum, _ internalformat: GLenum, _ pname: GLenum, _ bufSize: GLsizei, _ params: UnsafeMutablePointer<GLint>!)
    func glGetLightfv(_ light: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!)
    func glGetLightxv(_ light: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfixed>!)
    func glGetMaterialfv(_ face: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!)
    func glGetMaterialxv(_ face: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfixed>!)
    func glGetObjectLabelEXT(_ type: GLenum, _ object: GLuint, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ label: UnsafeMutablePointer<GLchar>!)
    func glGetPointerv(_ pname: GLenum, _ params: UnsafeMutablePointer<UnsafeMutableRawPointer?>!)
    func glGetProgramBinary(_ program: GLuint, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ binaryFormat: UnsafeMutablePointer<GLenum>!, _ binary: UnsafeMutableRawPointer!)
    func glGetProgramInfoLog(_ program: GLuint, _ bufsize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ infolog: UnsafeMutablePointer<GLchar>!)
    func glGetProgramPipelineInfoLogEXT(_ pipeline: GLuint, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ infoLog: UnsafeMutablePointer<GLchar>!)
    func glGetProgramPipelineivEXT(_ pipeline: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!)
    func glGetProgramiv(_ program: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!)
    func glGetQueryObjectuiv(_ id: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLuint>!)
    func glGetQueryObjectuivEXT(_ id: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLuint>!)
    func glGetQueryiv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!)
    func glGetQueryivEXT(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!)
    func glGetRenderbufferParameteriv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!)
    func glGetRenderbufferParameterivOES(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!)
    func glGetSamplerParameterfv(_ sampler: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!)
    func glGetSamplerParameteriv(_ sampler: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!)
    func glGetShaderInfoLog(_ shader: GLuint, _ bufsize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ infolog: UnsafeMutablePointer<GLchar>!)
    func glGetShaderPrecisionFormat(_ shadertype: GLenum, _ precisiontype: GLenum, _ range: UnsafeMutablePointer<GLint>!, _ precision: UnsafeMutablePointer<GLint>!)
    func glGetShaderSource(_ shader: GLuint, _ bufsize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ source: UnsafeMutablePointer<GLchar>!)
    func glGetShaderiv(_ shader: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!)
    func glGetString(_ name: GLenum) -> UnsafePointer<GLubyte>!
    func glGetStringi(_ name: GLenum, _ index: GLuint) -> UnsafePointer<GLubyte>!
    func glGetSynciv(_ sync: GLsync!, _ pname: GLenum, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ values: UnsafeMutablePointer<GLint>!)
    func glGetSyncivAPPLE(_ sync: GLsync!, _ pname: GLenum, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ values: UnsafeMutablePointer<GLint>!)
    func glGetTexEnvfv(_ env: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!)
    func glGetTexEnviv(_ env: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!)
    func glGetTexEnvxv(_ env: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfixed>!)
    func glGetTexParameterfv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!)
    func glGetTexParameteriv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!)
    func glGetTexParameterxv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfixed>!)
    func glGetTransformFeedbackVarying(_ program: GLuint, _ index: GLuint, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ size: UnsafeMutablePointer<GLsizei>!, _ type: UnsafeMutablePointer<GLenum>!, _ name: UnsafeMutablePointer<GLchar>!)
    func glGetUniformBlockIndex(_ program: GLuint, _ uniformBlockName: UnsafePointer<GLchar>!) -> GLuint
    func glGetUniformIndices(_ program: GLuint, _ uniformCount: GLsizei, _ uniformNames: UnsafePointer<UnsafePointer<GLchar>?>!, _ uniformIndices: UnsafeMutablePointer<GLuint>!)
    func glGetUniformLocation(_ program: GLuint, _ name: UnsafePointer<GLchar>!) -> Int32
    func glGetUniformfv(_ program: GLuint, _ location: GLint, _ params: UnsafeMutablePointer<GLfloat>!)
    func glGetUniformiv(_ program: GLuint, _ location: GLint, _ params: UnsafeMutablePointer<GLint>!)
    func glGetUniformuiv(_ program: GLuint, _ location: GLint, _ params: UnsafeMutablePointer<GLuint>!)
    func glGetVertexAttribIiv(_ index: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!)
    func glGetVertexAttribIuiv(_ index: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLuint>!)
    func glGetVertexAttribPointerv(_ index: GLuint, _ pname: GLenum, _ pointer: UnsafeMutablePointer<UnsafeMutableRawPointer?>!)
    func glGetVertexAttribfv(_ index: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!)
    func glGetVertexAttribiv(_ index: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!)
    func glHint(_ target: GLenum, _ mode: GLenum)
    func glInsertEventMarkerEXT(_ length: GLsizei, _ marker: UnsafePointer<GLchar>!)
    func glInvalidateFramebuffer(_ target: GLenum, _ numAttachments: GLsizei, _ attachments: UnsafePointer<GLenum>!)
    func glInvalidateSubFramebuffer(_ target: GLenum, _ numAttachments: GLsizei, _ attachments: UnsafePointer<GLenum>!, _ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei)
    func glIsBuffer(_ buffer: GLuint) -> GLboolean
    func glIsEnabled(_ cap: GLenum) -> GLboolean
    func glIsFramebuffer(_ framebuffer: GLuint) -> GLboolean
    func glIsFramebufferOES(_ framebuffer: GLuint) -> GLboolean
    func glIsProgram(_ program: GLuint) -> GLboolean
    func glIsProgramPipelineEXT(_ pipeline: GLuint) -> GLboolean
    func glIsQuery(_ id: GLuint) -> GLboolean
    func glIsQueryEXT(_ id: GLuint) -> GLboolean
    func glIsRenderbuffer(_ renderbuffer: GLuint) -> GLboolean
    func glIsRenderbufferOES(_ renderbuffer: GLuint) -> GLboolean
    func glIsSampler(_ sampler: GLuint) -> GLboolean
    func glIsShader(_ shader: GLuint) -> GLboolean
    func glIsSync(_ sync: GLsync!) -> GLboolean
    func glIsSyncAPPLE(_ sync: GLsync!) -> GLboolean
    func glIsTexture(_ texture: GLuint) -> GLboolean
    func glIsTransformFeedback(_ id: GLuint) -> GLboolean
    func glIsVertexArray(_ array: GLuint) -> GLboolean
    func glIsVertexArrayOES(_ array: GLuint) -> GLboolean
    func glLabelObjectEXT(_ type: GLenum, _ object: GLuint, _ length: GLsizei, _ label: UnsafePointer<GLchar>!)
    func glLightModelf(_ pname: GLenum, _ param: GLfloat)
    func glLightModelfv(_ pname: GLenum, _ params: UnsafePointer<GLfloat>!)
    func glLightModelx(_ pname: GLenum, _ param: GLfixed)
    func glLightModelxv(_ pname: GLenum, _ params: UnsafePointer<GLfixed>!)
    func glLightf(_ light: GLenum, _ pname: GLenum, _ param: GLfloat)
    func glLightfv(_ light: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfloat>!)
    func glLightx(_ light: GLenum, _ pname: GLenum, _ param: GLfixed)
    func glLightxv(_ light: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfixed>!)
    func glLineWidth(_ width: GLfloat)
    func glLineWidthx(_ width: GLfixed)
    func glLinkProgram(_ program: GLuint)
    func glLoadIdentity()
    func glLoadMatrixf(_ m: UnsafePointer<GLfloat>!)
    func glLoadMatrixx(_ m: UnsafePointer<GLfixed>!)
    func glLoadPaletteFromModelViewMatrixOES()
    func glLogicOp(_ opcode: GLenum)
    func glMapBufferOES(_ target: GLenum, _ access: GLenum) -> UnsafeMutableRawPointer!
    func glMapBufferRange(_ target: GLenum, _ offset: GLintptr, _ length: GLsizeiptr, _ access: GLbitfield) -> UnsafeMutableRawPointer!
    func glMapBufferRangeEXT(_ target: GLenum, _ offset: GLintptr, _ length: GLsizeiptr, _ access: GLbitfield) -> UnsafeMutableRawPointer!
    func glMaterialf(_ face: GLenum, _ pname: GLenum, _ param: GLfloat)
    func glMaterialfv(_ face: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfloat>!)
    func glMaterialx(_ face: GLenum, _ pname: GLenum, _ param: GLfixed)
    func glMaterialxv(_ face: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfixed>!)
    func glMatrixIndexPointerOES(_ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!)
    func glMatrixMode(_ mode: GLenum)
    func glMultMatrixf(_ m: UnsafePointer<GLfloat>!)
    func glMultMatrixx(_ m: UnsafePointer<GLfixed>!)
    func glMultiTexCoord4f(_ target: GLenum, _ s: GLfloat, _ t: GLfloat, _ r: GLfloat, _ q: GLfloat)
    func glMultiTexCoord4x(_ target: GLenum, _ s: GLfixed, _ t: GLfixed, _ r: GLfixed, _ q: GLfixed)
    func glNormal3f(_ nx: GLfloat, _ ny: GLfloat, _ nz: GLfloat)
    func glNormal3x(_ nx: GLfixed, _ ny: GLfixed, _ nz: GLfixed)
    func glNormalPointer(_ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!)
    func glOrthof(_ left: GLfloat, _ right: GLfloat, _ bottom: GLfloat, _ top: GLfloat, _ zNear: GLfloat, _ zFar: GLfloat)
    func glOrthox(_ left: GLfixed, _ right: GLfixed, _ bottom: GLfixed, _ top: GLfixed, _ zNear: GLfixed, _ zFar: GLfixed)
    func glPauseTransformFeedback()
    func glPixelStorei(_ pname: GLenum, _ param: GLint)
    func glPointParameterf(_ pname: GLenum, _ param: GLfloat)
    func glPointParameterfv(_ pname: GLenum, _ params: UnsafePointer<GLfloat>!)
    func glPointParameterx(_ pname: GLenum, _ param: GLfixed)
    func glPointParameterxv(_ pname: GLenum, _ params: UnsafePointer<GLfixed>!)
    func glPointSize(_ size: GLfloat)
    func glPointSizePointerOES(_ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!)
    func glPointSizex(_ size: GLfixed)
    func glPolygonOffset(_ factor: GLfloat, _ units: GLfloat)
    func glPolygonOffsetx(_ factor: GLfixed, _ units: GLfixed)
    func glPopGroupMarkerEXT()
    func glPopMatrix()
    func glProgramBinary(_ program: GLuint, _ binaryFormat: GLenum, _ binary: UnsafeRawPointer!, _ length: GLsizei)
    func glProgramParameteri(_ program: GLuint, _ pname: GLenum, _ value: GLint)
    func glProgramParameteriEXT(_ program: GLuint, _ pname: GLenum, _ value: GLint)
    func glProgramUniform1fEXT(_ program: GLuint, _ location: GLint, _ x: GLfloat)
    func glProgramUniform1fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLfloat>!)
    func glProgramUniform1iEXT(_ program: GLuint, _ location: GLint, _ x: GLint)
    func glProgramUniform1ivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLint>!)
    func glProgramUniform1uiEXT(_ program: GLuint, _ location: GLint, _ x: GLuint)
    func glProgramUniform1uivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!)
    func glProgramUniform2fEXT(_ program: GLuint, _ location: GLint, _ x: GLfloat, _ y: GLfloat)
    func glProgramUniform2fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLfloat>!)
    func glProgramUniform2iEXT(_ program: GLuint, _ location: GLint, _ x: GLint, _ y: GLint)
    func glProgramUniform2ivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLint>!)
    func glProgramUniform2uiEXT(_ program: GLuint, _ location: GLint, _ x: GLuint, _ y: GLuint)
    func glProgramUniform2uivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!)
    func glProgramUniform3fEXT(_ program: GLuint, _ location: GLint, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat)
    func glProgramUniform3fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLfloat>!)
    func glProgramUniform3iEXT(_ program: GLuint, _ location: GLint, _ x: GLint, _ y: GLint, _ z: GLint)
    func glProgramUniform3ivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLint>!)
    func glProgramUniform3uiEXT(_ program: GLuint, _ location: GLint, _ x: GLuint, _ y: GLuint, _ z: GLuint)
    func glProgramUniform3uivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!)
    func glProgramUniform4fEXT(_ program: GLuint, _ location: GLint, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat, _ w: GLfloat)
    func glProgramUniform4fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLfloat>!)
    func glProgramUniform4iEXT(_ program: GLuint, _ location: GLint, _ x: GLint, _ y: GLint, _ z: GLint, _ w: GLint)
    func glProgramUniform4ivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLint>!)
    func glProgramUniform4uiEXT(_ program: GLuint, _ location: GLint, _ x: GLuint, _ y: GLuint, _ z: GLuint, _ w: GLuint)
    func glProgramUniform4uivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!)
    func glProgramUniformMatrix2fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!)
    func glProgramUniformMatrix2x3fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!)
    func glProgramUniformMatrix2x4fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!)
    func glProgramUniformMatrix3fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!)
    func glProgramUniformMatrix3x2fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!)
    func glProgramUniformMatrix3x4fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!)
    func glProgramUniformMatrix4fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!)
    func glProgramUniformMatrix4x2fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!)
    func glProgramUniformMatrix4x3fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!)
    func glPushGroupMarkerEXT(_ length: GLsizei, _ marker: UnsafePointer<GLchar>!)
    func glPushMatrix()
    func glReadBuffer(_ mode: GLenum)
    func glReadPixels(_ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei, _ format: GLenum, _ type: GLenum, _ pixels: UnsafeMutableRawPointer!)
    func glReleaseShaderCompiler()
    func glRenderbufferStorage(_ target: GLenum, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei)
    func glRenderbufferStorageMultisample(_ target: GLenum, _ samples: GLsizei, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei)
    func glRenderbufferStorageMultisampleAPPLE(_ target: GLenum, _ samples: GLsizei, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei)
    func glRenderbufferStorageOES(_ target: GLenum, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei)
    func glResolveMultisampleFramebufferAPPLE()
    func glResumeTransformFeedback()
    func glRotatef(_ angle: GLfloat, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat)
    func glRotatex(_ angle: GLfixed, _ x: GLfixed, _ y: GLfixed, _ z: GLfixed)
    func glSampleCoverage(_ value: GLclampf, _ invert: GLboolean)
    func glSampleCoveragex(_ value: GLclampx, _ invert: GLboolean)
    func glSamplerParameterf(_ sampler: GLuint, _ pname: GLenum, _ param: GLfloat)
    func glSamplerParameterfv(_ sampler: GLuint, _ pname: GLenum, _ param: UnsafePointer<GLfloat>!)
    func glSamplerParameteri(_ sampler: GLuint, _ pname: GLenum, _ param: GLint)
    func glSamplerParameteriv(_ sampler: GLuint, _ pname: GLenum, _ param: UnsafePointer<GLint>!)
    func glScalef(_ x: GLfloat, _ y: GLfloat, _ z: GLfloat)
    func glScalex(_ x: GLfixed, _ y: GLfixed, _ z: GLfixed)
    func glScissor(_ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei)
    func glShadeModel(_ mode: GLenum)
    func glShaderBinary(_ n: GLsizei, _ shaders: UnsafePointer<GLuint>!, _ binaryformat: GLenum, _ binary: UnsafeRawPointer!, _ length: GLsizei)
    func glShaderSource(_ shader: GLuint, _ count: GLsizei, _ string: UnsafePointer<UnsafePointer<GLchar>?>!, _ length: UnsafePointer<GLint>!)
    func glStencilFunc(_ `func`: GLenum, _ ref: GLint, _ mask: GLuint)
    func glStencilFuncSeparate(_ face: GLenum, _ `func`: GLenum, _ ref: GLint, _ mask: GLuint)
    func glStencilMask(_ mask: GLuint)
    func glStencilMaskSeparate(_ face: GLenum, _ mask: GLuint)
    func glStencilOp(_ fail: GLenum, _ zfail: GLenum, _ zpass: GLenum)
    func glStencilOpSeparate(_ face: GLenum, _ fail: GLenum, _ zfail: GLenum, _ zpass: GLenum)
    func glTexCoordPointer(_ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!)
    func glTexEnvf(_ target: GLenum, _ pname: GLenum, _ param: GLfloat)
    func glTexEnvfv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfloat>!)
    func glTexEnvi(_ target: GLenum, _ pname: GLenum, _ param: GLint)
    func glTexEnviv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLint>!)
    func glTexEnvx(_ target: GLenum, _ pname: GLenum, _ param: GLfixed)
    func glTexEnvxv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfixed>!)
    func glTexImage2D(_ target: GLenum, _ level: GLint, _ internalformat: GLint, _ width: GLsizei, _ height: GLsizei, _ border: GLint, _ format: GLenum, _ type: GLenum, _ pixels: UnsafeRawPointer!)
    func glTexImage3D(_ target: GLenum, _ level: GLint, _ internalformat: GLint, _ width: GLsizei, _ height: GLsizei, _ depth: GLsizei, _ border: GLint, _ format: GLenum, _ type: GLenum, _ pixels: UnsafeRawPointer!)
    func glTexParameterf(_ target: GLenum, _ pname: GLenum, _ param: GLfloat)
    func glTexParameterfv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfloat>!)
    func glTexParameteri(_ target: GLenum, _ pname: GLenum, _ param: GLint)
    func glTexParameteriv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLint>!)
    func glTexParameterx(_ target: GLenum, _ pname: GLenum, _ param: GLfixed)
    func glTexParameterxv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfixed>!)
    func glTexStorage2D(_ target: GLenum, _ levels: GLsizei, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei)
    func glTexStorage2DEXT(_ target: GLenum, _ levels: GLsizei, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei)
    func glTexStorage3D(_ target: GLenum, _ levels: GLsizei, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei, _ depth: GLsizei)
    func glTexSubImage2D(_ target: GLenum, _ level: GLint, _ xoffset: GLint, _ yoffset: GLint, _ width: GLsizei, _ height: GLsizei, _ format: GLenum, _ type: GLenum, _ pixels: UnsafeRawPointer!)
    func glTexSubImage3D(_ target: GLenum, _ level: GLint, _ xoffset: GLint, _ yoffset: GLint, _ zoffset: GLint, _ width: GLsizei, _ height: GLsizei, _ depth: GLsizei, _ format: GLenum, _ type: GLenum, _ pixels: UnsafeRawPointer!)
    func glTransformFeedbackVaryings(_ program: GLuint, _ count: GLsizei, _ varyings: UnsafePointer<UnsafePointer<GLchar>?>!, _ bufferMode: GLenum)
    func glTranslatef(_ x: GLfloat, _ y: GLfloat, _ z: GLfloat)
    func glTranslatex(_ x: GLfixed, _ y: GLfixed, _ z: GLfixed)
    func glUniform1f(_ location: GLint, _ x: GLfloat)
    func glUniform1fv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLfloat>!)
    func glUniform1i(_ location: GLint, _ x: GLint)
    func glUniform1iv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLint>!)
    func glUniform1ui(_ location: GLint, _ v0: GLuint)
    func glUniform1uiv(_ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!)
    func glUniform2f(_ location: GLint, _ x: GLfloat, _ y: GLfloat)
    func glUniform2fv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLfloat>!)
    func glUniform2i(_ location: GLint, _ x: GLint, _ y: GLint)
    func glUniform2iv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLint>!)
    func glUniform2ui(_ location: GLint, _ v0: GLuint, _ v1: GLuint)
    func glUniform2uiv(_ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!)
    func glUniform3f(_ location: GLint, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat)
    func glUniform3fv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLfloat>!)
    func glUniform3i(_ location: GLint, _ x: GLint, _ y: GLint, _ z: GLint)
    func glUniform3iv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLint>!)
    func glUniform3ui(_ location: GLint, _ v0: GLuint, _ v1: GLuint, _ v2: GLuint)
    func glUniform3uiv(_ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!)
    func glUniform4f(_ location: GLint, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat, _ w: GLfloat)
    func glUniform4fv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLfloat>!)
    func glUniform4i(_ location: GLint, _ x: GLint, _ y: GLint, _ z: GLint, _ w: GLint)
    func glUniform4iv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLint>!)
    func glUniform4ui(_ location: GLint, _ v0: GLuint, _ v1: GLuint, _ v2: GLuint, _ v3: GLuint)
    func glUniform4uiv(_ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!)
    func glUniformBlockBinding(_ program: GLuint, _ uniformBlockIndex: GLuint, _ uniformBlockBinding: GLuint)
    func glUniformMatrix2fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!)
    func glUniformMatrix2x3fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!)
    func glUniformMatrix2x4fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!)
    func glUniformMatrix3fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!)
    func glUniformMatrix3x2fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!)
    func glUniformMatrix3x4fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!)
    func glUniformMatrix4fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!)
    func glUniformMatrix4x2fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!)
    func glUniformMatrix4x3fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!)
    func glUnmapBuffer(_ target: GLenum) -> GLboolean
    func glUnmapBufferOES(_ target: GLenum) -> GLboolean
    func glUseProgram(_ program: GLuint)
    func glUseProgramStagesEXT(_ pipeline: GLuint, _ stages: GLbitfield, _ program: GLuint)
    func glValidateProgram(_ program: GLuint)
    func glValidateProgramPipelineEXT(_ pipeline: GLuint)
    func glVertexAttrib1f(_ indx: GLuint, _ x: GLfloat)
    func glVertexAttrib1fv(_ indx: GLuint, _ values: UnsafePointer<GLfloat>!)
    func glVertexAttrib2f(_ indx: GLuint, _ x: GLfloat, _ y: GLfloat)
    func glVertexAttrib2fv(_ indx: GLuint, _ values: UnsafePointer<GLfloat>!)
    func glVertexAttrib3f(_ indx: GLuint, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat)
    func glVertexAttrib3fv(_ indx: GLuint, _ values: UnsafePointer<GLfloat>!)
    func glVertexAttrib4f(_ indx: GLuint, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat, _ w: GLfloat)
    func glVertexAttrib4fv(_ indx: GLuint, _ values: UnsafePointer<GLfloat>!)
    func glVertexAttribDivisor(_ index: GLuint, _ divisor: GLuint)
    func glVertexAttribDivisorEXT(_ index: GLuint, _ divisor: GLuint)
    func glVertexAttribI4i(_ index: GLuint, _ x: GLint, _ y: GLint, _ z: GLint, _ w: GLint)
    func glVertexAttribI4iv(_ index: GLuint, _ v: UnsafePointer<GLint>!)
    func glVertexAttribI4ui(_ index: GLuint, _ x: GLuint, _ y: GLuint, _ z: GLuint, _ w: GLuint)
    func glVertexAttribI4uiv(_ index: GLuint, _ v: UnsafePointer<GLuint>!)
    func glVertexAttribIPointer(_ index: GLuint, _ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!)
    func glVertexAttribPointer(_ indx: GLuint, _ size: GLint, _ type: GLenum, _ normalized: GLboolean, _ stride: GLsizei, _ ptr: UnsafeRawPointer!)
    func glVertexPointer(_ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!)
    func glViewport(_ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei)
    func glWaitSync(_ sync: GLsync!, _ flags: GLbitfield, _ timeout: GLuint64)
    func glWaitSyncAPPLE(_ sync: GLsync!, _ flags: GLbitfield, _ timeout: GLuint64)
    func glWeightPointerOES(_ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!)
}


extension GLESCommands {
    func glActiveShaderProgramEXT(_ pipeline: GLuint, _ program: GLuint) {
        _ = pipeline
        _ = program
        unimplemented()
    }

    func glActiveTexture(_ texture: GLenum) {
        _ = texture
        unimplemented()
    }

    func glAlphaFunc(_ `func`: GLenum, _ ref: GLclampf) {
        _ = `func`
        _ = ref
        unimplemented()
    }

    func glAlphaFuncx(_ `func`: GLenum, _ ref: GLclampx) {
        _ = `func`
        _ = ref
        unimplemented()
    }

    func glAttachShader(_ program: GLuint, _ shader: GLuint) {
        _ = program
        _ = shader
        unimplemented()
    }

    func glBeginQuery(_ target: GLenum, _ id: GLuint) {
        _ = target
        _ = id
        unimplemented()
    }

    func glBeginQueryEXT(_ target: GLenum, _ id: GLuint) {
        _ = target
        _ = id
        unimplemented()
    }

    func glBeginTransformFeedback(_ primitiveMode: GLenum) {
        _ = primitiveMode
        unimplemented()
    }

    func glBindAttribLocation(_ program: GLuint, _ index: GLuint, _ name: UnsafePointer<GLchar>!) {
        _ = program
        _ = index
        _ = name
        unimplemented()
    }

    func glBindBuffer(_ target: GLenum, _ buffer: GLuint) {
        _ = target
        _ = buffer
        unimplemented()
    }

    func glBindBufferBase(_ target: GLenum, _ index: GLuint, _ buffer: GLuint) {
        _ = target
        _ = index
        _ = buffer
        unimplemented()
    }

    func glBindBufferRange(_ target: GLenum, _ index: GLuint, _ buffer: GLuint, _ offset: GLintptr, _ size: GLsizeiptr) {
        _ = target
        _ = index
        _ = buffer
        _ = offset
        _ = size
        unimplemented()
    }

    func glBindFramebuffer(_ target: GLenum, _ framebuffer: GLuint) {
        _ = target
        _ = framebuffer
        unimplemented()
    }

    func glBindFramebufferOES(_ target: GLenum, _ framebuffer: GLuint) {
        _ = target
        _ = framebuffer
        unimplemented()
    }

    func glBindProgramPipelineEXT(_ pipeline: GLuint) {
        _ = pipeline
        unimplemented()
    }

    func glBindRenderbuffer(_ target: GLenum, _ renderbuffer: GLuint) {
        _ = target
        _ = renderbuffer
        unimplemented()
    }

    func glBindRenderbufferOES(_ target: GLenum, _ renderbuffer: GLuint) {
        _ = target
        _ = renderbuffer
        unimplemented()
    }

    func glBindSampler(_ unit: GLuint, _ sampler: GLuint) {
        _ = unit
        _ = sampler
        unimplemented()
    }

    func glBindTexture(_ target: GLenum, _ texture: GLuint) {
        _ = target
        _ = texture
        unimplemented()
    }

    func glBindTransformFeedback(_ target: GLenum, _ id: GLuint) {
        _ = target
        _ = id
        unimplemented()
    }

    func glBindVertexArray(_ array: GLuint) {
        _ = array
        unimplemented()
    }

    func glBindVertexArrayOES(_ array: GLuint) {
        _ = array
        unimplemented()
    }

    func glBlendColor(_ red: GLfloat, _ green: GLfloat, _ blue: GLfloat, _ alpha: GLfloat) {
        _ = red
        _ = green
        _ = blue
        _ = alpha
        unimplemented()
    }

    func glBlendEquation(_ mode: GLenum) {
        _ = mode
        unimplemented()
    }

    func glBlendEquationOES(_ mode: GLenum) {
        _ = mode
        unimplemented()
    }

    func glBlendEquationSeparate(_ modeRGB: GLenum, _ modeAlpha: GLenum) {
        _ = modeRGB
        _ = modeAlpha
        unimplemented()
    }

    func glBlendEquationSeparateOES(_ modeRGB: GLenum, _ modeAlpha: GLenum) {
        _ = modeRGB
        _ = modeAlpha
        unimplemented()
    }

    func glBlendFunc(_ sfactor: GLenum, _ dfactor: GLenum) {
        _ = sfactor
        _ = dfactor
        unimplemented()
    }

    func glBlendFuncSeparate(_ srcRGB: GLenum, _ dstRGB: GLenum, _ srcAlpha: GLenum, _ dstAlpha: GLenum) {
        _ = srcRGB
        _ = dstRGB
        _ = srcAlpha
        _ = dstAlpha
        unimplemented()
    }

    func glBlendFuncSeparateOES(_ srcRGB: GLenum, _ dstRGB: GLenum, _ srcAlpha: GLenum, _ dstAlpha: GLenum) {
        _ = srcRGB
        _ = dstRGB
        _ = srcAlpha
        _ = dstAlpha
        unimplemented()
    }

    func glBlitFramebuffer(_ srcX0: GLint, _ srcY0: GLint, _ srcX1: GLint, _ srcY1: GLint, _ dstX0: GLint, _ dstY0: GLint, _ dstX1: GLint, _ dstY1: GLint, _ mask: GLbitfield, _ filter: GLenum) {
        _ = srcX0
        _ = srcY0
        _ = srcX1
        _ = srcY1
        _ = dstX0
        _ = dstY0
        _ = dstX1
        _ = dstY1
        _ = mask
        _ = filter
        unimplemented()
    }

    func glBufferData(_ target: GLenum, _ size: GLsizeiptr, _ data: UnsafeRawPointer!, _ usage: GLenum) {
        _ = target
        _ = size
        _ = data
        _ = usage
        unimplemented()
    }

    func glBufferSubData(_ target: GLenum, _ offset: GLintptr, _ size: GLsizeiptr, _ data: UnsafeRawPointer!) {
        _ = target
        _ = offset
        _ = size
        _ = data
        unimplemented()
    }

    func glCheckFramebufferStatus(_ target: GLenum) -> GLenum {
        _ = target
        unimplemented()
        return 0
    }

    func glCheckFramebufferStatusOES(_ target: GLenum) -> GLenum {
        _ = target
        unimplemented()
        return 0
    }

    func glClear(_ mask: GLbitfield) {
        _ = mask
        unimplemented()
    }

    func glClearBufferfi(_ buffer: GLenum, _ drawbuffer: GLint, _ depth: GLfloat, _ stencil: GLint) {
        _ = buffer
        _ = drawbuffer
        _ = depth
        _ = stencil
        unimplemented()
    }

    func glClearBufferfv(_ buffer: GLenum, _ drawbuffer: GLint, _ value: UnsafePointer<GLfloat>!) {
        _ = buffer
        _ = drawbuffer
        _ = value
        unimplemented()
    }

    func glClearBufferiv(_ buffer: GLenum, _ drawbuffer: GLint, _ value: UnsafePointer<GLint>!) {
        _ = buffer
        _ = drawbuffer
        _ = value
        unimplemented()
    }

    func glClearBufferuiv(_ buffer: GLenum, _ drawbuffer: GLint, _ value: UnsafePointer<GLuint>!) {
        _ = buffer
        _ = drawbuffer
        _ = value
        unimplemented()
    }

    func glClearColor(_ red: GLfloat, _ green: GLfloat, _ blue: GLfloat, _ alpha: GLfloat) {
        _ = red
        _ = green
        _ = blue
        _ = alpha
        unimplemented()
    }

    func glClearColorx(_ red: GLclampx, _ green: GLclampx, _ blue: GLclampx, _ alpha: GLclampx) {
        _ = red
        _ = green
        _ = blue
        _ = alpha
        unimplemented()
    }

    func glClearDepthf(_ depth: GLclampf) {
        _ = depth
        unimplemented()
    }

    func glClearDepthx(_ depth: GLclampx) {
        _ = depth
        unimplemented()
    }

    func glClearStencil(_ s: GLint) {
        _ = s
        unimplemented()
    }

    func glClientActiveTexture(_ texture: GLenum) {
        _ = texture
        unimplemented()
    }

    func glClientWaitSync(_ sync: GLsync!, _ flags: GLbitfield, _ timeout: GLuint64) -> GLenum {
        _ = sync
        _ = flags
        _ = timeout
        unimplemented()
        return 0
    }

    func glClientWaitSyncAPPLE(_ sync: GLsync!, _ flags: GLbitfield, _ timeout: GLuint64) -> GLenum {
        _ = sync
        _ = flags
        _ = timeout
        unimplemented()
        return 0
    }

    func glClipPlanef(_ plane: GLenum, _ equation: UnsafePointer<GLfloat>!) {
        _ = plane
        _ = equation
        unimplemented()
    }

    func glClipPlanex(_ plane: GLenum, _ equation: UnsafePointer<GLfixed>!) {
        _ = plane
        _ = equation
        unimplemented()
    }

    func glColor4f(_ red: GLfloat, _ green: GLfloat, _ blue: GLfloat, _ alpha: GLfloat) {
        _ = red
        _ = green
        _ = blue
        _ = alpha
        unimplemented()
    }

    func glColor4ub(_ red: GLubyte, _ green: GLubyte, _ blue: GLubyte, _ alpha: GLubyte) {
        _ = red
        _ = green
        _ = blue
        _ = alpha
        unimplemented()
    }

    func glColor4x(_ red: GLfixed, _ green: GLfixed, _ blue: GLfixed, _ alpha: GLfixed) {
        _ = red
        _ = green
        _ = blue
        _ = alpha
        unimplemented()
    }

    func glColorMask(_ red: GLboolean, _ green: GLboolean, _ blue: GLboolean, _ alpha: GLboolean) {
        _ = red
        _ = green
        _ = blue
        _ = alpha
        unimplemented()
    }

    func glColorPointer(_ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!) {
        _ = size
        _ = type
        _ = stride
        _ = pointer
        unimplemented()
    }

    func glCompileShader(_ shader: GLuint) {
        _ = shader
        unimplemented()
    }

    func glCompressedTexImage2D(_ target: GLenum, _ level: GLint, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei, _ border: GLint, _ imageSize: GLsizei, _ data: UnsafeRawPointer!) {
        _ = target
        _ = level
        _ = internalformat
        _ = width
        _ = height
        _ = border
        _ = imageSize
        _ = data
        unimplemented()
    }

    func glCompressedTexImage3D(_ target: GLenum, _ level: GLint, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei, _ depth: GLsizei, _ border: GLint, _ imageSize: GLsizei, _ data: UnsafeRawPointer!) {
        _ = target
        _ = level
        _ = internalformat
        _ = width
        _ = height
        _ = depth
        _ = border
        _ = imageSize
        _ = data
        unimplemented()
    }

    func glCompressedTexSubImage2D(_ target: GLenum, _ level: GLint, _ xoffset: GLint, _ yoffset: GLint, _ width: GLsizei, _ height: GLsizei, _ format: GLenum, _ imageSize: GLsizei, _ data: UnsafeRawPointer!) {
        _ = target
        _ = level
        _ = xoffset
        _ = yoffset
        _ = width
        _ = height
        _ = format
        _ = imageSize
        _ = data
        unimplemented()
    }

    func glCompressedTexSubImage3D(_ target: GLenum, _ level: GLint, _ xoffset: GLint, _ yoffset: GLint, _ zoffset: GLint, _ width: GLsizei, _ height: GLsizei, _ depth: GLsizei, _ format: GLenum, _ imageSize: GLsizei, _ data: UnsafeRawPointer!) {
        _ = target
        _ = level
        _ = xoffset
        _ = yoffset
        _ = zoffset
        _ = width
        _ = height
        _ = depth
        _ = format
        _ = imageSize
        _ = data
        unimplemented()
    }

    func glCopyBufferSubData(_ readTarget: GLenum, _ writeTarget: GLenum, _ readOffset: GLintptr, _ writeOffset: GLintptr, _ size: GLsizeiptr) {
        _ = readTarget
        _ = writeTarget
        _ = readOffset
        _ = writeOffset
        _ = size
        unimplemented()
    }

    func glCopyTexImage2D(_ target: GLenum, _ level: GLint, _ internalformat: GLenum, _ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei, _ border: GLint) {
        _ = target
        _ = level
        _ = internalformat
        _ = x
        _ = y
        _ = width
        _ = height
        _ = border
        unimplemented()
    }

    func glCopyTexSubImage2D(_ target: GLenum, _ level: GLint, _ xoffset: GLint, _ yoffset: GLint, _ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei) {
        _ = target
        _ = level
        _ = xoffset
        _ = yoffset
        _ = x
        _ = y
        _ = width
        _ = height
        unimplemented()
    }

    func glCopyTexSubImage3D(_ target: GLenum, _ level: GLint, _ xoffset: GLint, _ yoffset: GLint, _ zoffset: GLint, _ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei) {
        _ = target
        _ = level
        _ = xoffset
        _ = yoffset
        _ = zoffset
        _ = x
        _ = y
        _ = width
        _ = height
        unimplemented()
    }

    func glCopyTextureLevelsAPPLE(_ destinationTexture: GLuint, _ sourceTexture: GLuint, _ sourceBaseLevel: GLint, _ sourceLevelCount: GLsizei) {
        _ = destinationTexture
        _ = sourceTexture
        _ = sourceBaseLevel
        _ = sourceLevelCount
        unimplemented()
    }

    func glCreateProgram() -> GLuint {
        unimplemented()
        return 0
    }

    func glCreateShader(_ type: GLenum) -> GLuint {
        _ = type
        unimplemented()
        return 0
    }

    func glCreateShaderProgramvEXT(_ type: GLenum, _ count: GLsizei, _ strings: UnsafePointer<UnsafePointer<GLchar>?>!) -> GLuint {
        _ = type
        _ = count
        _ = strings
        unimplemented()
        return 0
    }

    func glCullFace(_ mode: GLenum) {
        _ = mode
        unimplemented()
    }

    func glCurrentPaletteMatrixOES(_ matrixpaletteindex: GLuint) {
        _ = matrixpaletteindex
        unimplemented()
    }

    func glDeleteBuffers(_ n: GLsizei, _ buffers: UnsafePointer<GLuint>!) {
        _ = n
        _ = buffers
        unimplemented()
    }

    func glDeleteFramebuffers(_ n: GLsizei, _ framebuffers: UnsafePointer<GLuint>!) {
        _ = n
        _ = framebuffers
        unimplemented()
    }

    func glDeleteFramebuffersOES(_ n: GLsizei, _ framebuffers: UnsafePointer<GLuint>!) {
        _ = n
        _ = framebuffers
        unimplemented()
    }

    func glDeleteProgram(_ program: GLuint) {
        _ = program
        unimplemented()
    }

    func glDeleteProgramPipelinesEXT(_ n: GLsizei, _ pipelines: UnsafePointer<GLuint>!) {
        _ = n
        _ = pipelines
        unimplemented()
    }

    func glDeleteQueries(_ n: GLsizei, _ ids: UnsafePointer<GLuint>!) {
        _ = n
        _ = ids
        unimplemented()
    }

    func glDeleteQueriesEXT(_ n: GLsizei, _ ids: UnsafePointer<GLuint>!) {
        _ = n
        _ = ids
        unimplemented()
    }

    func glDeleteRenderbuffers(_ n: GLsizei, _ renderbuffers: UnsafePointer<GLuint>!) {
        _ = n
        _ = renderbuffers
        unimplemented()
    }

    func glDeleteRenderbuffersOES(_ n: GLsizei, _ renderbuffers: UnsafePointer<GLuint>!) {
        _ = n
        _ = renderbuffers
        unimplemented()
    }

    func glDeleteSamplers(_ count: GLsizei, _ samplers: UnsafePointer<GLuint>!) {
        _ = count
        _ = samplers
        unimplemented()
    }

    func glDeleteShader(_ shader: GLuint) {
        _ = shader
        unimplemented()
    }

    func glDeleteSync(_ sync: GLsync!) {
        _ = sync
        unimplemented()
    }

    func glDeleteSyncAPPLE(_ sync: GLsync!) {
        _ = sync
        unimplemented()
    }

    func glDeleteTextures(_ n: GLsizei, _ textures: UnsafePointer<GLuint>!) {
        _ = n
        _ = textures
        unimplemented()
    }

    func glDeleteTransformFeedbacks(_ n: GLsizei, _ ids: UnsafePointer<GLuint>!) {
        _ = n
        _ = ids
        unimplemented()
    }

    func glDeleteVertexArrays(_ n: GLsizei, _ arrays: UnsafePointer<GLuint>!) {
        _ = n
        _ = arrays
        unimplemented()
    }

    func glDeleteVertexArraysOES(_ n: GLsizei, _ arrays: UnsafePointer<GLuint>!) {
        _ = n
        _ = arrays
        unimplemented()
    }

    func glDepthFunc(_ `func`: GLenum) {
        _ = `func`
        unimplemented()
    }

    func glDepthMask(_ flag: GLboolean) {
        _ = flag
        unimplemented()
    }

    func glDepthRangef(_ zNear: GLclampf, _ zFar: GLclampf) {
        _ = zNear
        _ = zFar
        unimplemented()
    }

    func glDepthRangex(_ zNear: GLclampx, _ zFar: GLclampx) {
        _ = zNear
        _ = zFar
        unimplemented()
    }

    func glDetachShader(_ program: GLuint, _ shader: GLuint) {
        _ = program
        _ = shader
        unimplemented()
    }

    func glDisable(_ cap: GLenum) {
        _ = cap
        unimplemented()
    }

    func glDisableClientState(_ array: GLenum) {
        _ = array
        unimplemented()
    }

    func glDisableVertexAttribArray(_ index: GLuint) {
        _ = index
        unimplemented()
    }

    func glDiscardFramebufferEXT(_ target: GLenum, _ numAttachments: GLsizei, _ attachments: UnsafePointer<GLenum>!) {
        _ = target
        _ = numAttachments
        _ = attachments
        unimplemented()
    }

    func glDrawArrays(_ mode: GLenum, _ first: GLint, _ count: GLsizei) {
        _ = mode
        _ = first
        _ = count
        unimplemented()
    }

    func glDrawArraysInstanced(_ mode: GLenum, _ first: GLint, _ count: GLsizei, _ instancecount: GLsizei) {
        _ = mode
        _ = first
        _ = count
        _ = instancecount
        unimplemented()
    }

    func glDrawArraysInstancedEXT(_ mode: GLenum, _ first: GLint, _ count: GLsizei, _ instanceCount: GLsizei) {
        _ = mode
        _ = first
        _ = count
        _ = instanceCount
        unimplemented()
    }

    func glDrawBuffers(_ n: GLsizei, _ bufs: UnsafePointer<GLenum>!) {
        _ = n
        _ = bufs
        unimplemented()
    }

    func glDrawElements(_ mode: GLenum, _ count: GLsizei, _ type: GLenum, _ indices: UnsafeRawPointer!) {
        _ = mode
        _ = count
        _ = type
        _ = indices
        unimplemented()
    }

    func glDrawElementsInstanced(_ mode: GLenum, _ count: GLsizei, _ type: GLenum, _ indices: UnsafeRawPointer!, _ instancecount: GLsizei) {
        _ = mode
        _ = count
        _ = type
        _ = indices
        _ = instancecount
        unimplemented()
    }

    func glDrawElementsInstancedEXT(_ mode: GLenum, _ count: GLsizei, _ type: GLenum, _ indices: UnsafeRawPointer!, _ instanceCount: GLsizei) {
        _ = mode
        _ = count
        _ = type
        _ = indices
        _ = instanceCount
        unimplemented()
    }

    func glDrawRangeElements(_ mode: GLenum, _ start: GLuint, _ end: GLuint, _ count: GLsizei, _ type: GLenum, _ indices: UnsafeRawPointer!) {
        _ = mode
        _ = start
        _ = end
        _ = count
        _ = type
        _ = indices
        unimplemented()
    }

    func glDrawTexfOES(_ x: GLfloat, _ y: GLfloat, _ z: GLfloat, _ width: GLfloat, _ height: GLfloat) {
        _ = x
        _ = y
        _ = z
        _ = width
        _ = height
        unimplemented()
    }

    func glDrawTexfvOES(_ coords: UnsafePointer<GLfloat>!) {
        _ = coords
        unimplemented()
    }

    func glDrawTexiOES(_ x: GLint, _ y: GLint, _ z: GLint, _ width: GLint, _ height: GLint) {
        _ = x
        _ = y
        _ = z
        _ = width
        _ = height
        unimplemented()
    }

    func glDrawTexivOES(_ coords: UnsafePointer<GLint>!) {
        _ = coords
        unimplemented()
    }

    func glDrawTexsOES(_ x: GLshort, _ y: GLshort, _ z: GLshort, _ width: GLshort, _ height: GLshort) {
        _ = x
        _ = y
        _ = z
        _ = width
        _ = height
        unimplemented()
    }

    func glDrawTexsvOES(_ coords: UnsafePointer<GLshort>!) {
        _ = coords
        unimplemented()
    }

    func glDrawTexxOES(_ x: GLfixed, _ y: GLfixed, _ z: GLfixed, _ width: GLfixed, _ height: GLfixed) {
        _ = x
        _ = y
        _ = z
        _ = width
        _ = height
        unimplemented()
    }

    func glDrawTexxvOES(_ coords: UnsafePointer<GLfixed>!) {
        _ = coords
        unimplemented()
    }

    func glEnable(_ cap: GLenum) {
        _ = cap
        unimplemented()
    }

    func glEnableClientState(_ array: GLenum) {
        _ = array
        unimplemented()
    }

    func glEnableVertexAttribArray(_ index: GLuint) {
        _ = index
        unimplemented()
    }

    func glEndQuery(_ target: GLenum) {
        _ = target
        unimplemented()
    }

    func glEndQueryEXT(_ target: GLenum) {
        _ = target
        unimplemented()
    }

    func glEndTransformFeedback() {
        unimplemented()
    }

    func glFenceSync(_ condition: GLenum, _ flags: GLbitfield) -> GLsync! {
        _ = condition
        _ = flags
        unimplemented()
        return nil
    }

    func glFenceSyncAPPLE(_ condition: GLenum, _ flags: GLbitfield) -> GLsync! {
        _ = condition
        _ = flags
        unimplemented()
        return nil
    }

    func glFinish() {
        unimplemented()
    }

    func glFlush() {
        unimplemented()
    }

    func glFlushMappedBufferRange(_ target: GLenum, _ offset: GLintptr, _ length: GLsizeiptr) {
        _ = target
        _ = offset
        _ = length
        unimplemented()
    }

    func glFlushMappedBufferRangeEXT(_ target: GLenum, _ offset: GLintptr, _ length: GLsizeiptr) {
        _ = target
        _ = offset
        _ = length
        unimplemented()
    }

    func glFogf(_ pname: GLenum, _ param: GLfloat) {
        _ = pname
        _ = param
        unimplemented()
    }

    func glFogfv(_ pname: GLenum, _ params: UnsafePointer<GLfloat>!) {
        _ = pname
        _ = params
        unimplemented()
    }

    func glFogx(_ pname: GLenum, _ param: GLfixed) {
        _ = pname
        _ = param
        unimplemented()
    }

    func glFogxv(_ pname: GLenum, _ params: UnsafePointer<GLfixed>!) {
        _ = pname
        _ = params
        unimplemented()
    }

    func glFramebufferRenderbuffer(_ target: GLenum, _ attachment: GLenum, _ renderbuffertarget: GLenum, _ renderbuffer: GLuint) {
        _ = target
        _ = attachment
        _ = renderbuffertarget
        _ = renderbuffer
        unimplemented()
    }

    func glFramebufferRenderbufferOES(_ target: GLenum, _ attachment: GLenum, _ renderbuffertarget: GLenum, _ renderbuffer: GLuint) {
        _ = target
        _ = attachment
        _ = renderbuffertarget
        _ = renderbuffer
        unimplemented()
    }

    func glFramebufferTexture2D(_ target: GLenum, _ attachment: GLenum, _ textarget: GLenum, _ texture: GLuint, _ level: GLint) {
        _ = target
        _ = attachment
        _ = textarget
        _ = texture
        _ = level
        unimplemented()
    }

    func glFramebufferTexture2DOES(_ target: GLenum, _ attachment: GLenum, _ textarget: GLenum, _ texture: GLuint, _ level: GLint) {
        _ = target
        _ = attachment
        _ = textarget
        _ = texture
        _ = level
        unimplemented()
    }

    func glFramebufferTextureLayer(_ target: GLenum, _ attachment: GLenum, _ texture: GLuint, _ level: GLint, _ layer: GLint) {
        _ = target
        _ = attachment
        _ = texture
        _ = level
        _ = layer
        unimplemented()
    }

    func glFrontFace(_ mode: GLenum) {
        _ = mode
        unimplemented()
    }

    func glFrustumf(_ left: GLfloat, _ right: GLfloat, _ bottom: GLfloat, _ top: GLfloat, _ zNear: GLfloat, _ zFar: GLfloat) {
        _ = left
        _ = right
        _ = bottom
        _ = top
        _ = zNear
        _ = zFar
        unimplemented()
    }

    func glFrustumx(_ left: GLfixed, _ right: GLfixed, _ bottom: GLfixed, _ top: GLfixed, _ zNear: GLfixed, _ zFar: GLfixed) {
        _ = left
        _ = right
        _ = bottom
        _ = top
        _ = zNear
        _ = zFar
        unimplemented()
    }

    func glGenBuffers(_ n: GLsizei, _ buffers: UnsafeMutablePointer<GLuint>!) {
        _ = n
        _ = buffers
        unimplemented()
    }

    func glGenFramebuffers(_ n: GLsizei, _ framebuffers: UnsafeMutablePointer<GLuint>!) {
        _ = n
        _ = framebuffers
        unimplemented()
    }

    func glGenFramebuffersOES(_ n: GLsizei, _ framebuffers: UnsafeMutablePointer<GLuint>!) {
        _ = n
        _ = framebuffers
        unimplemented()
    }

    func glGenProgramPipelinesEXT(_ n: GLsizei, _ pipelines: UnsafeMutablePointer<GLuint>!) {
        _ = n
        _ = pipelines
        unimplemented()
    }

    func glGenQueries(_ n: GLsizei, _ ids: UnsafeMutablePointer<GLuint>!) {
        _ = n
        _ = ids
        unimplemented()
    }

    func glGenQueriesEXT(_ n: GLsizei, _ ids: UnsafeMutablePointer<GLuint>!) {
        _ = n
        _ = ids
        unimplemented()
    }

    func glGenRenderbuffers(_ n: GLsizei, _ renderbuffers: UnsafeMutablePointer<GLuint>!) {
        _ = n
        _ = renderbuffers
        unimplemented()
    }

    func glGenRenderbuffersOES(_ n: GLsizei, _ renderbuffers: UnsafeMutablePointer<GLuint>!) {
        _ = n
        _ = renderbuffers
        unimplemented()
    }

    func glGenSamplers(_ count: GLsizei, _ samplers: UnsafeMutablePointer<GLuint>!) {
        _ = count
        _ = samplers
        unimplemented()
    }

    func glGenTextures(_ n: GLsizei, _ textures: UnsafeMutablePointer<GLuint>!) {
        _ = n
        _ = textures
        unimplemented()
    }

    func glGenTransformFeedbacks(_ n: GLsizei, _ ids: UnsafeMutablePointer<GLuint>!) {
        _ = n
        _ = ids
        unimplemented()
    }

    func glGenVertexArrays(_ n: GLsizei, _ arrays: UnsafeMutablePointer<GLuint>!) {
        _ = n
        _ = arrays
        unimplemented()
    }

    func glGenVertexArraysOES(_ n: GLsizei, _ arrays: UnsafeMutablePointer<GLuint>!) {
        _ = n
        _ = arrays
        unimplemented()
    }

    func glGenerateMipmap(_ target: GLenum) {
        _ = target
        unimplemented()
    }

    func glGenerateMipmapOES(_ target: GLenum) {
        _ = target
        unimplemented()
    }

    func glGetActiveAttrib(_ program: GLuint, _ index: GLuint, _ bufsize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ size: UnsafeMutablePointer<GLint>!, _ type: UnsafeMutablePointer<GLenum>!, _ name: UnsafeMutablePointer<GLchar>!) {
        _ = program
        _ = index
        _ = bufsize
        _ = length
        _ = size
        _ = type
        _ = name
        unimplemented()
    }

    func glGetActiveUniform(_ program: GLuint, _ index: GLuint, _ bufsize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ size: UnsafeMutablePointer<GLint>!, _ type: UnsafeMutablePointer<GLenum>!, _ name: UnsafeMutablePointer<GLchar>!) {
        _ = program
        _ = index
        _ = bufsize
        _ = length
        _ = size
        _ = type
        _ = name
        unimplemented()
    }

    func glGetActiveUniformBlockName(_ program: GLuint, _ uniformBlockIndex: GLuint, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ uniformBlockName: UnsafeMutablePointer<GLchar>!) {
        _ = program
        _ = uniformBlockIndex
        _ = bufSize
        _ = length
        _ = uniformBlockName
        unimplemented()
    }

    func glGetActiveUniformBlockiv(_ program: GLuint, _ uniformBlockIndex: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        _ = program
        _ = uniformBlockIndex
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetActiveUniformsiv(_ program: GLuint, _ uniformCount: GLsizei, _ uniformIndices: UnsafePointer<GLuint>!, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        _ = program
        _ = uniformCount
        _ = uniformIndices
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetAttachedShaders(_ program: GLuint, _ maxcount: GLsizei, _ count: UnsafeMutablePointer<GLsizei>!, _ shaders: UnsafeMutablePointer<GLuint>!) {
        _ = program
        _ = maxcount
        _ = count
        _ = shaders
        unimplemented()
    }

    func glGetAttribLocation(_ program: GLuint, _ name: UnsafePointer<GLchar>!) -> Int32 {
        _ = program
        _ = name
        unimplemented()
        return 0
    }

    func glGetBooleanv(_ pname: GLenum, _ params: UnsafeMutablePointer<GLboolean>!) {
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetBufferParameteri64v(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint64>!) {
        _ = target
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetBufferParameteriv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        _ = target
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetBufferPointerv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<UnsafeMutableRawPointer?>!) {
        _ = target
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetBufferPointervOES(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<UnsafeMutableRawPointer?>!) {
        _ = target
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetClipPlanef(_ pname: GLenum, _ equation: UnsafeMutablePointer<GLfloat>!) {
        _ = pname
        _ = equation
        unimplemented()
    }

    func glGetClipPlanex(_ pname: GLenum, _ eqn: UnsafeMutablePointer<GLfixed>!) {
        _ = pname
        _ = eqn
        unimplemented()
    }

    func glGetFixedv(_ pname: GLenum, _ params: UnsafeMutablePointer<GLfixed>!) {
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetFloatv(_ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!) {
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetFragDataLocation(_ program: GLuint, _ name: UnsafePointer<GLchar>!) -> GLint {
        _ = program
        _ = name
        unimplemented()
        return 0
    }

    func glGetFramebufferAttachmentParameteriv(_ target: GLenum, _ attachment: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        _ = target
        _ = attachment
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetFramebufferAttachmentParameterivOES(_ target: GLenum, _ attachment: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        _ = target
        _ = attachment
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetInteger64i_v(_ target: GLenum, _ index: GLuint, _ data: UnsafeMutablePointer<GLint64>!) {
        _ = target
        _ = index
        _ = data
        unimplemented()
    }

    func glGetInteger64v(_ pname: GLenum, _ params: UnsafeMutablePointer<GLint64>!) {
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetInteger64vAPPLE(_ pname: GLenum, _ params: UnsafeMutablePointer<GLint64>!) {
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetIntegeri_v(_ target: GLenum, _ index: GLuint, _ data: UnsafeMutablePointer<GLint>!) {
        _ = target
        _ = index
        _ = data
        unimplemented()
    }

    func glGetIntegerv(_ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetInternalformativ(_ target: GLenum, _ internalformat: GLenum, _ pname: GLenum, _ bufSize: GLsizei, _ params: UnsafeMutablePointer<GLint>!) {
        _ = target
        _ = internalformat
        _ = pname
        _ = bufSize
        _ = params
        unimplemented()
    }

    func glGetLightfv(_ light: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!) {
        _ = light
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetLightxv(_ light: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfixed>!) {
        _ = light
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetMaterialfv(_ face: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!) {
        _ = face
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetMaterialxv(_ face: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfixed>!) {
        _ = face
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetObjectLabelEXT(_ type: GLenum, _ object: GLuint, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ label: UnsafeMutablePointer<GLchar>!) {
        _ = type
        _ = object
        _ = bufSize
        _ = length
        _ = label
        unimplemented()
    }

    func glGetPointerv(_ pname: GLenum, _ params: UnsafeMutablePointer<UnsafeMutableRawPointer?>!) {
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetProgramBinary(_ program: GLuint, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ binaryFormat: UnsafeMutablePointer<GLenum>!, _ binary: UnsafeMutableRawPointer!) {
        _ = program
        _ = bufSize
        _ = length
        _ = binaryFormat
        _ = binary
        unimplemented()
    }

    func glGetProgramInfoLog(_ program: GLuint, _ bufsize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ infolog: UnsafeMutablePointer<GLchar>!) {
        _ = program
        _ = bufsize
        _ = length
        _ = infolog
        unimplemented()
    }

    func glGetProgramPipelineInfoLogEXT(_ pipeline: GLuint, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ infoLog: UnsafeMutablePointer<GLchar>!) {
        _ = pipeline
        _ = bufSize
        _ = length
        _ = infoLog
        unimplemented()
    }

    func glGetProgramPipelineivEXT(_ pipeline: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        _ = pipeline
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetProgramiv(_ program: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        _ = program
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetQueryObjectuiv(_ id: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLuint>!) {
        _ = id
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetQueryObjectuivEXT(_ id: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLuint>!) {
        _ = id
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetQueryiv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        _ = target
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetQueryivEXT(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        _ = target
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetRenderbufferParameteriv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        _ = target
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetRenderbufferParameterivOES(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        _ = target
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetSamplerParameterfv(_ sampler: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!) {
        _ = sampler
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetSamplerParameteriv(_ sampler: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        _ = sampler
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetShaderInfoLog(_ shader: GLuint, _ bufsize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ infolog: UnsafeMutablePointer<GLchar>!) {
        _ = shader
        _ = bufsize
        _ = length
        _ = infolog
        unimplemented()
    }

    func glGetShaderPrecisionFormat(_ shadertype: GLenum, _ precisiontype: GLenum, _ range: UnsafeMutablePointer<GLint>!, _ precision: UnsafeMutablePointer<GLint>!) {
        _ = shadertype
        _ = precisiontype
        _ = range
        _ = precision
        unimplemented()
    }

    func glGetShaderSource(_ shader: GLuint, _ bufsize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ source: UnsafeMutablePointer<GLchar>!) {
        _ = shader
        _ = bufsize
        _ = length
        _ = source
        unimplemented()
    }

    func glGetShaderiv(_ shader: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        _ = shader
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetString(_ name: GLenum) -> UnsafePointer<GLubyte>! {
        _ = name
        unimplemented()
        return nil
    }

    func glGetStringi(_ name: GLenum, _ index: GLuint) -> UnsafePointer<GLubyte>! {
        _ = name
        _ = index
        unimplemented()
        return nil
    }

    func glGetSynciv(_ sync: GLsync!, _ pname: GLenum, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ values: UnsafeMutablePointer<GLint>!) {
        _ = sync
        _ = pname
        _ = bufSize
        _ = length
        _ = values
        unimplemented()
    }

    func glGetSyncivAPPLE(_ sync: GLsync!, _ pname: GLenum, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ values: UnsafeMutablePointer<GLint>!) {
        _ = sync
        _ = pname
        _ = bufSize
        _ = length
        _ = values
        unimplemented()
    }

    func glGetTexEnvfv(_ env: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!) {
        _ = env
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetTexEnviv(_ env: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        _ = env
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetTexEnvxv(_ env: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfixed>!) {
        _ = env
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetTexParameterfv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!) {
        _ = target
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetTexParameteriv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        _ = target
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetTexParameterxv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfixed>!) {
        _ = target
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetTransformFeedbackVarying(_ program: GLuint, _ index: GLuint, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ size: UnsafeMutablePointer<GLsizei>!, _ type: UnsafeMutablePointer<GLenum>!, _ name: UnsafeMutablePointer<GLchar>!) {
        _ = program
        _ = index
        _ = bufSize
        _ = length
        _ = size
        _ = type
        _ = name
        unimplemented()
    }

    func glGetUniformBlockIndex(_ program: GLuint, _ uniformBlockName: UnsafePointer<GLchar>!) -> GLuint {
        _ = program
        _ = uniformBlockName
        unimplemented()
        return 0
    }

    func glGetUniformIndices(_ program: GLuint, _ uniformCount: GLsizei, _ uniformNames: UnsafePointer<UnsafePointer<GLchar>?>!, _ uniformIndices: UnsafeMutablePointer<GLuint>!) {
        _ = program
        _ = uniformCount
        _ = uniformNames
        _ = uniformIndices
        unimplemented()
    }

    func glGetUniformLocation(_ program: GLuint, _ name: UnsafePointer<GLchar>!) -> Int32 {
        _ = program
        _ = name
        unimplemented()
        return 0
    }

    func glGetUniformfv(_ program: GLuint, _ location: GLint, _ params: UnsafeMutablePointer<GLfloat>!) {
        _ = program
        _ = location
        _ = params
        unimplemented()
    }

    func glGetUniformiv(_ program: GLuint, _ location: GLint, _ params: UnsafeMutablePointer<GLint>!) {
        _ = program
        _ = location
        _ = params
        unimplemented()
    }

    func glGetUniformuiv(_ program: GLuint, _ location: GLint, _ params: UnsafeMutablePointer<GLuint>!) {
        _ = program
        _ = location
        _ = params
        unimplemented()
    }

    func glGetVertexAttribIiv(_ index: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        _ = index
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetVertexAttribIuiv(_ index: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLuint>!) {
        _ = index
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetVertexAttribPointerv(_ index: GLuint, _ pname: GLenum, _ pointer: UnsafeMutablePointer<UnsafeMutableRawPointer?>!) {
        _ = index
        _ = pname
        _ = pointer
        unimplemented()
    }

    func glGetVertexAttribfv(_ index: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!) {
        _ = index
        _ = pname
        _ = params
        unimplemented()
    }

    func glGetVertexAttribiv(_ index: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
        _ = index
        _ = pname
        _ = params
        unimplemented()
    }

    func glHint(_ target: GLenum, _ mode: GLenum) {
        _ = target
        _ = mode
        unimplemented()
    }

    func glInsertEventMarkerEXT(_ length: GLsizei, _ marker: UnsafePointer<GLchar>!) {
        _ = length
        _ = marker
        unimplemented()
    }

    func glInvalidateFramebuffer(_ target: GLenum, _ numAttachments: GLsizei, _ attachments: UnsafePointer<GLenum>!) {
        _ = target
        _ = numAttachments
        _ = attachments
        unimplemented()
    }

    func glInvalidateSubFramebuffer(_ target: GLenum, _ numAttachments: GLsizei, _ attachments: UnsafePointer<GLenum>!, _ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei) {
        _ = target
        _ = numAttachments
        _ = attachments
        _ = x
        _ = y
        _ = width
        _ = height
        unimplemented()
    }

    func glIsBuffer(_ buffer: GLuint) -> GLboolean {
        _ = buffer
        unimplemented()
        return 0
    }

    func glIsEnabled(_ cap: GLenum) -> GLboolean {
        _ = cap
        unimplemented()
        return 0
    }

    func glIsFramebuffer(_ framebuffer: GLuint) -> GLboolean {
        _ = framebuffer
        unimplemented()
        return 0
    }

    func glIsFramebufferOES(_ framebuffer: GLuint) -> GLboolean {
        _ = framebuffer
        unimplemented()
        return 0
    }

    func glIsProgram(_ program: GLuint) -> GLboolean {
        _ = program
        unimplemented()
        return 0
    }

    func glIsProgramPipelineEXT(_ pipeline: GLuint) -> GLboolean {
        _ = pipeline
        unimplemented()
        return 0
    }

    func glIsQuery(_ id: GLuint) -> GLboolean {
        _ = id
        unimplemented()
        return 0
    }

    func glIsQueryEXT(_ id: GLuint) -> GLboolean {
        _ = id
        unimplemented()
        return 0
    }

    func glIsRenderbuffer(_ renderbuffer: GLuint) -> GLboolean {
        _ = renderbuffer
        unimplemented()
        return 0
    }

    func glIsRenderbufferOES(_ renderbuffer: GLuint) -> GLboolean {
        _ = renderbuffer
        unimplemented()
        return 0
    }

    func glIsSampler(_ sampler: GLuint) -> GLboolean {
        _ = sampler
        unimplemented()
        return 0
    }

    func glIsShader(_ shader: GLuint) -> GLboolean {
        _ = shader
        unimplemented()
        return 0
    }

    func glIsSync(_ sync: GLsync!) -> GLboolean {
        _ = sync
        unimplemented()
        return 0
    }

    func glIsSyncAPPLE(_ sync: GLsync!) -> GLboolean {
        _ = sync
        unimplemented()
        return 0
    }

    func glIsTexture(_ texture: GLuint) -> GLboolean {
        _ = texture
        unimplemented()
        return 0
    }

    func glIsTransformFeedback(_ id: GLuint) -> GLboolean {
        _ = id
        unimplemented()
        return 0
    }

    func glIsVertexArray(_ array: GLuint) -> GLboolean {
        _ = array
        unimplemented()
        return 0
    }

    func glIsVertexArrayOES(_ array: GLuint) -> GLboolean {
        _ = array
        unimplemented()
        return 0
    }

    func glLabelObjectEXT(_ type: GLenum, _ object: GLuint, _ length: GLsizei, _ label: UnsafePointer<GLchar>!) {
        _ = type
        _ = object
        _ = length
        _ = label
        unimplemented()
    }

    func glLightModelf(_ pname: GLenum, _ param: GLfloat) {
        _ = pname
        _ = param
        unimplemented()
    }

    func glLightModelfv(_ pname: GLenum, _ params: UnsafePointer<GLfloat>!) {
        _ = pname
        _ = params
        unimplemented()
    }

    func glLightModelx(_ pname: GLenum, _ param: GLfixed) {
        _ = pname
        _ = param
        unimplemented()
    }

    func glLightModelxv(_ pname: GLenum, _ params: UnsafePointer<GLfixed>!) {
        _ = pname
        _ = params
        unimplemented()
    }

    func glLightf(_ light: GLenum, _ pname: GLenum, _ param: GLfloat) {
        _ = light
        _ = pname
        _ = param
        unimplemented()
    }

    func glLightfv(_ light: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfloat>!) {
        _ = light
        _ = pname
        _ = params
        unimplemented()
    }

    func glLightx(_ light: GLenum, _ pname: GLenum, _ param: GLfixed) {
        _ = light
        _ = pname
        _ = param
        unimplemented()
    }

    func glLightxv(_ light: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfixed>!) {
        _ = light
        _ = pname
        _ = params
        unimplemented()
    }

    func glLineWidth(_ width: GLfloat) {
        _ = width
        unimplemented()
    }

    func glLineWidthx(_ width: GLfixed) {
        _ = width
        unimplemented()
    }

    func glLinkProgram(_ program: GLuint) {
        _ = program
        unimplemented()
    }

    func glLoadIdentity() {
        unimplemented()
    }

    func glLoadMatrixf(_ m: UnsafePointer<GLfloat>!) {
        _ = m
        unimplemented()
    }

    func glLoadMatrixx(_ m: UnsafePointer<GLfixed>!) {
        _ = m
        unimplemented()
    }

    func glLoadPaletteFromModelViewMatrixOES() {
        unimplemented()
    }

    func glLogicOp(_ opcode: GLenum) {
        _ = opcode
        unimplemented()
    }

    func glMapBufferOES(_ target: GLenum, _ access: GLenum) -> UnsafeMutableRawPointer! {
        _ = target
        _ = access
        unimplemented()
        return nil
    }

    func glMapBufferRange(_ target: GLenum, _ offset: GLintptr, _ length: GLsizeiptr, _ access: GLbitfield) -> UnsafeMutableRawPointer! {
        _ = target
        _ = offset
        _ = length
        _ = access
        unimplemented()
        return nil
    }

    func glMapBufferRangeEXT(_ target: GLenum, _ offset: GLintptr, _ length: GLsizeiptr, _ access: GLbitfield) -> UnsafeMutableRawPointer! {
        _ = target
        _ = offset
        _ = length
        _ = access
        unimplemented()
        return nil
    }

    func glMaterialf(_ face: GLenum, _ pname: GLenum, _ param: GLfloat) {
        _ = face
        _ = pname
        _ = param
        unimplemented()
    }

    func glMaterialfv(_ face: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfloat>!) {
        _ = face
        _ = pname
        _ = params
        unimplemented()
    }

    func glMaterialx(_ face: GLenum, _ pname: GLenum, _ param: GLfixed) {
        _ = face
        _ = pname
        _ = param
        unimplemented()
    }

    func glMaterialxv(_ face: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfixed>!) {
        _ = face
        _ = pname
        _ = params
        unimplemented()
    }

    func glMatrixIndexPointerOES(_ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!) {
        _ = size
        _ = type
        _ = stride
        _ = pointer
        unimplemented()
    }

    func glMatrixMode(_ mode: GLenum) {
        _ = mode
        unimplemented()
    }

    func glMultMatrixf(_ m: UnsafePointer<GLfloat>!) {
        _ = m
        unimplemented()
    }

    func glMultMatrixx(_ m: UnsafePointer<GLfixed>!) {
        _ = m
        unimplemented()
    }

    func glMultiTexCoord4f(_ target: GLenum, _ s: GLfloat, _ t: GLfloat, _ r: GLfloat, _ q: GLfloat) {
        _ = target
        _ = s
        _ = t
        _ = r
        _ = q
        unimplemented()
    }

    func glMultiTexCoord4x(_ target: GLenum, _ s: GLfixed, _ t: GLfixed, _ r: GLfixed, _ q: GLfixed) {
        _ = target
        _ = s
        _ = t
        _ = r
        _ = q
        unimplemented()
    }

    func glNormal3f(_ nx: GLfloat, _ ny: GLfloat, _ nz: GLfloat) {
        _ = nx
        _ = ny
        _ = nz
        unimplemented()
    }

    func glNormal3x(_ nx: GLfixed, _ ny: GLfixed, _ nz: GLfixed) {
        _ = nx
        _ = ny
        _ = nz
        unimplemented()
    }

    func glNormalPointer(_ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!) {
        _ = type
        _ = stride
        _ = pointer
        unimplemented()
    }

    func glOrthof(_ left: GLfloat, _ right: GLfloat, _ bottom: GLfloat, _ top: GLfloat, _ zNear: GLfloat, _ zFar: GLfloat) {
        _ = left
        _ = right
        _ = bottom
        _ = top
        _ = zNear
        _ = zFar
        unimplemented()
    }

    func glOrthox(_ left: GLfixed, _ right: GLfixed, _ bottom: GLfixed, _ top: GLfixed, _ zNear: GLfixed, _ zFar: GLfixed) {
        _ = left
        _ = right
        _ = bottom
        _ = top
        _ = zNear
        _ = zFar
        unimplemented()
    }

    func glPauseTransformFeedback() {
        unimplemented()
    }

    func glPixelStorei(_ pname: GLenum, _ param: GLint) {
        _ = pname
        _ = param
        unimplemented()
    }

    func glPointParameterf(_ pname: GLenum, _ param: GLfloat) {
        _ = pname
        _ = param
        unimplemented()
    }

    func glPointParameterfv(_ pname: GLenum, _ params: UnsafePointer<GLfloat>!) {
        _ = pname
        _ = params
        unimplemented()
    }

    func glPointParameterx(_ pname: GLenum, _ param: GLfixed) {
        _ = pname
        _ = param
        unimplemented()
    }

    func glPointParameterxv(_ pname: GLenum, _ params: UnsafePointer<GLfixed>!) {
        _ = pname
        _ = params
        unimplemented()
    }

    func glPointSize(_ size: GLfloat) {
        _ = size
        unimplemented()
    }

    func glPointSizePointerOES(_ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!) {
        _ = type
        _ = stride
        _ = pointer
        unimplemented()
    }

    func glPointSizex(_ size: GLfixed) {
        _ = size
        unimplemented()
    }

    func glPolygonOffset(_ factor: GLfloat, _ units: GLfloat) {
        _ = factor
        _ = units
        unimplemented()
    }

    func glPolygonOffsetx(_ factor: GLfixed, _ units: GLfixed) {
        _ = factor
        _ = units
        unimplemented()
    }

    func glPopGroupMarkerEXT() {
        unimplemented()
    }

    func glPopMatrix() {
        unimplemented()
    }

    func glProgramBinary(_ program: GLuint, _ binaryFormat: GLenum, _ binary: UnsafeRawPointer!, _ length: GLsizei) {
        _ = program
        _ = binaryFormat
        _ = binary
        _ = length
        unimplemented()
    }

    func glProgramParameteri(_ program: GLuint, _ pname: GLenum, _ value: GLint) {
        _ = program
        _ = pname
        _ = value
        unimplemented()
    }

    func glProgramParameteriEXT(_ program: GLuint, _ pname: GLenum, _ value: GLint) {
        _ = program
        _ = pname
        _ = value
        unimplemented()
    }

    func glProgramUniform1fEXT(_ program: GLuint, _ location: GLint, _ x: GLfloat) {
        _ = program
        _ = location
        _ = x
        unimplemented()
    }

    func glProgramUniform1fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLfloat>!) {
        _ = program
        _ = location
        _ = count
        _ = value
        unimplemented()
    }

    func glProgramUniform1iEXT(_ program: GLuint, _ location: GLint, _ x: GLint) {
        _ = program
        _ = location
        _ = x
        unimplemented()
    }

    func glProgramUniform1ivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLint>!) {
        _ = program
        _ = location
        _ = count
        _ = value
        unimplemented()
    }

    func glProgramUniform1uiEXT(_ program: GLuint, _ location: GLint, _ x: GLuint) {
        _ = program
        _ = location
        _ = x
        unimplemented()
    }

    func glProgramUniform1uivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!) {
        _ = program
        _ = location
        _ = count
        _ = value
        unimplemented()
    }

    func glProgramUniform2fEXT(_ program: GLuint, _ location: GLint, _ x: GLfloat, _ y: GLfloat) {
        _ = program
        _ = location
        _ = x
        _ = y
        unimplemented()
    }

    func glProgramUniform2fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLfloat>!) {
        _ = program
        _ = location
        _ = count
        _ = value
        unimplemented()
    }

    func glProgramUniform2iEXT(_ program: GLuint, _ location: GLint, _ x: GLint, _ y: GLint) {
        _ = program
        _ = location
        _ = x
        _ = y
        unimplemented()
    }

    func glProgramUniform2ivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLint>!) {
        _ = program
        _ = location
        _ = count
        _ = value
        unimplemented()
    }

    func glProgramUniform2uiEXT(_ program: GLuint, _ location: GLint, _ x: GLuint, _ y: GLuint) {
        _ = program
        _ = location
        _ = x
        _ = y
        unimplemented()
    }

    func glProgramUniform2uivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!) {
        _ = program
        _ = location
        _ = count
        _ = value
        unimplemented()
    }

    func glProgramUniform3fEXT(_ program: GLuint, _ location: GLint, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat) {
        _ = program
        _ = location
        _ = x
        _ = y
        _ = z
        unimplemented()
    }

    func glProgramUniform3fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLfloat>!) {
        _ = program
        _ = location
        _ = count
        _ = value
        unimplemented()
    }

    func glProgramUniform3iEXT(_ program: GLuint, _ location: GLint, _ x: GLint, _ y: GLint, _ z: GLint) {
        _ = program
        _ = location
        _ = x
        _ = y
        _ = z
        unimplemented()
    }

    func glProgramUniform3ivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLint>!) {
        _ = program
        _ = location
        _ = count
        _ = value
        unimplemented()
    }

    func glProgramUniform3uiEXT(_ program: GLuint, _ location: GLint, _ x: GLuint, _ y: GLuint, _ z: GLuint) {
        _ = program
        _ = location
        _ = x
        _ = y
        _ = z
        unimplemented()
    }

    func glProgramUniform3uivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!) {
        _ = program
        _ = location
        _ = count
        _ = value
        unimplemented()
    }

    func glProgramUniform4fEXT(_ program: GLuint, _ location: GLint, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat, _ w: GLfloat) {
        _ = program
        _ = location
        _ = x
        _ = y
        _ = z
        _ = w
        unimplemented()
    }

    func glProgramUniform4fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLfloat>!) {
        _ = program
        _ = location
        _ = count
        _ = value
        unimplemented()
    }

    func glProgramUniform4iEXT(_ program: GLuint, _ location: GLint, _ x: GLint, _ y: GLint, _ z: GLint, _ w: GLint) {
        _ = program
        _ = location
        _ = x
        _ = y
        _ = z
        _ = w
        unimplemented()
    }

    func glProgramUniform4ivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLint>!) {
        _ = program
        _ = location
        _ = count
        _ = value
        unimplemented()
    }

    func glProgramUniform4uiEXT(_ program: GLuint, _ location: GLint, _ x: GLuint, _ y: GLuint, _ z: GLuint, _ w: GLuint) {
        _ = program
        _ = location
        _ = x
        _ = y
        _ = z
        _ = w
        unimplemented()
    }

    func glProgramUniform4uivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!) {
        _ = program
        _ = location
        _ = count
        _ = value
        unimplemented()
    }

    func glProgramUniformMatrix2fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
        _ = program
        _ = location
        _ = count
        _ = transpose
        _ = value
        unimplemented()
    }

    func glProgramUniformMatrix2x3fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
        _ = program
        _ = location
        _ = count
        _ = transpose
        _ = value
        unimplemented()
    }

    func glProgramUniformMatrix2x4fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
        _ = program
        _ = location
        _ = count
        _ = transpose
        _ = value
        unimplemented()
    }

    func glProgramUniformMatrix3fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
        _ = program
        _ = location
        _ = count
        _ = transpose
        _ = value
        unimplemented()
    }

    func glProgramUniformMatrix3x2fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
        _ = program
        _ = location
        _ = count
        _ = transpose
        _ = value
        unimplemented()
    }

    func glProgramUniformMatrix3x4fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
        _ = program
        _ = location
        _ = count
        _ = transpose
        _ = value
        unimplemented()
    }

    func glProgramUniformMatrix4fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
        _ = program
        _ = location
        _ = count
        _ = transpose
        _ = value
        unimplemented()
    }

    func glProgramUniformMatrix4x2fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
        _ = program
        _ = location
        _ = count
        _ = transpose
        _ = value
        unimplemented()
    }

    func glProgramUniformMatrix4x3fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
        _ = program
        _ = location
        _ = count
        _ = transpose
        _ = value
        unimplemented()
    }

    func glPushGroupMarkerEXT(_ length: GLsizei, _ marker: UnsafePointer<GLchar>!) {
        _ = length
        _ = marker
        unimplemented()
    }

    func glPushMatrix() {
        unimplemented()
    }

    func glReadBuffer(_ mode: GLenum) {
        _ = mode
        unimplemented()
    }

    func glReadPixels(_ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei, _ format: GLenum, _ type: GLenum, _ pixels: UnsafeMutableRawPointer!) {
        _ = x
        _ = y
        _ = width
        _ = height
        _ = format
        _ = type
        _ = pixels
        unimplemented()
    }

    func glReleaseShaderCompiler() {
        unimplemented()
    }

    func glRenderbufferStorage(_ target: GLenum, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei) {
        _ = target
        _ = internalformat
        _ = width
        _ = height
        unimplemented()
    }

    func glRenderbufferStorageMultisample(_ target: GLenum, _ samples: GLsizei, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei) {
        _ = target
        _ = samples
        _ = internalformat
        _ = width
        _ = height
        unimplemented()
    }

    func glRenderbufferStorageMultisampleAPPLE(_ target: GLenum, _ samples: GLsizei, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei) {
        _ = target
        _ = samples
        _ = internalformat
        _ = width
        _ = height
        unimplemented()
    }

    func glRenderbufferStorageOES(_ target: GLenum, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei) {
        _ = target
        _ = internalformat
        _ = width
        _ = height
        unimplemented()
    }

    func glResolveMultisampleFramebufferAPPLE() {
        unimplemented()
    }

    func glResumeTransformFeedback() {
        unimplemented()
    }

    func glRotatef(_ angle: GLfloat, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat) {
        _ = angle
        _ = x
        _ = y
        _ = z
        unimplemented()
    }

    func glRotatex(_ angle: GLfixed, _ x: GLfixed, _ y: GLfixed, _ z: GLfixed) {
        _ = angle
        _ = x
        _ = y
        _ = z
        unimplemented()
    }

    func glSampleCoverage(_ value: GLclampf, _ invert: GLboolean) {
        _ = value
        _ = invert
        unimplemented()
    }

    func glSampleCoveragex(_ value: GLclampx, _ invert: GLboolean) {
        _ = value
        _ = invert
        unimplemented()
    }

    func glSamplerParameterf(_ sampler: GLuint, _ pname: GLenum, _ param: GLfloat) {
        _ = sampler
        _ = pname
        _ = param
        unimplemented()
    }

    func glSamplerParameterfv(_ sampler: GLuint, _ pname: GLenum, _ param: UnsafePointer<GLfloat>!) {
        _ = sampler
        _ = pname
        _ = param
        unimplemented()
    }

    func glSamplerParameteri(_ sampler: GLuint, _ pname: GLenum, _ param: GLint) {
        _ = sampler
        _ = pname
        _ = param
        unimplemented()
    }

    func glSamplerParameteriv(_ sampler: GLuint, _ pname: GLenum, _ param: UnsafePointer<GLint>!) {
        _ = sampler
        _ = pname
        _ = param
        unimplemented()
    }

    func glScalef(_ x: GLfloat, _ y: GLfloat, _ z: GLfloat) {
        _ = x
        _ = y
        _ = z
        unimplemented()
    }

    func glScalex(_ x: GLfixed, _ y: GLfixed, _ z: GLfixed) {
        _ = x
        _ = y
        _ = z
        unimplemented()
    }

    func glScissor(_ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei) {
        _ = x
        _ = y
        _ = width
        _ = height
        unimplemented()
    }

    func glShadeModel(_ mode: GLenum) {
        _ = mode
        unimplemented()
    }

    func glShaderBinary(_ n: GLsizei, _ shaders: UnsafePointer<GLuint>!, _ binaryformat: GLenum, _ binary: UnsafeRawPointer!, _ length: GLsizei) {
        _ = n
        _ = shaders
        _ = binaryformat
        _ = binary
        _ = length
        unimplemented()
    }

    func glShaderSource(_ shader: GLuint, _ count: GLsizei, _ string: UnsafePointer<UnsafePointer<GLchar>?>!, _ length: UnsafePointer<GLint>!) {
        _ = shader
        _ = count
        _ = string
        _ = length
        unimplemented()
    }

    func glStencilFunc(_ `func`: GLenum, _ ref: GLint, _ mask: GLuint) {
        _ = `func`
        _ = ref
        _ = mask
        unimplemented()
    }

    func glStencilFuncSeparate(_ face: GLenum, _ `func`: GLenum, _ ref: GLint, _ mask: GLuint) {
        _ = face
        _ = `func`
        _ = ref
        _ = mask
        unimplemented()
    }

    func glStencilMask(_ mask: GLuint) {
        _ = mask
        unimplemented()
    }

    func glStencilMaskSeparate(_ face: GLenum, _ mask: GLuint) {
        _ = face
        _ = mask
        unimplemented()
    }

    func glStencilOp(_ fail: GLenum, _ zfail: GLenum, _ zpass: GLenum) {
        _ = fail
        _ = zfail
        _ = zpass
        unimplemented()
    }

    func glStencilOpSeparate(_ face: GLenum, _ fail: GLenum, _ zfail: GLenum, _ zpass: GLenum) {
        _ = face
        _ = fail
        _ = zfail
        _ = zpass
        unimplemented()
    }

    func glTexCoordPointer(_ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!) {
        _ = size
        _ = type
        _ = stride
        _ = pointer
        unimplemented()
    }

    func glTexEnvf(_ target: GLenum, _ pname: GLenum, _ param: GLfloat) {
        _ = target
        _ = pname
        _ = param
        unimplemented()
    }

    func glTexEnvfv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfloat>!) {
        _ = target
        _ = pname
        _ = params
        unimplemented()
    }

    func glTexEnvi(_ target: GLenum, _ pname: GLenum, _ param: GLint) {
        _ = target
        _ = pname
        _ = param
        unimplemented()
    }

    func glTexEnviv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLint>!) {
        _ = target
        _ = pname
        _ = params
        unimplemented()
    }

    func glTexEnvx(_ target: GLenum, _ pname: GLenum, _ param: GLfixed) {
        _ = target
        _ = pname
        _ = param
        unimplemented()
    }

    func glTexEnvxv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfixed>!) {
        _ = target
        _ = pname
        _ = params
        unimplemented()
    }

    func glTexImage2D(_ target: GLenum, _ level: GLint, _ internalformat: GLint, _ width: GLsizei, _ height: GLsizei, _ border: GLint, _ format: GLenum, _ type: GLenum, _ pixels: UnsafeRawPointer!) {
        _ = target
        _ = level
        _ = internalformat
        _ = width
        _ = height
        _ = border
        _ = format
        _ = type
        _ = pixels
        unimplemented()
    }

    func glTexImage3D(_ target: GLenum, _ level: GLint, _ internalformat: GLint, _ width: GLsizei, _ height: GLsizei, _ depth: GLsizei, _ border: GLint, _ format: GLenum, _ type: GLenum, _ pixels: UnsafeRawPointer!) {
        _ = target
        _ = level
        _ = internalformat
        _ = width
        _ = height
        _ = depth
        _ = border
        _ = format
        _ = type
        _ = pixels
        unimplemented()
    }

    func glTexParameterf(_ target: GLenum, _ pname: GLenum, _ param: GLfloat) {
        _ = target
        _ = pname
        _ = param
        unimplemented()
    }

    func glTexParameterfv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfloat>!) {
        _ = target
        _ = pname
        _ = params
        unimplemented()
    }

    func glTexParameteri(_ target: GLenum, _ pname: GLenum, _ param: GLint) {
        _ = target
        _ = pname
        _ = param
        unimplemented()
    }

    func glTexParameteriv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLint>!) {
        _ = target
        _ = pname
        _ = params
        unimplemented()
    }

    func glTexParameterx(_ target: GLenum, _ pname: GLenum, _ param: GLfixed) {
        _ = target
        _ = pname
        _ = param
        unimplemented()
    }

    func glTexParameterxv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfixed>!) {
        _ = target
        _ = pname
        _ = params
        unimplemented()
    }

    func glTexStorage2D(_ target: GLenum, _ levels: GLsizei, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei) {
        _ = target
        _ = levels
        _ = internalformat
        _ = width
        _ = height
        unimplemented()
    }

    func glTexStorage2DEXT(_ target: GLenum, _ levels: GLsizei, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei) {
        _ = target
        _ = levels
        _ = internalformat
        _ = width
        _ = height
        unimplemented()
    }

    func glTexStorage3D(_ target: GLenum, _ levels: GLsizei, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei, _ depth: GLsizei) {
        _ = target
        _ = levels
        _ = internalformat
        _ = width
        _ = height
        _ = depth
        unimplemented()
    }

    func glTexSubImage2D(_ target: GLenum, _ level: GLint, _ xoffset: GLint, _ yoffset: GLint, _ width: GLsizei, _ height: GLsizei, _ format: GLenum, _ type: GLenum, _ pixels: UnsafeRawPointer!) {
        _ = target
        _ = level
        _ = xoffset
        _ = yoffset
        _ = width
        _ = height
        _ = format
        _ = type
        _ = pixels
        unimplemented()
    }

    func glTexSubImage3D(_ target: GLenum, _ level: GLint, _ xoffset: GLint, _ yoffset: GLint, _ zoffset: GLint, _ width: GLsizei, _ height: GLsizei, _ depth: GLsizei, _ format: GLenum, _ type: GLenum, _ pixels: UnsafeRawPointer!) {
        _ = target
        _ = level
        _ = xoffset
        _ = yoffset
        _ = zoffset
        _ = width
        _ = height
        _ = depth
        _ = format
        _ = type
        _ = pixels
        unimplemented()
    }

    func glTransformFeedbackVaryings(_ program: GLuint, _ count: GLsizei, _ varyings: UnsafePointer<UnsafePointer<GLchar>?>!, _ bufferMode: GLenum) {
        _ = program
        _ = count
        _ = varyings
        _ = bufferMode
        unimplemented()
    }

    func glTranslatef(_ x: GLfloat, _ y: GLfloat, _ z: GLfloat) {
        _ = x
        _ = y
        _ = z
        unimplemented()
    }

    func glTranslatex(_ x: GLfixed, _ y: GLfixed, _ z: GLfixed) {
        _ = x
        _ = y
        _ = z
        unimplemented()
    }

    func glUniform1f(_ location: GLint, _ x: GLfloat) {
        _ = location
        _ = x
        unimplemented()
    }

    func glUniform1fv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLfloat>!) {
        _ = location
        _ = count
        _ = v
        unimplemented()
    }

    func glUniform1i(_ location: GLint, _ x: GLint) {
        _ = location
        _ = x
        unimplemented()
    }

    func glUniform1iv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLint>!) {
        _ = location
        _ = count
        _ = v
        unimplemented()
    }

    func glUniform1ui(_ location: GLint, _ v0: GLuint) {
        _ = location
        _ = v0
        unimplemented()
    }

    func glUniform1uiv(_ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!) {
        _ = location
        _ = count
        _ = value
        unimplemented()
    }

    func glUniform2f(_ location: GLint, _ x: GLfloat, _ y: GLfloat) {
        _ = location
        _ = x
        _ = y
        unimplemented()
    }

    func glUniform2fv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLfloat>!) {
        _ = location
        _ = count
        _ = v
        unimplemented()
    }

    func glUniform2i(_ location: GLint, _ x: GLint, _ y: GLint) {
        _ = location
        _ = x
        _ = y
        unimplemented()
    }

    func glUniform2iv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLint>!) {
        _ = location
        _ = count
        _ = v
        unimplemented()
    }

    func glUniform2ui(_ location: GLint, _ v0: GLuint, _ v1: GLuint) {
        _ = location
        _ = v0
        _ = v1
        unimplemented()
    }

    func glUniform2uiv(_ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!) {
        _ = location
        _ = count
        _ = value
        unimplemented()
    }

    func glUniform3f(_ location: GLint, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat) {
        _ = location
        _ = x
        _ = y
        _ = z
        unimplemented()
    }

    func glUniform3fv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLfloat>!) {
        _ = location
        _ = count
        _ = v
        unimplemented()
    }

    func glUniform3i(_ location: GLint, _ x: GLint, _ y: GLint, _ z: GLint) {
        _ = location
        _ = x
        _ = y
        _ = z
        unimplemented()
    }

    func glUniform3iv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLint>!) {
        _ = location
        _ = count
        _ = v
        unimplemented()
    }

    func glUniform3ui(_ location: GLint, _ v0: GLuint, _ v1: GLuint, _ v2: GLuint) {
        _ = location
        _ = v0
        _ = v1
        _ = v2
        unimplemented()
    }

    func glUniform3uiv(_ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!) {
        _ = location
        _ = count
        _ = value
        unimplemented()
    }

    func glUniform4f(_ location: GLint, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat, _ w: GLfloat) {
        _ = location
        _ = x
        _ = y
        _ = z
        _ = w
        unimplemented()
    }

    func glUniform4fv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLfloat>!) {
        _ = location
        _ = count
        _ = v
        unimplemented()
    }

    func glUniform4i(_ location: GLint, _ x: GLint, _ y: GLint, _ z: GLint, _ w: GLint) {
        _ = location
        _ = x
        _ = y
        _ = z
        _ = w
        unimplemented()
    }

    func glUniform4iv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLint>!) {
        _ = location
        _ = count
        _ = v
        unimplemented()
    }

    func glUniform4ui(_ location: GLint, _ v0: GLuint, _ v1: GLuint, _ v2: GLuint, _ v3: GLuint) {
        _ = location
        _ = v0
        _ = v1
        _ = v2
        _ = v3
        unimplemented()
    }

    func glUniform4uiv(_ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!) {
        _ = location
        _ = count
        _ = value
        unimplemented()
    }

    func glUniformBlockBinding(_ program: GLuint, _ uniformBlockIndex: GLuint, _ uniformBlockBinding: GLuint) {
        _ = program
        _ = uniformBlockIndex
        _ = uniformBlockBinding
        unimplemented()
    }

    func glUniformMatrix2fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
        _ = location
        _ = count
        _ = transpose
        _ = value
        unimplemented()
    }

    func glUniformMatrix2x3fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
        _ = location
        _ = count
        _ = transpose
        _ = value
        unimplemented()
    }

    func glUniformMatrix2x4fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
        _ = location
        _ = count
        _ = transpose
        _ = value
        unimplemented()
    }

    func glUniformMatrix3fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
        _ = location
        _ = count
        _ = transpose
        _ = value
        unimplemented()
    }

    func glUniformMatrix3x2fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
        _ = location
        _ = count
        _ = transpose
        _ = value
        unimplemented()
    }

    func glUniformMatrix3x4fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
        _ = location
        _ = count
        _ = transpose
        _ = value
        unimplemented()
    }

    func glUniformMatrix4fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
        _ = location
        _ = count
        _ = transpose
        _ = value
        unimplemented()
    }

    func glUniformMatrix4x2fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
        _ = location
        _ = count
        _ = transpose
        _ = value
        unimplemented()
    }

    func glUniformMatrix4x3fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
        _ = location
        _ = count
        _ = transpose
        _ = value
        unimplemented()
    }

    func glUnmapBuffer(_ target: GLenum) -> GLboolean {
        _ = target
        unimplemented()
        return 0
    }

    func glUnmapBufferOES(_ target: GLenum) -> GLboolean {
        _ = target
        unimplemented()
        return 0
    }

    func glUseProgram(_ program: GLuint) {
        _ = program
        unimplemented()
    }

    func glUseProgramStagesEXT(_ pipeline: GLuint, _ stages: GLbitfield, _ program: GLuint) {
        _ = pipeline
        _ = stages
        _ = program
        unimplemented()
    }

    func glValidateProgram(_ program: GLuint) {
        _ = program
        unimplemented()
    }

    func glValidateProgramPipelineEXT(_ pipeline: GLuint) {
        _ = pipeline
        unimplemented()
    }

    func glVertexAttrib1f(_ indx: GLuint, _ x: GLfloat) {
        _ = indx
        _ = x
        unimplemented()
    }

    func glVertexAttrib1fv(_ indx: GLuint, _ values: UnsafePointer<GLfloat>!) {
        _ = indx
        _ = values
        unimplemented()
    }

    func glVertexAttrib2f(_ indx: GLuint, _ x: GLfloat, _ y: GLfloat) {
        _ = indx
        _ = x
        _ = y
        unimplemented()
    }

    func glVertexAttrib2fv(_ indx: GLuint, _ values: UnsafePointer<GLfloat>!) {
        _ = indx
        _ = values
        unimplemented()
    }

    func glVertexAttrib3f(_ indx: GLuint, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat) {
        _ = indx
        _ = x
        _ = y
        _ = z
        unimplemented()
    }

    func glVertexAttrib3fv(_ indx: GLuint, _ values: UnsafePointer<GLfloat>!) {
        _ = indx
        _ = values
        unimplemented()
    }

    func glVertexAttrib4f(_ indx: GLuint, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat, _ w: GLfloat) {
        _ = indx
        _ = x
        _ = y
        _ = z
        _ = w
        unimplemented()
    }

    func glVertexAttrib4fv(_ indx: GLuint, _ values: UnsafePointer<GLfloat>!) {
        _ = indx
        _ = values
        unimplemented()
    }

    func glVertexAttribDivisor(_ index: GLuint, _ divisor: GLuint) {
        _ = index
        _ = divisor
        unimplemented()
    }

    func glVertexAttribDivisorEXT(_ index: GLuint, _ divisor: GLuint) {
        _ = index
        _ = divisor
        unimplemented()
    }

    func glVertexAttribI4i(_ index: GLuint, _ x: GLint, _ y: GLint, _ z: GLint, _ w: GLint) {
        _ = index
        _ = x
        _ = y
        _ = z
        _ = w
        unimplemented()
    }

    func glVertexAttribI4iv(_ index: GLuint, _ v: UnsafePointer<GLint>!) {
        _ = index
        _ = v
        unimplemented()
    }

    func glVertexAttribI4ui(_ index: GLuint, _ x: GLuint, _ y: GLuint, _ z: GLuint, _ w: GLuint) {
        _ = index
        _ = x
        _ = y
        _ = z
        _ = w
        unimplemented()
    }

    func glVertexAttribI4uiv(_ index: GLuint, _ v: UnsafePointer<GLuint>!) {
        _ = index
        _ = v
        unimplemented()
    }

    func glVertexAttribIPointer(_ index: GLuint, _ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!) {
        _ = index
        _ = size
        _ = type
        _ = stride
        _ = pointer
        unimplemented()
    }

    func glVertexAttribPointer(_ indx: GLuint, _ size: GLint, _ type: GLenum, _ normalized: GLboolean, _ stride: GLsizei, _ ptr: UnsafeRawPointer!) {
        _ = indx
        _ = size
        _ = type
        _ = normalized
        _ = stride
        _ = ptr
        unimplemented()
    }

    func glVertexPointer(_ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!) {
        _ = size
        _ = type
        _ = stride
        _ = pointer
        unimplemented()
    }

    func glViewport(_ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei) {
        _ = x
        _ = y
        _ = width
        _ = height
        unimplemented()
    }

    func glWaitSync(_ sync: GLsync!, _ flags: GLbitfield, _ timeout: GLuint64) {
        _ = sync
        _ = flags
        _ = timeout
        unimplemented()
    }

    func glWaitSyncAPPLE(_ sync: GLsync!, _ flags: GLbitfield, _ timeout: GLuint64) {
        _ = sync
        _ = flags
        _ = timeout
        unimplemented()
    }

    func glWeightPointerOES(_ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!) {
        _ = size
        _ = type
        _ = stride
        _ = pointer
        unimplemented()
    }

}

/// Public GLES C entry points. Implemented commands reach `GLESState`;
/// the rest fail-closed with `GL_INVALID_OPERATION` when a context is current.

public func glActiveShaderProgramEXT(_ pipeline: GLuint, _ program: GLuint) {
    glesForward { $0.glActiveShaderProgramEXT(pipeline, program) }
}

public func glActiveTexture(_ texture: GLenum) {
    glesForward { $0.glActiveTexture(texture) }
}

public func glAlphaFunc(_ `func`: GLenum, _ ref: GLclampf) {
    glesForward { $0.glAlphaFunc(`func`, ref) }
}

public func glAlphaFuncx(_ `func`: GLenum, _ ref: GLclampx) {
    glesForward { $0.glAlphaFuncx(`func`, ref) }
}

public func glAttachShader(_ program: GLuint, _ shader: GLuint) {
    glesForward { $0.glAttachShader(program, shader) }
}

public func glBeginQuery(_ target: GLenum, _ id: GLuint) {
    glesForward { $0.glBeginQuery(target, id) }
}

public func glBeginQueryEXT(_ target: GLenum, _ id: GLuint) {
    glesForward { $0.glBeginQueryEXT(target, id) }
}

public func glBeginTransformFeedback(_ primitiveMode: GLenum) {
    glesForward { $0.glBeginTransformFeedback(primitiveMode) }
}

public func glBindAttribLocation(_ program: GLuint, _ index: GLuint, _ name: UnsafePointer<GLchar>!) {
    glesForward { $0.glBindAttribLocation(program, index, name) }
}

public func glBindBuffer(_ target: GLenum, _ buffer: GLuint) {
    glesForward { $0.glBindBuffer(target, buffer) }
}

public func glBindBufferBase(_ target: GLenum, _ index: GLuint, _ buffer: GLuint) {
    glesForward { $0.glBindBufferBase(target, index, buffer) }
}

public func glBindBufferRange(_ target: GLenum, _ index: GLuint, _ buffer: GLuint, _ offset: GLintptr, _ size: GLsizeiptr) {
    glesForward { $0.glBindBufferRange(target, index, buffer, offset, size) }
}

public func glBindFramebuffer(_ target: GLenum, _ framebuffer: GLuint) {
    glesForward { $0.glBindFramebuffer(target, framebuffer) }
}

public func glBindFramebufferOES(_ target: GLenum, _ framebuffer: GLuint) {
    glesForward { $0.glBindFramebufferOES(target, framebuffer) }
}

public func glBindProgramPipelineEXT(_ pipeline: GLuint) {
    glesForward { $0.glBindProgramPipelineEXT(pipeline) }
}

public func glBindRenderbuffer(_ target: GLenum, _ renderbuffer: GLuint) {
    glesForward { $0.glBindRenderbuffer(target, renderbuffer) }
}

public func glBindRenderbufferOES(_ target: GLenum, _ renderbuffer: GLuint) {
    glesForward { $0.glBindRenderbufferOES(target, renderbuffer) }
}

public func glBindSampler(_ unit: GLuint, _ sampler: GLuint) {
    glesForward { $0.glBindSampler(unit, sampler) }
}

public func glBindTexture(_ target: GLenum, _ texture: GLuint) {
    glesForward { $0.glBindTexture(target, texture) }
}

public func glBindTransformFeedback(_ target: GLenum, _ id: GLuint) {
    glesForward { $0.glBindTransformFeedback(target, id) }
}

public func glBindVertexArray(_ array: GLuint) {
    glesForward { $0.glBindVertexArray(array) }
}

public func glBindVertexArrayOES(_ array: GLuint) {
    glesForward { $0.glBindVertexArrayOES(array) }
}

public func glBlendColor(_ red: GLfloat, _ green: GLfloat, _ blue: GLfloat, _ alpha: GLfloat) {
    glesForward { $0.glBlendColor(red, green, blue, alpha) }
}

public func glBlendEquation(_ mode: GLenum) {
    glesForward { $0.glBlendEquation(mode) }
}

public func glBlendEquationOES(_ mode: GLenum) {
    glesForward { $0.glBlendEquationOES(mode) }
}

public func glBlendEquationSeparate(_ modeRGB: GLenum, _ modeAlpha: GLenum) {
    glesForward { $0.glBlendEquationSeparate(modeRGB, modeAlpha) }
}

public func glBlendEquationSeparateOES(_ modeRGB: GLenum, _ modeAlpha: GLenum) {
    glesForward { $0.glBlendEquationSeparateOES(modeRGB, modeAlpha) }
}

public func glBlendFunc(_ sfactor: GLenum, _ dfactor: GLenum) {
    glesForward { $0.glBlendFunc(sfactor, dfactor) }
}

public func glBlendFuncSeparate(_ srcRGB: GLenum, _ dstRGB: GLenum, _ srcAlpha: GLenum, _ dstAlpha: GLenum) {
    glesForward { $0.glBlendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha) }
}

public func glBlendFuncSeparateOES(_ srcRGB: GLenum, _ dstRGB: GLenum, _ srcAlpha: GLenum, _ dstAlpha: GLenum) {
    glesForward { $0.glBlendFuncSeparateOES(srcRGB, dstRGB, srcAlpha, dstAlpha) }
}

public func glBlitFramebuffer(_ srcX0: GLint, _ srcY0: GLint, _ srcX1: GLint, _ srcY1: GLint, _ dstX0: GLint, _ dstY0: GLint, _ dstX1: GLint, _ dstY1: GLint, _ mask: GLbitfield, _ filter: GLenum) {
    glesForward { $0.glBlitFramebuffer(srcX0, srcY0, srcX1, srcY1, dstX0, dstY0, dstX1, dstY1, mask, filter) }
}

public func glBufferData(_ target: GLenum, _ size: GLsizeiptr, _ data: UnsafeRawPointer!, _ usage: GLenum) {
    glesForward { $0.glBufferData(target, size, data, usage) }
}

public func glBufferSubData(_ target: GLenum, _ offset: GLintptr, _ size: GLsizeiptr, _ data: UnsafeRawPointer!) {
    glesForward { $0.glBufferSubData(target, offset, size, data) }
}

public func glCheckFramebufferStatus(_ target: GLenum) -> GLenum {
    return glesForwardRet(0) { $0.glCheckFramebufferStatus(target) }
}

public func glCheckFramebufferStatusOES(_ target: GLenum) -> GLenum {
    return glesForwardRet(0) { $0.glCheckFramebufferStatusOES(target) }
}

public func glClear(_ mask: GLbitfield) {
    glesForward { $0.glClear(mask) }
}

public func glClearBufferfi(_ buffer: GLenum, _ drawbuffer: GLint, _ depth: GLfloat, _ stencil: GLint) {
    glesForward { $0.glClearBufferfi(buffer, drawbuffer, depth, stencil) }
}

public func glClearBufferfv(_ buffer: GLenum, _ drawbuffer: GLint, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glClearBufferfv(buffer, drawbuffer, value) }
}

public func glClearBufferiv(_ buffer: GLenum, _ drawbuffer: GLint, _ value: UnsafePointer<GLint>!) {
    glesForward { $0.glClearBufferiv(buffer, drawbuffer, value) }
}

public func glClearBufferuiv(_ buffer: GLenum, _ drawbuffer: GLint, _ value: UnsafePointer<GLuint>!) {
    glesForward { $0.glClearBufferuiv(buffer, drawbuffer, value) }
}

public func glClearColor(_ red: GLfloat, _ green: GLfloat, _ blue: GLfloat, _ alpha: GLfloat) {
    glesForward { $0.glClearColor(red, green, blue, alpha) }
}

public func glClearColorx(_ red: GLclampx, _ green: GLclampx, _ blue: GLclampx, _ alpha: GLclampx) {
    glesForward { $0.glClearColorx(red, green, blue, alpha) }
}

public func glClearDepthf(_ depth: GLclampf) {
    glesForward { $0.glClearDepthf(depth) }
}

public func glClearDepthx(_ depth: GLclampx) {
    glesForward { $0.glClearDepthx(depth) }
}

public func glClearStencil(_ s: GLint) {
    glesForward { $0.glClearStencil(s) }
}

public func glClientActiveTexture(_ texture: GLenum) {
    glesForward { $0.glClientActiveTexture(texture) }
}

public func glClientWaitSync(_ sync: GLsync!, _ flags: GLbitfield, _ timeout: GLuint64) -> GLenum {
    return glesForwardRet(0) { $0.glClientWaitSync(sync, flags, timeout) }
}

public func glClientWaitSyncAPPLE(_ sync: GLsync!, _ flags: GLbitfield, _ timeout: GLuint64) -> GLenum {
    return glesForwardRet(0) { $0.glClientWaitSyncAPPLE(sync, flags, timeout) }
}

public func glClipPlanef(_ plane: GLenum, _ equation: UnsafePointer<GLfloat>!) {
    glesForward { $0.glClipPlanef(plane, equation) }
}

public func glClipPlanex(_ plane: GLenum, _ equation: UnsafePointer<GLfixed>!) {
    glesForward { $0.glClipPlanex(plane, equation) }
}

public func glColor4f(_ red: GLfloat, _ green: GLfloat, _ blue: GLfloat, _ alpha: GLfloat) {
    glesForward { $0.glColor4f(red, green, blue, alpha) }
}

public func glColor4ub(_ red: GLubyte, _ green: GLubyte, _ blue: GLubyte, _ alpha: GLubyte) {
    glesForward { $0.glColor4ub(red, green, blue, alpha) }
}

public func glColor4x(_ red: GLfixed, _ green: GLfixed, _ blue: GLfixed, _ alpha: GLfixed) {
    glesForward { $0.glColor4x(red, green, blue, alpha) }
}

public func glColorMask(_ red: GLboolean, _ green: GLboolean, _ blue: GLboolean, _ alpha: GLboolean) {
    glesForward { $0.glColorMask(red, green, blue, alpha) }
}

public func glColorPointer(_ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!) {
    glesForward { $0.glColorPointer(size, type, stride, pointer) }
}

public func glCompileShader(_ shader: GLuint) {
    glesForward { $0.glCompileShader(shader) }
}

public func glCompressedTexImage2D(_ target: GLenum, _ level: GLint, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei, _ border: GLint, _ imageSize: GLsizei, _ data: UnsafeRawPointer!) {
    glesForward { $0.glCompressedTexImage2D(target, level, internalformat, width, height, border, imageSize, data) }
}

public func glCompressedTexImage3D(_ target: GLenum, _ level: GLint, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei, _ depth: GLsizei, _ border: GLint, _ imageSize: GLsizei, _ data: UnsafeRawPointer!) {
    glesForward { $0.glCompressedTexImage3D(target, level, internalformat, width, height, depth, border, imageSize, data) }
}

public func glCompressedTexSubImage2D(_ target: GLenum, _ level: GLint, _ xoffset: GLint, _ yoffset: GLint, _ width: GLsizei, _ height: GLsizei, _ format: GLenum, _ imageSize: GLsizei, _ data: UnsafeRawPointer!) {
    glesForward { $0.glCompressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, imageSize, data) }
}

public func glCompressedTexSubImage3D(_ target: GLenum, _ level: GLint, _ xoffset: GLint, _ yoffset: GLint, _ zoffset: GLint, _ width: GLsizei, _ height: GLsizei, _ depth: GLsizei, _ format: GLenum, _ imageSize: GLsizei, _ data: UnsafeRawPointer!) {
    glesForward { $0.glCompressedTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, imageSize, data) }
}

public func glCopyBufferSubData(_ readTarget: GLenum, _ writeTarget: GLenum, _ readOffset: GLintptr, _ writeOffset: GLintptr, _ size: GLsizeiptr) {
    glesForward { $0.glCopyBufferSubData(readTarget, writeTarget, readOffset, writeOffset, size) }
}

public func glCopyTexImage2D(_ target: GLenum, _ level: GLint, _ internalformat: GLenum, _ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei, _ border: GLint) {
    glesForward { $0.glCopyTexImage2D(target, level, internalformat, x, y, width, height, border) }
}

public func glCopyTexSubImage2D(_ target: GLenum, _ level: GLint, _ xoffset: GLint, _ yoffset: GLint, _ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei) {
    glesForward { $0.glCopyTexSubImage2D(target, level, xoffset, yoffset, x, y, width, height) }
}

public func glCopyTexSubImage3D(_ target: GLenum, _ level: GLint, _ xoffset: GLint, _ yoffset: GLint, _ zoffset: GLint, _ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei) {
    glesForward { $0.glCopyTexSubImage3D(target, level, xoffset, yoffset, zoffset, x, y, width, height) }
}

public func glCopyTextureLevelsAPPLE(_ destinationTexture: GLuint, _ sourceTexture: GLuint, _ sourceBaseLevel: GLint, _ sourceLevelCount: GLsizei) {
    glesForward { $0.glCopyTextureLevelsAPPLE(destinationTexture, sourceTexture, sourceBaseLevel, sourceLevelCount) }
}

public func glCreateProgram() -> GLuint {
    return glesForwardRet(0) { $0.glCreateProgram() }
}

public func glCreateShader(_ type: GLenum) -> GLuint {
    return glesForwardRet(0) { $0.glCreateShader(type) }
}

public func glCreateShaderProgramvEXT(_ type: GLenum, _ count: GLsizei, _ strings: UnsafePointer<UnsafePointer<GLchar>?>!) -> GLuint {
    return glesForwardRet(0) { $0.glCreateShaderProgramvEXT(type, count, strings) }
}

public func glCullFace(_ mode: GLenum) {
    glesForward { $0.glCullFace(mode) }
}

public func glCurrentPaletteMatrixOES(_ matrixpaletteindex: GLuint) {
    glesForward { $0.glCurrentPaletteMatrixOES(matrixpaletteindex) }
}

public func glDeleteBuffers(_ n: GLsizei, _ buffers: UnsafePointer<GLuint>!) {
    glesForward { $0.glDeleteBuffers(n, buffers) }
}

public func glDeleteFramebuffers(_ n: GLsizei, _ framebuffers: UnsafePointer<GLuint>!) {
    glesForward { $0.glDeleteFramebuffers(n, framebuffers) }
}

public func glDeleteFramebuffersOES(_ n: GLsizei, _ framebuffers: UnsafePointer<GLuint>!) {
    glesForward { $0.glDeleteFramebuffersOES(n, framebuffers) }
}

public func glDeleteProgram(_ program: GLuint) {
    glesForward { $0.glDeleteProgram(program) }
}

public func glDeleteProgramPipelinesEXT(_ n: GLsizei, _ pipelines: UnsafePointer<GLuint>!) {
    glesForward { $0.glDeleteProgramPipelinesEXT(n, pipelines) }
}

public func glDeleteQueries(_ n: GLsizei, _ ids: UnsafePointer<GLuint>!) {
    glesForward { $0.glDeleteQueries(n, ids) }
}

public func glDeleteQueriesEXT(_ n: GLsizei, _ ids: UnsafePointer<GLuint>!) {
    glesForward { $0.glDeleteQueriesEXT(n, ids) }
}

public func glDeleteRenderbuffers(_ n: GLsizei, _ renderbuffers: UnsafePointer<GLuint>!) {
    glesForward { $0.glDeleteRenderbuffers(n, renderbuffers) }
}

public func glDeleteRenderbuffersOES(_ n: GLsizei, _ renderbuffers: UnsafePointer<GLuint>!) {
    glesForward { $0.glDeleteRenderbuffersOES(n, renderbuffers) }
}

public func glDeleteSamplers(_ count: GLsizei, _ samplers: UnsafePointer<GLuint>!) {
    glesForward { $0.glDeleteSamplers(count, samplers) }
}

public func glDeleteShader(_ shader: GLuint) {
    glesForward { $0.glDeleteShader(shader) }
}

public func glDeleteSync(_ sync: GLsync!) {
    glesForward { $0.glDeleteSync(sync) }
}

public func glDeleteSyncAPPLE(_ sync: GLsync!) {
    glesForward { $0.glDeleteSyncAPPLE(sync) }
}

public func glDeleteTextures(_ n: GLsizei, _ textures: UnsafePointer<GLuint>!) {
    glesForward { $0.glDeleteTextures(n, textures) }
}

public func glDeleteTransformFeedbacks(_ n: GLsizei, _ ids: UnsafePointer<GLuint>!) {
    glesForward { $0.glDeleteTransformFeedbacks(n, ids) }
}

public func glDeleteVertexArrays(_ n: GLsizei, _ arrays: UnsafePointer<GLuint>!) {
    glesForward { $0.glDeleteVertexArrays(n, arrays) }
}

public func glDeleteVertexArraysOES(_ n: GLsizei, _ arrays: UnsafePointer<GLuint>!) {
    glesForward { $0.glDeleteVertexArraysOES(n, arrays) }
}

public func glDepthFunc(_ `func`: GLenum) {
    glesForward { $0.glDepthFunc(`func`) }
}

public func glDepthMask(_ flag: GLboolean) {
    glesForward { $0.glDepthMask(flag) }
}

public func glDepthRangef(_ zNear: GLclampf, _ zFar: GLclampf) {
    glesForward { $0.glDepthRangef(zNear, zFar) }
}

public func glDepthRangex(_ zNear: GLclampx, _ zFar: GLclampx) {
    glesForward { $0.glDepthRangex(zNear, zFar) }
}

public func glDetachShader(_ program: GLuint, _ shader: GLuint) {
    glesForward { $0.glDetachShader(program, shader) }
}

public func glDisable(_ cap: GLenum) {
    glesForward { $0.glDisable(cap) }
}

public func glDisableClientState(_ array: GLenum) {
    glesForward { $0.glDisableClientState(array) }
}

public func glDisableVertexAttribArray(_ index: GLuint) {
    glesForward { $0.glDisableVertexAttribArray(index) }
}

public func glDiscardFramebufferEXT(_ target: GLenum, _ numAttachments: GLsizei, _ attachments: UnsafePointer<GLenum>!) {
    glesForward { $0.glDiscardFramebufferEXT(target, numAttachments, attachments) }
}

public func glDrawArrays(_ mode: GLenum, _ first: GLint, _ count: GLsizei) {
    glesForward { $0.glDrawArrays(mode, first, count) }
}

public func glDrawArraysInstanced(_ mode: GLenum, _ first: GLint, _ count: GLsizei, _ instancecount: GLsizei) {
    glesForward { $0.glDrawArraysInstanced(mode, first, count, instancecount) }
}

public func glDrawArraysInstancedEXT(_ mode: GLenum, _ first: GLint, _ count: GLsizei, _ instanceCount: GLsizei) {
    glesForward { $0.glDrawArraysInstancedEXT(mode, first, count, instanceCount) }
}

public func glDrawBuffers(_ n: GLsizei, _ bufs: UnsafePointer<GLenum>!) {
    glesForward { $0.glDrawBuffers(n, bufs) }
}

public func glDrawElements(_ mode: GLenum, _ count: GLsizei, _ type: GLenum, _ indices: UnsafeRawPointer!) {
    glesForward { $0.glDrawElements(mode, count, type, indices) }
}

public func glDrawElementsInstanced(_ mode: GLenum, _ count: GLsizei, _ type: GLenum, _ indices: UnsafeRawPointer!, _ instancecount: GLsizei) {
    glesForward { $0.glDrawElementsInstanced(mode, count, type, indices, instancecount) }
}

public func glDrawElementsInstancedEXT(_ mode: GLenum, _ count: GLsizei, _ type: GLenum, _ indices: UnsafeRawPointer!, _ instanceCount: GLsizei) {
    glesForward { $0.glDrawElementsInstancedEXT(mode, count, type, indices, instanceCount) }
}

public func glDrawRangeElements(_ mode: GLenum, _ start: GLuint, _ end: GLuint, _ count: GLsizei, _ type: GLenum, _ indices: UnsafeRawPointer!) {
    glesForward { $0.glDrawRangeElements(mode, start, end, count, type, indices) }
}

public func glDrawTexfOES(_ x: GLfloat, _ y: GLfloat, _ z: GLfloat, _ width: GLfloat, _ height: GLfloat) {
    glesForward { $0.glDrawTexfOES(x, y, z, width, height) }
}

public func glDrawTexfvOES(_ coords: UnsafePointer<GLfloat>!) {
    glesForward { $0.glDrawTexfvOES(coords) }
}

public func glDrawTexiOES(_ x: GLint, _ y: GLint, _ z: GLint, _ width: GLint, _ height: GLint) {
    glesForward { $0.glDrawTexiOES(x, y, z, width, height) }
}

public func glDrawTexivOES(_ coords: UnsafePointer<GLint>!) {
    glesForward { $0.glDrawTexivOES(coords) }
}

public func glDrawTexsOES(_ x: GLshort, _ y: GLshort, _ z: GLshort, _ width: GLshort, _ height: GLshort) {
    glesForward { $0.glDrawTexsOES(x, y, z, width, height) }
}

public func glDrawTexsvOES(_ coords: UnsafePointer<GLshort>!) {
    glesForward { $0.glDrawTexsvOES(coords) }
}

public func glDrawTexxOES(_ x: GLfixed, _ y: GLfixed, _ z: GLfixed, _ width: GLfixed, _ height: GLfixed) {
    glesForward { $0.glDrawTexxOES(x, y, z, width, height) }
}

public func glDrawTexxvOES(_ coords: UnsafePointer<GLfixed>!) {
    glesForward { $0.glDrawTexxvOES(coords) }
}

public func glEnable(_ cap: GLenum) {
    glesForward { $0.glEnable(cap) }
}

public func glEnableClientState(_ array: GLenum) {
    glesForward { $0.glEnableClientState(array) }
}

public func glEnableVertexAttribArray(_ index: GLuint) {
    glesForward { $0.glEnableVertexAttribArray(index) }
}

public func glEndQuery(_ target: GLenum) {
    glesForward { $0.glEndQuery(target) }
}

public func glEndQueryEXT(_ target: GLenum) {
    glesForward { $0.glEndQueryEXT(target) }
}

public func glEndTransformFeedback() {
    glesForward { $0.glEndTransformFeedback() }
}

public func glFenceSync(_ condition: GLenum, _ flags: GLbitfield) -> GLsync! {
    return glesForwardRet(nil) { $0.glFenceSync(condition, flags) }
}

public func glFenceSyncAPPLE(_ condition: GLenum, _ flags: GLbitfield) -> GLsync! {
    return glesForwardRet(nil) { $0.glFenceSyncAPPLE(condition, flags) }
}

public func glFinish() {
    glesForward { $0.glFinish() }
}

public func glFlush() {
    glesForward { $0.glFlush() }
}

public func glFlushMappedBufferRange(_ target: GLenum, _ offset: GLintptr, _ length: GLsizeiptr) {
    glesForward { $0.glFlushMappedBufferRange(target, offset, length) }
}

public func glFlushMappedBufferRangeEXT(_ target: GLenum, _ offset: GLintptr, _ length: GLsizeiptr) {
    glesForward { $0.glFlushMappedBufferRangeEXT(target, offset, length) }
}

public func glFogf(_ pname: GLenum, _ param: GLfloat) {
    glesForward { $0.glFogf(pname, param) }
}

public func glFogfv(_ pname: GLenum, _ params: UnsafePointer<GLfloat>!) {
    glesForward { $0.glFogfv(pname, params) }
}

public func glFogx(_ pname: GLenum, _ param: GLfixed) {
    glesForward { $0.glFogx(pname, param) }
}

public func glFogxv(_ pname: GLenum, _ params: UnsafePointer<GLfixed>!) {
    glesForward { $0.glFogxv(pname, params) }
}

public func glFramebufferRenderbuffer(_ target: GLenum, _ attachment: GLenum, _ renderbuffertarget: GLenum, _ renderbuffer: GLuint) {
    glesForward { $0.glFramebufferRenderbuffer(target, attachment, renderbuffertarget, renderbuffer) }
}

public func glFramebufferRenderbufferOES(_ target: GLenum, _ attachment: GLenum, _ renderbuffertarget: GLenum, _ renderbuffer: GLuint) {
    glesForward { $0.glFramebufferRenderbufferOES(target, attachment, renderbuffertarget, renderbuffer) }
}

public func glFramebufferTexture2D(_ target: GLenum, _ attachment: GLenum, _ textarget: GLenum, _ texture: GLuint, _ level: GLint) {
    glesForward { $0.glFramebufferTexture2D(target, attachment, textarget, texture, level) }
}

public func glFramebufferTexture2DOES(_ target: GLenum, _ attachment: GLenum, _ textarget: GLenum, _ texture: GLuint, _ level: GLint) {
    glesForward { $0.glFramebufferTexture2DOES(target, attachment, textarget, texture, level) }
}

public func glFramebufferTextureLayer(_ target: GLenum, _ attachment: GLenum, _ texture: GLuint, _ level: GLint, _ layer: GLint) {
    glesForward { $0.glFramebufferTextureLayer(target, attachment, texture, level, layer) }
}

public func glFrontFace(_ mode: GLenum) {
    glesForward { $0.glFrontFace(mode) }
}

public func glFrustumf(_ left: GLfloat, _ right: GLfloat, _ bottom: GLfloat, _ top: GLfloat, _ zNear: GLfloat, _ zFar: GLfloat) {
    glesForward { $0.glFrustumf(left, right, bottom, top, zNear, zFar) }
}

public func glFrustumx(_ left: GLfixed, _ right: GLfixed, _ bottom: GLfixed, _ top: GLfixed, _ zNear: GLfixed, _ zFar: GLfixed) {
    glesForward { $0.glFrustumx(left, right, bottom, top, zNear, zFar) }
}

public func glGenBuffers(_ n: GLsizei, _ buffers: UnsafeMutablePointer<GLuint>!) {
    glesForward { $0.glGenBuffers(n, buffers) }
}

public func glGenFramebuffers(_ n: GLsizei, _ framebuffers: UnsafeMutablePointer<GLuint>!) {
    glesForward { $0.glGenFramebuffers(n, framebuffers) }
}

public func glGenFramebuffersOES(_ n: GLsizei, _ framebuffers: UnsafeMutablePointer<GLuint>!) {
    glesForward { $0.glGenFramebuffersOES(n, framebuffers) }
}

public func glGenProgramPipelinesEXT(_ n: GLsizei, _ pipelines: UnsafeMutablePointer<GLuint>!) {
    glesForward { $0.glGenProgramPipelinesEXT(n, pipelines) }
}

public func glGenQueries(_ n: GLsizei, _ ids: UnsafeMutablePointer<GLuint>!) {
    glesForward { $0.glGenQueries(n, ids) }
}

public func glGenQueriesEXT(_ n: GLsizei, _ ids: UnsafeMutablePointer<GLuint>!) {
    glesForward { $0.glGenQueriesEXT(n, ids) }
}

public func glGenRenderbuffers(_ n: GLsizei, _ renderbuffers: UnsafeMutablePointer<GLuint>!) {
    glesForward { $0.glGenRenderbuffers(n, renderbuffers) }
}

public func glGenRenderbuffersOES(_ n: GLsizei, _ renderbuffers: UnsafeMutablePointer<GLuint>!) {
    glesForward { $0.glGenRenderbuffersOES(n, renderbuffers) }
}

public func glGenSamplers(_ count: GLsizei, _ samplers: UnsafeMutablePointer<GLuint>!) {
    glesForward { $0.glGenSamplers(count, samplers) }
}

public func glGenTextures(_ n: GLsizei, _ textures: UnsafeMutablePointer<GLuint>!) {
    glesForward { $0.glGenTextures(n, textures) }
}

public func glGenTransformFeedbacks(_ n: GLsizei, _ ids: UnsafeMutablePointer<GLuint>!) {
    glesForward { $0.glGenTransformFeedbacks(n, ids) }
}

public func glGenVertexArrays(_ n: GLsizei, _ arrays: UnsafeMutablePointer<GLuint>!) {
    glesForward { $0.glGenVertexArrays(n, arrays) }
}

public func glGenVertexArraysOES(_ n: GLsizei, _ arrays: UnsafeMutablePointer<GLuint>!) {
    glesForward { $0.glGenVertexArraysOES(n, arrays) }
}

public func glGenerateMipmap(_ target: GLenum) {
    glesForward { $0.glGenerateMipmap(target) }
}

public func glGenerateMipmapOES(_ target: GLenum) {
    glesForward { $0.glGenerateMipmapOES(target) }
}

public func glGetActiveAttrib(_ program: GLuint, _ index: GLuint, _ bufsize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ size: UnsafeMutablePointer<GLint>!, _ type: UnsafeMutablePointer<GLenum>!, _ name: UnsafeMutablePointer<GLchar>!) {
    glesForward { $0.glGetActiveAttrib(program, index, bufsize, length, size, type, name) }
}

public func glGetActiveUniform(_ program: GLuint, _ index: GLuint, _ bufsize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ size: UnsafeMutablePointer<GLint>!, _ type: UnsafeMutablePointer<GLenum>!, _ name: UnsafeMutablePointer<GLchar>!) {
    glesForward { $0.glGetActiveUniform(program, index, bufsize, length, size, type, name) }
}

public func glGetActiveUniformBlockName(_ program: GLuint, _ uniformBlockIndex: GLuint, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ uniformBlockName: UnsafeMutablePointer<GLchar>!) {
    glesForward { $0.glGetActiveUniformBlockName(program, uniformBlockIndex, bufSize, length, uniformBlockName) }
}

public func glGetActiveUniformBlockiv(_ program: GLuint, _ uniformBlockIndex: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetActiveUniformBlockiv(program, uniformBlockIndex, pname, params) }
}

public func glGetActiveUniformsiv(_ program: GLuint, _ uniformCount: GLsizei, _ uniformIndices: UnsafePointer<GLuint>!, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetActiveUniformsiv(program, uniformCount, uniformIndices, pname, params) }
}

public func glGetAttachedShaders(_ program: GLuint, _ maxcount: GLsizei, _ count: UnsafeMutablePointer<GLsizei>!, _ shaders: UnsafeMutablePointer<GLuint>!) {
    glesForward { $0.glGetAttachedShaders(program, maxcount, count, shaders) }
}

public func glGetAttribLocation(_ program: GLuint, _ name: UnsafePointer<GLchar>!) -> Int32 {
    return glesForwardRet(0) { $0.glGetAttribLocation(program, name) }
}

public func glGetBooleanv(_ pname: GLenum, _ params: UnsafeMutablePointer<GLboolean>!) {
    glesForward { $0.glGetBooleanv(pname, params) }
}

public func glGetBufferParameteri64v(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint64>!) {
    glesForward { $0.glGetBufferParameteri64v(target, pname, params) }
}

public func glGetBufferParameteriv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetBufferParameteriv(target, pname, params) }
}

public func glGetBufferPointerv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<UnsafeMutableRawPointer?>!) {
    glesForward { $0.glGetBufferPointerv(target, pname, params) }
}

public func glGetBufferPointervOES(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<UnsafeMutableRawPointer?>!) {
    glesForward { $0.glGetBufferPointervOES(target, pname, params) }
}

public func glGetClipPlanef(_ pname: GLenum, _ equation: UnsafeMutablePointer<GLfloat>!) {
    glesForward { $0.glGetClipPlanef(pname, equation) }
}

public func glGetClipPlanex(_ pname: GLenum, _ eqn: UnsafeMutablePointer<GLfixed>!) {
    glesForward { $0.glGetClipPlanex(pname, eqn) }
}

public func glGetFixedv(_ pname: GLenum, _ params: UnsafeMutablePointer<GLfixed>!) {
    glesForward { $0.glGetFixedv(pname, params) }
}

public func glGetFloatv(_ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!) {
    glesForward { $0.glGetFloatv(pname, params) }
}

public func glGetFragDataLocation(_ program: GLuint, _ name: UnsafePointer<GLchar>!) -> GLint {
    return glesForwardRet(0) { $0.glGetFragDataLocation(program, name) }
}

public func glGetFramebufferAttachmentParameteriv(_ target: GLenum, _ attachment: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetFramebufferAttachmentParameteriv(target, attachment, pname, params) }
}

public func glGetFramebufferAttachmentParameterivOES(_ target: GLenum, _ attachment: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetFramebufferAttachmentParameterivOES(target, attachment, pname, params) }
}

public func glGetInteger64i_v(_ target: GLenum, _ index: GLuint, _ data: UnsafeMutablePointer<GLint64>!) {
    glesForward { $0.glGetInteger64i_v(target, index, data) }
}

public func glGetInteger64v(_ pname: GLenum, _ params: UnsafeMutablePointer<GLint64>!) {
    glesForward { $0.glGetInteger64v(pname, params) }
}

public func glGetInteger64vAPPLE(_ pname: GLenum, _ params: UnsafeMutablePointer<GLint64>!) {
    glesForward { $0.glGetInteger64vAPPLE(pname, params) }
}

public func glGetIntegeri_v(_ target: GLenum, _ index: GLuint, _ data: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetIntegeri_v(target, index, data) }
}

public func glGetIntegerv(_ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetIntegerv(pname, params) }
}

public func glGetInternalformativ(_ target: GLenum, _ internalformat: GLenum, _ pname: GLenum, _ bufSize: GLsizei, _ params: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetInternalformativ(target, internalformat, pname, bufSize, params) }
}

public func glGetLightfv(_ light: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!) {
    glesForward { $0.glGetLightfv(light, pname, params) }
}

public func glGetLightxv(_ light: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfixed>!) {
    glesForward { $0.glGetLightxv(light, pname, params) }
}

public func glGetMaterialfv(_ face: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!) {
    glesForward { $0.glGetMaterialfv(face, pname, params) }
}

public func glGetMaterialxv(_ face: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfixed>!) {
    glesForward { $0.glGetMaterialxv(face, pname, params) }
}

public func glGetObjectLabelEXT(_ type: GLenum, _ object: GLuint, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ label: UnsafeMutablePointer<GLchar>!) {
    glesForward { $0.glGetObjectLabelEXT(type, object, bufSize, length, label) }
}

public func glGetPointerv(_ pname: GLenum, _ params: UnsafeMutablePointer<UnsafeMutableRawPointer?>!) {
    glesForward { $0.glGetPointerv(pname, params) }
}

public func glGetProgramBinary(_ program: GLuint, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ binaryFormat: UnsafeMutablePointer<GLenum>!, _ binary: UnsafeMutableRawPointer!) {
    glesForward { $0.glGetProgramBinary(program, bufSize, length, binaryFormat, binary) }
}

public func glGetProgramInfoLog(_ program: GLuint, _ bufsize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ infolog: UnsafeMutablePointer<GLchar>!) {
    glesForward { $0.glGetProgramInfoLog(program, bufsize, length, infolog) }
}

public func glGetProgramPipelineInfoLogEXT(_ pipeline: GLuint, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ infoLog: UnsafeMutablePointer<GLchar>!) {
    glesForward { $0.glGetProgramPipelineInfoLogEXT(pipeline, bufSize, length, infoLog) }
}

public func glGetProgramPipelineivEXT(_ pipeline: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetProgramPipelineivEXT(pipeline, pname, params) }
}

public func glGetProgramiv(_ program: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetProgramiv(program, pname, params) }
}

public func glGetQueryObjectuiv(_ id: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLuint>!) {
    glesForward { $0.glGetQueryObjectuiv(id, pname, params) }
}

public func glGetQueryObjectuivEXT(_ id: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLuint>!) {
    glesForward { $0.glGetQueryObjectuivEXT(id, pname, params) }
}

public func glGetQueryiv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetQueryiv(target, pname, params) }
}

public func glGetQueryivEXT(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetQueryivEXT(target, pname, params) }
}

public func glGetRenderbufferParameteriv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetRenderbufferParameteriv(target, pname, params) }
}

public func glGetRenderbufferParameterivOES(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetRenderbufferParameterivOES(target, pname, params) }
}

public func glGetSamplerParameterfv(_ sampler: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!) {
    glesForward { $0.glGetSamplerParameterfv(sampler, pname, params) }
}

public func glGetSamplerParameteriv(_ sampler: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetSamplerParameteriv(sampler, pname, params) }
}

public func glGetShaderInfoLog(_ shader: GLuint, _ bufsize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ infolog: UnsafeMutablePointer<GLchar>!) {
    glesForward { $0.glGetShaderInfoLog(shader, bufsize, length, infolog) }
}

public func glGetShaderPrecisionFormat(_ shadertype: GLenum, _ precisiontype: GLenum, _ range: UnsafeMutablePointer<GLint>!, _ precision: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetShaderPrecisionFormat(shadertype, precisiontype, range, precision) }
}

public func glGetShaderSource(_ shader: GLuint, _ bufsize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ source: UnsafeMutablePointer<GLchar>!) {
    glesForward { $0.glGetShaderSource(shader, bufsize, length, source) }
}

public func glGetShaderiv(_ shader: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetShaderiv(shader, pname, params) }
}

public func glGetString(_ name: GLenum) -> UnsafePointer<GLubyte>! {
    return glesForwardRet(nil) { $0.glGetString(name) }
}

public func glGetStringi(_ name: GLenum, _ index: GLuint) -> UnsafePointer<GLubyte>! {
    return glesForwardRet(nil) { $0.glGetStringi(name, index) }
}

public func glGetSynciv(_ sync: GLsync!, _ pname: GLenum, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ values: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetSynciv(sync, pname, bufSize, length, values) }
}

public func glGetSyncivAPPLE(_ sync: GLsync!, _ pname: GLenum, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ values: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetSyncivAPPLE(sync, pname, bufSize, length, values) }
}

public func glGetTexEnvfv(_ env: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!) {
    glesForward { $0.glGetTexEnvfv(env, pname, params) }
}

public func glGetTexEnviv(_ env: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetTexEnviv(env, pname, params) }
}

public func glGetTexEnvxv(_ env: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfixed>!) {
    glesForward { $0.glGetTexEnvxv(env, pname, params) }
}

public func glGetTexParameterfv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!) {
    glesForward { $0.glGetTexParameterfv(target, pname, params) }
}

public func glGetTexParameteriv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetTexParameteriv(target, pname, params) }
}

public func glGetTexParameterxv(_ target: GLenum, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfixed>!) {
    glesForward { $0.glGetTexParameterxv(target, pname, params) }
}

public func glGetTransformFeedbackVarying(_ program: GLuint, _ index: GLuint, _ bufSize: GLsizei, _ length: UnsafeMutablePointer<GLsizei>!, _ size: UnsafeMutablePointer<GLsizei>!, _ type: UnsafeMutablePointer<GLenum>!, _ name: UnsafeMutablePointer<GLchar>!) {
    glesForward { $0.glGetTransformFeedbackVarying(program, index, bufSize, length, size, type, name) }
}

public func glGetUniformBlockIndex(_ program: GLuint, _ uniformBlockName: UnsafePointer<GLchar>!) -> GLuint {
    return glesForwardRet(0) { $0.glGetUniformBlockIndex(program, uniformBlockName) }
}

public func glGetUniformIndices(_ program: GLuint, _ uniformCount: GLsizei, _ uniformNames: UnsafePointer<UnsafePointer<GLchar>?>!, _ uniformIndices: UnsafeMutablePointer<GLuint>!) {
    glesForward { $0.glGetUniformIndices(program, uniformCount, uniformNames, uniformIndices) }
}

public func glGetUniformLocation(_ program: GLuint, _ name: UnsafePointer<GLchar>!) -> Int32 {
    return glesForwardRet(0) { $0.glGetUniformLocation(program, name) }
}

public func glGetUniformfv(_ program: GLuint, _ location: GLint, _ params: UnsafeMutablePointer<GLfloat>!) {
    glesForward { $0.glGetUniformfv(program, location, params) }
}

public func glGetUniformiv(_ program: GLuint, _ location: GLint, _ params: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetUniformiv(program, location, params) }
}

public func glGetUniformuiv(_ program: GLuint, _ location: GLint, _ params: UnsafeMutablePointer<GLuint>!) {
    glesForward { $0.glGetUniformuiv(program, location, params) }
}

public func glGetVertexAttribIiv(_ index: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetVertexAttribIiv(index, pname, params) }
}

public func glGetVertexAttribIuiv(_ index: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLuint>!) {
    glesForward { $0.glGetVertexAttribIuiv(index, pname, params) }
}

public func glGetVertexAttribPointerv(_ index: GLuint, _ pname: GLenum, _ pointer: UnsafeMutablePointer<UnsafeMutableRawPointer?>!) {
    glesForward { $0.glGetVertexAttribPointerv(index, pname, pointer) }
}

public func glGetVertexAttribfv(_ index: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLfloat>!) {
    glesForward { $0.glGetVertexAttribfv(index, pname, params) }
}

public func glGetVertexAttribiv(_ index: GLuint, _ pname: GLenum, _ params: UnsafeMutablePointer<GLint>!) {
    glesForward { $0.glGetVertexAttribiv(index, pname, params) }
}

public func glHint(_ target: GLenum, _ mode: GLenum) {
    glesForward { $0.glHint(target, mode) }
}

public func glInsertEventMarkerEXT(_ length: GLsizei, _ marker: UnsafePointer<GLchar>!) {
    glesForward { $0.glInsertEventMarkerEXT(length, marker) }
}

public func glInvalidateFramebuffer(_ target: GLenum, _ numAttachments: GLsizei, _ attachments: UnsafePointer<GLenum>!) {
    glesForward { $0.glInvalidateFramebuffer(target, numAttachments, attachments) }
}

public func glInvalidateSubFramebuffer(_ target: GLenum, _ numAttachments: GLsizei, _ attachments: UnsafePointer<GLenum>!, _ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei) {
    glesForward { $0.glInvalidateSubFramebuffer(target, numAttachments, attachments, x, y, width, height) }
}

public func glIsBuffer(_ buffer: GLuint) -> GLboolean {
    return glesForwardRet(0) { $0.glIsBuffer(buffer) }
}

public func glIsEnabled(_ cap: GLenum) -> GLboolean {
    return glesForwardRet(0) { $0.glIsEnabled(cap) }
}

public func glIsFramebuffer(_ framebuffer: GLuint) -> GLboolean {
    return glesForwardRet(0) { $0.glIsFramebuffer(framebuffer) }
}

public func glIsFramebufferOES(_ framebuffer: GLuint) -> GLboolean {
    return glesForwardRet(0) { $0.glIsFramebufferOES(framebuffer) }
}

public func glIsProgram(_ program: GLuint) -> GLboolean {
    return glesForwardRet(0) { $0.glIsProgram(program) }
}

public func glIsProgramPipelineEXT(_ pipeline: GLuint) -> GLboolean {
    return glesForwardRet(0) { $0.glIsProgramPipelineEXT(pipeline) }
}

public func glIsQuery(_ id: GLuint) -> GLboolean {
    return glesForwardRet(0) { $0.glIsQuery(id) }
}

public func glIsQueryEXT(_ id: GLuint) -> GLboolean {
    return glesForwardRet(0) { $0.glIsQueryEXT(id) }
}

public func glIsRenderbuffer(_ renderbuffer: GLuint) -> GLboolean {
    return glesForwardRet(0) { $0.glIsRenderbuffer(renderbuffer) }
}

public func glIsRenderbufferOES(_ renderbuffer: GLuint) -> GLboolean {
    return glesForwardRet(0) { $0.glIsRenderbufferOES(renderbuffer) }
}

public func glIsSampler(_ sampler: GLuint) -> GLboolean {
    return glesForwardRet(0) { $0.glIsSampler(sampler) }
}

public func glIsShader(_ shader: GLuint) -> GLboolean {
    return glesForwardRet(0) { $0.glIsShader(shader) }
}

public func glIsSync(_ sync: GLsync!) -> GLboolean {
    return glesForwardRet(0) { $0.glIsSync(sync) }
}

public func glIsSyncAPPLE(_ sync: GLsync!) -> GLboolean {
    return glesForwardRet(0) { $0.glIsSyncAPPLE(sync) }
}

public func glIsTexture(_ texture: GLuint) -> GLboolean {
    return glesForwardRet(0) { $0.glIsTexture(texture) }
}

public func glIsTransformFeedback(_ id: GLuint) -> GLboolean {
    return glesForwardRet(0) { $0.glIsTransformFeedback(id) }
}

public func glIsVertexArray(_ array: GLuint) -> GLboolean {
    return glesForwardRet(0) { $0.glIsVertexArray(array) }
}

public func glIsVertexArrayOES(_ array: GLuint) -> GLboolean {
    return glesForwardRet(0) { $0.glIsVertexArrayOES(array) }
}

public func glLabelObjectEXT(_ type: GLenum, _ object: GLuint, _ length: GLsizei, _ label: UnsafePointer<GLchar>!) {
    glesForward { $0.glLabelObjectEXT(type, object, length, label) }
}

public func glLightModelf(_ pname: GLenum, _ param: GLfloat) {
    glesForward { $0.glLightModelf(pname, param) }
}

public func glLightModelfv(_ pname: GLenum, _ params: UnsafePointer<GLfloat>!) {
    glesForward { $0.glLightModelfv(pname, params) }
}

public func glLightModelx(_ pname: GLenum, _ param: GLfixed) {
    glesForward { $0.glLightModelx(pname, param) }
}

public func glLightModelxv(_ pname: GLenum, _ params: UnsafePointer<GLfixed>!) {
    glesForward { $0.glLightModelxv(pname, params) }
}

public func glLightf(_ light: GLenum, _ pname: GLenum, _ param: GLfloat) {
    glesForward { $0.glLightf(light, pname, param) }
}

public func glLightfv(_ light: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfloat>!) {
    glesForward { $0.glLightfv(light, pname, params) }
}

public func glLightx(_ light: GLenum, _ pname: GLenum, _ param: GLfixed) {
    glesForward { $0.glLightx(light, pname, param) }
}

public func glLightxv(_ light: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfixed>!) {
    glesForward { $0.glLightxv(light, pname, params) }
}

public func glLineWidth(_ width: GLfloat) {
    glesForward { $0.glLineWidth(width) }
}

public func glLineWidthx(_ width: GLfixed) {
    glesForward { $0.glLineWidthx(width) }
}

public func glLinkProgram(_ program: GLuint) {
    glesForward { $0.glLinkProgram(program) }
}

public func glLoadIdentity() {
    glesForward { $0.glLoadIdentity() }
}

public func glLoadMatrixf(_ m: UnsafePointer<GLfloat>!) {
    glesForward { $0.glLoadMatrixf(m) }
}

public func glLoadMatrixx(_ m: UnsafePointer<GLfixed>!) {
    glesForward { $0.glLoadMatrixx(m) }
}

public func glLoadPaletteFromModelViewMatrixOES() {
    glesForward { $0.glLoadPaletteFromModelViewMatrixOES() }
}

public func glLogicOp(_ opcode: GLenum) {
    glesForward { $0.glLogicOp(opcode) }
}

public func glMapBufferOES(_ target: GLenum, _ access: GLenum) -> UnsafeMutableRawPointer! {
    return glesForwardRet(nil) { $0.glMapBufferOES(target, access) }
}

public func glMapBufferRange(_ target: GLenum, _ offset: GLintptr, _ length: GLsizeiptr, _ access: GLbitfield) -> UnsafeMutableRawPointer! {
    return glesForwardRet(nil) { $0.glMapBufferRange(target, offset, length, access) }
}

public func glMapBufferRangeEXT(_ target: GLenum, _ offset: GLintptr, _ length: GLsizeiptr, _ access: GLbitfield) -> UnsafeMutableRawPointer! {
    return glesForwardRet(nil) { $0.glMapBufferRangeEXT(target, offset, length, access) }
}

public func glMaterialf(_ face: GLenum, _ pname: GLenum, _ param: GLfloat) {
    glesForward { $0.glMaterialf(face, pname, param) }
}

public func glMaterialfv(_ face: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfloat>!) {
    glesForward { $0.glMaterialfv(face, pname, params) }
}

public func glMaterialx(_ face: GLenum, _ pname: GLenum, _ param: GLfixed) {
    glesForward { $0.glMaterialx(face, pname, param) }
}

public func glMaterialxv(_ face: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfixed>!) {
    glesForward { $0.glMaterialxv(face, pname, params) }
}

public func glMatrixIndexPointerOES(_ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!) {
    glesForward { $0.glMatrixIndexPointerOES(size, type, stride, pointer) }
}

public func glMatrixMode(_ mode: GLenum) {
    glesForward { $0.glMatrixMode(mode) }
}

public func glMultMatrixf(_ m: UnsafePointer<GLfloat>!) {
    glesForward { $0.glMultMatrixf(m) }
}

public func glMultMatrixx(_ m: UnsafePointer<GLfixed>!) {
    glesForward { $0.glMultMatrixx(m) }
}

public func glMultiTexCoord4f(_ target: GLenum, _ s: GLfloat, _ t: GLfloat, _ r: GLfloat, _ q: GLfloat) {
    glesForward { $0.glMultiTexCoord4f(target, s, t, r, q) }
}

public func glMultiTexCoord4x(_ target: GLenum, _ s: GLfixed, _ t: GLfixed, _ r: GLfixed, _ q: GLfixed) {
    glesForward { $0.glMultiTexCoord4x(target, s, t, r, q) }
}

public func glNormal3f(_ nx: GLfloat, _ ny: GLfloat, _ nz: GLfloat) {
    glesForward { $0.glNormal3f(nx, ny, nz) }
}

public func glNormal3x(_ nx: GLfixed, _ ny: GLfixed, _ nz: GLfixed) {
    glesForward { $0.glNormal3x(nx, ny, nz) }
}

public func glNormalPointer(_ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!) {
    glesForward { $0.glNormalPointer(type, stride, pointer) }
}

public func glOrthof(_ left: GLfloat, _ right: GLfloat, _ bottom: GLfloat, _ top: GLfloat, _ zNear: GLfloat, _ zFar: GLfloat) {
    glesForward { $0.glOrthof(left, right, bottom, top, zNear, zFar) }
}

public func glOrthox(_ left: GLfixed, _ right: GLfixed, _ bottom: GLfixed, _ top: GLfixed, _ zNear: GLfixed, _ zFar: GLfixed) {
    glesForward { $0.glOrthox(left, right, bottom, top, zNear, zFar) }
}

public func glPauseTransformFeedback() {
    glesForward { $0.glPauseTransformFeedback() }
}

public func glPixelStorei(_ pname: GLenum, _ param: GLint) {
    glesForward { $0.glPixelStorei(pname, param) }
}

public func glPointParameterf(_ pname: GLenum, _ param: GLfloat) {
    glesForward { $0.glPointParameterf(pname, param) }
}

public func glPointParameterfv(_ pname: GLenum, _ params: UnsafePointer<GLfloat>!) {
    glesForward { $0.glPointParameterfv(pname, params) }
}

public func glPointParameterx(_ pname: GLenum, _ param: GLfixed) {
    glesForward { $0.glPointParameterx(pname, param) }
}

public func glPointParameterxv(_ pname: GLenum, _ params: UnsafePointer<GLfixed>!) {
    glesForward { $0.glPointParameterxv(pname, params) }
}

public func glPointSize(_ size: GLfloat) {
    glesForward { $0.glPointSize(size) }
}

public func glPointSizePointerOES(_ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!) {
    glesForward { $0.glPointSizePointerOES(type, stride, pointer) }
}

public func glPointSizex(_ size: GLfixed) {
    glesForward { $0.glPointSizex(size) }
}

public func glPolygonOffset(_ factor: GLfloat, _ units: GLfloat) {
    glesForward { $0.glPolygonOffset(factor, units) }
}

public func glPolygonOffsetx(_ factor: GLfixed, _ units: GLfixed) {
    glesForward { $0.glPolygonOffsetx(factor, units) }
}

public func glPopGroupMarkerEXT() {
    glesForward { $0.glPopGroupMarkerEXT() }
}

public func glPopMatrix() {
    glesForward { $0.glPopMatrix() }
}

public func glProgramBinary(_ program: GLuint, _ binaryFormat: GLenum, _ binary: UnsafeRawPointer!, _ length: GLsizei) {
    glesForward { $0.glProgramBinary(program, binaryFormat, binary, length) }
}

public func glProgramParameteri(_ program: GLuint, _ pname: GLenum, _ value: GLint) {
    glesForward { $0.glProgramParameteri(program, pname, value) }
}

public func glProgramParameteriEXT(_ program: GLuint, _ pname: GLenum, _ value: GLint) {
    glesForward { $0.glProgramParameteriEXT(program, pname, value) }
}

public func glProgramUniform1fEXT(_ program: GLuint, _ location: GLint, _ x: GLfloat) {
    glesForward { $0.glProgramUniform1fEXT(program, location, x) }
}

public func glProgramUniform1fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glProgramUniform1fvEXT(program, location, count, value) }
}

public func glProgramUniform1iEXT(_ program: GLuint, _ location: GLint, _ x: GLint) {
    glesForward { $0.glProgramUniform1iEXT(program, location, x) }
}

public func glProgramUniform1ivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLint>!) {
    glesForward { $0.glProgramUniform1ivEXT(program, location, count, value) }
}

public func glProgramUniform1uiEXT(_ program: GLuint, _ location: GLint, _ x: GLuint) {
    glesForward { $0.glProgramUniform1uiEXT(program, location, x) }
}

public func glProgramUniform1uivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!) {
    glesForward { $0.glProgramUniform1uivEXT(program, location, count, value) }
}

public func glProgramUniform2fEXT(_ program: GLuint, _ location: GLint, _ x: GLfloat, _ y: GLfloat) {
    glesForward { $0.glProgramUniform2fEXT(program, location, x, y) }
}

public func glProgramUniform2fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glProgramUniform2fvEXT(program, location, count, value) }
}

public func glProgramUniform2iEXT(_ program: GLuint, _ location: GLint, _ x: GLint, _ y: GLint) {
    glesForward { $0.glProgramUniform2iEXT(program, location, x, y) }
}

public func glProgramUniform2ivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLint>!) {
    glesForward { $0.glProgramUniform2ivEXT(program, location, count, value) }
}

public func glProgramUniform2uiEXT(_ program: GLuint, _ location: GLint, _ x: GLuint, _ y: GLuint) {
    glesForward { $0.glProgramUniform2uiEXT(program, location, x, y) }
}

public func glProgramUniform2uivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!) {
    glesForward { $0.glProgramUniform2uivEXT(program, location, count, value) }
}

public func glProgramUniform3fEXT(_ program: GLuint, _ location: GLint, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat) {
    glesForward { $0.glProgramUniform3fEXT(program, location, x, y, z) }
}

public func glProgramUniform3fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glProgramUniform3fvEXT(program, location, count, value) }
}

public func glProgramUniform3iEXT(_ program: GLuint, _ location: GLint, _ x: GLint, _ y: GLint, _ z: GLint) {
    glesForward { $0.glProgramUniform3iEXT(program, location, x, y, z) }
}

public func glProgramUniform3ivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLint>!) {
    glesForward { $0.glProgramUniform3ivEXT(program, location, count, value) }
}

public func glProgramUniform3uiEXT(_ program: GLuint, _ location: GLint, _ x: GLuint, _ y: GLuint, _ z: GLuint) {
    glesForward { $0.glProgramUniform3uiEXT(program, location, x, y, z) }
}

public func glProgramUniform3uivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!) {
    glesForward { $0.glProgramUniform3uivEXT(program, location, count, value) }
}

public func glProgramUniform4fEXT(_ program: GLuint, _ location: GLint, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat, _ w: GLfloat) {
    glesForward { $0.glProgramUniform4fEXT(program, location, x, y, z, w) }
}

public func glProgramUniform4fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glProgramUniform4fvEXT(program, location, count, value) }
}

public func glProgramUniform4iEXT(_ program: GLuint, _ location: GLint, _ x: GLint, _ y: GLint, _ z: GLint, _ w: GLint) {
    glesForward { $0.glProgramUniform4iEXT(program, location, x, y, z, w) }
}

public func glProgramUniform4ivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLint>!) {
    glesForward { $0.glProgramUniform4ivEXT(program, location, count, value) }
}

public func glProgramUniform4uiEXT(_ program: GLuint, _ location: GLint, _ x: GLuint, _ y: GLuint, _ z: GLuint, _ w: GLuint) {
    glesForward { $0.glProgramUniform4uiEXT(program, location, x, y, z, w) }
}

public func glProgramUniform4uivEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!) {
    glesForward { $0.glProgramUniform4uivEXT(program, location, count, value) }
}

public func glProgramUniformMatrix2fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glProgramUniformMatrix2fvEXT(program, location, count, transpose, value) }
}

public func glProgramUniformMatrix2x3fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glProgramUniformMatrix2x3fvEXT(program, location, count, transpose, value) }
}

public func glProgramUniformMatrix2x4fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glProgramUniformMatrix2x4fvEXT(program, location, count, transpose, value) }
}

public func glProgramUniformMatrix3fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glProgramUniformMatrix3fvEXT(program, location, count, transpose, value) }
}

public func glProgramUniformMatrix3x2fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glProgramUniformMatrix3x2fvEXT(program, location, count, transpose, value) }
}

public func glProgramUniformMatrix3x4fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glProgramUniformMatrix3x4fvEXT(program, location, count, transpose, value) }
}

public func glProgramUniformMatrix4fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glProgramUniformMatrix4fvEXT(program, location, count, transpose, value) }
}

public func glProgramUniformMatrix4x2fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glProgramUniformMatrix4x2fvEXT(program, location, count, transpose, value) }
}

public func glProgramUniformMatrix4x3fvEXT(_ program: GLuint, _ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glProgramUniformMatrix4x3fvEXT(program, location, count, transpose, value) }
}

public func glPushGroupMarkerEXT(_ length: GLsizei, _ marker: UnsafePointer<GLchar>!) {
    glesForward { $0.glPushGroupMarkerEXT(length, marker) }
}

public func glPushMatrix() {
    glesForward { $0.glPushMatrix() }
}

public func glReadBuffer(_ mode: GLenum) {
    glesForward { $0.glReadBuffer(mode) }
}

public func glReadPixels(_ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei, _ format: GLenum, _ type: GLenum, _ pixels: UnsafeMutableRawPointer!) {
    glesForward { $0.glReadPixels(x, y, width, height, format, type, pixels) }
}

public func glReleaseShaderCompiler() {
    glesForward { $0.glReleaseShaderCompiler() }
}

public func glRenderbufferStorage(_ target: GLenum, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei) {
    glesForward { $0.glRenderbufferStorage(target, internalformat, width, height) }
}

public func glRenderbufferStorageMultisample(_ target: GLenum, _ samples: GLsizei, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei) {
    glesForward { $0.glRenderbufferStorageMultisample(target, samples, internalformat, width, height) }
}

public func glRenderbufferStorageMultisampleAPPLE(_ target: GLenum, _ samples: GLsizei, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei) {
    glesForward { $0.glRenderbufferStorageMultisampleAPPLE(target, samples, internalformat, width, height) }
}

public func glRenderbufferStorageOES(_ target: GLenum, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei) {
    glesForward { $0.glRenderbufferStorageOES(target, internalformat, width, height) }
}

public func glResolveMultisampleFramebufferAPPLE() {
    glesForward { $0.glResolveMultisampleFramebufferAPPLE() }
}

public func glResumeTransformFeedback() {
    glesForward { $0.glResumeTransformFeedback() }
}

public func glRotatef(_ angle: GLfloat, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat) {
    glesForward { $0.glRotatef(angle, x, y, z) }
}

public func glRotatex(_ angle: GLfixed, _ x: GLfixed, _ y: GLfixed, _ z: GLfixed) {
    glesForward { $0.glRotatex(angle, x, y, z) }
}

public func glSampleCoverage(_ value: GLclampf, _ invert: GLboolean) {
    glesForward { $0.glSampleCoverage(value, invert) }
}

public func glSampleCoveragex(_ value: GLclampx, _ invert: GLboolean) {
    glesForward { $0.glSampleCoveragex(value, invert) }
}

public func glSamplerParameterf(_ sampler: GLuint, _ pname: GLenum, _ param: GLfloat) {
    glesForward { $0.glSamplerParameterf(sampler, pname, param) }
}

public func glSamplerParameterfv(_ sampler: GLuint, _ pname: GLenum, _ param: UnsafePointer<GLfloat>!) {
    glesForward { $0.glSamplerParameterfv(sampler, pname, param) }
}

public func glSamplerParameteri(_ sampler: GLuint, _ pname: GLenum, _ param: GLint) {
    glesForward { $0.glSamplerParameteri(sampler, pname, param) }
}

public func glSamplerParameteriv(_ sampler: GLuint, _ pname: GLenum, _ param: UnsafePointer<GLint>!) {
    glesForward { $0.glSamplerParameteriv(sampler, pname, param) }
}

public func glScalef(_ x: GLfloat, _ y: GLfloat, _ z: GLfloat) {
    glesForward { $0.glScalef(x, y, z) }
}

public func glScalex(_ x: GLfixed, _ y: GLfixed, _ z: GLfixed) {
    glesForward { $0.glScalex(x, y, z) }
}

public func glScissor(_ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei) {
    glesForward { $0.glScissor(x, y, width, height) }
}

public func glShadeModel(_ mode: GLenum) {
    glesForward { $0.glShadeModel(mode) }
}

public func glShaderBinary(_ n: GLsizei, _ shaders: UnsafePointer<GLuint>!, _ binaryformat: GLenum, _ binary: UnsafeRawPointer!, _ length: GLsizei) {
    glesForward { $0.glShaderBinary(n, shaders, binaryformat, binary, length) }
}

public func glShaderSource(_ shader: GLuint, _ count: GLsizei, _ string: UnsafePointer<UnsafePointer<GLchar>?>!, _ length: UnsafePointer<GLint>!) {
    glesForward { $0.glShaderSource(shader, count, string, length) }
}

public func glStencilFunc(_ `func`: GLenum, _ ref: GLint, _ mask: GLuint) {
    glesForward { $0.glStencilFunc(`func`, ref, mask) }
}

public func glStencilFuncSeparate(_ face: GLenum, _ `func`: GLenum, _ ref: GLint, _ mask: GLuint) {
    glesForward { $0.glStencilFuncSeparate(face, `func`, ref, mask) }
}

public func glStencilMask(_ mask: GLuint) {
    glesForward { $0.glStencilMask(mask) }
}

public func glStencilMaskSeparate(_ face: GLenum, _ mask: GLuint) {
    glesForward { $0.glStencilMaskSeparate(face, mask) }
}

public func glStencilOp(_ fail: GLenum, _ zfail: GLenum, _ zpass: GLenum) {
    glesForward { $0.glStencilOp(fail, zfail, zpass) }
}

public func glStencilOpSeparate(_ face: GLenum, _ fail: GLenum, _ zfail: GLenum, _ zpass: GLenum) {
    glesForward { $0.glStencilOpSeparate(face, fail, zfail, zpass) }
}

public func glTexCoordPointer(_ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!) {
    glesForward { $0.glTexCoordPointer(size, type, stride, pointer) }
}

public func glTexEnvf(_ target: GLenum, _ pname: GLenum, _ param: GLfloat) {
    glesForward { $0.glTexEnvf(target, pname, param) }
}

public func glTexEnvfv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfloat>!) {
    glesForward { $0.glTexEnvfv(target, pname, params) }
}

public func glTexEnvi(_ target: GLenum, _ pname: GLenum, _ param: GLint) {
    glesForward { $0.glTexEnvi(target, pname, param) }
}

public func glTexEnviv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLint>!) {
    glesForward { $0.glTexEnviv(target, pname, params) }
}

public func glTexEnvx(_ target: GLenum, _ pname: GLenum, _ param: GLfixed) {
    glesForward { $0.glTexEnvx(target, pname, param) }
}

public func glTexEnvxv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfixed>!) {
    glesForward { $0.glTexEnvxv(target, pname, params) }
}

public func glTexImage2D(_ target: GLenum, _ level: GLint, _ internalformat: GLint, _ width: GLsizei, _ height: GLsizei, _ border: GLint, _ format: GLenum, _ type: GLenum, _ pixels: UnsafeRawPointer!) {
    glesForward { $0.glTexImage2D(target, level, internalformat, width, height, border, format, type, pixels) }
}

public func glTexImage3D(_ target: GLenum, _ level: GLint, _ internalformat: GLint, _ width: GLsizei, _ height: GLsizei, _ depth: GLsizei, _ border: GLint, _ format: GLenum, _ type: GLenum, _ pixels: UnsafeRawPointer!) {
    glesForward { $0.glTexImage3D(target, level, internalformat, width, height, depth, border, format, type, pixels) }
}

public func glTexParameterf(_ target: GLenum, _ pname: GLenum, _ param: GLfloat) {
    glesForward { $0.glTexParameterf(target, pname, param) }
}

public func glTexParameterfv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfloat>!) {
    glesForward { $0.glTexParameterfv(target, pname, params) }
}

public func glTexParameteri(_ target: GLenum, _ pname: GLenum, _ param: GLint) {
    glesForward { $0.glTexParameteri(target, pname, param) }
}

public func glTexParameteriv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLint>!) {
    glesForward { $0.glTexParameteriv(target, pname, params) }
}

public func glTexParameterx(_ target: GLenum, _ pname: GLenum, _ param: GLfixed) {
    glesForward { $0.glTexParameterx(target, pname, param) }
}

public func glTexParameterxv(_ target: GLenum, _ pname: GLenum, _ params: UnsafePointer<GLfixed>!) {
    glesForward { $0.glTexParameterxv(target, pname, params) }
}

public func glTexStorage2D(_ target: GLenum, _ levels: GLsizei, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei) {
    glesForward { $0.glTexStorage2D(target, levels, internalformat, width, height) }
}

public func glTexStorage2DEXT(_ target: GLenum, _ levels: GLsizei, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei) {
    glesForward { $0.glTexStorage2DEXT(target, levels, internalformat, width, height) }
}

public func glTexStorage3D(_ target: GLenum, _ levels: GLsizei, _ internalformat: GLenum, _ width: GLsizei, _ height: GLsizei, _ depth: GLsizei) {
    glesForward { $0.glTexStorage3D(target, levels, internalformat, width, height, depth) }
}

public func glTexSubImage2D(_ target: GLenum, _ level: GLint, _ xoffset: GLint, _ yoffset: GLint, _ width: GLsizei, _ height: GLsizei, _ format: GLenum, _ type: GLenum, _ pixels: UnsafeRawPointer!) {
    glesForward { $0.glTexSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels) }
}

public func glTexSubImage3D(_ target: GLenum, _ level: GLint, _ xoffset: GLint, _ yoffset: GLint, _ zoffset: GLint, _ width: GLsizei, _ height: GLsizei, _ depth: GLsizei, _ format: GLenum, _ type: GLenum, _ pixels: UnsafeRawPointer!) {
    glesForward { $0.glTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, type, pixels) }
}

public func glTransformFeedbackVaryings(_ program: GLuint, _ count: GLsizei, _ varyings: UnsafePointer<UnsafePointer<GLchar>?>!, _ bufferMode: GLenum) {
    glesForward { $0.glTransformFeedbackVaryings(program, count, varyings, bufferMode) }
}

public func glTranslatef(_ x: GLfloat, _ y: GLfloat, _ z: GLfloat) {
    glesForward { $0.glTranslatef(x, y, z) }
}

public func glTranslatex(_ x: GLfixed, _ y: GLfixed, _ z: GLfixed) {
    glesForward { $0.glTranslatex(x, y, z) }
}

public func glUniform1f(_ location: GLint, _ x: GLfloat) {
    glesForward { $0.glUniform1f(location, x) }
}

public func glUniform1fv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLfloat>!) {
    glesForward { $0.glUniform1fv(location, count, v) }
}

public func glUniform1i(_ location: GLint, _ x: GLint) {
    glesForward { $0.glUniform1i(location, x) }
}

public func glUniform1iv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLint>!) {
    glesForward { $0.glUniform1iv(location, count, v) }
}

public func glUniform1ui(_ location: GLint, _ v0: GLuint) {
    glesForward { $0.glUniform1ui(location, v0) }
}

public func glUniform1uiv(_ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!) {
    glesForward { $0.glUniform1uiv(location, count, value) }
}

public func glUniform2f(_ location: GLint, _ x: GLfloat, _ y: GLfloat) {
    glesForward { $0.glUniform2f(location, x, y) }
}

public func glUniform2fv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLfloat>!) {
    glesForward { $0.glUniform2fv(location, count, v) }
}

public func glUniform2i(_ location: GLint, _ x: GLint, _ y: GLint) {
    glesForward { $0.glUniform2i(location, x, y) }
}

public func glUniform2iv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLint>!) {
    glesForward { $0.glUniform2iv(location, count, v) }
}

public func glUniform2ui(_ location: GLint, _ v0: GLuint, _ v1: GLuint) {
    glesForward { $0.glUniform2ui(location, v0, v1) }
}

public func glUniform2uiv(_ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!) {
    glesForward { $0.glUniform2uiv(location, count, value) }
}

public func glUniform3f(_ location: GLint, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat) {
    glesForward { $0.glUniform3f(location, x, y, z) }
}

public func glUniform3fv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLfloat>!) {
    glesForward { $0.glUniform3fv(location, count, v) }
}

public func glUniform3i(_ location: GLint, _ x: GLint, _ y: GLint, _ z: GLint) {
    glesForward { $0.glUniform3i(location, x, y, z) }
}

public func glUniform3iv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLint>!) {
    glesForward { $0.glUniform3iv(location, count, v) }
}

public func glUniform3ui(_ location: GLint, _ v0: GLuint, _ v1: GLuint, _ v2: GLuint) {
    glesForward { $0.glUniform3ui(location, v0, v1, v2) }
}

public func glUniform3uiv(_ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!) {
    glesForward { $0.glUniform3uiv(location, count, value) }
}

public func glUniform4f(_ location: GLint, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat, _ w: GLfloat) {
    glesForward { $0.glUniform4f(location, x, y, z, w) }
}

public func glUniform4fv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLfloat>!) {
    glesForward { $0.glUniform4fv(location, count, v) }
}

public func glUniform4i(_ location: GLint, _ x: GLint, _ y: GLint, _ z: GLint, _ w: GLint) {
    glesForward { $0.glUniform4i(location, x, y, z, w) }
}

public func glUniform4iv(_ location: GLint, _ count: GLsizei, _ v: UnsafePointer<GLint>!) {
    glesForward { $0.glUniform4iv(location, count, v) }
}

public func glUniform4ui(_ location: GLint, _ v0: GLuint, _ v1: GLuint, _ v2: GLuint, _ v3: GLuint) {
    glesForward { $0.glUniform4ui(location, v0, v1, v2, v3) }
}

public func glUniform4uiv(_ location: GLint, _ count: GLsizei, _ value: UnsafePointer<GLuint>!) {
    glesForward { $0.glUniform4uiv(location, count, value) }
}

public func glUniformBlockBinding(_ program: GLuint, _ uniformBlockIndex: GLuint, _ uniformBlockBinding: GLuint) {
    glesForward { $0.glUniformBlockBinding(program, uniformBlockIndex, uniformBlockBinding) }
}

public func glUniformMatrix2fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glUniformMatrix2fv(location, count, transpose, value) }
}

public func glUniformMatrix2x3fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glUniformMatrix2x3fv(location, count, transpose, value) }
}

public func glUniformMatrix2x4fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glUniformMatrix2x4fv(location, count, transpose, value) }
}

public func glUniformMatrix3fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glUniformMatrix3fv(location, count, transpose, value) }
}

public func glUniformMatrix3x2fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glUniformMatrix3x2fv(location, count, transpose, value) }
}

public func glUniformMatrix3x4fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glUniformMatrix3x4fv(location, count, transpose, value) }
}

public func glUniformMatrix4fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glUniformMatrix4fv(location, count, transpose, value) }
}

public func glUniformMatrix4x2fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glUniformMatrix4x2fv(location, count, transpose, value) }
}

public func glUniformMatrix4x3fv(_ location: GLint, _ count: GLsizei, _ transpose: GLboolean, _ value: UnsafePointer<GLfloat>!) {
    glesForward { $0.glUniformMatrix4x3fv(location, count, transpose, value) }
}

public func glUnmapBuffer(_ target: GLenum) -> GLboolean {
    return glesForwardRet(0) { $0.glUnmapBuffer(target) }
}

public func glUnmapBufferOES(_ target: GLenum) -> GLboolean {
    return glesForwardRet(0) { $0.glUnmapBufferOES(target) }
}

public func glUseProgram(_ program: GLuint) {
    glesForward { $0.glUseProgram(program) }
}

public func glUseProgramStagesEXT(_ pipeline: GLuint, _ stages: GLbitfield, _ program: GLuint) {
    glesForward { $0.glUseProgramStagesEXT(pipeline, stages, program) }
}

public func glValidateProgram(_ program: GLuint) {
    glesForward { $0.glValidateProgram(program) }
}

public func glValidateProgramPipelineEXT(_ pipeline: GLuint) {
    glesForward { $0.glValidateProgramPipelineEXT(pipeline) }
}

public func glVertexAttrib1f(_ indx: GLuint, _ x: GLfloat) {
    glesForward { $0.glVertexAttrib1f(indx, x) }
}

public func glVertexAttrib1fv(_ indx: GLuint, _ values: UnsafePointer<GLfloat>!) {
    glesForward { $0.glVertexAttrib1fv(indx, values) }
}

public func glVertexAttrib2f(_ indx: GLuint, _ x: GLfloat, _ y: GLfloat) {
    glesForward { $0.glVertexAttrib2f(indx, x, y) }
}

public func glVertexAttrib2fv(_ indx: GLuint, _ values: UnsafePointer<GLfloat>!) {
    glesForward { $0.glVertexAttrib2fv(indx, values) }
}

public func glVertexAttrib3f(_ indx: GLuint, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat) {
    glesForward { $0.glVertexAttrib3f(indx, x, y, z) }
}

public func glVertexAttrib3fv(_ indx: GLuint, _ values: UnsafePointer<GLfloat>!) {
    glesForward { $0.glVertexAttrib3fv(indx, values) }
}

public func glVertexAttrib4f(_ indx: GLuint, _ x: GLfloat, _ y: GLfloat, _ z: GLfloat, _ w: GLfloat) {
    glesForward { $0.glVertexAttrib4f(indx, x, y, z, w) }
}

public func glVertexAttrib4fv(_ indx: GLuint, _ values: UnsafePointer<GLfloat>!) {
    glesForward { $0.glVertexAttrib4fv(indx, values) }
}

public func glVertexAttribDivisor(_ index: GLuint, _ divisor: GLuint) {
    glesForward { $0.glVertexAttribDivisor(index, divisor) }
}

public func glVertexAttribDivisorEXT(_ index: GLuint, _ divisor: GLuint) {
    glesForward { $0.glVertexAttribDivisorEXT(index, divisor) }
}

public func glVertexAttribI4i(_ index: GLuint, _ x: GLint, _ y: GLint, _ z: GLint, _ w: GLint) {
    glesForward { $0.glVertexAttribI4i(index, x, y, z, w) }
}

public func glVertexAttribI4iv(_ index: GLuint, _ v: UnsafePointer<GLint>!) {
    glesForward { $0.glVertexAttribI4iv(index, v) }
}

public func glVertexAttribI4ui(_ index: GLuint, _ x: GLuint, _ y: GLuint, _ z: GLuint, _ w: GLuint) {
    glesForward { $0.glVertexAttribI4ui(index, x, y, z, w) }
}

public func glVertexAttribI4uiv(_ index: GLuint, _ v: UnsafePointer<GLuint>!) {
    glesForward { $0.glVertexAttribI4uiv(index, v) }
}

public func glVertexAttribIPointer(_ index: GLuint, _ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!) {
    glesForward { $0.glVertexAttribIPointer(index, size, type, stride, pointer) }
}

public func glVertexAttribPointer(_ indx: GLuint, _ size: GLint, _ type: GLenum, _ normalized: GLboolean, _ stride: GLsizei, _ ptr: UnsafeRawPointer!) {
    glesForward { $0.glVertexAttribPointer(indx, size, type, normalized, stride, ptr) }
}

public func glVertexPointer(_ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!) {
    glesForward { $0.glVertexPointer(size, type, stride, pointer) }
}

public func glViewport(_ x: GLint, _ y: GLint, _ width: GLsizei, _ height: GLsizei) {
    glesForward { $0.glViewport(x, y, width, height) }
}

public func glWaitSync(_ sync: GLsync!, _ flags: GLbitfield, _ timeout: GLuint64) {
    glesForward { $0.glWaitSync(sync, flags, timeout) }
}

public func glWaitSyncAPPLE(_ sync: GLsync!, _ flags: GLbitfield, _ timeout: GLuint64) {
    glesForward { $0.glWaitSyncAPPLE(sync, flags, timeout) }
}

public func glWeightPointerOES(_ size: GLint, _ type: GLenum, _ stride: GLsizei, _ pointer: UnsafeRawPointer!) {
    glesForward { $0.glWeightPointerOES(size, type, stride, pointer) }
}

