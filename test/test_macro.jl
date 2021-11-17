include("../src/Dataclass.jl")
using .DataClass

@dataclass mutable struct Register
    value::Int64
    valuestr::String
    _initvars = [_init=true, _repr=true, _eq=true, _order=true, _unsafe_hash=false, _frozen=true]
end
