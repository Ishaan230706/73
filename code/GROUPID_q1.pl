% P1: Department Assignment Puzzle, Reloaded.
%
% A solution is a list of four terms p(Name, Dept, Lang, Project), in the order
% Alex, Ben, Carla, Dana. Solutions are found by generating every legal
% assignment and keeping those in which the chosen clues hold.

:- use_module(library(lists)).

% values(?Attribute, ?Values)
%   Declarative reading: Values lists every possible value of Attribute.
values(name,       ['Alex', 'Ben', 'Carla', 'Dana']).
values(department, [research, development, design, testing]).
values(language,   [python, java, 'c++', javascript]).
values(project,    ['AI', web, embedded, data]).

% assemble(+Names, +Depts, +Langs, +Projects, -Solution)
%   Declarative reading: the i-th term of Solution is p/4 of the i-th elements
%   of Names, Depts, Langs and Projects, which all have the same length.
assemble([], [], [], [], []).
assemble([Name|Names], [Dept|Depts], [Lang|Langs], [Project|Projects],
         [p(Name, Dept, Lang, Project)|People]) :-
    assemble(Names, Depts, Langs, Projects, People).

% candidate(-Solution)
%   Declarative reading: Solution gives the four friends, in their fixed order,
%   a different department, language and project each.
candidate(Solution) :-
    values(name, Names),
    values(department, AllDepts),
    values(language, AllLangs),
    values(project, AllProjects),
    permutation(AllDepts, Depts),
    permutation(AllLangs, Langs),
    permutation(AllProjects, Projects),
    assemble(Names, Depts, Langs, Projects, Solution).

% clue(?N, +Solution)
%   Declarative reading: clue number N holds in the fully filled-in Solution.
%   Values are unique within an attribute, so memberchk/2 finds the one friend
%   that a description picks out, and each clue succeeds at most once.

% Clue 1: The friend who prefers the AI project does not work in research and is not Dana.
clue(1, Solution) :-
    memberchk(p(Name, Dept, _, 'AI'), Solution),
    Dept \== research,
    Name \== 'Dana'.
% Clue 2: Alex does not work in development and does not prefer C++.
clue(2, Solution) :-
    memberchk(p('Alex', Dept, Lang, _), Solution),
    Dept \== development,
    Lang \== 'c++'.
% Clue 3: The friend working in the testing department likes Python.
clue(3, Solution) :-
    memberchk(p(_, testing, python, _), Solution).
% Clue 4: Ben prefers web projects and does not work in testing.
clue(4, Solution) :-
    memberchk(p('Ben', Dept, _, web), Solution),
    Dept \== testing.
% Clue 5: The friend whose favorite language is Java works in the design department.
clue(5, Solution) :-
    memberchk(p(_, design, java, _), Solution).
% Clue 6: Carla's project preference is not embedded, and her department is not development.
clue(6, Solution) :-
    memberchk(p('Carla', Dept, _, Project), Solution),
    Project \== embedded,
    Dept \== development.
% Clue 7: Dana's favorite language is not Java, and she works in research or testing.
clue(7, Solution) :-
    memberchk(p('Dana', Dept, Lang, _), Solution),
    Lang \== java,
    memberchk(Dept, [research, testing]).
% Clue 8: The friend who prefers data projects works in research and does not use JavaScript.
clue(8, Solution) :-
    memberchk(p(_, research, Lang, data), Solution),
    Lang \== javascript.

% solution(+Active, -Solution)
%   Declarative reading: Solution is a legal assignment in which there is no
%   clue numbered in Active that does not hold. Other clues play no part.
solution(Active, Solution) :-
    candidate(Solution),
    forall(member(N, Active), clue(N, Solution)).

% print_person(+Person)
%   Declarative reading: always true of a p/4 term. As its only effect it
%   writes that term as the line "Name = [Dept, Lang, Project]".
print_person(p(Name, Dept, Lang, Project)) :-
    format("~w = [~w, ~w, ~w]~n", [Name, Dept, Lang, Project]).

% main
%   Declarative reading: clues 1 to 8 have a solution. The first one found is printed.
main :-
    once(solution([1, 2, 3, 4, 5, 6, 7, 8], Solution)),
    forall(member(Person, Solution), print_person(Person)).

% count_solutions(+Active, ?N)
%   Declarative reading: exactly N legal assignments satisfy the clues numbered
%   in Active, ignoring all other clues.
count_solutions(Active, N) :-
    findall(Solution, solution(Active, Solution), Solutions),
    length(Solutions, N).
