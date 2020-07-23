using PixelArray, Test, Random

# Tests for PAZeroSet
include("./pazeroset/identity.jl")
include("./pazeroset/falses.jl")
include("./pazeroset/trues.jl")
include("./pazeroset/manyinputs.jl")
include("./pazeroset/toofew.jl")
include("./pazeroset/toomany.jl")

# Tests for PAGraph
include("./pagraph/identity.jl")
include("./pagraph/falses.jl")
include("./pagraph/manyinputs.jl")
include("./pagraph/toofew.jl")
include("./pagraph/toomany.jl")

# Tests for multiplication
include("./mult/identity.jl")
include("./mult/assoc.jl")
include("./mult/zero.jl")
include("./mult/and.jl")

@testset "All Pixel Array Tests" begin
    @testset "PAZeroSet Tests" begin
        @test test_pazeroset_identity()
        @test test_pazeroset_falses()
        @test test_pazeroset_trues()
        @test test_pazeroset_manyinputs()
        @test test_pazeroset_toofew()
        @test test_pazeroset_toomany()
    end

    @testset "PAGraph Tests" begin
        @test test_pagraph_identity()
        @test test_pagraph_falses()
        @test test_pagraph_manyinputs()
        @test test_pagraph_toofew()
        @test test_pagraph_toomany()
    end

    @testset "Multiplication Tests" begin
        @test test_mult_identity()
        @test test_mult_assoc()
        @test test_mult_zero()
        @test test_mult_and()
    end
end
