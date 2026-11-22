% P2: Form a Valid Arithmetic Equation.
%
% An expression is a tree, either num(N) or node(Op, Left, Right). Trees are
% generated together with their integer values, so an invalid division is
% pruned as soon as it is formed. Text is produced only for equations that
% have been found, and is never read back.

:- use_module(library(lists)).

% split(+List, -Front, -Back)
%   Declarative reading: Front and Back are non-empty and List is Front
%   followed by Back. So both are strictly shorter than List.
split(List, [F|Front], [B|Back]) :-
    append([F|Front], [B|Back], List).
