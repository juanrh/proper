%% Author: juanrh
%% Created: 21/11/2011
%% Description: TODO: Add description to proper_aux
-module(proper_aux).

%%
%% Include files
%%

%%
%% Types
%%
-export_type([maybe/1, maybe_state/2]) .

% more standard idiom for the types rich_result/1 and rich_result/2 from proper_typeserver
% similar to Haskell's Maybe type constructor, but using Erlang usual atoms.
% Haskell's Maybe module could be adapted to Erlang using this idiom
-type maybe(T) :: {ok,T} | {error,term()} . % the term() associated to error is the descripction
-type maybe_state(T,S) :: {ok,T,S} | {error,term()} .

%%
%% Exported Functions
%%
-export([maybe_map/2, m_bind/2, map_while/2, cat_maybes/1, filter_map/3, is_ok/1, is_error/1, from_ok/1]).

%%
%% API Functions
%%

% type to be augmented in future overloading.
	% corresponds to Haskell's bind operator (>>=) implementation for Maybe
-spec m_bind(maybe(T), fun((T) -> maybe(T))) -> maybe(T) when T :: term().
m_bind({error, _Reason} = Error, _F) -> Error;
m_bind({ok, X}, F) -> F(X) .

-spec is_ok(maybe(term())) -> boolean() .
is_ok({ok, _}) -> true;
is_ok({error, _}) -> false .

-spec is_error(maybe(term())) -> boolean() .
is_error({ok, _}) -> false;
is_error({error, _}) -> true .

-spec from_ok(maybe(T)) -> T when T :: term() .
from_ok({ok, X}) -> X ;
from_ok({error, _}) -> throw(from_ok_1_applied_to_error) .

% Maps with unwraping if everything ok, otherwise returns the first error with its reason
% Not to be confused with Haskell's mapMaybe
-spec maybe_map(F :: fun((A) -> maybe(B)), Xs :: [A]) -> Ys :: maybe([B]) when A :: term(), B :: term() .
maybe_map(F, Xs) -> maybe_map_acc(Xs, F, []).
-spec maybe_map_acc(Xs :: [A], F :: fun((A) -> maybe(B)), [B]) -> Ys :: maybe([B]) when A :: term(), B :: term() .
maybe_map_acc([], _F, Acc) -> {ok, lists:reverse(Acc)} ;
maybe_map_acc([X | Xs], F, Acc) ->
	case (F(X)) of
		{ok, ResX} -> maybe_map_acc(Xs, F, [ResX| Acc]);
		{error, _Reason} = Error -> Error 
	end.

% Note the first element that doesn't pass the tests is also included in the returning list!
-spec map_while(F:: fun((A) -> {boolean(), B}), Xs :: [A]) -> Ys :: [B] when A :: term(), B :: term() .
map_while(_F, []) -> [] ;
map_while(F, [X | Xs]) ->
	{Continue, ResX}  = F(X),
 	case Continue of
		true -> [ResX | map_while(F, Xs)];
		_ -> [ResX]
	end .

% Erlang's version of Haskell's catMaybes: filters the errors from the input 
% list and unwraps succesful values 
-spec cat_maybes([maybe(T)]) -> [T] when T :: term() . 
cat_maybes(Xs) -> [X || {ok, X} <- Xs] .

-spec filter_map(FilterFun :: fun((A) -> boolean()), MapFun :: fun((A) -> B), Xs :: [A]) 
	-> [B] when A :: term(), B :: term().
filter_map(FilterFun, MapFun, Xs) -> filter_map_acc(Xs, FilterFun, MapFun, []) .
-spec filter_map_acc(Xs :: [A], FilterFun :: fun((A) -> boolean()), MapFun :: fun((A) -> B), Acc :: [B]) 
	-> [B] when A :: term(), B :: term().
filter_map_acc([], _FilterFun, _MapFun, Acc) -> lists:reverse(Acc) ;
filter_map_acc([X|Xs], FilterFun, MapFun, Acc) ->
	case FilterFun(X) of 
		true -> filter_map_acc(Xs, FilterFun, MapFun, [MapFun(X)|Acc]) ;
		false ->  filter_map_acc(Xs, FilterFun, MapFun, Acc)
	end .