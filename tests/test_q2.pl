% Tests for P2 (Form a Valid Arithmetic Equation).
% Run: swipl -q -f tests/test_q2.pl -g run_tests -t halt
%
% Expected lists and counts come from an independent brute force. The tests
% also parse each returned equation to check it. Only the tests do that: the
% solution itself never parses text.

:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(occurs)).
:- use_module(library(readutil)).
:- use_module(library(process)).
:- use_module(library(time)).

% ---------- fixtures ----------

% exact_case(?List, ?Equations)
%   Declarative reading: Equations are all the valid equations of List, sorted.
exact_case([4,2,5,3], ["4*2-5=3", "4*2=5+3", "4-2=5-3", "4/2=5-3",
                       "4=2*(5-3)", "4=2+(5-3)", "4=2+5-3"]).
exact_case([2,3,4], []).
exact_case([2,4,8], ["2*4=8"]).
exact_case([], []).
exact_case([5], []).
exact_case([0], []).
exact_case([5,5], ["5=5"]).
exact_case([0,0], ["0=0"]).
exact_case([5,6], []).
exact_case([12,12], ["12=12"]).
exact_case([1,2,12], []).
exact_case([7,2,3], []).
exact_case([6,4,2], ["6-4=2", "6=4+2"]).
exact_case([0,0,0], ["0*0=0", "0+0=0", "0-0=0", "0=0*0", "0=0+0", "0=0-0"]).
exact_case([0,5,0], ["0*5=0", "0/5=0", "0=5*0"]).
exact_case([0,0,5], ["0=0*5", "0=0/5"]).
exact_case([5,0,5], ["5+0=5", "5-0=5", "5=0+5"]).
exact_case([1,1,1], ["1*1=1", "1/1=1", "1=1*1", "1=1/1"]).
exact_case([4,2,3,18], ["(4+2)*3=18"]).
exact_case([4,2,3,10], ["4+2*3=10"]).
exact_case([1,2,3,6], ["1*(2*3)=6", "1*2*3=6", "1+(2+3)=6", "1+2+3=6", "1=2*3/6"]).
exact_case([1,2,3,2], ["1-(2-3)=2", "1-2+3=2", "1=2-(3-2)", "1=2-3+2"]).
exact_case([8,4,2,4], ["8/(4-2)=4", "8/(4/2)=4", "8/4*2=4", "8/4+2=4",
                       "8=(4-2)*4", "8=4/2*4"]).
exact_case([8,4,2,1], ["8/(4*2)=1", "8/4/2=1", "8/4=2*1", "8/4=2/1",
                       "8=4*(2*1)", "8=4*(2/1)", "8=4*2*1", "8=4*2/1"]).
exact_case([10,10,2,50], ["10*(10/2)=50", "10*10/2=50", "10*10=2*50"]).
exact_case([100000000000000000000,1,100000000000000000001],
           ["100000000000000000000+1=100000000000000000001"]).

% count_case(?List, ?N)
%   Declarative reading: List has exactly N equations.
count_case([4,2,5,3], 7).
count_case([], 0).
count_case([9], 0).
count_case([1,1,1,1], 30).
count_case([0,0,0,0], 45).
count_case([12,3,4,1], 8).
count_case([10,20,30,0], 4).
count_case([1,2,3,4,5], 14).
count_case([2,3,5,7,11], 12).
count_case([3,5,2,4,1], 25).
count_case([6,6,6,6,6], 24).
count_case([9,0,3,3,0], 85).
count_case([2,9,3,1,3], 10).
count_case([1,2,3,4,5,6], 101).
count_case([1,2,3,4,5,6,7], 529).

% rule_case(?Why, ?List, ?Equation, ?Expected)
%   Declarative reading: Equation is (present) or is not (absent) an equation of List.
rule_case(left_low_in_high,        [4,2,3,18],    "(4+2)*3=18",  present).
rule_case(high_needs_no_parens,    [4,2,3,10],    "4+2*3=10",    present).
rule_case(left_same_level,         [8,4,2,4],     "8/4*2=4",     present).
rule_case(right_same_level_high,   [8,4,2,1],     "8/(4*2)=1",   present).
rule_case(right_same_operator,     [8,4,2,4],     "8/(4/2)=4",   present).
rule_case(right_same_level_low,    [2,3,1,4],     "2+(3-1)=4",   present).
rule_case(right_minus,             [1,2,3,2],     "1-(2-3)=2",   present).
rule_case(left_assoc_minus,        [1,2,3,1,5],   "1-2-3=1-5",   present).
rule_case(left_assoc_sum,          [1,2,3,6],     "1+2+3=6",     present).
rule_case(both_trees_of_a_sum,     [1,2,3,6],     "1+(2+3)=6",   present).
rule_case(negative_subvalue,       [3,5,2,0],     "3-5+2=0",     present).
rule_case(negative_both_sides,     [3,5,1,3],     "3-5=1-3",     present).
rule_case(negative_exact_division, [2,8,3,1,3],   "(2-8)/3=1-3", present).
rule_case(negative_inexact,        [2,9,3,1,3],   "(2-9)/3=1-3", absent).
rule_case(inexact_inner_division,  [7,2,2,7],     "7/2*2=7",     absent).
rule_case(inexact_top_division,    [7,2,3],       "7/2=3",       absent).
rule_case(zero_over_zero,          [0,0,0],       "0/0=0",       absent).
rule_case(no_digit_joining,        [1,2,12],      "12=12",       absent).
rule_case(needless_left_parens,    [1,2,3,6],     "(1+2)+3=6",   absent).

% checked_list(?List)
%   Declarative reading: every equation returned for List is checked by itself.
checked_list([4,2,5,3]).
checked_list([9,0,3,3,0]).
checked_list([6,6,6,6,6]).
checked_list([1,2,3,4,5,6]).
checked_list([8,4,2,2,1,0]).

% ---------- tests ----------

% test(?Name, ?Goal)
%   Declarative reading: the requirement called Name holds exactly when Goal succeeds.
test(all(List), ( q2:all_equations(List, Got), Got == Expected )) :-
    exact_case(List, Expected).
test(count(List, N), ( q2:count_equations(List, Got), Got == N )) :-
    count_case(List, N).
test(count_is_length(List), ( q2:all_equations(List, Es), q2:count_equations(List, N),
                              length(Es, Len), Len == N )) :-
    exact_case(List, _).
test(rule(Why), ( q2:all_equations(List, Es), in_or_out(Where, Equation, Es) )) :-
    rule_case(Why, List, Equation, Where).
test(generate_gives_one_of(List), ( q2:generate_equation(List, E), string(E),
                                    memberchk(E, Expected) )) :-
    exact_case(List, Expected),
    Expected \== [].
test(generate_fails(List), ( q2_defined(generate_equation/2),
                             \+ q2:generate_equation(List, _) )) :-
    ( exact_case(List, []) ; List = [2,3,5,7,11,13,1000003] ).
test(all_empty_for_seven, ( q2:all_equations([2,3,5,7,11,13,1000003], Es), Es == [] )).
test(generate_backtracking_is_sound,
     ( findall(E, q2:generate_equation([4,2,5,3], E), Es), Es = [_|_],
       exact_case([4,2,5,3], Valid), subset(Es, Valid) )).
test(generate_accepts_a_valid_bound_equation,
     ( q2:generate_equation([4,2,5,3], "4=2+5-3") )).
test(generate_rejects_an_invalid_bound_equation,
     ( q2_defined(generate_equation/2), \+ q2:generate_equation([4,2,5,3], "4+2=5+3") )).
test(generate_rejects_an_atom,
     ( q2_defined(generate_equation/2), \+ q2:generate_equation([2,4,8], '2*4=8') )).
test(only_strings(List), ( q2:all_equations(List, Es), Es = [_|_], maplist(string, Es) )) :-
    checked_list(List).
test(sorted_without_duplicates(List), ( q2:all_equations(List, Es), Es = [_|_],
                                        sort(Es, Sorted), Sorted == Es )) :-
    checked_list(List).
test(each_equation_is_valid(List), ( q2:all_equations(List, Es), Es = [_|_],
                                     maplist(valid_equation(List), Es) )) :-
    checked_list(List).
test(prints_nothing,
     ( with_output_to(string(Out),
                      ( q2:all_equations([4,2,5,3], _), q2:count_equations([2,4,8], _),
                        q2:generate_equation([4,2,5,3], _) )),
       Out == "" )).
test(loads_silently, ( code_file(F), swipl(['-q','-f',F,'-g',true,'-t',halt], exit(0), "", "") )).
test(grader_command,
     ( code_file(F),
       swipl(['-q','-f',F,'-g','all_equations([2,4,8],Es),print(Es)','-t',halt],
             exit(0), Out, ""),
       Out == "[\"2*4=8\"]" )).
test(uses_nothing_forbidden, uses_nothing_forbidden).

% in_or_out(+Where, +Equation, +Equations)
%   Declarative reading: Equation is present in, or absent from, Equations as Where says.
in_or_out(present, Equation, Es) :- memberchk(Equation, Es).
in_or_out(absent, Equation, Es) :- \+ memberchk(Equation, Es).

% q2_defined(+Spec)
%   Declarative reading: the solution defines the predicate Spec.
q2_defined(Name/Arity) :-
    functor(Head, Name, Arity),
    predicate_property(q2:Head, defined).

% valid_equation(+List, +Equation)
%   Declarative reading: Equation is a canonical, exact, true equation over List in order.
%   Prolog's own precedence for + - * / is the canonical rule, so reading and
%   writing the text back must give the identical string.
valid_equation(List, Equation) :-
    string(Equation),
    \+ sub_string(Equation, _, _, _, " "),
    term_string(Term, Equation),
    nonvar(Term),
    Term = (Left = Right),
    exact_value(Left, Value),
    exact_value(Right, Value),
    phrase(( leaves(Left), leaves(Right) ), Leaves),
    Leaves == List,
    term_string(Term, Again),
    Again == Equation.

% exact_value(+Term, -Value)
%   Declarative reading: Value is the integer value of Term, with every division exact.
exact_value(N, N) :- integer(N), N >= 0.
exact_value(A+B, V) :- exact_value(A, X), exact_value(B, Y), V is X + Y.
exact_value(A-B, V) :- exact_value(A, X), exact_value(B, Y), V is X - Y.
exact_value(A*B, V) :- exact_value(A, X), exact_value(B, Y), V is X * Y.
exact_value(A/B, V) :- exact_value(A, X), exact_value(B, Y),
                       Y =\= 0, V is X // Y, X =:= V * Y.

% leaves(+Term)//
%   Declarative reading: the list described is the numbers of Term from left to right.
leaves(N) --> { integer(N) }, [N].
leaves(T) --> { compound(T), T =.. [_, A, B] }, leaves(A), leaves(B).

% uses_nothing_forbidden
%   Declarative reading: the solution source has no banned predicate, directive or library.
uses_nothing_forbidden :-
    code_file(File),
    read_file_to_terms(File, Terms, []),
    Banned = [assert,asserta,assertz,retract,retractall,abolish,b_setval,nb_setval,
              nb_linkval,recorda,recordz,flag,set_flag,table,halt,initialization,
              term_string,term_to_atom,read_term,read_term_from_atom,format,write,print],
    forall(( member(T, Terms), sub_term(Part, T), callable(Part) ),
           ( functor(Part, Name, _), \+ memberchk(Name, Banned) )),
    forall(member((:- Directive), Terms),
           ( nonvar(Directive), Directive = use_module(library(Lib)),
             memberchk(Lib, [lists,apply,yall,aggregate]) )).

% ---------- harness ----------

% code_file(-File)
%   Declarative reading: File is the one code/*_q2.pl of this repository.
code_file(File) :-
    source_file(code_file(_), This),
    file_directory_name(This, Dir),
    atomic_list_concat([Dir, '/../code/*_q2.pl'], Pattern),
    expand_file_name(Pattern, [File]),
    exists_file(File).

% swipl(+Args, -Status, -Out, -Err)
%   Declarative reading: running this SWI-Prolog on Args gives Status, Out and Err.
swipl(Args, Status, Out, Err) :-
    current_prolog_flag(executable, Exe),
    setup_call_cleanup(
        process_create(Exe, Args,
                       [stdin(null), stdout(pipe(O)), stderr(pipe(E)), process(Pid)]),
        ( read_string(O, _, Out0), read_string(E, _, Err0) ),
        ( close(O), close(E), process_wait(Pid, Status0) )),
    Status = Status0, Out = Out0, Err = Err0.

% outcome(+Goal, -Result)
%   Declarative reading: Result is pass, fail or error(E) according to Goal.
outcome(Goal, Result) :-
    catch(( call_with_time_limit(30, once(Goal)) -> Result = pass ; Result = fail ),
          Error,
          Result = error(Error)).

% run_tests
%   Declarative reading: every test passes.
run_tests :-
    ( code_file(File) -> load_files(q2:File, []) ; true ),
    findall(Name-Result, ( test(Name, Goal), outcome(Goal, Result) ), Results),
    forall(( member(Name-Result, Results), Result \== pass ),
           ( Result = error(_) -> format("ERROR ~q~n", [Name])
           ; format("FAIL  ~q~n", [Name])
           )),
    include([_-pass]>>true, Results, Passed),
    length(Results, Total),
    length(Passed, Count),
    format("P2: ~d of ~d tests passed~n", [Count, Total]),
    Count =:= Total.
