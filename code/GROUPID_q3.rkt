#lang racket/base
; S1: Binary Tree Traversals.
;
; A tree is () or (value left right), so for a non-empty node the value is
; (car node), the left subtree (cadr node) and the right subtree (caddr node).
; The traversals visit left before right, cons each value onto an accumulator
; as it is reached, and reverse once at the end, which keeps them linear.

; (my-reverse lst) -> the top-level elements of lst in reverse order
;   Recursive reading: when nothing is left, the answer is what was reversed
;   so far; otherwise move the first element onto the front of that.
(define (my-reverse lst)
  (let loop ((rest lst) (reversed '()))
    (if (null? rest)
        reversed
        (loop (cdr rest) (cons (car rest) reversed)))))

; (inorder tree) -> the values in the order left subtree, node, right subtree
;   Recursive reading: () adds nothing to what has been seen; a node adds all
;   of its left subtree, then its value, then all of its right subtree.
(define (inorder tree)
  (my-reverse
   (let visit ((node tree) (seen '()))
     (if (null? node)
         seen
         (visit (caddr node)
                (cons (car node) (visit (cadr node) seen)))))))

; (print-inorder tree) -> prints the inorder list on one line
;   Recursive reading: none of its own; inorder does the recursion.
(define (print-inorder tree)
  (display (inorder tree))
  (newline))

; (preorder tree) -> the values in the order node, left subtree, right subtree
;   Recursive reading: () adds nothing to what has been seen; a node adds its
;   value, then all of its left subtree, then all of its right subtree.
(define (preorder tree)
  (my-reverse
   (let visit ((node tree) (seen '()))
     (if (null? node)
         seen
         (visit (caddr node)
                (visit (cadr node) (cons (car node) seen)))))))
