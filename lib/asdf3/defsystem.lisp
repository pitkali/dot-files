;;;; -------------------------------------------------------------------------
;;;; Defsystem

(asdf/package:define-package :asdf/defsystem
  (:recycle :asdf/defsystem :asdf)
  (:use :asdf/common-lisp :asdf/driver :asdf/upgrade
   :asdf/component :asdf/system :asdf/cache
   :asdf/find-system :asdf/find-component :asdf/lisp-action :asdf/operate
   :asdf/backward-internals)
  (:export
   #:defsystem #:register-system-definition
   #:class-for-type #:*default-component-class*
   #:determine-system-directory #:parse-component-form
   #:duplicate-names #:non-toplevel-system #:non-system-system
   #:sysdef-error-component #:check-component-input))
(in-package :asdf/defsystem)

;;; Pathname
(with-upgradability ()
  (defun determine-system-directory (pathname)
    ;; The defsystem macro calls this function to determine
    ;; the pathname of a system as follows:
    ;; 1. if the pathname argument is an pathname object (NOT a namestring),
    ;;    that is already an absolute pathname, return it.
    ;; 2. otherwise, the directory containing the LOAD-PATHNAME
    ;;    is considered (as deduced from e.g. *LOAD-PATHNAME*), and
    ;;    if it is indeed available and an absolute pathname, then
    ;;    the PATHNAME argument is normalized to a relative pathname
    ;;    as per PARSE-UNIX-NAMESTRING (with ENSURE-DIRECTORY T)
    ;;    and merged into that DIRECTORY as per SUBPATHNAME.
    ;;    Note: avoid *COMPILE-FILE-PATHNAME* because .asd is loaded,
    ;;    and may be from within the EVAL-WHEN of a file compilation.
    ;; If no absolute pathname was found, we return NIL.
    (check-type pathname (or null string pathname))
    (pathname-directory-pathname
     (resolve-symlinks*
      (ensure-absolute-pathname
       (parse-unix-namestring pathname :type :directory)
       #'(lambda () (ensure-absolute-pathname
                     (load-pathname) 'get-pathname-defaults nil))
       nil)))))


;;; Component class
(with-upgradability ()
  (defvar *default-component-class* 'cl-source-file)

  (defun class-for-type (parent type)
    (or (loop :for symbol :in (list
                               type
                               (find-symbol* type *package* nil)
                               (find-symbol* type :asdf/interface nil)
                               (and (stringp type) (safe-read-from-string type :package :asdf/interface)))
              :for class = (and symbol (symbolp symbol) (find-class* symbol nil))
              :when (and class
                         (#-cormanlisp subtypep #+cormanlisp cl::subclassp
                          class (find-class* 'component)))
                :return class)
        (and (eq type :file)
             (find-class*
              (or (loop :for p = parent :then (component-parent p) :while p
                        :thereis (module-default-component-class p))
                  *default-component-class*) nil))
        (sysdef-error "don't recognize component type ~A" type))))


;;; Check inputs
(with-upgradability ()
  (define-condition duplicate-names (system-definition-error)
    ((name :initarg :name :reader duplicate-names-name))
    (:report (lambda (c s)
               (format s (compatfmt "~@<Error while defining system: multiple components are given same name ~S~@:>")
                       (duplicate-names-name c)))))

  (define-condition non-system-system (system-definition-error)
    ((name :initarg :name :reader non-system-system-name)
     (class-name :initarg :class-name :reader non-system-system-class-name))
    (:report (lambda (c s)
               (format s (compatfmt "~@<Error while defining system ~S: class ~S isn't a subclass of ~S~@:>")
                       (non-system-system-name c) (non-system-system-class-name c) 'system))))

  (define-condition non-toplevel-system (system-definition-error)
    ((parent :initarg :parent :reader non-toplevel-system-parent)
     (name :initarg :name :reader non-toplevel-system-name))
    (:report (lambda (c s)
               (format s (compatfmt "~@<Error while defining system: component ~S claims to have a system ~S as a child~@:>")
                       (non-toplevel-system-parent c) (non-toplevel-system-name c)))))

  (defun sysdef-error-component (msg type name value)
    (sysdef-error (strcat msg (compatfmt "~&~@<The value specified for ~(~A~) ~A is ~S~@:>"))
                  type name value))

  (defun check-component-input (type name weakly-depends-on
                                depends-on components)
    "A partial test of the values of a component."
    (unless (listp depends-on)
      (sysdef-error-component ":depends-on must be a list."
                              type name depends-on))
    (unless (listp weakly-depends-on)
      (sysdef-error-component ":weakly-depends-on must be a list."
                              type name weakly-depends-on))
    (unless (listp components)
      (sysdef-error-component ":components must be NIL or a list of components."
                              type name components)))

  (defun* (normalize-version) (form &key pathname component parent)
    (labels ((invalid (&optional (continuation "using NIL instead"))
               (warn (compatfmt "~@<Invalid :version specifier ~S~@[ for component ~S~]~@[ in ~S~]~@[ from file ~S~]~@[, ~A~]~@:>")
                     form component parent pathname continuation))
             (invalid-parse (control &rest args)
               (unless (builtin-system-p (find-component parent component))
                 (apply 'warn control args)
                 (invalid))))
      (if-let (v (typecase form
                   ((or string null) form)
                   (real
                    (invalid "Substituting a string")
                    (format nil "~D" form)) ;; 1.0 becomes "1.0"
                   (cons
                    (case (first form)
                      ((:read-file-form)
                       (destructuring-bind (subpath &key (at 0)) (rest form)
                         (safe-read-file-form (subpathname pathname subpath) :at at :package :asdf-user)))
                      ((:read-file-line)
                       (destructuring-bind (subpath &key (at 0)) (rest form)
                         (read-file-lines (subpathname pathname subpath) :at at)))
                      (otherwise
                       (invalid))))
                   (t
                    (invalid))))
        (if-let (pv (parse-version v #'invalid-parse))
          (unparse-version pv)
          (invalid))))))


;;; Main parsing function
(with-upgradability ()
  (defun* (parse-component-form) (parent options &key previous-serial-component)
    (destructuring-bind
        (type name &rest rest &key
                                (builtin-system-p () bspp)
                                ;; the following list of keywords is reproduced below in the
                                ;; remove-plist-keys form.  important to keep them in sync
                                components pathname perform explain output-files operation-done-p
                                weakly-depends-on depends-on serial
                                do-first if-component-dep-fails version
                                ;; list ends
         &allow-other-keys) options
      (declare (ignorable perform explain output-files operation-done-p builtin-system-p))
      (check-component-input type name weakly-depends-on depends-on components)
      (when (and parent
                 (find-component parent name)
                 (not ;; ignore the same object when rereading the defsystem
                  (typep (find-component parent name)
                         (class-for-type parent type))))
        (error 'duplicate-names :name name))
      (when do-first (error "DO-FIRST is not supported anymore as of ASDF 3"))
      (let* ((name (coerce-name name))
             (args `(:name ,name
                     :pathname ,pathname
                     ,@(when parent `(:parent ,parent))
                     ,@(remove-plist-keys
                        '(:components :pathname :if-component-dep-fails :version
                          :perform :explain :output-files :operation-done-p
                          :weakly-depends-on :depends-on :serial)
                        rest)))
             (component (find-component parent name))
             (class (class-for-type parent type)))
        (when (and parent (subtypep class 'system))
          (error 'non-toplevel-system :parent parent :name name))
        (if component ; preserve identity
            (apply 'reinitialize-instance component args)
            (setf component (apply 'make-instance class args)))
        (component-pathname component) ; eagerly compute the absolute pathname
        (let ((sysfile (system-source-file (component-system component)))) ;; requires the previous
          (when (and (typep component 'system) (not bspp))
            (setf (builtin-system-p component) (lisp-implementation-pathname-p sysfile)))
          (setf version (normalize-version version :component name :parent parent :pathname sysfile)))
        ;; Don't use the accessor: kluge to avoid upgrade issue on CCL 1.8.
        ;; A better fix is required.
        (setf (slot-value component 'version) version)
        (when (typep component 'parent-component)
          (setf (component-children component)
                (loop
                  :with previous-component = nil
                  :for c-form :in components
                  :for c = (parse-component-form component c-form
                                                 :previous-serial-component previous-component)
                  :for name = (component-name c)
                  :collect c
                  :when serial :do (setf previous-component name)))
          (compute-children-by-name component))
        (when previous-serial-component
          (push previous-serial-component depends-on))
        (when weakly-depends-on
          ;; ASDF4: deprecate this feature and remove it.
          (appendf depends-on
                   (remove-if (complement #'(lambda (x) (find-system x nil))) weakly-depends-on)))
        ;; Used by POIU. ASDF4: rename to component-depends-on?
        (setf (component-sideway-dependencies component) depends-on)
        (%refresh-component-inline-methods component rest)
        (when if-component-dep-fails
          (%resolve-if-component-dep-fails if-component-dep-fails component))
        component)))

  (defun register-system-definition
      (name &rest options &key pathname (class 'system) (source-file () sfp)
                            defsystem-depends-on &allow-other-keys)
    ;; The system must be registered before we parse the body,
    ;; otherwise we recur when trying to find an existing system
    ;; of the same name to reuse options (e.g. pathname) from.
    ;; To avoid infinite recursion in cases where you defsystem a system
    ;; that is registered to a different location to find-system,
    ;; we also need to remember it in a special variable *systems-being-defined*.
    (with-system-definitions ()
      (let* ((name (coerce-name name))
             (source-file (if sfp source-file (resolve-symlinks* (load-pathname))))
             (registered (system-registered-p name))
             (registered! (if registered
                              (rplaca registered (get-file-stamp source-file))
                              (register-system
                               (make-instance 'system :name name :source-file source-file))))
             (system (reset-system (cdr registered!)
                                   :name name :source-file source-file))
             (component-options (remove-plist-key :class options))
             (defsystem-dependencies (loop :for spec :in defsystem-depends-on :collect
                                           (resolve-dependency-spec nil spec))))
        (setf (gethash name *systems-being-defined*) system)
        (apply 'load-systems defsystem-dependencies)
        ;; We change-class AFTER we loaded the defsystem-depends-on
        ;; since the class might be defined as part of those.
        (let ((class (class-for-type nil class)))
          (unless (subtypep class 'system)
            (error 'non-system-system :name name :class-name (class-name class)))
          (unless (eq (type-of system) class)
            (change-class system class)))
        (parse-component-form
         nil (list*
              :module name
              :pathname (determine-system-directory pathname)
              component-options)))))

  (defmacro defsystem (name &body options)
    `(apply 'register-system-definition ',name ',options)))
