module UnitfulMoles 

using Unitful

export @mol, @xmol, @compound, @u_str, @unit, uconvert, parse_compound, sum_base

macro mol(x::Symbol, grams::Real)
    symb = Symbol("mol", x)
    abbr = "mol($x)"
    name = "Moles $(x)"
    equals = """ $(grams)u"g" """
    tf = true

    expr = Expr(:block)
    push!(expr.args, parse("""@unit $symb "$abbr" "$name" $equals $tf"""))
    esc(expr)
end

macro xmol(base::Symbol, compound::Symbol)
    elements = parse_compound(string(compound))
    n = 1/sum_base(base, elements)

    symb = Symbol(base, "mol", compound)
    abbr = "$(base)-mol($compound)"
    name = "$base-moles $(compound)"
    equals = "$(n)mol$(compound)"
    tf = true

    expr = Expr(:block)
    push!(expr.args, parse("""@compound $compound"""))
    push!(expr.args, parse("""@unit $symb "$abbr" "$name" $equals $tf"""))
    esc(expr)
end

macro compound(name::Symbol)
    elements = parse_compound(string(name))
    weight = 0.0u"g"
    for (el, n) in elements
        weight += getweight(el) * n
    end
    weight_stripped = ustrip(weight)
    str = """@mol $name $weight_stripped"""
    return esc(parse(str))
end


function sum_base(base, elements::Array{Pair{String,Int},1})
    number = 0
    for (element, n) in elements
        if string(base) == element; 
            number += n 
        end
    end
    return number
end

function parse_compound(str::String)
    elements = Pair{String,Int}[]
    numstring = ""
    element = str[1:1]
    for c in str[2:end]
        if 48 <= convert(Int, c) <= 57 # Check c is a number
            numstring *= c
        elseif isupper(c)
            push_element!(elements, element, numstring)
            element = string(c)
            numstring = "" 
        elseif islower(c)
            element *= c
        end
    end
    push_element!(elements, element, numstring)
    return elements
end

function push_element!(elements, element, n)
    if n == ""; n = "1" end
    push!(elements, element => parse(Int, n))
end

function getweight(arg::String)
    local w
    try
        w = eval(parse("""uconvert(u"g", 1Main.mol$(arg))"""))
    catch 
        w = eval(parse("""uconvert(u"g", 1u"mol$(arg)")"""))
    end
    return w
end

end # module
