% Tests for P1 (Department Assignment Puzzle).
% Run: swipl -q -f tests/test_q1.pl -g run_tests -t halt
%
% Expected values were worked out by brute force over all 13824 assignments,
% independently of the solution.

:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(occurs)).
:- use_module(library(readutil)).
:- use_module(library(process)).
:- use_module(library(time)).

% ---------- fixtures ----------

% as_solution(+World, -Solution)
%   Declarative reading: Solution is World written as a list of p/4 terms.
as_solution(w([DA,DB,DC,DD], [LA,LB,LC,LD], [PA,PB,PC,PD]),
            [p('Alex',DA,LA,PA), p('Ben',DB,LB,PB),
             p('Carla',DC,LC,PC), p('Dana',DD,LD,PD)]).

% world(?Id, ?World)
%   Declarative reading: World is the named fixture. a, b and c are all the
%   solutions of clues 1-8; layout is the non-answer layout example from the PDF.
world(a, w([design,development,research,testing], [java,javascript,'c++',python],
           ['AI',web,data,embedded])).
world(b, w([design,development,testing,research], [java,javascript,python,'c++'],
           [embedded,web,'AI',data])).
world(c, w([testing,development,design,research], [python,javascript,java,'c++'],
           [embedded,web,'AI',data])).
world(layout, w([research,development,design,testing], [python,java,'c++',javascript],
                ['AI',web,embedded,data])).

% breaks(?Clue, ?Why, ?World)
%   Declarative reading: World is a legal assignment in which Clue is false for reason Why.
breaks(1, ai_in_research, w([design,development,research,testing],
                            [java,javascript,python,'c++'], [embedded,web,'AI',data])).
breaks(1, ai_is_dana,     w([design,development,research,testing],
                            [java,javascript,python,'c++'], [embedded,web,data,'AI'])).
breaks(2, alex_develops,  w([development,design,testing,research],
                            [java,javascript,python,'c++'], [embedded,web,'AI',data])).
breaks(2, alex_uses_cpp,  w([design,development,testing,research],
                            ['c++',javascript,python,java], [embedded,web,'AI',data])).
breaks(3, tester_not_python, w([design,development,testing,research],
                            [python,javascript,java,'c++'], [embedded,web,'AI',data])).
breaks(4, ben_not_web,    w([design,development,testing,research],
                            [java,javascript,python,'c++'], [web,embedded,'AI',data])).
breaks(4, ben_tests,      w([design,testing,development,research],
                            [java,javascript,python,'c++'], [embedded,web,'AI',data])).
breaks(5, java_not_design, w([design,development,testing,research],
                            [python,javascript,java,'c++'], [embedded,web,'AI',data])).
breaks(6, carla_embedded, w([design,development,testing,research],
                            [java,javascript,python,'c++'], ['AI',web,embedded,data])).
breaks(6, carla_develops, w([design,testing,development,research],
                            [java,javascript,python,'c++'], [embedded,web,'AI',data])).
breaks(7, dana_uses_java, w([design,development,testing,research],
                            ['c++',javascript,python,java], [embedded,web,'AI',data])).
breaks(7, dana_designs,   w([research,development,testing,design],
                            [java,javascript,python,'c++'], [embedded,web,'AI',data])).
breaks(8, data_not_research, w([research,development,testing,design],
                            [java,javascript,python,'c++'], [embedded,web,'AI',data])).
breaks(8, data_uses_js,   w([design,development,testing,research],
                            [java,'c++',python,javascript], [embedded,web,'AI',data])).

% count_case(?Active, ?N)
%   Declarative reading: exactly N assignments satisfy the clues in Active.
count_case([], 13824).
count_case([1], 7776).
count_case([2], 7776).
count_case([3], 3456).
count_case([4], 2592).
count_case([5], 3456).
count_case([6], 7776).
count_case([7], 5184).
count_case([8], 2592).
count_case([2,3,4,5,6,7,8], 4).
count_case([1,3,4,5,6,7,8], 6).
count_case([1,2,4,5,6,7,8], 13).
count_case([1,2,3,5,6,7,8], 12).
count_case([1,2,3,4,6,7,8], 9).
count_case([1,2,3,4,5,7,8], 7).
count_case([1,2,3,4,5,6,8], 5).
count_case([1,2,3,4,5,6,7], 16).
count_case([1,2,3,4,5,6,7,8], 3).
count_case([8,7,6,5,4,3,2,1], 3).
count_case([3,3], 3456).
count_case([1,2,3,4,5,6,7,8,9], 1).
count_case([99], 0).

% ---------- tests ----------

% test(?Name, ?Goal)
%   Declarative reading: the requirement called Name holds exactly when Goal succeeds.
test(clue_true(N, Id), ( as_solution(W, S), q1:clue(N, S) )) :-
    member(Id, [a,b,c]), world(Id, W), between(1, 8, N).
test(clue_false(N, Why), ( as_solution(W, S), q1_defined(clue/2), \+ q1:clue(N, S) )) :-
    breaks(N, Why, W).
test(layout_example(N, holds), ( as_solution(W, S), q1:clue(N, S) )) :-
    world(layout, W), member(N, [2,4,7]).
test(layout_example(N, fails), ( as_solution(W, S), q1_defined(clue/2), \+ q1:clue(N, S) )) :-
    world(layout, W), member(N, [1,3,5,6,8]).
test(clue_succeeds_once(N), ( as_solution(W, S), findall(x, q1:clue(N, S), [x]) )) :-
    world(b, W), between(1, 9, N).
test(count(Active, N), ( q1:count_solutions(Active, Got), Got == N )) :-
    count_case(Active, N).
test(count_accepts_a_bound_n, ( q1:count_solutions([1,2,3,4,5,6,7,8], 3),
                                \+ q1:count_solutions([1,2,3,4,5,6,7,8], 4) )).
test(count_prints_nothing, ( with_output_to(string(Out), q1:count_solutions([1], _)),
                             Out == "" )).
test(clue_9_true_in_the_kept_solution, ( world(b, W), as_solution(W, S), q1:clue(9, S) )).
test(clue_9_false_in(Id), ( as_solution(W, S), q1_has_clue(9), \+ q1:clue(9, S) )) :-
    member(Id, [a,c]), world(Id, W).
test(clue_9_comment_directly_above, clue_9_comment(_)).
test(clue_9_names_no_friend, ( clue_9_comment(Comment), clue_9_is_nameless(Comment) )).
test(main_prints_one_solution, main_prints_a_solution).
test(loads_silently, ( code_file(F), swipl(['-q','-f',F,'-g',true,'-t',halt], exit(0), "", "") )).
test(uses_nothing_forbidden, uses_nothing_forbidden).

% q1_defined(+Spec)
%   Declarative reading: the solution defines the predicate Spec.
q1_defined(Name/Arity) :-
    functor(Head, Name, Arity),
    predicate_property(q1:Head, defined).

% q1_has_clue(+N)
%   Declarative reading: the solution source contains a clause for clue N.
q1_has_clue(N) :-
    code_file(File),
    read_file_to_terms(File, Terms, []),
    member((clue(M, _) :- _), Terms),
    M == N.

% clue_9_comment(-Comment)
%   Declarative reading: Comment is the "% CLUE 9:" line directly above clue(9, ...).
clue_9_comment(Comment) :-
    code_file(File),
    read_file_to_string(File, Text, []),
    split_string(Text, "\n", "", Lines),
    append(_, [Comment, Head|_], Lines),
    sub_string(Head, 0, _, _, "clue(9,"),
    sub_string(Comment, 0, _, _, "% CLUE 9:").

% clue_9_is_nameless(+Comment)
%   Declarative reading: neither Comment nor the clause of clue 9 mentions a friend.
clue_9_is_nameless(Comment) :-
    code_file(File),
    read_file_to_terms(File, Terms, []),
    member((clue(N, _) :- Body), Terms),
    N == 9,
    Names = ['Alex','Ben','Carla','Dana'],
    forall(member(Name, Names),
           ( \+ sub_string(Comment, _, _, _, Name),
             \+ ( sub_term(Part, Body), Part == Name ) )).

% main_prints_a_solution
%   Declarative reading: the grader's command prints exactly one of the three solutions.
main_prints_a_solution :-
    code_file(File),
    swipl(['-q','-f',File,'-g',main,'-t',halt], exit(0), Out, ""),
    member(Id, [a,b,c]),
    world(Id, W),
    as_solution(W, S),
    with_output_to(string(Expected),
        forall(member(p(N,D,L,P), S), format("~w = [~w, ~w, ~w]~n", [N,D,L,P]))),
    Out == Expected.

% uses_nothing_forbidden
%   Declarative reading: the solution source has no banned predicate, directive or library.
uses_nothing_forbidden :-
    code_file(File),
    read_file_to_terms(File, Terms, []),
    Banned = [assert,asserta,assertz,retract,retractall,abolish,b_setval,nb_setval,
              nb_linkval,recorda,recordz,flag,set_flag,table,halt,initialization],
    forall(( member(T, Terms), sub_term(Part, T), callable(Part) ),
           ( functor(Part, Name, _), \+ memberchk(Name, Banned) )),
    forall(member((:- Directive), Terms),
           ( nonvar(Directive), Directive = use_module(library(Lib)),
             memberchk(Lib, [lists,apply,yall,aggregate]) )).

% ---------- harness ----------

% code_file(-File)
%   Declarative reading: File is the one code/*_q1.pl of this repository.
code_file(File) :-
    source_file(code_file(_), This),
    file_directory_name(This, Dir),
    atomic_list_concat([Dir, '/../code/*_q1.pl'], Pattern),
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
    ( code_file(File) -> load_files(q1:File, []) ; true ),
    findall(Name-Result, ( test(Name, Goal), outcome(Goal, Result) ), Results),
    forall(( member(Name-Result, Results), Result \== pass ),
           ( Result = error(_) -> format("ERROR ~q~n", [Name])
           ; format("FAIL  ~q~n", [Name])
           )),
    include([_-pass]>>true, Results, Passed),
    length(Results, Total),
    length(Passed, Count),
    format("P1: ~d of ~d tests passed~n", [Count, Total]),
    Count =:= Total.
