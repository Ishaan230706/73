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
