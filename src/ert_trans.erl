-module(ert_trans).

-export([parse_transform/2]).

-compile({parse_transform, parse_trans_codegen}).

-pt_pp_src(true).


-define(HOST, <<"https://www.googleapis.com">>).

parse_transform(Forms, Opts) ->
    C = parse_trans:initial_context(Forms, Opts),
    {Exports, Funs} = parse_trans:do_inspect(fun inspect/4, {[], []}, Forms, C),
    parse_trans:do_insert_forms(above, lists:flatten([Exports, Funs]), Forms, C).

inspect(attribute, {attribute, Line, endpoints,
                   {RootUri, _Auth, Methods}}, _C, {ExportAcc, FunAcc}) ->
    {Export, Funs} =
        lists:unzip(
          lists:map(
            fun({Method, HttpMethod, Required, Optional}) ->
                    MethodInternal = list_to_atom(atom_to_list(Method)++"_"),
                    {{attribute,1,export,[{Method, length(Required)+1}]},
                     [gen_req_fun(Line, Method, MethodInternal, Required),
                      codegen:gen_function(MethodInternal,
                                           fun(Required, Options) ->
                                                   Path = lists:foldl(fun({K, V}, Acc) ->
                                                                              binary:replace(Acc, <<"<", (list_to_binary(K))/binary, ">">>, V)
                                                                      end, {'$var', RootUri}, Required),
                                                   OptionalParams = ert_requests:build_qs(Options, {'$var', Optional}),
                                                   ert_requests:do({'$var', HttpMethod},
                                                                   ?HOST,
                                                                   <<Path/binary, "?" , OptionalParams/binary>>, [], [])
                                           end)]}
            end, Methods)),

    {true, {[Export | ExportAcc], [Funs | FunAcc]}};
inspect(_, _, _, Acc) ->
    {false, Acc}.

gen_req_fun(Line, Method, MethodInternal, Required) ->
    Vars = [{var, Line, X} || {X, _Type} <- Required],
    Cons = to_cons(Vars, Line),
    {function, Line, Method, length(Required)+1,
     [{clause, Line,
       Vars ++ [{var, Line, 'Optional'}],
       [],
       [{call, Line, {atom, Line, MethodInternal}, [Cons, {var, Line, 'Optional'}]}]}]}.

to_cons([], Line) ->
    {nil, Line};
to_cons([{var, _, H}], Line) ->
    {cons, Line, {tuple, Line, [{string, Line, atom_to_list(H)}, {var, Line, H}]}, {nil, Line}};
to_cons([{var, _, H} | T], Line) ->
    {cons, Line, {tuple, Line, [{string, Line, atom_to_list(H)}, {var, Line, H}]}, to_cons(T, Line)}.
