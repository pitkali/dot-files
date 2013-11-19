#!/usr/bin/env racket
#lang racket/base

;; Module for describing available version control systems in a given
;; directory, and then describing that properly for shell prompt. Guiding
;; principle is speed regardless of repository size. Imaging running this
;; continuously in a git repository containing all chromium sources, for
;; several platforms, on an old-fashioned spinning hard drive.

(provide describe-vcs-for-path
         describe-vcs-for-path/shell)

;;; Utilities for finding various directories

(define (contains-directory? path subdir)
  (directory-exists? (build-path path subdir)))

(define (contains-subpath? path subpath)
  (define dst (build-path path subpath))
  (or (directory-exists? dst)
      (file-exists? dst)))

;; Find a directory, starting at `path' and moving upwards that
;; satisfies `pred?', which has to be a function taking a path
;; as an argument.
(define (find-enclosing-dir pred? [path (current-directory)])
  (if (pred? path)
      path
      (let ([parent (simplify-path (build-path path "..") #f)])
        (if (equal? path parent)
            ;; We can't move further upwards; thus we failed
            #f
            (find-enclosing-dir pred? parent)))))

(define (find-enclosing-dir-with-dir subdir [path (current-directory)])
  (find-enclosing-dir (λ (p) (contains-directory? p subdir)) path))

(define (find-enclosing-dir-with-path subpath [path (current-directory)])
  (find-enclosing-dir (λ (p) (contains-subpath? p subpath)) path))


;;; Data representation

;; All VCS description functions will act as transformers of a database. The
;; database itself is going to be implemented as a simple association list. The
;; keys are symbols describing a VCS, for example 'git for git. Values will be
;; association lists describing particular VCS state.
;;
;; For all VCS the following keys should be provided:
;; * 'source-root for path of top level directory within repository/checkout,
;; * 'colour for a string to prepend to selected description to indicate colour,
;; * 'descriptions for a list of possible descriptions, ordered towards
;;   the shortest one.

;; Remove `prefix' from `str' if it starts with it. Returns #f otherwise.
(define (string-remove-prefix prefix str)
  (let* ([prefix-len (string-length prefix)]
         [str-len (string-length str)])
    (if (< str-len prefix-len)
        #f
        (let ([head (substring str 0 prefix-len)]
              [tail (substring str prefix-len)])
          (if (string=? head prefix) tail #f)))))

(define (read-line-from-path path)
  (if (file-exists? path)
      (let ([line (with-input-from-file path (λ () (read-line)) #:mode 'text)])
        (if (eof-object? line) "" line))
      ""))

;; Describes how to check status of a VCS.
(struct vcs-checker (;; Symbol of this VCS.
                     name

                     ;; String describing colour to use for this VCS.
                     colour

                     ;; Finds a VCS source root for path, or returns
                     ;; #f, if this VCS is not used in the path.
                     ;;
                     ;; (-> info
                     ;;     (or/c path-string? path-for-some-system?)
                     ;;     (or/c (or/c path-string? path-for-some-system?)
                     ;;           #f))
                     source-root

                     ;; Adds status information for this VCS to the database.
                     ;; Operates on current database and source root.
                     ;; Will not be called if source-root function returns #f.
                     ;;
                     ;; (-> info
                     ;;     (or/c path-string? path-for-some-system?)
                     ;;     dictionary describing VCS status)
                     check-status))

;; Uses vcs-checker structure to check VCS status in a path, and augment info accordingly.
(define (probe-vcs vcs info [path (current-directory)])
  (define source-root (let ([raw-path ((vcs-checker-source-root vcs) info path)])
                        (if raw-path (resolve-path raw-path) #f)))
  (if (not source-root)
      info
      (cons `(,(vcs-checker-name vcs) . ((source-root . ,source-root)
                                         (colour . ,(vcs-checker-colour vcs))
                                         ,@((vcs-checker-check-status vcs) info source-root)))
            info)))

(define (cdr-assq key d)
  (let ([entry (assq key d)])
    (if entry (cdr entry) #f)))

(define (info-for-vcs info name)
  (cdr-assq name info))

(define (lookup-for-vcs key vcs-info)
  (cdr-assq key vcs-info))

;;; Git

;; The git backend, in addition to the standard keys, remembers the following:
;; * 'git-dir -- where is the actual git directory, submodule aware;
;; * 'branch-name -- name of the current branch, or #f for detached HEAD.

(define (find-git-dir source-root)
  (define dot-git (build-path source-root ".git"))
  (if (directory-exists? dot-git)
      dot-git
      (let ([relpath (string-remove-prefix "gitdir: "
                                           (read-line-from-path dot-git))])
        (if relpath
            (simplify-path (build-path source-root relpath))
            #f))))

(define (describe-git-head git-dir)
  (let* ([head-path (build-path git-dir "HEAD")]
         [head-desc (read-line-from-path head-path)]
         [symbolic-ref (string-remove-prefix "ref: " head-desc)]
         [branch (string-remove-prefix "refs/heads/" (or symbolic-ref ""))])
    (cond
     [branch `(branch . ,branch)]
     [symbolic-ref `(ref . ,symbolic-ref)]
     [else `(commit . ,(substring head-desc 0 8))])))

(define (git-source-root info path)
  (find-enclosing-dir-with-path ".git" path))

(define (git-check-status info source-root)
  (let* ([git-dir (find-git-dir source-root)]
         [head-desc (describe-git-head git-dir)]
         [head-type (car head-desc)]
         [head-string (cdr head-desc)])
    `((branch-name . ,(if (eq? head-type 'branch) head-string #f))
      (git-dir . ,git-dir)
      (descriptions . (,(format " (g:~a)" head-string) " (git)" " (g)")))))

(define git-checker (vcs-checker 'git "$GIT_COLOUR"
                                 git-source-root
                                 git-check-status))

;;; Stacked GIT

;; Runs checks only if in git repository.

(define (stg-branch-dir git-dir branch-name)
  (let* ([branch-components (regexp-split #rx"/" branch-name)]
         [branch-subpath (apply build-path branch-components)])
    (build-path git-dir "patches" branch-subpath)))

(define (stg-applied branch-dir)
  (with-input-from-file
      (build-path branch-dir "applied")
    (λ () (for/last ([line (in-lines)]) line))
    #:mode 'text))

(define (stg-source-root info path)
  (let ([git-info (info-for-vcs 'git info)])
    (if (not git-info)
        #f
        (let* ([git-dir (lookup-for-vcs 'git-dir git-info)]
               [branch-name (lookup-for-vcs 'branch-name git-info)]
               [branch-dir (if branch-name (stg-branch-dir git-dir branch-name) #f)])
          (if (or (not branch-name)
                  (not (directory-exists? branch-dir)))
              #f
              (lookup-for-vcs 'source-root git-info))))))

(define (stg-check-status info source-root)
  (define git-info (info-for-vcs 'git info))
  (let* ([git-dir (lookup-for-vcs 'git-dir git-info)]
         [branch-name (lookup-for-vcs 'branch-name git-info)]
         [branch-dir (stg-branch-dir git-dir branch-name)])
    `((descriptions . (,(format " (s:~a)" (or (stg-applied branch-dir) "-"))
                      " (stg)"
                      " (s)")))))

(define stg-checker (vcs-checker 'stg "$STG_COLOUR"
                                 stg-source-root stg-check-status))

;;; Mercurial support

(define (hg-source-root info path)
  (find-enclosing-dir-with-dir ".hg" path))

(define (hg-mq-patch-name source-root)
  (define (path-exists? path)
    (or (file-exists? path)
        (directory-exists? path)))
  (define patches-dir (build-path source-root ".hg" "patches"))
  (define (top-patch)
    (define (process-line line)
      (cond
       [(regexp-match #px"^[0-9a-fA-F]+:(.*)$" line) => (λ (match) (cadr match))]
       [else ""]))
    (with-input-from-file (build-path patches-dir "status")
      (λ () (or (for/last ([line (in-lines)]
                           ;; Skip whitespace only lines, just in case.
                           #:unless (regexp-match? #px"^[ \t\r\n]*$" line))
                  (process-line line))
                ""))
      #:mode 'text))
  (if (not (path-exists? (build-path patches-dir "series")))
      ""
      (format "#~a" (top-patch))))

(define (hg-check-status info source-root)
  (let* ([branch-path (build-path source-root ".hg" "branch")]
         ;; If branch-path exists, read branch name from it, defaulting to empty string.
         ;; If it's not there, we're on default branch, which we'll denote as empty string
         ;; as well. Mentioning `default' as the branch name is not really useful.
         [branch-name (read-line-from-path branch-path)]
         [bookmark-path (build-path source-root ".hg" "bookmarks.current")]
         [bookmark-name (read-line-from-path bookmark-path)]
         [mq-patch (hg-mq-patch-name source-root)])
    `((descriptions . (,(format " (hg:~a~a~a)"
                                (if (string=? branch-name "default") "" branch-name)
                                (if (or (= (string-length bookmark-name) 0)
                                        (string=? bookmark-name "@"))
                                    ;; If there's no bookmark or it's the default one,
                                    ;; use it's name verbatim.
                                    bookmark-name
                                    ;; Otherwise prepend `@' to denote bookmark name.
                                    (format "@~a" bookmark-name))
                                mq-patch)
                       " (hg)" " (h)")))))

(define hg-checker (vcs-checker 'hg "$HG_COLOUR"
                                hg-source-root hg-check-status))

;;; Bazaar support

(define (basename path)
  (let-values ([(base name dir) (split-path path)])
    name))

(define (bzr-nick-from-file path)
  (define (process-line line)
    (cond
     [(eof-object? line) #f]
     [(regexp-match #px"^nickname *= *(.*)$" line) => (λ (match) (cadr match))]
     [else (process-line (read-line))]))
  (with-input-from-file path
    (λ () (process-line (read-line)))
    #:mode 'text))

(define (bzr-nick source-root)
  (define basename-string (path->string (basename source-root)))
  (define branch-conf-path (build-path source-root ".bzr" "branch" "branch.conf"))
  (if (not (file-exists? branch-conf-path))
      basename-string
      (or (bzr-nick-from-file branch-conf-path)
          basename-string)))

(define (bzr-source-root info path)
  (find-enclosing-dir-with-dir ".bzr" path))

(define (bzr-check-status info source-root)
  (define nick (bzr-nick source-root))
  `((descriptions . (,(format " (bzr:~a)" nick) " (bzr)" " (b)"))))

(define bzr-checker (vcs-checker 'bzr "$BZR_COLOUR"
                                 bzr-source-root bzr-check-status))

;;; Getting it all together

(define checkers (list git-checker stg-checker hg-checker bzr-checker))

(define (build-vcs-info [path (current-directory)])
  (reverse (foldl (λ (vcs info)
                     (with-handlers ([exn:fail? (λ (e) info)])
                       (probe-vcs vcs info path)))
                  '() checkers)))

(define (vcs-collect info key)
  (map (λ (vcs-info) (lookup-for-vcs key (cdr vcs-info))) info))

(define (total-descriptions-length descriptions)
  (foldl (λ (descriptions length)
            (+ length (if (null? descriptions) 0 (string-length (car descriptions)))))
         0 descriptions))

(define (fit-descriptions descriptions max-length)
  (let fitter ([fixed '()] [descriptions descriptions])
    (if (or (>= max-length (+ (total-descriptions-length fixed)
                              (total-descriptions-length descriptions)))
            (null? descriptions))
        (append (reverse fixed) descriptions)
        (if (null? (cdar descriptions))
            (fitter (cons (car descriptions) fixed)
                    (cdr descriptions))
            (fitter fixed
                    (cons (cdar descriptions) (cdr descriptions)))))))

(define (describe-vcs-for-path [path (current-directory)] [max-length 80])
  (let ([info (build-vcs-info path)])
    (if (null? info)
        (values " " " ")
        (let* ([desc-list (vcs-collect info 'descriptions)]
               [desc-list (fit-descriptions desc-list max-length)]
               [desc (apply string-append (map car desc-list))]
               [colours (vcs-collect info 'colour)]
               [decorated (apply string-append (map (λ (col d) (string-append col (car d)))
                                                    colours desc-list))])
          (values desc decorated)))))

(define (describe-vcs-for-path/shell [path (current-directory)] [max-length 80])
  (let-values ([(raw decorated) (describe-vcs-for-path path max-length)])
    (format "~a\t~a" raw decorated)))

(module+ main
  (provide main)
  (define (main)
    (let* ([argv (current-command-line-arguments)]
           [max-width (if (< 0 (vector-length argv))
                          (string->number (vector-ref argv 0))
                          80)])
      (displayln (describe-vcs-for-path/shell (current-directory) max-width))))
  (main))
