;; SchemeSpheres environment

(define eval-file
  (lambda (file)
    (for-each eval (with-input-from-file file read-all))))
(parameterize
 ((current-directory
   (cond-expand (android "sdcard") (else "spheres"))))
 (load "core/lib/syntax-case.o1")
 (eval-file "core/src/base-macros.scm")
 (eval-file "core/src/assert-macros.scm")
 (SDL_Log "Successfully loaded environment"))


;; Initialize globals
(define (init-globals)
  (if (zero? (shell-command "wget localhost:8000/globals.scm -O assets/src/globals.scm"))
      (load "assets/src/globals.scm")
      (println "globals.scm could not be retrieved"))
  (if (zero? (shell-command "wget localhost:8000/engine-types.scm -O assets/src/engine-types.scm"))
      (load "assets/src/engine-types.scm")
      (println "engine-types.scm could not be retrieved")))

;; Automatically load files
(init-globals)

;; Update the app Scheme source code
(define (go)
  (define (update-source source)
    (if (zero? (shell-command (string-append "wget localhost:8000/" source " -O assets/src/" source)))
        (load (string-append "spheres/src/" source))
        (let ((message (string-append source " could not be retrieved")))
          (SDL_Log message)
          (println message))))
  (eval '(add-cond-expand-feature! ios))
  ;; gl-utils.scm
  (update-source "gl-utils.scm")
  ;; engine.scm
  (update-source "engine.scm")
  ;; app.scm
  (update-source "app.scm")
  'success)

;; Install and run the remote REPL: IP address of the computer running the debug server
;; (if (remote-repl-setup! "localhost" port: 20000)
;;     (begin
;;       (remote-repl-run!)
;;       (SDL_Log "***** Successfully connected to Gambit Debug Server *****"))
;;     (SDL_Log "***** Unable to connect to Gambit Debug Server. Are you running 'sense'? *****"))

(go)

;; Put the main thread to sleep
(thread-sleep! +inf.0)
