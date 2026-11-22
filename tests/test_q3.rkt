#lang racket/base
; Tests for S1 (Binary Tree Traversals).
; Run: racket tests/test_q3.rkt
;
; The solution is run as the grader runs it: calls are appended to a copy of
; the file. These tests may use all of Racket; the solution may not.

(require racket/file racket/list racket/port racket/runtime-path racket/string racket/system)

(define-runtime-path code-dir "../code")

; (solution-file) -> the one code/*_q3.rkt, or #f
(define (solution-file)
  (define found
    (if (directory-exists? code-dir)
        (filter (lambda (p) (regexp-match? #rx"_q3[.]rkt$" (path->string p)))
                (directory-list code-dir #:build? #t))
        '()))
  (and (= 1 (length found)) (car found)))

; (run-appended calls) -> stdout when the solution plus calls runs cleanly, else a diagnosis
(define (run-appended calls)
  (define code (solution-file))
  (cond
    [(not code) "<no solution file>"]
    [else
     (define dir (make-temporary-file "s1-test-~a" 'directory))
     (define copy (build-path dir "q3.rkt"))
     (display-to-file (string-append (file->string code) "\n" calls "\n") copy)
     (define out (open-output-string))
     (define err (open-output-string))
     (define control
       (fifth (process*/ports out (open-input-string "") err
                              (find-executable-path (find-system-path 'exec-file))
                              copy)))
     (define finished? (sync/timeout 30 (thread (lambda () (control 'wait)))))
     (unless finished? (control 'kill))
     (begin0
       (cond [(not finished?) "<timeout>"]
             [(and (zero? (control 'exit-code)) (string=? "" (get-output-string err)))
              (get-output-string out)]
             [else (string-append "<error> " (get-output-string err))])
       (delete-directory/files dir))]))

; ---------- whitelist checker ----------

; every composition of car and cdr from two to four levels
(define (c...r depth)
  (if (= depth 0)
      '("")
      (append-map (lambda (rest) (list (string-append "a" rest) (string-append "d" rest)))
                  (c...r (- depth 1)))))

(define permitted
  (append '(define lambda let let* letrec if cond else and or not begin quote
            cons car cdr list null? pair? eq? assq assoc
            + - * < > <= >= = max display newline)
          (map (lambda (middle) (string->symbol (string-append "c" middle "r")))
               (append (c...r 2) (c...r 3) (c...r 4)))))

; (within-rules? forms) -> do the forms compile with nothing but the permitted bindings?
(define (within-rules? forms)
  (and (not (has-banned-literal? forms))
       (with-handlers ([exn:fail? (lambda (e) #f)])
         (parameterize ([current-namespace (make-base-namespace)])
           (eval `(module whitelist racket/base
                    (provide #%module-begin #%app #%datum ,@permitted)))
           (eval `(module checked 'whitelist ,@forms))
           #t))))

; (has-banned-literal? v) -> does v contain a string, vector, hash, byte string or char?
(define (has-banned-literal? v)
  (cond [(pair? v) (or (has-banned-literal? (car v)) (has-banned-literal? (cdr v)))]
        [else (or (string? v) (vector? v) (hash? v) (bytes? v) (char? v))]))

; (solution-forms) -> the top-level forms after the #lang line
(define (solution-forms)
  (call-with-input-file (solution-file)
    (lambda (in)
      (read-line in)
      (for/list ([form (in-port read in)]) form))))

; ---------- reference definitions, deliberately naive ----------

(define (ref-in t)
  (if (null? t) '() (append (ref-in (second t)) (list (first t)) (ref-in (third t)))))
(define (ref-pre t)
  (if (null? t) '() (append (list (first t)) (ref-pre (second t)) (ref-pre (third t)))))
(define (ref-post t)
  (if (null? t) '() (append (ref-post (second t)) (ref-post (third t)) (list (first t)))))
(define (ref-height t)
  (if (null? t) 0 (+ 1 (max (ref-height (second t)) (ref-height (third t))))))
(define (ref-leaves t)
  (cond [(null? t) 0]
        [(and (null? (second t)) (null? (third t))) 1]
        [else (+ (ref-leaves (second t)) (ref-leaves (third t)))]))

(define (random-tree budget)
  (cond
    [(or (= budget 0) (= 0 (random 9))) '()]
    [else
     (define left-budget (random budget))
     (list (if (= 0 (random 2)) (- (random 100) 50) (list-ref '(a b c x y z + *) (random 8)))
           (random-tree left-budget)
           (random-tree (- budget 1 left-budget)))]))

; ---------- cases ----------

(define t1 '(4 (2 (1 () ()) (3 () ())) (6 (5 () ()) (7 () ()))))
(define t2 '(1 () (2 () (3 () ()))))
(define t3 '(a (b () ()) (c () ())))

; name, tree, inorder, preorder, postorder, (height leaves)
(define fixed-cases
  `(("t1" ,t1 "(1 2 3 4 5 6 7)" "(4 2 1 3 6 5 7)" "(1 3 2 5 7 6 4)" "(3 4)")
    ("t2" ,t2 "(1 2 3)" "(1 2 3)" "(3 2 1)" "(3 1)")
    ("t3" ,t3 "(b a c)" "(a b c)" "(b c a)" "(2 2)")
    ("empty" () "()" "()" "()" "(0 0)")
    ("one node" (9 () ()) "(9)" "(9)" "(9)" "(1 1)")
    ("zero as a value" (0 () ()) "(0)" "(0)" "(0)" "(1 1)")
    ("only left" (3 (2 (1 () ()) ()) ()) "(1 2 3)" "(3 2 1)" "(1 2 3)" "(3 1)")
    ("left child only" (1 (2 () ()) ()) "(2 1)" "(1 2)" "(2 1)" "(2 1)")
    ("right child only" (1 () (2 () ())) "(1 2)" "(1 2)" "(2 1)" "(2 1)")
    ("zigzag" (1 (2 () (3 () ())) ()) "(2 3 1)" "(1 2 3)" "(3 2 1)" "(3 1)")
    ("repeated values" (5 (5 () ()) (5 () ())) "(5 5 5)" "(5 5 5)" "(5 5 5)" "(2 2)")
    ("negative and mixed" (-1 (x () ()) (2.5 () ())) "(x -1 2.5)" "(-1 x 2.5)" "(x 2.5 -1)" "(2 2)")
    ("operator symbols" (+ (* () ()) ()) "(* +)" "(+ *)" "(* +)" "(2 1)")))

(define (lines . items)
  (string-append* (map (lambda (item) (format "~a\n" item)) items)))

; (chain-test side depth) -> check a chain 1, 2, ..., depth from the root down
(define (chain-test side depth)
  (define down (range 1 (+ depth 1)))
  (define up (reverse down))
  (lambda ()
    (equal?
     (run-appended
      (string-append
       (format "(define grader-chain (for/fold ([below '()]) ([i (in-range ~a 0 -1)]) " depth)
       (if (eq? side 'left) "(list i below '())))" "(list i '() below)))")
       "(print-inorder grader-chain)(print-all-traversals grader-chain)"
       "(print-height-and-leaves grader-chain)"))
     (if (eq? side 'left)
         (lines up up down up (list depth 1))
         (lines down down down up (list depth 1))))))

(define tests
  (append
   (append-map
    (lambda (c)
      (apply
       (lambda (name t in pre post both)
         (list
          (cons (format "print-inorder: ~a" name)
                (lambda () (equal? (run-appended (format "(print-inorder '~s)" t)) (lines in))))
          (cons (format "print-all-traversals: ~a" name)
                (lambda () (equal? (run-appended (format "(print-all-traversals '~s)" t))
                                   (lines in pre post))))
          (cons (format "print-height-and-leaves: ~a" name)
                (lambda () (equal? (run-appended (format "(print-height-and-leaves '~s)" t))
                                   (lines both))))))
       c))
    fixed-cases)
   (for*/list ([depth '(100 10000 100000)] [side '(left right)])
     (cons (format "~a chain of depth ~a" side depth) (chain-test side depth)))
   (list
    (cons "300 random trees agree with the reference"
          (lambda ()
            (random-seed 2026)
            (define trees (for/list ([i 300]) (random-tree (random 40))))
            (equal?
             (run-appended
              (string-append*
               (for/list ([t trees])
                 (format "(print-all-traversals '~s)(print-height-and-leaves '~s)\n" t t))))
             (string-append*
              (for/list ([t trees])
                (lines (ref-in t) (ref-pre t) (ref-post t) (list (ref-height t) (ref-leaves t))))))))
    (cons "loading prints nothing" (lambda () (equal? "" (run-appended ""))))
    (cons "the grader may define common names"
          (lambda ()
            (equal? "(1)\n"
                    (run-appended
                     (string-append "(define t1 '(1 () ()))(define t2 '())(define t3 '())"
                                    "(define t '())(define tree '())(define result '())"
                                    "(print-inorder t1)")))))
    (cons "first line is #lang racket/base"
          (lambda () (equal? "#lang racket/base" (car (file->lines (solution-file))))))
    (cons "only definitions at the top level"
          (lambda () (andmap (lambda (f) (and (pair? f) (eq? 'define (car f)))) (solution-forms))))
    (cons "only permitted built-ins" (lambda () (within-rules? (solution-forms)))))))

; The checker itself must accept good code and reject each kind of bad code.
(define controls
  (cons
   (cons "checker accepts permitted code"
         (lambda ()
           (within-rules? '((define (f l) (let go ((l l)) (cond ((null? l) 0)
                                                               (else (+ 1 (go (cdr l)))))))))))
   (for/list ([bad '((define (f l) (length l)) (define (f l) (append l l)) (define (f l) (map f l))
                     (define (f l) (list? l)) (define (f l) (zero? l)) (define (f l) (set! l 1))
                     (define (f l) (when l l)) (define (f) (read)) (define (f) "text"))])
     (cons (format "checker rejects ~s" bad) (lambda () (not (within-rules? (list bad))))))))

(define failures
  (for/fold ([failed 0]) ([test (append controls tests)])
    (define ok? (with-handlers ([exn:fail? (lambda (e) #f)]) ((cdr test))))
    (unless ok? (printf "FAIL  ~a\n" (car test)))
    (if ok? failed (+ failed 1))))

(define total (+ (length controls) (length tests)))
(printf "S1: ~a of ~a tests passed\n" (- total failures) total)
(exit (if (= failures 0) 0 1))
