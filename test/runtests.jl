using Test, Gantner, Dates

name = joinpath(@__DIR__, "..", "example", "data.dat")

@testset "gantnerinfo" begin
    # check gantnerinfo
    nc, nv, fs, chanlegendtext, starttime = gantnerinfo(name)
    @test nc == 6
    @test nv == 200_000
    @test fs == 10_000.0
    @test chanlegendtext == ["Trig Condition", "DI_01a", "FI_01a", "2nd MUX AI_01", "1st MUX AI_03"]
    #@test isapprox(starttime, unix2datetime(ctime(name)), atol=1e-3) # isapprox not valid with these types
end

@testset "gantnerread" begin
    #check gantnerread for all channels
    (t, time, chanTextLegend) = gantnerread(name)
    @test t == 0.0:0.0001:19.9999
    @test time[2,5] == 0.001806761370971799

    # check gantnerread where the sampling time is read, rather than recreated
    (t, time, chanTextLegend) = gantnerread(name; lazytime = false)
    @test t[1] == 44210.79703523496

    # check gantnerread, where only one channel is read
    (t, time, chanTextLegend) = gantnerread(name, 6)
    @test typeof(time) == Vector{Float64}
    @test length(time) == 200_000
    @test time[5] == -0.004325194749981165
end