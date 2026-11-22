---
name: scheme-dev
description: Write, test and review purely functional Scheme in Racket 8.x (#lang racket/base) for CS F301 Assignment 2. Use for any work on a .rkt file in code/ or tests/, or when reviewing Scheme for recursion, efficiency or whitelist compliance.
---

# Scheme development

## Language and version

- Racket 8.x. The first line of every `.rkt` file is exactly `#lang racket/base`.
- Solution files hold definitions only. The grader appends its calls to the end of the file
  and runs `racket <file>`.

## How to work

1. Do one unit at a time: one function, one test file, or one review.
2. Before coding, state the recursion: base case, smaller argument, and how results combine.
3. Write or identify the test first and see it fail.
4. Write the smallest function that meets the specification.
5. Run the self-review checklist below, then the tests, and only then answer.

## Hard constraints for solution files

Allowed, and nothing else from `racket/base`:

- Forms: `define`, `lambda`, `let`, `let*`, `letrec`, named `let`, `if`, `cond` with `else`,
  `and`, `or`, `not`, `begin`, `quote`.
- Lists: `cons`, `car`, `cdr`, `list`, every `car`/`cdr` composition up to four levels.
- Tests: `null?`, `pair?`, `eq?`. Lookup: `assq`, `assoc`.
- Numbers: `+ - * < > <= >= =` and `max`.
- Output: `display`, `newline`. Input, for S2 only: `read`.

Not allowed, among others:

- `set!` and its relatives, vectors, hash tables, strings (including string literals), `do`, `for`.
- `length`, `append`, `reverse`, `map`, `filter`, `member`, `memq`, `list-ref`, `list-tail`.
- Easy to use by accident: `list?`, `equal?`, `zero?`, `number?`, `symbol?`, `apply`, `when`,
  `unless`, `case`, `/`, `min`, `add1`, `printf`, `void`, `error`, `require`, quasiquote.

If one is needed, write a helper with a `my-` prefix from the allowed forms.

## Coding conventions

### Naming

- `kebab-case` throughout. Predicates end in `?` (`leaf?`). Printers start with `print-`.
- Replacements for banned built-ins are `my-length`, `my-map`, `my-reverse`.
- Accumulators say what they hold (`count`, `seen`, `done`), not `x2` or `tmp`.

### Comments and readings

Every function has a header of this shape:

```scheme
; (my-length lst) -> number of top-level elements of lst
;   Recursive reading: () has length 0; any other list has 1 + the length of its cdr.
```

- The reading covers the base case and the recursive case.
- For an accumulator, say what it holds on every call.

### Style

- Pass all state as arguments. No mutation.
- Use tail recursion where it is natural (counting, reversing, walking a long list). Keep plain
  structural recursion where the result really is a combination of two recursive results.
- Build lists with `cons` at the front and reverse once, so the cost stays linear.
- Keep calculation apart from printing: pure functions return, `print-` functions display.
- Use `let*` whenever evaluation order matters, as with consecutive `read`s.

## How to run and test

From the repository root (`<id>` is the group ID):

```sh
racket code/<id>_q3.rkt                  # must print nothing
racket code/<id>_q4.rkt                  # must print nothing
racket tests/test_q3.rkt
racket tests/test_q4.rkt

# the way the grader runs it
T=$(mktemp -d); cp code/<id>_q4.rkt "$T/q4.rkt"
echo "(print-insert-result)" >> "$T/q4.rkt"
echo "7 () 3" | racket "$T/q4.rkt"       # prints (7)
```

The test files compile each solution in a language that provides only the whitelist. They exit
non-zero if any test fails. Test files may use the rest of Racket.

For each function test: the specified examples, `()`, one element, symbols as well as numbers,
repeated values, deep nesting (at least 100) and long lists (at least 10,000).

## Self-review checklist (apply before answering)

- [ ] Name and argument order match the specification exactly.
- [ ] Every identifier is whitelisted, a parameter, or defined in the file.
- [ ] The recursive reading is true of every branch.
- [ ] Each recursive call is on a smaller argument, and `()` is handled.
- [ ] `car` and `cdr` are applied only to pairs.
- [ ] Cost is linear: no repeated length or appending inside a recursion.
- [ ] An empty sublist is still a list: test `(or (null? v) (pair? v))`.
- [ ] Lengths are measured on the original list, before insertion.
- [ ] Output uses `display` and ends in exactly one newline per line.
- [ ] No top-level expression, so loading prints nothing.
- [ ] No top-level name that a grader is likely to define (`t1`, `tree`, `result`).
- [ ] The tests were run, and their real output was read.

## Known failure modes of AI tools writing Scheme

| Failure | What to do |
| --- | --- |
| Reaches for `length`, `map`, `append` or `reverse` | All are banned. Write the helper. |
| Uses `list?` to detect a sublist | Banned. Use `(or (null? v) (pair? v))`. |
| Uses `pair?` alone to detect a list | `(pair? '())` is false, so empty sublists are skipped. |
| Takes `(car '())` | An error in Racket. Test `null?` first. |
| Uses `(cdr node)` as the left subtree | The left subtree is `(cadr node)`, the right is `(caddr node)`. |
| Appends inside a traversal | Quadratic on skewed trees. Use an accumulator. |
| Forgets that an accumulator reverses order | Reverse once at the end. |
| Writes `set-car!` from R5RS | Racket pairs are immutable, and mutation is banned anyway. |
| Compares numbers with `eq?` | False for large numbers. Use `=`. |
| Prints with `write`, `print` or `printf` | Banned, and the format differs. Use `display`. |
| Puts an example call at the top level | Module-level values print on load. Put calls in tests. |
| Leaves two definitions of one function after a refactor | A module rejects duplicates. Replace the old one. |
| Claims code works without running it | Run the commands above first. |
