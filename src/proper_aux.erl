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
-export_types([maybe, maybe_state]) .

% more standard idiom for the types rich_result/1 and rich_result/2 from proper_typeserver
% similar to Haskell's Maybe type constructor, but using Erlang usual atoms.
% Haskell's Maybe module could be adapted to Erlang using this idiom
-type maybe(T) :: {ok,T} | {error,term()} . % the term() associated to error is the descripction
-type maybe_state(T,S) :: {ok,T,S} | {error,term()} .

%%
%% Exported Functions
%%
-export([maybe_map/2, m_bind/2, map_while/2]).

%%
%% API Functions
%%

% Maps with unwrapping if everything ok, otherwise returns the first error with its reason
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

% type to be augmented in future overloading.
	% corresponds to Haskell's bind operator (>>=) implementation for Maybe
-spec m_bind(maybe(T), fun((T) -> maybe(T))) -> maybe(T) when T :: term().
m_bind({error, _Reason} = Error, _F) -> Error;
m_bind({ok, X}, F) -> F(X) .

% Note the first element that doesn't pass the tests is also included in the returning list!
-spec map_while(F:: fun((A) -> {boolean(), B}), Xs :: [A]) -> Ys :: [B] when A :: term(), B :: term() .
map_while(_F, []) -> [] ;
map_while(F, [X | Xs]) ->
	{Continue, ResX}  = F(X),
 	case Continue of
		true -> [ResX | map_while(F, Xs)];
		_ -> [ResX]
	end .


