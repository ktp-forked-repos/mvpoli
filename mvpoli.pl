% 5 * x ^ 6: * y ^ 3
% as_monomial(C, X) :- C \= X, atomic(X).


as_polynomial(X, poly(P)) :-
  as_polynomial_p(X, P).

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

as_monomial_i(X, m(OC, TD, Vs)) :-
  as_monomial_p(X, C, Vs),
  OC is -C,
  td(Vs, TD).

as_monomial(X, m(C, TD, Vs)) :-
  as_monomial_p(X, C, Vs),
  td(Vs, TD).

as_monomial_p(X * Y, C, [V | Vs]) :-
  as_monomial_p(X, C, Vs),
  !,
  asvar(Y, V).
as_monomial_p(X, X, []) :-
  number(X),
  !.
as_monomial_p(X, 1, [V]) :-
  asvar(X, V).

asvar(X ^ N, v(N, X)) :-
  integer(N),
  !,
  N >= 0.
asvar(X ^ N, v(N, X)) :-
  atom(N),
  !.
asvar(X, v(1, X)) :-
  atom(X).

td([v(N1, _) | Vs], N) :-
  td(Vs, N2),
  !,
  N is N1+N2.

td([v(N1, _)], N1).

test(X * Y, X, Y).
