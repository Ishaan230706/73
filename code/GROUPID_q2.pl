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

% apply_op(?Op, +X, +Y, ?Z)
%   Declarative reading: Z is the integer X Op Y. A division exists only if
%   Y is not zero and leaves no remainder.
apply_op(+, X, Y, Z) :-
    Z is X + Y.
apply_op(-, X, Y, Z) :-
    Z is X - Y.
apply_op(*, X, Y, Z) :-
    Z is X * Y.
apply_op(/, X, Y, Z) :-
    Y =\= 0,
    X mod Y =:= 0,
    Z is X // Y.

% expression(+Numbers, -Tree, ?Value)
%   Declarative reading: Tree is an expression over exactly Numbers, in that
%   order, in which every division is exact, and Value is its value.
%   Base case: one number. Otherwise the top operator joins the expressions
%   for the two parts of some split, each a shorter list.
expression([N], num(N), N).
expression(Numbers, node(Op, Left, Right), Value) :-
    split(Numbers, Front, Back),
    expression(Front, Left, X),
    expression(Back, Right, Y),
    apply_op(Op, X, Y, Value).

% precedence(?Op, ?Level)
%   Declarative reading: Op binds at Level. A higher level binds tighter.
precedence(+, 1).
precedence(-, 1).
precedence(*, 2).
precedence(/, 2).

% needs_parentheses(+Side, +ParentOp, +Child)
%   Declarative reading: Child, as the Side operand of ParentOp, is printed in
%   parentheses. No clause matches num(_), so a number never is.
needs_parentheses(left, ParentOp, node(ChildOp, _, _)) :-
    precedence(ParentOp, Parent),
    precedence(ChildOp, Child),
    Child < Parent.
needs_parentheses(right, ParentOp, node(ChildOp, _, _)) :-
    precedence(ParentOp, Parent),
    precedence(ChildOp, Child),
    Child =< Parent.

% bracket(+Side, +ParentOp, +Child, +Text0, -Text)
%   Declarative reading: Text is Text0, the text of Child, with parentheses
%   around it exactly when Child needs them as that operand of ParentOp.
bracket(Side, ParentOp, Child, Text0, Text) :-
    (   needs_parentheses(Side, ParentOp, Child)
    ->  atomics_to_string(["(", Text0, ")"], Text)
    ;   Text = Text0
    ).

% expression_text(+Tree, -Text)
%   Declarative reading: Text is the canonical string of Tree: a number in
%   decimal, or the two operand texts, bracketed as needed, around the operator.
expression_text(num(N), Text) :-
    atomics_to_string([N], Text).
expression_text(node(Op, Left, Right), Text) :-
    expression_text(Left, LeftText0),
    expression_text(Right, RightText0),
    bracket(left, Op, Left, LeftText0, LeftText),
    bracket(right, Op, Right, RightText0, RightText),
    atomics_to_string([LeftText, Op, RightText], Text).

% equation(+Numbers, ?Equation)
%   Declarative reading: Equation is the canonical string L=R for some split
%   of Numbers and some expressions L and R over its parts with equal values.
equation(Numbers, Equation) :-
    split(Numbers, Front, Back),
    expression(Front, Left, Value),
    expression(Back, Right, Value),
    expression_text(Left, LeftText),
    expression_text(Right, RightText),
    atomics_to_string([LeftText, "=", RightText], Text),
    Equation = Text.            % unify afterwards, so a bound atom is not accepted

% generate_equation(+List, ?Equation)
%   Declarative reading: Equation is a valid equation of List. One is given,
%   and there is no answer when List has none.
generate_equation(List, Equation) :-
    once(equation(List, Equation)).

% all_equations(+List, -Equations)
%   Declarative reading: Equations is the set of all valid equations of List,
%   as a list in standard order.
all_equations(List, Equations) :-
    findall(Equation, equation(List, Equation), Found),
    sort(Found, Equations).
