using Aqua

@testset "Aqua.jl" begin
    Aqua.test_all(Gantner; deps_compat=(ignore=[:Dates],))
end