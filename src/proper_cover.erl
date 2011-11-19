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
	% Setup ets table for execution results
	ets:new(?EXE_RESULTS_ETS_NAME, [named_table]),
	% gets the types for the arguments of the spec'ed functions in Module
	MfaArgsTypesList = proper_types:create_specs_args_types(Module),
    OffspringPids = lists:map(fun({MFA, ArgsTypes}) -> spawn(?MODULE, fun try_input_types/3, [self(), MFA, ArgsTypes]) end, MfaArgsTypesList),
	receive
		{MfaExecuted, ExeResult} -> ets:insert(?EXE_RESULTS_ETS_NAME, {MfaExecuted, ExeResult})
	after
		?DEFAULT_TIMEOUT ->
			% kill remaining processes
			lists:map(fun(Pid) -> exit(Pid, kill) end,  OffspringPids),
			% records the timeout, works because 'timeout' is always different to any mfa()
			ets:insert(?EXE_RESULTS_ETS_NAME, {timeout, true})
	end,
	TimeoutTriggered = 
		case ets:lookup(?EXE_RESULTS_ETS_NAME, timeout) of
			[] -> false ;
			_ -> true
		end,
	ets:delete(?EXE_RESULTS_ETS_NAME, timeout),
	% TODO: create EUnit tests from here
	Result = ets:tab2list(?EXE_RESULTS_ETS_NAME),
	% Tear down ets table for execution results
	ets:delete(?EXE_RESULTS_ETS_NAME),
	case TimeoutTriggered of
		false -> {ok, Result} ;
		true -> {timeout, Result}  
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
	From ! ExeResult,
	ok . 

% 	MfaArgsTypesList = proper_types:create_specs_args_types(tests),
% -spec create_specs_args_types(Module :: atom()) -> [{mfa(), [proper_types:type()]}] .


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
