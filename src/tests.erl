-module(tests) .

%  c(tests, [debug_info]) .
% recargar el codigo compilado por make
% l(proper_typeserver) .   
% l(proper)
%-export([g/1, g2/1, g3/1, h/2, h2/3, append/1, append/2]).
-compile(export_all) .

%%
%% Include files
%%
  % para PropEr
%-include_lib("proper/include/proper.hrl").
% -spec not_specced(any(), any(), any(), any()) -> any().  
not_specced(X, Y, hola, {a, b}) -> {a, Y, X} .

-spec f() -> integer() .
f() -> 0 .

% Testear una spec  
% proper:check_spec({proper_tests,g,1}) .
% proper:numtests(200, proper:check_spec({proper_tests,g,1})) . <-- esto no va pq pq impacientemente evalua el segundo argumento, se hace con:
% proper:check_spec({proper_tests,g,1}, [{numtests, 200}]). 
-spec g(0 | {'hola',_} | {'pepe',string()}) -> any().
g(0) -> 1 ;
g(2) -> 3; % "error" q meti y q no se detecta con check_spec, pq en realidad esto no es un error pq g/1 si que cumple con el contrato de su spec: siempre sabe responder a lo q le dicen y no devuelve cosas de mas (pq puede devolver any()), este es el orden monotono en la entrada antimonotono en la salida. Lo q pasa es q en este ejemplo g/1 es mayor en el orden monotono_in, antimonotono_out
%g({hola, Xs}) -> "adios" ++ Xs; % si se quita esta clausula si q pilla el error de entrada sin cubrir => no cumple en contrato de la spec de atender a esta entrada
g({pepe, X}) -> X .

% proper:check_spec({proper_tests,g2,1}).
-spec g2(0 | 1) -> 0 | 1 .
g2(0) -> 0 ;
g2(1) -> 1 . % si se quita esta clausula error de entrada no cubierta

% proper:check_spec({proper_tests,g3,1}).
-spec g3(0 | 1) -> 0 | 1 .
g3(0) -> 1 ;
g3(1) -> 0 .
% g3(1) -> 2 . % esta clausula da error de salida fuera de la spec

-spec h(integer(), [integer()]) -> ok | {bad, string()} .
h(0, _) -> ok ;
h(X, Xs) -> case length(Xs) > X of
				false -> {bad, "malamente"} ;
				true -> ok
			end . 

-spec append(List1, List2) -> List3 when
      List1 :: [T],
      List2 :: [T],
      List3 :: [T],
      T :: term().

append(L1, L2) -> L1 ++ L2.

%% append(L) appends the list of lists L

-spec append(ListOfLists) -> List1 when
      ListOfLists :: [List],
      List :: [T],
      List1 :: [T],
      T :: term().

append([E]) -> E;
append([H|T]) -> H ++ append(T);
append([]) -> [].

% en la tercera componente me esta devolviendo la lista de argumentos!			
%20> proper_gen:pick(proper:j_spec_test_case({tests,h,2})) .
%WARNING: Some garbage has been left in the process registry and the code server
%to allow for the returned function(s) to run normally. 
%Please run proper:global_state_erase() when done.
%{ok,{forall,[-13,[-1,-3,-10,-3,10,5,-18,4,7,11]],
%            #Fun<proper_typeserver.0.26871082>}}

-spec h2({integer(), string()}, [integer()], {hola, string()}) -> integer() .
h2(X, _Y, _Z) -> X .
%29> proper_gen:pick(proper:j_spec_test_case({tests,h2,3})) .
%WARNING: Some garbage has been left in the process registry and the code server
%to allow for the returned function(s) to run normally. 
%Please run proper:global_state_erase() when done.
%{ok,{forall,[{-3,
%              [608707,384571,874542,596636,844970,
%               329454,235290,765838,1012405,498600]},
%             [10,4,3,-6,1,5],
%             {hola,[238346,1058746,887273,317733,
%                    983162,158345,2157,787676]}],
%            #Fun<proper_typeserver.0.26871082>}}

% de todas formas algo esta mal aqui pq proper:pick/1 deberia ir mejor y devolver valores simples y no dar ese warning sobre la basura
%31> proper_gen:pick(proper_types:int()) .
%{ok,-9}


% Notese que para 
% prop_singleton() ->
% 	?FORALL(X, union([ 1, [1], <<>> ]), X == X) .
% si la llamamos en la consola nos da:
% {forall,{'$type',[{generator,#Fun<proper_types.31.116110946>},
%                   {is_instance,#Fun<proper_types.32.79107777>},
%                   {kind,basic},
%                   {shrinkers,[#Fun<proper_types.33.4996438>,
%                               #Fun<proper_types.34.74840378>]}]},
%         #Fun<cover_gen.0.378323>}
% q es algo de la misma forma que lo q nos da proper:j_spec_test_case({tests,h,2})
% 32> proper:j_spec_test_case({tests,h,2}) .
% {forall,
%  {'$type',
%   [{generator,#Fun<proper_types.52.40509376>},
% â€¦

% NUEVO: parece q vamos bien
%12> proper_gen:pick(proper:create_spec_args_types({tests, g,1})) .
%{ok,[{pepe,[]}]}
%13> proper:create_spec_args_types({tests, g,1}) .
%{'$type',
%    [{generator,#Fun<proper_types.52.40509376>},
%     {get_indices,#Fun<proper_types.54.3141332>},
%     {internal_types,
%         [{'$type',
%              [{generator,
%                   #Fun<proper_types.31.116110946>},
%               {is_instance,
%                   #Fun<proper_types.32.79107777>},
%               {kind,basic},
%               {shrinkers,
%                   [#Fun<proper_types.33.4996438>,
%                    #Fun<proper_types.34.74840378>]}]}]},
%     {is_instance,#Fun<proper_types.53.120017758>},
%     {kind,container},
%     {retrieve,#Fun<lists.nth.2>},
%     {update,#Fun<proper_arith.list_update.3>}]}
%17> proper_gen:pick(proper:create_spec_args_types({tests, g,1})) .
%{ok,[{hola,{<<16,151,240,208,8,0:1>>,
%            {},-16.432167845203523,-3}}]}
%18> proper_gen:pick(proper:create_spec_args_types({tests, g,1})) .
%{ok,[0]}
%20> proper_gen:pick(proper:create_spec_args_types({tests, h,2})) .
%{ok,[22,[7,2,4]]}

% lo mas sorprendente es que es instantaneo: aunque los tipos q esta generando son muy sencillos
% 28> io:fwrite("~p~n", [lists:map(fun(Size) -> element(2, proper_gen:pick(proper_types:create_spec_args_types({tests, h,2}), Size)) end, lists:seq(1, 100))]) .
% esto en cambio ya tarda unos cuantos segundos: se puede optimizar pq usar pick es muy rupestre
% 37> io:fwrite("~p~n", [lists:map(fun(Size) -> element(2, proper_gen:pick(proper_types:create_spec_args_types({tests, append,1}), Size)) end, lists:seq(1, 100))]) .

% [{mfa(), [proper_types:type()]}] 
%  proper:create_specs_args_types(tests) .
test_cover_1() ->
	MfaArgsTypesList = proper_types:create_specs_args_types(tests),
    % TenTests = fun({{Mod, Fun, _Ar}, ArgsTypes}) -> apply(Mod, Fun, element(2, proper_gen:pick(ArgsTypes, 10))) end,
	TenTests = fun({{Mod, Fun, Ar}, ArgsTypes}) -> 
					R =  try apply(Mod, Fun, element(2, proper_gen:pick(ArgsTypes, 10))) 
							catch _:_ -> {error, overapproximation_failure}
						  end,
					{{Mod, Fun, Ar}, R}  
			end,
    Res = lists:map(TenTests, MfaArgsTypesList),
	io:fwrite("~p~n", [Res]) .

% 100> tests:test_cover_1() .
% [{{tests,g,1},{error,overapproximation_failure}},
%  {{tests,append,2},
%   [{},
%    {êl,{[]},{},9.8657602919318,'à\215'},
%    [{},1,{{},['\214¸\211µ\220\217C¹î'],'ùsgá÷'}],
%    [[],'¥',{},-2,{}],
%    [{},'¹/Á\017½','Û\035\231«ÒyïÝ®',14,
%     {[]},
%     8.464066795647838,
%     {{}},
%     'Lc¦',
%     [{<<>>}]],
%    ')î','(8',
%    ['','','åæØE-äôü','\\',-15.755949901910856,'¤iÉxÂ','F^\d',
%     19.58131130624219,-6],
%    <<89,206,15,85,227,28,59,190,30:5>>,
%    {},
%    {-9.137341185741786,4.082754273972165,
%     [0.7591829003611885,'','K',{}],
%     <<83,150,8:5>>,
%     -19.20384746271314,'a6\003q\235\006\023y'},
%    [[-12.405661103768992,[{}],-0.15766764273059652,'ã\223ÕiÄ\tò'],
%     [{}],
%     -13.3653956363964],
%    <<34,2,223,8:4>>,
%    [13,6,'&0­ÊñþW','Îô"','è\231=«ôÈ',2,ú],
%    <<"X">>]},
%  {{tests,f,0},0},
%  {{tests,h,2},{bad,"malamente"}},
%  {{tests,g2,1},1},
%  {{tests,g3,1},0},
%  {{tests,h2,3},{-10,[]}},
%  {{tests,append,1},{error,overapproximation_failure}}]
% ok

% proper_cover:create_cover_tests(tests) .
% 5> proper_cover:create_cover_tests(lists) . 
% works quickly but lots of warnings from proper
% WARNING: Some garbage has been left in the proce