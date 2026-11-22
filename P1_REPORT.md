# P1 report

## Result (P1.b)

`count_solutions([1,2,3,4,5,6,7,8], N)` gives **N = 3**.

The three solutions (A, B and C), out of 4!³ = 13,824 possible assignments, are:

| | Alex | Ben | Carla | Dana |
| --- | --- | --- | --- | --- |
| A | design, java, AI | development, javascript, web | research, c++, data | testing, python, embedded |
| B | design, java, embedded | development, javascript, web | testing, python, AI | research, c++, data |
| C | testing, python, embedded | development, javascript, web | design, java, AI | research, c++, data |

## What this says about the puzzle

**It is consistent but under-determined.** A solution exists, so the clues do not contradict
each other. It is not unique, so "the answer" is not defined: a program that stops at the first
solution prints something valid but gives no hint that two other answers exist. Counting is
what exposes this.

**Part of it is forced.** In every solution Ben is development, javascript, web. Research
always goes with C++ and data, design with Java, and testing with Python.

**Part of it is open.** The clues do not settle which of Alex, Carla and Dana holds the
research, design and testing roles, or whether AI goes with design or with testing.

**No clue is redundant.** Leaving out any one clue increases N:

| Clue left out | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| N | 4 | 6 | 13 | 12 | 9 | 7 | 5 | 16 |

So the fault is missing information, and the repair is to add a clue.

## What it means for the repair (P1.c)

A and C consist of the same four (department, language, project) triples. Only the people
holding them differ. A clue that names nobody cannot see who holds a triple, so it has the
same truth value in A and C and can never keep just one of them. **B is the only solution
that a nameless clue can isolate.**

What sets B apart is that AI goes with testing, where in A and C it goes with design:

> Clue 9: The friend who prefers the AI project works in the testing department.

`count_solutions([1,2,3,4,5,6,7,8,9], N)` gives **N = 1**, and the solution kept is B.
