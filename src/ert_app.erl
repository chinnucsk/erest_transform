%%%-------------------------------------------------------------------
%%% @author Tristan Sloughter <tristan@heroku.com>
%%% @copyright (C) 2013, Tristan Sloughter
%%% @doc
%%%
%%% @end
%%% Created : 9 Sep 2013 by Tristan Sloughter <tristan@heroku.com>
%%%-------------------------------------------------------------------
-module(ert_app).

-behaviour(application).

%% Application callbacks
-export([start/0, start/2, stop/1]).

%%%===================================================================
%%% Application callbacks
%%%===================================================================

start() ->
    start_deps(ert, permanent).

start_deps(App, Type) ->
    case application:start(App, Type) of
        ok ->
            ok;
        {error, {not_started, Dep}} ->
            start_deps(Dep, Type),
            start_deps(App, Type)
    end.

start(_StartType, _StartArgs) ->
    egc_sup:start_link().

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%%===================================================================
%%% Internal functions
%%%===================================================================
