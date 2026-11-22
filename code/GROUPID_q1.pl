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
