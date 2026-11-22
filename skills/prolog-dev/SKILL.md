---
name: prolog-dev
description: Write, test and review pure SWI-Prolog 9.x predicates for CS F301 Assignment 2. Use for any work on a .pl file in code/ or tests/, or when reviewing Prolog for termination, determinism or rule compliance.
---

# Prolog development

## Language and version

- SWI-Prolog 9.x, traditional-style source files loaded into `user`.
- Text in double quotes is a string. `'AI'` and `'c++'` are quoted atoms.
- Solution files are loaded by the grader with `swipl -q -f <file> -g <goal> -t halt`.

## How to work

1. Do one unit at a time: one predicate, one test file, or one review.
2. Before coding, state the predicate's mode and what makes it true.
3. Write or identify the test first and see it fail.
4. Write the smallest predicate that meets the specification.
5. Run the self-review checklist below, then the tests, and only then answer.

## Hard constraints for solution files

- Libraries: only `lists`, `apply`, `yall` and `aggregate`. ISO and SWI-Prolog built-ins are fine.
- Never use `assert*`, `retract*`, `abolish`, `b_setval`, `nb_setval`, flags, the recorded
  database or tabling to hold state. All state travels in arguments.
- No `initialization` directive and no call to `halt`.
- Only definitions and `use_module` directives. Loading prints nothing.
- Print only where the specification asks for it.
- Never build text and parse it back in order to evaluate it.

## Coding conventions

### Naming

- Predicates are `snake_case` and describe a relation: `candidate/1`, `needs_parentheses/3`.
- Variables are descriptive `CamelCase`. A list is plural (`Names`, `Trees`).
- Accumulators and intermediate states are numbered (`Text0`, `Text`).
- Intentionally unused variables are `_` or start with `_`.

### Comments and readings

Every predicate has a header of this shape, with `+` input, `-` output and `?` either:

```prolog
% sum_of(+Numbers, -Sum)
%   Declarative reading: Sum is the total of the integers in Numbers.
```

- The declarative reading says what is true, not the order of execution.
- Add a "why" comment only where ordering matters for termination, or a rule is easy to misread.
- Keep the clauses of a predicate together, base case first.

### Style

- Prefer unification in clause heads, and pattern-match on structure.
- Represent data as terms (`num(N)`, `node(Op, Left, Right)`), never as text.
- Use `findall/3` for all solutions and `once/1` where exactly one is specified.
- Use `is` to calculate and `=:=` / `=\=` to compare numbers.
- Avoid cuts. If a commit is needed, use `( If -> Then ; Else )` with a fully bound condition.

## How to run and test

From the repository root (`<id>` is the group ID):

```sh
swipl -q -f code/<id>_q1.pl -g main -t halt
swipl -q -f code/<id>_q1.pl -g "count_solutions([1,2,3],N), print(N), nl" -t halt
swipl -q -f code/<id>_q2.pl -g "all_equations([2,4,8],Es), print(Es), nl" -t halt
swipl -q -f tests/test_q1.pl -g run_tests -t halt
swipl -q -f tests/test_q2.pl -g run_tests -t halt
```

A test command exits non-zero if any test fails. Test files may use other libraries because
the restrictions apply to solution files.

For each predicate test: the specified examples, the empty and smallest inputs, a failing
input, duplicates and zero, and the exact type of every output.

## Self-review checklist (apply before answering)

- [ ] Name, arity and argument order match the specification exactly.
- [ ] The declarative reading is true of every clause.
- [ ] Each recursive call is on a strictly smaller argument, so failure is finite.
- [ ] Forced backtracking gives no wrong or repeated answer.
- [ ] "No answer" is failure or `[]` as specified, never an exception.
- [ ] Every variable is bound before `is`, arithmetic comparison, `\+` or `\==` uses it.
- [ ] Every division has a non-zero divisor and leaves no remainder where exactness is required.
- [ ] Output type is exact: string, atom, list and number are not interchangeable.
- [ ] The file loads with no warning and no output.
- [ ] No forbidden library, predicate or directive appears.
- [ ] No answer is hard-coded. It is derived from the rules.
- [ ] The tests were run, and their real output was read.

## Known failure modes of AI tools writing Prolog

| Failure | What to do |
| --- | --- |
| Uses `X = A + B` to calculate | `=` only builds a term. Use `X is A + B`. |
| Uses `/` for exact integer division | `7/2` is `3.5`. Check `B =\= 0, A mod B =:= 0`, then use `//`. |
| Lets `A/0` reach `is` | It raises an error instead of failing. Guard first. |
| Puts `\+` or `\==` before its variables are bound | Negation is not sound on open terms. Generate, then test. |
| Writes `AI` or `c++` unquoted | `AI` is a variable and `c++` is a syntax error. Quote both. |
| Returns an atom or code list for a string | Build with `atomics_to_string/2` and test with `string/1`. |
| Splits with `append/3` without non-empty parts | One side equals the whole list and recursion never ends. Use `[_\|_]` patterns. |
| Adds cuts to silence choice points | Answers are lost. Restructure, or use `once/1` at the interface. |
| Uses `msort/2` to remove duplicates | Only `sort/2` removes them. |
| Expects bindings to survive `findall/3` or `forall/2` | `findall` copies and `forall` undoes bindings. |
| Invents library predicates | Confirm each one exists in an allowed library or is built in. |
| Adds `:- initialization(main).` or `halt` | Both break the grader. Leave them out. |
| Hard-codes the example answer | Test inputs that are not in the specification. |
| Claims code works without running it | Run the commands above first. |
