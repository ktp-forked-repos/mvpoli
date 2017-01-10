%%%%% -*- Mode: Prolog -*-

%%%%% mvpoli.pl --
%%%%% 793307 Trovato Gaetano
%%%%% 793509 Vivace Antonio
%
% TODO
% fix mindegree/maxdegree
% unwanted backtracking on test #2
%
% PARSING %

%%%% as_polynomial(+Expression, -Poly)
%% True when poly(Monomials) unifies with the internal representation
%% of the normalised polynomial.
%
as_polynomial(Input, poly(Monomials)) :-
  as_polynomial_p(Input, RawMonomials),
  norm_p(RawMonomials, Monomials).

%%%% as_monomial(+Expression, -Monomial)
%% True when Monomial unifies with the internal representation
%% of the normalised monomial.
%
as_monomial(Input, Monomial) :-
  as_monomial_p(Input, C, Vd),
  td(Vd, TD),
  norm_m(m(C, TD, Vd), Monomial).

%%%% as_monomial_i(-Mono1, +Mono2)
%% True when Mono1 unifies with the opposite of Mono2.
%
as_monomial_i(X, m(OC, TD, Vs)) :-
  as_monomial_p(X, C, Vs),
  OC is -C,
  td(Vs, TD).

%%%% as_polynomial_p(+Expression, -Monomials)
%% True when Monomials unifies with the list of the Input
%% monomials.
%
as_polynomial_p(X + Y, [M | Ms]) :-
  as_monomial(Y, M),
  !,
  as_polynomial_p(X, Ms).

as_polynomial_p(X - Y, [M | Ms]) :-
  as_monomial_i(Y, M),
  !,
  as_polynomial_p(X, Ms).

as_polynomial_p(X, [M]) :-
  as_monomial(X, M).

as_monomial_p(X, X, []) :-
  number(X),
  !.

as_monomial_p(X * Y, C, [V | Vs]) :-
  as_monomial_p(X, C, Vs),
  !,
  as_var(Y, V).

as_monomial_p(-X, -1, [V]) :-
  !,
  as_var(X, V).

as_monomial_p(X, 1, [V]) :-
  as_var(X, V).

%%%% as_var(+Expression, -Var)
%% True when Var unifies with v(N, X) where N is the exponent and
%% X the atom representing the variable.
%
as_var(X ^ N, v(N, X)) :-
  integer(N),
  !,
  N >= 0.

as_var(X ^ N, v(N, X)) :-
  atom(N),
  !.

as_var(X, v(1, X)) :-
  atom(X).

%%%% td(+VarList, -N)
%% True when N unifies with the sum of the grade of
%% every variable in VarList
%
td([v(N1, _) | Vs], N) :-
  td(Vs, N2),
  !,
  N is N1+N2.

td([v(N1, _)], N1) :- !.

td([], 0).

% NORMALISATION %

%%%% norm_m(+Mono1, -Mono2)
%% True when Mono2 unifies with Mono1 normalised.
%
norm_m(m(C, Td, []), m(C, Td, [])) :- !.
norm_m(m(0, _, _), m(0, 0, [])) :- !.
norm_m(m(C, 0, _), m(C, 0, [])) :- !.

norm_m(m(C, G, X), m(C, G, O)) :-
  sort(2, @=<, X, SX),
  norm_mm(SX, O).

%%%% norm_mm(+VarList1, -VarList2)
%% True when VarList2 unifies with VarList1 simplified.
%
norm_mm([v(0, X) | Ms], MMs) :-
  !,
  norm_mm(Ms, MMs).

norm_mm([v(C1, X) , v(C2, X) | Ms], MMs) :-
  !,
  C3 is C1+C2,
  norm_mm([v(C3,X) | Ms] , MMs).

norm_mm([v(C1, X), v(C2, Y) | Ms], [v(C1,X) | MMs]) :-
  !,
  X \= Y,
  norm_mm([v(C2,Y) | Ms], MMs).

norm_mm([v(C1, X)], [v(C1,X)]).

%%%% norm_p(+Monomials, -NSMonomials)
%% True when NMonomials unifies with the list of normalised
%% and sorted Monomials.
%
norm_p(Monomials, NSMonomials) :-
  predsort(sort_m, Monomials, SMonomials),
  norm_pp(SMonomials, PMonomials),
  norm_ms(PMonomials, NSMonomials).

norm_ms([m(C, Td, Vars)], [NMonomial]) :-
  !,
  norm_m(m(C, Td, Vars), NMonomial).

norm_ms([m(C, Td, Vars) | Ms], [NMonomial | NMs]) :-
  norm_m(m(C, Td, Vars), NMonomial),
  norm_ms(Ms, NMs).

%%%% norm_pp(+Monomials, -SMonomials)
%% True when SMonomials unifies with the list of simplyfied Monomials.
%
norm_pp([m(C, Td, Vs), m(0, _, _) | Ms], MMs) :-
  !,
  norm_pp([m(C, Td, Vs) | Ms], MMs).

norm_pp([m(0, _, _), m(C, Td, Vs) | Ms], MMs) :-
  !,
  norm_pp([m(C, Td, Vs) | Ms], MMs).

norm_pp([m(C1, Td, Vs), m(C2, _, Vs) | Ms], MMs ) :-
  !,
  C3 is C1+C2,
  norm_pp([m(C3, Td, Vs) | Ms], MMs).

norm_pp([m(C1, S1, Vs1), m(C2, S2, Vs2) | Ms], [m(C1, S1, Vs1) | MMs]) :-
  !,
  Vs1 \= Vs2,
  norm_pp([m(C2, S2, Vs2) | Ms], MMs).

norm_pp([m(C, Td, Vs)], [m(C, Td, Vs)]).

% SORTING %

sort_m(>, m(_, Td1, _), m(_, Td2, _)) :-
  Td1 > Td2,
  !.

sort_m(<, m(_, Td1, _), m(_, Td2, _)) :-
  Td1 < Td2,
  !.

sort_m(>, m(_, Td1, Vars1), m(_, Td1, Vars2)) :-
  sort_disparity(Vars2, Vars1),
  !.

sort_m(<, m(_, Td1, Vars1), m(_, Td1, Vars2)) :-
  sort_disparity(Vars1, Vars2),
  !.

sort_disparity([v(_,Var1) | Vars1], [v(_,Var1) | Vars2]) :-
  !,
  sort_disparity(Vars1, Vars2).

sort_disparity([v(_,Var1) | _], [v(_,Var2) | _]) :-
  msort([Var1, Var2], [Var1, Var2]),
  !.

sort_disparity([], []) :- !.
sort_disparity([], _) :- !.

% CHECKING %

%%%% is_monomial(+Monomial)
%% True when Monomial is a valid Monomial (internal representation).
%
is_monomial(m(_, TD, VPs)) :-
  integer(TD),
  TD >= 0,
  is_list(VPs).

%%%% is_varpower(+Var)
%% True when Var is a valid Variable (internal representation).
%
is_varpower(v(Power, VarSymbol)) :-
  integer(Power),
  Power >= 0,
  atom(VarSymbol).

%%%% is_polynomial(+Polynomial)
%% True when Polynomial is a valid Polynomial (internal representation).
%
is_polynomial(poly(Monomials)) :-
  is_list(Monomials),
  foreach(member(M, Monomials), is_monomial(M)).

% PRINTING %

%%%% pprint_polynomial(+Poly)
%% True when the Prolog interpreter succeds to print a human representation
%% of Poly.
%
pprint_polynomial(Arg) :-
  as_valid(Arg, Argv),
  pprint_polynomial_v(Argv).

pprint_polynomial_v(poly(L)) :-
  !,
  pprint_pp(L).

pprint_pp(m(0, _, _)) :-
  !,
  write(0).

pprint_pp([m(A, B, C)]) :-
  !,
  pprint_m(m(A, B, C)).

pprint_pp([M | Ms]) :-
  !,
  pprint_m(M),
  write(' + '),
  pprint_pp(Ms).

pprint_m(m(C, _, [])) :-
  !,
  write(C).

pprint_m(m(1, _, L)) :-
  !,
  pprint_mm(L).

pprint_m(m(-1, _, L)) :-
  !,
  write('-'),
  pprint_mm(L).

pprint_m(m(X, 0, [])) :-
  !,
  write(X).

pprint_m(m(X, _, L)) :-
  write(X),
  write(' * '),
  pprint_mm(L).

pprint_mm([L]) :-
  as_var(_, L),
  !,
  pprint_v(L).

pprint_mm([L | Ls]) :-
  !,
  pprint_v(L),
  write(' * '),
  pprint_mm(Ls).

pprint_v(v(1, Y)) :-
  !,
  upcase_atom(Y, Yc),
  write(Yc).

pprint_v(v(X, Y)) :-
  upcase_atom(Y, Yc),
  write(Yc),
  write('^'),
  write(X).

% OPERATIONS %

%%%% coefficients(+Poly, -Cofficients)
%% True when Coefficients unifies with the list of every monomial coefficient
%% of Poly.
%

coefficients(Arg, C) :-
  as_valid(Arg, poly(Ms)),
  coefficients_l(Ms, C).

coefficients_l([], []) :- !.

coefficients_l([m(C, _, _)], [C]) :- !.

coefficients_l([m(C, _, _) | Ms], [C | Cs]) :-
  coefficients_l(Ms, Cs).

%%%% variables(+Poly, -Vars)
%% True when Vars unifies with the list of every Variable in Poly in a
%% lexicographical order. Duplicates are removed (the highest 
%% grade is kept).
%

variables(Arg, Vars) :-
  as_valid(Arg, Argv),
  variables_v(Argv, Vars).

variables_v(poly(P), Vars) :-
  variables_ao(poly(P), AOVars),
  sort(0, @=<, AOVars, Vars).

%%%% variables_ao(+Poly, -Vars)
%% True when Vars unifies with the list of every Variable in Poly in the
%% Appearing Order. Duplicates are removed (the highest 
%% grade is kept).
% 
variables_ao(poly(Ms), Vars) :-
  variables_m(Ms, Cd),
  list_to_set(Cd, Vars).

variables_m([m(_, _, [])], []) :- !.

variables_m([m(_, _, Vars)], V):-
  !,
  variables_vars(Vars, V).

variables_m([m(_, _, Vars) | Ms], R) :-
  variables_vars(Vars, V),
  variables_m(Ms, Vs),
  append(V, Vs, R).

variables_vars([], []).
variables_vars([v(_, N)], [N]) :- !.
variables_vars([v(_, N) | Vs], [N | Ns]) :-
  variables_vars(Vs, Ns).

%%%% monomials(+Poly, -Monomials)
%% True when Monomials unifies with the list of every monomail in Poly.
% 
monomials(poly(Ms), Ms) :- !.

% Accept an Expression, too
monomials(Expression, Ms) :-
  as_polynomial(Expression, Poly),
  monomials(Poly, Ms).

%%%% maxdegree(+Poly, -MaxD)
%% True when MD unifies with the maximum degree of the monomials in Poly.
%
maxdegree(poly([m(0, _, _)]), 0) :- !.
maxdegree(poly([]), 0) :- !.

maxdegree(poly([m(_, MaxD, _) | _]), MaxD) :- !.

% Accept an Expression, too
maxdegree(Expression, MaxDegree) :-
  as_polynomial(Expression, Poly),
  maxdegree(Poly, MaxDegree).

%%%% mindegree(+Poly, -MinD)
%% True when MD unifies with the minimum degree of the monomials in Poly.
%
mindegree(poly([m(0, _, _)]), 0) :- !.
mindegree(poly([]), 0) :- !.

mindegree(poly(Ms), MinD) :-
  !,
  reverse(Ms, ([m(_, MinD, _) | _])).

% Accept an Expression, too
mindegree(Expression, MinDegree) :-
  as_polynomial(Expression, Poly),
  mindegree(Poly, MinDegree).

%%%% polyplus(+P1, +P2, -Sum)
%% True when Sum unifies with the polynomial sum of P1 and P2.
%
% 0 is neutral for polyplus
polyplus_v(P1, poly([m(0, _, _)]), P1) :- !.
polyplus_v(poly([m(0, _, _)]), P1, P1) :- !.
polyplus_v(P1, poly([]), P1) :- !.
polyplus_v(poly([]), P1, P1) :- !.
polyplus_v(poly(P1), poly(P2), poly(P3)) :-
  !,
  append(P1, P2, P3o),
  norm_p(P3o, P3).



% polyplus accepts monomials too, as arguments.
polyplus(Arg1, Arg2, Result) :-
  as_valid(Arg1, Arg1v),
  as_valid(Arg2, Arg2v),
  polyplus_v(Arg1v, Arg2v, Result).



as_valid(poly(P1), poly(P1)) :- !.
as_valid(m(C, Td, Vars), poly([m(C, Td, Vars)])) :- !.
as_valid(Expression, P) :-
  !,
  as_polynomial(Expression, P).
%%%% polyminus(+P1, +P2, -Diff)
%% True when Diff unifies with the polynomial difference of P1 and P2.
%
polyminus(Arg1, Arg2, Result) :-
  as_valid(Arg1, Arg1v),
  as_valid(Arg2, Arg2v),
  poly_i(Arg2v, Arg2i),
  polyplus(Arg1v, Arg2i, Result).

poly_i(poly(Ms), poly(IMs)) :-
  poly_ii(Ms, IMs).

poly_ii([ M | Ms], [OM | OMs] ) :-
  monomial_i(M, OM),
  poly_ii(Ms, OMs).

poly_ii([M], [Om]) :-
  monomial_i(M, Om).

monomial_i(m(C, G, Vars), m(Ci, G, Vars)) :-
  Ci is -C.

%%%% monotimes(+Mono1, +Mono2, -MonoProduct)
%% True when MonoProduct unifies with the monomial product 
%% of Mono1 and Mono2.
%
monotimes(m(C1, Td1, Vars1), m(C2, Td2, Vars2), m(C3, Td3, Vars3n)) :-
  C3 is C1 * C2,
  Td3 is Td1 + Td2,
  append(Vars1, Vars2, Vars3),
  norm_m(m(C3, Td3, Vars3), m(C3, Td3, Vars3n)).

%%%% polytimes(+Poly1, +Poly2, -PolyProduct)
%% True when PolyProduct unifies with the polynomial product 
%% of Poly1 and Poly2
%
polytimes(Arg1, Arg2, Result) :-
  as_valid(Arg1, Arg1v),
  as_valid(Arg2, Arg2v),
  polytimes_v(Arg1v, Arg2v, Result).

% 0 is absorbing for polytimes
polytimes_v(_, poly([m(0, _, _)]), poly([m(0, 0, [])])) :- !.
polytimes_v(poly([m(0,_, _)]), _, poly([m(0, 0, [])])) :- !.
polytimes_v(_, poly([]), poly([m(0, 0, [])])) :- !.
polytimes_v(poly([]), _, poly([m(0, 0, [])])) :- !.

% 1 is neutral for polytimes
polytimes_v(A, poly([m(1, _, [])]), A) :- !.
polytimes_v(poly([m(1, _, [])]), A, A) :- !.

polytimes_v(poly(M1s), poly(M2s), poly(ResultN)) :-
  !,
  polytimes_m(M1s, M2s, Result),
  flatten(Result, ResultF),
  norm_p(ResultF, ResultN).

polytimes_m(M1s, [m(C, Td, Vars)], R) :-
  !,
  polymono(M1s, m(C, Td, Vars), R).

polytimes_m(M1s, [M2 | M2s], [R | Rs]) :-
  polymono(M1s, M2, R),
  polytimes_m(M1s, M2s, Rs).

%%%% polymono(+Poly, +Mono, -PMProduct)
%% True when PMProduct unifies with the polynomial product of 
%% polynomial Poly and monomial Mono.
%
polymono([m(C1, Td1, Vars1)], m(C2, Td2, Vars2), R) :-
  !,
  monotimes(m(C1, Td1, Vars1), m(C2, Td2, Vars2), R).

polymono([M | Ms], M2, [R | Rs]) :-
  monotimes(M, M2, R),
  polymono(Ms, M2, Rs).


%%%% polyval(+Poly, +Values, -Result)
%% True when Result unifies with the computation of Poly using Values
%% for the variables appearing in Poly.
%% Values is a list of integers associating with the list variables
%% (lexicographical order).
%
polyval(Arg, InputValues, Result) :-
  as_valid(Arg, Argv),
  polyval_v(Argv, InputValues, Result).

polyval_v(poly(P1), InputValues, Result) :-
  !,
  vvList(poly(P1), InputValues, VVList),
  variables_ao(poly(P1), AOVars),
  getVValues(VVList, AOVars, AOVVars),
  stripValues(AOVVars, AOInputValues),
  with_output_to(string(PPoly), pprint_polynomial(poly(P1))),
  term_string(Term, PPoly, [variables(AOInputValues)]),
  Result is Term.

%%%% vvList(+Poly, +Values, -VarValues)
%% True when VarValues unifies with a list of (Var, Value) pairs.
%
vvList(Poly, Values, VarValues) :-
  variables(Poly, Vars),
  vvList_m(Vars, Values, VarValues).

vvList_m([Var], [Value], [(Var, Value)]) :-
  atom(Var),
  !.

vvList_m([Var | Vars], [Value | Values], [(Var, Value) | VarValues]) :-
  vvList_m(Vars, Values, VarValues).

%%%% getVValues(+VVList, +Variables, -ReorderedVVList)
%% True when ReorderedVVList unifies with a reordered version of VVList,
%% where VVList is a list of (Var, Value) pairs.
% 
getVValues(VVList, [Var], [(Var, Value)]) :-
  atom(Var),
  !,
  getValue(Var, VVList, Value).

getVValues(VVList, [Var | AOVars], [(Var, Value) | AOVVars]) :-
  getValue(Var, VVList, Value),
  getVValues(VVList, AOVars, AOVVars).

getValue(Var, [(Var, Value) | _], Value) :- !.
getValue(Var, [(_, _) | VVList], Value) :-
  getValue(Var, VVList, Value).

stripValues([(_, Value)], [Value]) :- !.
stripValues([(_, Value) | VValues], [Value | Values]) :-
  stripValues(VValues, Values).

%%%%% end of file -- mvpoli.pl --
