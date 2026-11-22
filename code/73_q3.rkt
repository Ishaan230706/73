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

; (postorder tree) -> the values in the order left subtree, right subtree, node
;   Recursive reading: () adds nothing to what has been seen; a node adds all
;   of its left subtree, then all of its right subtree, then its value.
(define (postorder tree)
  (my-reverse
   (let visit ((node tree) (seen '()))
     (if (null? node)
         seen
         (cons (car node)
               (visit (caddr node) (visit (cadr node) seen)))))))

; (print-all-traversals tree) -> prints inorder, preorder and postorder, one per line
;   Recursive reading: none of its own; the three traversals do the recursion.
(define (print-all-traversals tree)
  (print-inorder tree)
  (display (preorder tree))
  (newline)
  (display (postorder tree))
  (newline))

; (tree-height tree) -> the height of tree
;   Recursive reading: () has height 0; a node has 1 plus the larger of the
;   heights of its two subtrees.
(define (tree-height tree)
  (if (null? tree)
      0
      (+ 1 (max (tree-height (cadr tree))
                (tree-height (caddr tree))))))

; (leaf? node) -> true when node is a node with two empty subtrees
;   Recursive reading: none, it looks one level down. () is not a leaf.
(define (leaf? node)
  (and (pair? node)
       (null? (cadr node))
       (null? (caddr node))))

; (count-leaves tree) -> the number of leaves of tree
;   Recursive reading: () adds no leaf to the count so far; a leaf adds one;
;   any other node adds the leaves of its left and then of its right subtree.
(define (count-leaves tree)
  (let visit ((node tree) (count 0))
    (cond ((null? node) count)
          ((leaf? node) (+ count 1))
          (else (visit (caddr node) (visit (cadr node) count))))))

; (print-height-and-leaves tree) -> prints the list (height leaf-count) on one line
;   Recursive reading: none of its own; tree-height and count-leaves do the recursion.
(define (print-height-and-leaves tree)
  (display (list (tree-height tree) (count-leaves tree)))
  (newline))
