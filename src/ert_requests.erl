-module(ert_requests).




%%

-export([do/5
        ,build_qs/2]).

-compile({parse_transform, lager_transform}).

do(Method, Url, Path, Headers, Body) ->
    {ok, Status, _RespHeaders, Client}
        = hackney:request(Method, <<Url/binary, Path/binary>>,
                          Headers,
                          Body, []),
    lager:info("at=do method=~p path=~s status=~p", [Method, Path, Status]),
    {ok, Result, _Client1} = hackney:body(Client),
    Result.

build_qs(Options, OptionalParams) ->
    list_to_binary(string:join(lists:foldl(fun({Name, Value}, QS) ->
                                                   [case proplist:get_value(Name, OptionalParams) of
                                                        undefined ->
                                                            [];
                                                        {Name, string} ->
                                                            io_lib:format("~p=~s", [Name, Value]);
                                                        {Name, integer} ->
                                                            io_lib:format("~p=~i", [Name, Value])
                                                    end | QS]
                                           end, [], Options), "&")).
