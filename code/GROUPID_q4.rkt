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
