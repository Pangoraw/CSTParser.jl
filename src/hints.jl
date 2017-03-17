module Hints
abstract Format
abstract Lint
type Hint{C}
    loc
end

@enum(FormatCodes,
AddWhiteSpace,
DeleteWhiteSpace,
Useelseif,
Indents)

@enum(LintCodes,
DuplicateArgumentName,
ArgumentFunctionNameConflict,
SlurpingPosition, 
KWPosition,
ImportInFunction)

function apply(hints::Vector{Hint}, str)
    str1 = deepcopy(str)
    ng = length(hints)
    for i = ng:-1:1
        str1 = apply(hints[i], str1)
    end
    str1
end

function apply(h::Hint{AddWhiteSpace}, str)
    if h.loc isa Tuple
        # loc = ind2chr(str, h.loc[1])
        str = string(str[1:h.loc[1]], " "^h.loc[2], str[h.loc[1] + 1 : end])
    else
        # loc = ind2chr(str, h.loc)
        str = string(str[1:h.loc], " ", str[h.loc + 1:end])
    end
end

function apply(h::Hint{DeleteWhiteSpace}, str)
    s1 = ind2chr(str, first(h.loc))
    s2 = ind2chr(str, last(h.loc) + 1)
    str = string(str[1:s1], str[s2:end])
end
end

# Formatting

islbracket(t::Token) = t.kind == Tokens.LPAREN ||
                        t.kind == Tokens.LBRACE ||
                        t.kind == Tokens.LSQUARE

isrbracket(t::Token) = t.kind == Tokens.RPAREN ||
                        t.kind == Tokens.RBRACE ||
                        t.kind == Tokens.RSQUARE

function format_op(ps, prec)
    # prec = precedence(ps.t)
    if prec == 8 || prec == 13 || prec == 14 || prec == 15
        if ps.lws.kind != EmptyWS
            push!(ps.hints, Hint{Hints.DeleteWhiteSpace}(ps.lws.startbyte + 1 : ps.lws.endbyte + 1))
        end
        if ps.ws.kind != EmptyWS
            push!(ps.hints, Hint{Hints.DeleteWhiteSpace}(ps.ws.startbyte + 1 : ps.ws.endbyte + 1))
        end
    elseif ps.t.kind == Tokens.ISSUBTYPE || ps.t.kind == Tokens.DDDOT
    else
        if ps.lws.kind == EmptyWS
            push!(ps.hints, Hint{Hints.AddWhiteSpace}(ps.t.startbyte))
        end
        if ps.ws.kind == EmptyWS
            push!(ps.hints, Hint{Hints.AddWhiteSpace}(ps.t.endbyte + 1))
        end
    end
end

function format_comma(ps)
    if ps.lws.kind != EmptyWS && !(islbracket(ps.lt))
        push!(ps.hints, Hint{Hints.DeleteWhiteSpace}(ps.lws.startbyte + 1 : ps.lws.endbyte + 1))
    end
    if ps.ws.kind == EmptyWS && !(isrbracket(ps.nt))
        push!(ps.hints, Hint{Hints.AddWhiteSpace}(ps.nt.startbyte))
    end
end

function format_lbracket(ps)
    if ps.ws.kind != EmptyWS
        push!(ps.hints, Hint{Hints.DeleteWhiteSpace}(ps.ws.startbyte + 1 : ps.ws.endbyte + 1))
    end
end

function format_rbracket(ps)
    if ps.lws.kind != EmptyWS
        push!(ps.hints, Hint{Hints.DeleteWhiteSpace}(ps.lws.startbyte + 1 : ps.lws.endbyte + 1))
    end
end

function format_indent(ps, start_col)
    if (start_col > 0 && ps.nt.startpos[2] != start_col + 4)
        dindent = start_col + 4 - ps.nt.startpos[2]
        if dindent > 0
            push!(ps.hints, Hint{Hints.AddWhiteSpace}((ps.nt.startbyte, dindent)))
        else
            push!(ps.hints, Hint{Hints.DeleteWhiteSpace}(ps.nt.startbyte + (dindent + 1 : 0)))
        end
    end
end
