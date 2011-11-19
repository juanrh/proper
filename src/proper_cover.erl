%% Author: juanrh
%% Created: 19/11/2011
%% Description: TODO: Add description to proper_cover
-module(proper_cover).

%%
%% Include files
%%

-include("proper_internal.hrl").

%%
%% Exported Functions
%%
-export([create_cover_tests/1]).

%%
%% Macros
%%
% FIXME: just for the proof-of-concept 
-define(DEFAULT_SIZE, 10) .
-define(DEFAULT_TIMEOUT, 30000) .
-define(EXE_RESULTS_ETS_NAME, exe_results). 

%%
%% API Functions
%%
-type success_exe_return() :: {success, {Input :: [term()], Output :: term()}} .
-type exception_exe_return() :: {exception, {Input :: [term()], Reason :: term()}} .
-type exe_return() :: {mfa(), success_exe_return() | exception_exe_return()} .
% FIXME
-type cover_tests() :: [{mfa(), exe_return()}] .
-spec create_cover_tests(Module :: atom()) ->{ok, cover_tests()} | {timeout, cover_tests()} .  
create_cover_tests(Module) ->
	% TODO: call Dialyzer first in order to get specs for all the functions
	%cover_setup(Module),
	% Setup ets table for execution results
	ets:new(?EXE_RESULTS_ETS_NAME, [named_table]),
	% gets the types for the arguments of the spec'ed functions in Module
	MfaArgsTypesList = proper_types:create_specs_args_types(Module),
	Self = self(), 
	OffspringPids = 
		lists:map(fun({MFA, ArgsTypes}) -> spawn(fun() -> try_input_types(Self, MFA, ArgsTypes) end) end, MfaArgsTypesList), 
	TimeoutTriggered = create_cover_tests_loop(OffspringPids),
	% TODO: create EUnit tests from here
	Result = ets:tab2list(?EXE_RESULTS_ETS_NAME),
	% Tear down ets table for execution results
	ets:delete(?EXE_RESULTS_ETS_NAME),
	%cover_report(Module), 
	case TimeoutTriggered of
		no_timeout -> {ok, Result} ;
		timeout -> {timeout, Result}  
	end .

-spec create_cover_tests_loop(OffspringPids :: [pid()]) -> no_timeout | timeout .
create_cover_tests_loop([]) -> no_timeout ;
create_cover_tests_loop(OffspringPids) -> 
	receive
		{Pid, {MfaExecuted, ExeResult}} -> ets:insert(?EXE_RESULTS_ETS_NAME, {MfaExecuted, ExeResult}),
		create_cover_tests_loop(lists:delete(Pid, OffspringPids))
	after
		?DEFAULT_TIMEOUT ->
			% kill remaining processes
			lists:map(fun(Pid) -> exit(Pid, kill) end,  OffspringPids),
			timeout
	end .

-spec try_input_types(From :: pid(), mfa(), ArgsTypes :: [proper_types:type()]) -> ok .  
	% type of the returning message sent to the caller
	%  {mfa, {success, {Input :: [term()], Output :: term()}} | {exception, {Input :: [term()], Reason :: term()}}} .
try_input_types(From, {Mod, Fun, _Ar} = MFA, ArgsTypes) ->
	% TODO: error handling in proper_gen, replacing proper_gen:pick/2 to inprove performance, handling size of generated input
	{ok, SampleInput} = proper_gen:pick(ArgsTypes, ?DEFAULT_SIZE),
	ExeResult = try {MFA, {success, {SampleInput, apply(Mod, Fun, SampleInput)}}} 
					catch Class:Exception -> {MFA, {exception, {SampleInput, {Class, Exception}}}}
				end,
	From ! {self(), ExeResult},
	ok . 

% Cover problems 
% 7> cover:start() .
% {ok,<0.61.0>}
% 8> cover:compile_beam(tests) .
% {ok,tests}
% 9> proper_cover:create_cover_tests(tests) .
% ** exception error: no match of right hand side value 
%                     {error,
%                      {cant_load_code,tests,
%                       {cant_find_object_file,
%                        cant_find_source_file}}}
%      in function  proper_types:create_specs_args_types/1
%      in call from proper_cover:create_cover_tests/1
% 11> cover:stop() .                          
% ok
% 12> proper_cover:create_cover_tests(tests) .
% ... (works without exceptions)
% already reported in http://osdir.com/ml/erlang-questions-programming/2011-06/msg00627.html  
% "PropEr relies on the source if the beam file cannot be found (it can't when it's cover compiled), 
% and it doesn't seem to know about ERL_LIBS or the include paths used. Especially since rebar copies 
% the source file to the .eunit folder, it's harder for PropEr to detect linked source files." 
cover_setup(Module) ->
	cover:start(),
	% cover:compile_module(Module) .
	io:fwrite("Calling cover:compile_beam(~p)", [Module]),
	cover:compile_beam(Module),
	io:fwrite("Exiting from cover_setup/1") .

cover_report(Module) ->
	% FIXME
	io:fwrite("~n~nCover stats:~n"),
	io:fwrite("module stats: ~p", [cover:analyse(Module, coverage, module)]),
	io:fwrite("~nfunction stats: ~p", [cover:analyse(Module, coverage, function)]),
	cover:stop(), 
	io:fwrite("~n~n~n") .

%%
%% Local Functions
%%




% TODO: when using it to generate covers, adding some size stuff in the line of the call to
% global_state_reset(Opts) inside the body of proper:mfa_test/3, to increse the size of the generated
% tests

%%-----------------------------------------------------------------------------
%% Changes in other modules
%%-----------------------------------------------------------------------------
% proper_types
% - added create_spec_args_types/1, create_specs_args_types/1
% proper_typeserver
% - new clause in handle call
% - added create_spec_args_types/1, create_spec_args_types/2
