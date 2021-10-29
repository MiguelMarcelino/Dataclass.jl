using Dataclass
using Test

DataClass.@dataclass mutable struct Register
    value::Int64
    valuestr::String
    _initvars = [_init=true, _repr=true, _eq=true, _order=true, _unsafe_hash=false, _frozen=true]
end

@testset "Dataclass.jl" begin
    a = Register(1, "1")
    b = Register(10, "4")
    setfield!(a, :value, 10) # Tests if struct fields can still be edited
    __init__(a, 10, "2")
    @test __eq__(a, Register(10, "2")) # Test init
    @test __repr__(a) == "Register(10, 2)"
    @test __eq__(a,b) == false
    @test __lt__(a, b) == true
    @test __le__(a, b) == true
    @test __gt__(a, b) == false
    @test __ge__(a, b) == false
    @test __key(a) == (10, "2")
    @test __hash__(a) == 2845903754746135373
end
