#lang racket/base
; S2: Conditionally Insert into a Nested List.
;
; The atom x is put at the front of every list, at every level of nesting,
; whose original length passes a test. For insert-if-short the test is "less
; than n". () is an ordinary list of length 0.

; (my-length lst) -> the number of top-level elements of lst
;   Recursive reading: () has length 0; any other list has 1 + the length of
;   its cdr. count holds the 1s added so far.
(define (my-length lst)
  (let loop ((rest lst) (count 0))
    (if (null? rest)
        count
        (loop (cdr rest) (+ count 1)))))

; (my-map f lst) -> the list of (f e) for each top-level element e, in order
;   Recursive reading: () maps to (); otherwise (f first) goes on the front of
;   the mapping of the rest.
(define (my-map f lst)
  (if (null? lst)
      '()
      (cons (f (car lst)) (my-map f (cdr lst)))))

; (list-value? v) -> true when v is a list rather than an atom
;   Recursive reading: none. v is a list if it is () or a pair, as there are no
;   dotted pairs in the input. pair? alone would miss ().
(define (list-value? v)
  (or (null? v) (pair? v)))

; (make-inserter x len-ok?) -> a function from a list to that list with x in
;                              front of every list whose length passes len-ok?
;   Recursive reading: the function returned replaces each sublist by its own
;   answer and keeps atoms; then it puts x in front if len-ok? holds of the
;   length of the original list.
(define (make-inserter x len-ok?)
  (letrec ((insert
            (lambda (lst)
              (let ((inside (my-map (lambda (v) (if (list-value? v) (insert v) v))
                                    lst)))
                (if (len-ok? (my-length lst))
                    (cons x inside)
                    inside)))))
    insert))

; (insert-if-short x lst n) -> lst with x in front of every list shorter than n
;   Recursive reading: that of make-inserter, where a length passes when it is
;   less than n. So () becomes (x) whenever 0 < n.
(define (insert-if-short x lst n)
  ((make-inserter x (lambda (len) (< len n))) lst))

; (print-insert-result) -> reads x, lst and n, prints the resulting list
;   Recursive reading: none of its own. let* fixes the order of the three reads.
(define (print-insert-result)
  (let* ((x (read))
         (lst (read))
         (n (read)))
    (display (insert-if-short x lst n))
    (newline)))
