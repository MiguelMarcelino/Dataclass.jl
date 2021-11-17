module Dataclass
export @dataclass

macro dataclass(expr::Expr)
    structName = expr.args[2]
    ismutable = expr.args[1]
    fields = []
    initvars = []
    raw_fields = expr.args[3]
    if raw_fields isa Expr && raw_fields.head == :block
        raw_fields = raw_fields.args
    end

    for field in raw_fields
        field isa LineNumberNode && continue

        if isa(field, Expr) &&
           length(field.args) == 2 &&
           isa(field.args[1], Symbol)
            name = field.args[1]
            type =
                (field.head == :(::)) ? Core.eval(__module__, field.args[2]) :
                (type = field.args[2])
            # save _initvars
            (name != :(_initvars)) ? push!(fields, :($(name)::$(type))) :
            initvars = type
        end

    end

    map(eval, initvars.args)
    fields = Tuple(fields)

    quote
        # If _frozen is true, should we not allow __init__(self) to be created and
        # remove mutable attribute from the struct?

        # Struct definition
        if $(esc(ismutable))
            mutable struct $(esc(structName))
                $(map(esc, fields)...)
            end
        else
            struct $(esc(structName))
                $(map(esc, fields)...)
            end
        end

        # Dataclass Functions
        # __init__
        if $(esc(_init))
            function $(esc(:(__init__)))(
                $(esc(:(self)))::$(esc(structName)),
                $(map(esc, fields)...),
            )
                fNames = fieldnames($(esc(structName)))
                for (field, fName) in zip([$(map(esc, fields)...)], fNames)
                    setfield!(self, fName, field)
                end
            end
        end

        # __repr__
        if $(esc(_repr))
            function $(esc(:(__repr__)))($(esc(:(self)))::$(esc(structName)))
                fNames = fieldnames($(esc(structName)))
                str_repr = string($(esc(structName)))
                field_arr = []
                for fName in fNames
                    push!(field_arr, getfield(self, fName))
                end
                field_str = join(field_arr, ", ")
                return str_repr * "(" * field_str * ")"
            end
        end

        # __eq__
        if $(esc(_eq))
            function $(esc(:(__eq__)))(
                $(esc(:(self)))::$(esc(structName)),
                $(esc(:(other)))::$(esc(structName)),
            )
                return $(esc(:__key))(self) == $(esc(:__key))(other)
            end
        end

        if $(esc(_order))
            # __lt__
            function $(esc(:(__lt__)))(
                $(esc(:(self)))::$(esc(structName)),
                $(esc(:(other)))::$(esc(structName)),
            )::Bool
                return $(esc(:__key))(self) < $(esc(:__key))(other)
            end

            # __le__
            function $(esc(:(__le__)))(
                $(esc(:(self)))::$(esc(structName)),
                $(esc(:(other)))::$(esc(structName)),
            )::Bool
                return $(esc(:__key))(self) <= $(esc(:__key))(other)
            end

            # __gt__
            function $(esc(:(__gt__)))(
                $(esc(:(self)))::$(esc(structName)),
                $(esc(:(other)))::$(esc(structName)),
            )::Bool
                return $(esc(:__key))(self) > $(esc(:__key))(other)
            end

            # __ge__
            function $(esc(:(__ge__)))(
                $(esc(:(self)))::$(esc(structName)),
                $(esc(:(other)))::$(esc(structName)),
            )::Bool
                return $(esc(:__key))(self) >= $(esc(:__key))(other)
            end
        end

        # __unsafe_hash__
        if !$(esc(_unsafe_hash))
            if $(esc(_eq)) && $(esc(ismutable))
                # __hash__
                # Rules:
                # - If a class does not define an __eq__() method it should not define a __hash__() operation either --> OK
                # - If it defines __eq__() but not __hash__(), its instances will not be usable as items in hashable collections --> Not covered here
                # - If a class defines mutable objects and implements an __eq__() method, it should not implement __hash__() --> OK
                function $(esc(:(__hash__)))(
                    $(esc(:(self)))::$(esc(structName)),
                )
                    return hash($(esc(:__key))(self))
                end
            end
        end

        # Additional Functions
        # __key
        function $(esc(:(__key)))($(esc(:(self)))::$(esc(structName)))
            fNames = fieldnames($(esc(structName)))
            fieldValues = []
            for fName in fNames
                push!(fieldValues, getfield(self, fName))
            end
            return Tuple(fieldValues)
        end
    end
end

end #module
