;;;; -------------------------------------------------------------------------
;;; Internal hacks for backward-compatibility

(asdf/package:define-package :asdf/backward-internals
  (:recycle :asdf/backward-internals :asdf)
  (:use :asdf/common-lisp :asdf/driver :asdf/upgrade
   :asdf/system :asdf/component :asdf/operation
   :asdf/find-system :asdf/action :asdf/lisp-action)
  (:export ;; for internal use
   #:load-sysdef #:make-temporary-package
   #:%refresh-component-inline-methods
   #:%resolve-if-component-dep-fails
   #:make-sub-operation
   #:load-sysdef #:make-temporary-package))
(in-package :asdf/backward-internals)

;;;; Backward compatibility with "inline methods"
(with-upgradability ()
  (defparameter +asdf-methods+
    '(perform-with-restarts perform explain output-files operation-done-p))

  (defun %remove-component-inline-methods (component)
    (dolist (name +asdf-methods+)
      (map ()
           ;; this is inefficient as most of the stored
           ;; methods will not be for this particular gf
           ;; But this is hardly performance-critical
           #'(lambda (m)
               (remove-method (symbol-function name) m))
           (component-inline-methods component)))
    (component-inline-methods component) nil)

  (defun %define-component-inline-methods (ret rest)
    (loop* :for (key value) :on rest :by #'cddr
           :for name = (and (keywordp key) (find key +asdf-methods+ :test 'string=))
           :when name :do
           (destructuring-bind (op &rest body) value
             (loop :for arg = (pop body)
                   :while (atom arg)
                   :collect arg :into qualifiers
                   :finally
                      (destructuring-bind (o c) arg
                        (pushnew
                         (eval `(defmethod ,name ,@qualifiers ((,o ,op) (,c (eql ,ret))) ,@body))
                         (component-inline-methods ret)))))))

  (defun %refresh-component-inline-methods (component rest)
    ;; clear methods, then add the new ones
    (%remove-component-inline-methods component)
    (%define-component-inline-methods component rest)))

;;;; PARTIAL SUPPORT for the :if-component-dep-fails component attribute
;; and the companion asdf:feature pseudo-dependency.
;; This won't recurse into dependencies to accumulate feature conditions.
;; Therefore it will accept the SB-ROTATE-BYTE of an old SBCL
;; (older than 1.1.2.20-fe6da9f) but won't suffice to load an old nibbles.
(with-upgradability ()
  (defun %resolve-if-component-dep-fails (if-component-dep-fails component)
    (asdf-message "The system definition for ~S uses deprecated ~
                 ASDF option :IF-COMPONENT-DEP-DAILS. ~
                 Starting with ASDF 3, please use :IF-FEATURE instead"
                  (coerce-name (component-system component)))
    ;; This only supports the pattern of use of the "feature" seen in the wild
    (check-type component parent-component)
    (check-type if-component-dep-fails (member :fail :ignore :try-next))
    (unless (eq if-component-dep-fails :fail)
      (loop :with o = (make-operation 'compile-op)
            :for c :in (component-children component) :do
              (loop* :for (feature? feature) :in (component-depends-on o c)
                     :when (eq feature? 'feature) :do
                     (setf (component-if-feature c) feature))))))

(when-upgrading (:when (fboundp 'make-sub-operation))
  (defun make-sub-operation (c o dep-c dep-o)
    (declare (ignore c o dep-c dep-o)) (asdf-upgrade-error)))


;;;; load-sysdef
(with-upgradability ()
  (defun load-sysdef (name pathname)
    (load-asd pathname :name name))

  (defun make-temporary-package ()
    ;; For loading a .asd file, we dont't make a temporary package anymore,
    ;; but use ASDF-USER. I'd like to have this function do this,
    ;; but since whoever uses it is likely to delete-package the result afterwards,
    ;; this would be a bad idea, so preserve the old behavior.
    (make-package (fresh-package-name :prefix :asdf :index 0) :use '(:cl :asdf))))


