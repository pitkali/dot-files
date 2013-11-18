(load "/Users/pitkali/.my-config/lib/asdf3/build/asdf.lisp")
(setf asdf:*warnings-file-type* nil)

;;; The following lines added by ql:add-to-init-file:
#-quicklisp
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))
