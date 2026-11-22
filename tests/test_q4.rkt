#lang racket/base
; Tests for S2 (Conditionally Insert into a Nested List).
; Run: racket tests/test_q4.rkt
;
; The solution is run as the grader runs it: calls are appended to a copy of
; the file and input is given on stdin. These tests may use all of Racket;
; the solution may not.

(require racket/file racket/list racket/port racket/runtime-path racket/string racket/system)

(define-runtime-path code-dir "../code")

; (solution-file) -> the one code/*_q4.rkt, or #f
(define (solution-file)
  (define found
    (if (directory-exists? code-dir)
        (filter (lambda (p) (regexp-match? #rx"_q4[.]rkt$" (path->string p)))
                (directory-list code-dir #:build? #t))
        '()))
  (and (= 1 (length found)) (car found)))

; (run-appended calls input) -> stdout when the solution plus calls runs cleanly, else a diagnosis
(define (run-appended calls [input ""])
  (define code (solution-file))
  (cond
    [(not code) "<no solution file>"]
    [else
     (define dir (make-temporary-file "s2-test-~a" 'directory))
     (define copy (build-path dir "q4.rkt"))
     (display-to-file (string-append (file->string code) "\n" calls "\n") copy)
     (define out (open-output-string))
     (define err (open-output-string))
     (define control
       (fifth (process*/ports out (open-input-string input) err
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
            + - * < > <= >= = max display newline read)
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

; (definitions-of name) -> every top-level definition of name
(define (definitions-of name)
  (filter (lambda (f)
            (and (pair? f) (eq? 'define (first f))
                 (eq? name (if (pair? (second f)) (car (second f)) (second f)))))
          (solution-forms)))

; (mentions? form name) -> does name occur in form?
(define (mentions? form name)
  (cond [(pair? form) (or (mentions? (car form) name) (mentions? (cdr form) name))]
        [else (eq? form name)]))

; ---------- reference, deliberately naive ----------

(define (ref-insert x lst ok?)
  (define mapped (map (lambda (v) (if (list? v) (ref-insert x v ok?) v)) lst))
  (if (ok? (length lst)) (cons x mapped) mapped))

(define (random-nested depth)
  (for/list ([i (random 6)])
    (if (and (> depth 0) (< (random 10) 4))
        (random-nested (- depth 1))
        (list-ref '(0 1 2 3 7 9 a b sym -4 + 2.5) (random 12)))))

; ---------- cases ----------

; name, stdin, stdout without the final newline
(define stdin-cases
  '(("PDF example 1" "42 ((1 2) (3 4 5) (6) ()) 3" "((42 1 2) (3 4 5) (42 6) (42))")
    ("PDF example 2" "0 (((1) 2) (3) ((4 5 6) ())) 3" "((0 (0 1) 2) (0 3) (0 (4 5 6) (0)))")
    ("PDF example 3" "7 () 3" "(7)")
    ("PDF example 4" "7 () 0" "()")
    ("empty, n = 1" "7 () 1" "(7)")
    ("n = 0 changes nothing" "9 (() (1) ((2) ())) 0" "(() (1) ((2) ()))")
    ("n = 1 fills only empty lists" "9 (() (1) ((2) ())) 1" "((9) (1) ((2) (9)))")
    ("length n-1 is short" "5 (1 2) 3" "(5 1 2)")
    ("length n is not short" "5 (1 2 3) 3" "(1 2 3)")
    ("length n+1 is not short" "5 (1 2 3 4) 3" "(1 2 3 4)")
    ("original length, not the new one" "5 ((1) (2)) 3" "(5 (5 1) (5 2))")
    ("flat list, large n" "0 (1 2 3) 1000000000000000000000" "(0 1 2 3)")
    ("sublist counts as one element" "5 ((1 2 3 4 5)) 2" "(5 (1 2 3 4 5))")
    ("nested empties" "z ((())) 2" "(z (z (z)))")
    ("symbols" "x (a (b c) ()) 4" "(x a (x b c) (x))")
    ("operator symbol as x" "+ (1 (2)) 2" "(1 (+ 2))")
    ("x already present" "1 (1 (1)) 5" "(1 1 (1 1))")
    ("negative x" "-3 (0) 2" "(-3 0)")
    ("input over several lines" "42\n((1 2)\n (3))\n\n3\n" "(42 (42 1 2) (42 3))")
    ("extra spaces" "   7    (  )    3   " "(7)")))

; call, stdout
(define call-cases
  '(("(display (my-length '()))" "0")
    ("(display (my-length '(a)))" "1")
    ("(display (my-length '((1 2 3) () x)))" "3")
    ("(display (my-length (for/list ([i 100000]) i)))" "100000")
    ("(display (my-map (lambda (v) (* v v)) '()))" "()")
    ("(display (my-map (lambda (v) (* v v)) '(1 2 3 4)))" "(1 4 9 16)")
    ("(display (my-map (lambda (v) (list v)) '(a (b))))" "((a) ((b)))")
    ("(display (insert-if-short 42 '((1 2) (3 4 5) (6) ()) 3))" "((42 1 2) (3 4 5) (42 6) (42))")
    ("(display (insert-if-short 7 '() 0))" "()")
    ("(display ((make-inserter 9 (lambda (k) (= k 0))) '(() (1) (()))))" "((9) (1) ((9)))")
    ("(display ((make-inserter 'e even?) '((1 2) (3) () (4 5 6))))" "(e (e 1 2) (3) (e) (4 5 6))")
    ("(display ((make-inserter 0 (lambda (k) (> k 2))) '((1 2 3) (4) ())))" "(0 (0 1 2 3) (4) ())")
    ("(display ((make-inserter 0 (lambda (k) #f)) '((1) ())))" "((1) ())")
    ("(define f (make-inserter 1 zero?)) (display (f '())) (display (f '(2))) (display (f '()))"
     "(1)(2)(1)")))

(define (nest depth core)
  (for/fold ([inner core]) ([i depth]) (list inner)))

(define (line v) (format "~a\n" v))

; (big-test name x lst n expected) -> a test that sends lst through stdin
(define (big-test name x lst n expected)
  (cons name
        (lambda ()
          (equal? (run-appended "(print-insert-result)" (format "~a ~a ~a" x lst n))
                  (line (expected))))))

(define tests
  (append
   (for/list ([c stdin-cases])
     (cons (first c)
           (lambda () (equal? (run-appended "(print-insert-result)" (second c)) (line (third c))))))
   (for/list ([c call-cases])
     (cons (first c) (lambda () (equal? (run-appended (first c)) (second c)))))
   (list
    (big-test "depth 100" 9 (nest 100 '()) 3
              (lambda () (for/fold ([inner '(9)]) ([i 100]) (list 9 inner))))
    (big-test "depth 100, only the empty list is short" 9 (nest 100 '()) 1
              (lambda () (nest 100 '(9))))
    (big-test "depth 10000" 9 (nest 10000 '()) 2
              (lambda () (for/fold ([inner '(9)]) ([i 10000]) (list 9 inner))))
    (big-test "10000 atoms, short" 'x (range 10000) 10001 (lambda () (cons 'x (range 10000))))
    (big-test "10000 atoms, not short" 'x (range 10000) 10000 (lambda () (range 10000)))
    (big-test "10000 empty sublists" 5 (make-list 10000 '()) 1 (lambda () (make-list 10000 '(5))))
    (big-test "100000 atoms" 'x (range 100000) 100001 (lambda () (cons 'x (range 100000))))
    (cons "400 random lists agree with the reference"
          (lambda ()
            (random-seed 2026)
            (define inputs (for/list ([i 400]) (list (random 100) (random-nested 4) (random 7))))
            (equal?
             (run-appended
              (string-append* (make-list (length inputs) "(print-insert-result)\n"))
              (string-append* (for/list ([i inputs])
                                (format "~a ~a ~a\n" (first i) (second i) (third i)))))
             (string-append*
              (for/list ([i inputs])
                (line (ref-insert (first i) (second i) (lambda (k) (< k (third i))))))))))
    (cons "loading prints nothing and reads nothing"
          (lambda () (equal? "" (run-appended "" "42 (1) 3"))))
    (cons "first line is #lang racket/base"
          (lambda () (equal? "#lang racket/base" (car (file->lines (solution-file))))))
    (cons "only definitions at the top level"
          (lambda () (andmap (lambda (f) (and (pair? f) (eq? 'define (car f)))) (solution-forms))))
    (cons "one insert-if-short, defined with make-inserter"
          (lambda ()
            (define found (definitions-of 'insert-if-short))
            (and (= 1 (length found)) (mentions? found 'make-inserter))))
    (cons "make-inserter uses my-length and my-map"
          (lambda ()
            (define found (definitions-of 'make-inserter))
            (and (= 1 (length found)) (mentions? found 'my-length) (mentions? found 'my-map))))
    (cons "only permitted built-ins" (lambda () (within-rules? (solution-forms)))))))

; The checker itself must accept good code and reject each kind of bad code.
(define controls
  (cons
   (cons "checker accepts permitted code"
         (lambda ()
           (within-rules? '((define (f) (let* ((a (read)) (b (caddr a))) (display b) (newline)))))))
   (for/list ([bad '((define (f l) (length l)) (define (f l) (append l l)) (define (f l) (map f l))
                     (define (f l) (list? l)) (define (f l) (zero? l)) (define (f l) (set! l 1))
                     (define (f l) (when l l)) (define (f l) (printf l)) (define (f) "text"))])
     (cons (format "checker rejects ~s" bad) (lambda () (not (within-rules? (list bad))))))))

(define failures
  (for/fold ([failed 0]) ([test (append controls tests)])
    (define ok? (with-handlers ([exn:fail? (lambda (e) #f)]) ((cdr test))))
    (unless ok? (printf "FAIL  ~a\n" (car test)))
    (if ok? failed (+ failed 1))))

(define total (+ (length controls) (length tests)))
(printf "S2: ~a of ~a tests passed\n" (- total failures) total)
(exit (if (= failures 0) 0 1))
