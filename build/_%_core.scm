(define-cond-expand-feature compile-to-c)
(define-cond-expand-feature debug)
(define-cond-expand-feature android)
(define-cond-expand-feature mobile)
(cond-expand
 (optimize
  (declare (standard-bindings) (extended-bindings) (not safe) (block)))
 (debug (declare
          (safe)
          (debug)
          (debug-location)
          (debug-source)
          (debug-environments)))
 (else (void)))
(define (fusion:error . msgs)
  (SDL_LogError
   SDL_LOG_CATEGORY_APPLICATION
   (apply string-append
          (map (lambda (m)
                 (string-append (if (string? m) m (object->string m)) " "))
               msgs)))
  (SDL_Quit))
(define (fusion:error-log . msgs)
  (SDL_LogError
   SDL_LOG_CATEGORY_APPLICATION
   (apply string-append
          (map (lambda (m)
                 (string-append (if (string? m) m (object->string m)) " "))
               msgs))))
(define (fusion:create-shader shader-type shader-code)
  (let ((shader-id (glCreateShader shader-type))
        (shader-status* (alloc-GLint* 1)))
    (glShaderSource shader-id 1 (list shader-code) #f)
    (glCompileShader shader-id)
    (glGetShaderiv shader-id GL_COMPILE_STATUS shader-status*)
    (if (= GL_FALSE (*->GLint shader-status*))
        (let ((info-log-length* (alloc-GLint* 1)))
          (glGetShaderiv shader-id GL_INFO_LOG_LENGTH info-log-length*)
          (let* ((info-log-length (*->GLint info-log-length*))
                 (info-log* (alloc-GLchar* info-log-length)))
            (glGetShaderInfoLog shader-id info-log-length #f info-log*)
            (fusion:error
             (string-append
              "GL Shading Language compilation -- "
              (*->string info-log*))))))
    shader-id))
(define* (fusion:create-program shaders (bind-callback #f))
         (let ((program-id (glCreateProgram))
               (program-status* (alloc-GLint* 1)))
           (if bind-callback (bind-callback program-id))
           (for-each (lambda (s) (glAttachShader program-id s)) shaders)
           (glLinkProgram program-id)
           (glGetProgramiv program-id GL_LINK_STATUS program-status*)
           (if (= GL_FALSE (*->GLint program-status*))
               (let ((info-log-length* (alloc-GLint* 1)))
                 (glGetProgramiv
                  program-id
                  GL_INFO_LOG_LENGTH
                  info-log-length*)
                 (let* ((info-log-length (*->GLint info-log-length*))
                        (info-log* (alloc-GLchar* info-log-length)))
                   (glGetProgramInfoLog
                    program-id
                    info-log-length
                    #f
                    info-log*)
                   (fusion:error
                    (string-append
                     "GL Shading Language linkage -- "
                     (*->string info-log*))))))
           (for-each (lambda (s) (glDetachShader program-id s)) shaders)
           program-id))
(define (fusion:load-text-file path)
  (and-let*
   ((rw (SDL_RWFromFile path "rt"))
    (file-size (SDL_RWsize rw))
    (buffer (alloc-char* (+ 1 file-size)))
    (bytes-read (SDL_RWread rw (*->void* buffer) 1 file-size)))
   (SDL_RWclose rw)
   (char*-set! buffer file-size #\nul)
   (*->string buffer)))