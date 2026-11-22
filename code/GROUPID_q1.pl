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
