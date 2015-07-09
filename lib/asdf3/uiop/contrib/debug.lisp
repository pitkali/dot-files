;;;;; A few essential debugging utilities by Faré,
;;;;; to be loaded in the *PACKAGE* that you wish to debug.
;;
;; We want debugging utilities in the _current_ package,
;; so we don't have to either change the package structure
;; or use heavy package prefixes everywhere.
;;
;; The short names of symbols below are unlikely to clash
;; with global bindings of any well-designed source file being debugged,
;; yet are quite practical in a debugging session.
#|
;;; If ASDF is already loaded,
;;; you can load these utilities in the current package as follows:
(d:asdf-debug)
;; which if you left the :D nickname to asdf/driver is short for:
(asdf/utility::asdf-debug)

;; The above macro can be configured to load any other debugging utility
;; that you may prefer to this one, with your customizations,
;; by setting the variable
;;    asdf-utility:*asdf-debug-utility*
;; to a form that evaluates to a designator of the pathname to your file.
;; For instance, on a home directory shared via NFS with different names
;; on different machines, with your debug file in ~/lisp/debug-utils.lisp
;; you could in your ~/.sbclrc have the following configuration setting:
(require :asdf)
(setf asdf/utility:*asdf-debug-utility*
      '(asdf/pathname:subpathname (asdf/os:user-homedir) "lisp/debug-utils.lisp"))

;;; If ASDF is not loaded (for instance, when debugging ASDF itself),
;;; Try the below, fixing the pathname to point to this file:
(eval-when (:compile-toplevel :load-toplevel :execute)
  (let ((kw (read-from-string (format nil ":DBG-~A" (package-name *package*)))))
    (unless (member kw *features*)
      (load "/home/tunes/cl/asdf/contrib/debug.lisp"))))

|#

;;; Here we define the magic package-dependent feature.
;;; With it, you should be able to use #+DBG-/PACKAGE-NAME/
;;; to annotate your debug statements, e.g. upper-case #+DBG-ASDF
;;; This will be all upper-case even in lower-case lisps.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (let ((kw (read-from-string
             (format nil ":DBG-~:@(~A~)" (package-name *package*)))))
    (pushnew kw *features*)))

;;; Now for the debugging stuff itself.
;;; First, my all-purpose print-debugging macro
(defmacro DBG (tag &rest exprs)
  "simple debug statement macro:
TAG is typically a constant string or keyword,
but in general is an expression returning a tag to be printed first;
if the expression returns NIL, nothing is printed.
EXPRS are expressions, which when the TAG was not NIL are evaluated in order,
with their source code then their return values being printed each time.
The last expresion is *always* evaluated and its values are returned,
but its source and return values are only printed if TAG was not NIL;
previous expressions are not evaluated at all if TAG returned NIL.
The macro expansion has relatively low overhead in space of time."
  (let* ((last-expr (car (last exprs)))
         (other-exprs (butlast exprs))
         (tag-var (gensym "TAG"))
         (thunk-var (gensym "THUNK")))
    `(let ((,tag-var ,tag))
       (flet ,(when exprs `((,thunk-var () ,last-expr)))
         (if ,tag-var
             (DBG-helper ,tag-var
                         (list ,@(loop :for x :in other-exprs :collect
                                       `(cons ',x #'(lambda () ,x))))
                         ',last-expr ,(if exprs `#',thunk-var nil))
             ,(if exprs `(,thunk-var) '(values)))))))

(defun DBG-helper (tag expressions-thunks last-expression last-thunk)
  ;; Helper for the above debugging macro
  (labels
      ((f (stream fmt &rest args)
         (with-standard-io-syntax
           (let ((*print-readably* nil)
                 (*package* (find-package :cl)))
             (apply 'format stream fmt args)
             (finish-output stream))))
       (z (stream)
         (f stream "~&"))
       (e (fmt arg)
         (f *error-output* fmt arg))
       (x (expression thunk)
         (e "~&  ~S => " expression)
         (let ((results (multiple-value-list (funcall thunk))))
           (e "~{~S~^ ~}~%" results)
           (apply 'values results))))
    (map () #'z (list *standard-output* *error-output* *trace-output*))
    (e "~A~%" tag)
    (loop :for (expression . thunk) :in expressions-thunks
          :do (x expression thunk))
    (if last-thunk
        (x last-expression last-thunk)
        (values))))


;;; Quick definitions for use at the REPL
(defun w (&rest x) (format t "~&~{~S~^ ~}~%" x)) ;Write, space separated + LF
(defun a (&rest x) (format t "~&~{~A~}~%" x)) ;print Anything, no separator, LF
(defun e (x) (cons x (ignore-errors (list (eval x))))) ;eValuate
(defmacro x (x) `(format t "~&~S => ~S~%" ',x ,x)) ;eXamine
(defmacro !a (&rest foo) ; define! Alias
  `(progn ,@(loop :for (alias name) :on foo :by #'cddr
                  :collect (if (macro-function name)
                               `(defmacro ,alias (&rest x) `(,',name ,@x))
                               `(defun ,alias (&rest x) (apply ',name x))))))

;;; common aliases
(!a
 d describe
 ap apropos
 !p defparameter
 m1 macroexpand-1)

;;; SLIME integration
(when (find-package :swank)
  (eval (read-from-string "(!a i swank:inspect-in-emacs)")))
