using Test, Gantner, Dates

name = joinpath(@__DIR__, "..", "example", "data.dat")

@testset "gantnerinfo" begin
    # check gantnerinfo
    nc, nv, fs, chanlegendtext, starttime, finishtime = gantnerinfo(name)
    @test nc == 5
    @test nv == 200_000
    @test fs == 10_000.0
    @test chanlegendtext == ["Trig Condition", "DI_01a", "FI_01a", "2nd MUX AI_01", "1st MUX AI_03"]
    #@test isapprox(starttime, unix2datetime(ctime(name)), atol=1e-3) # isapprox not valid with these types
end

@testset "gantnerread" begin
    #check gantnerread for all channels
    (t, data, fs, chanTextLegend) = gantnerread(name)
    @test t == 0.0:0.0001:19.9999
    @test data[2,5] == 0.001806761370971799

    #check gantnerread for all channels with scaling array
    scalefactors = [1.0; 2.0; 3.0; 4.0; 5.0]
    (t, data, fs, chanTextLegend) = gantnerread(name, scale=scalefactors)
    @test t == 0.0:0.0001:19.9999
    @test data[2,5] == 5.0 * 0.001806761370971799

    #check gantnerread for all channels with scaling Float64
    scalefactors = 5.0
    (t, data, fs, chanTextLegend) = gantnerread(name, scale=scalefactors)
    @test t == 0.0:0.0001:19.9999
    @test data[2,5] == 5.0 * 0.001806761370971799

    # check gantnerread where the sampling time is read, rather than recreated
    (t, data, fs, chanTextLegend) = gantnerread(name; lazytime = false)
    @test t[1] == 44210.79703523496

    # check gantnerread, where only one channel is read and scale factor is used
    (t, data, fs, chanTextLegend) = gantnerread(name, 5, scale=2.0)
    @test typeof(data) == Vector{Float64}
    @test length(data) == 200_000
    @test data[5] == 2.0 * -0.004325194749981165

    # check gantnerread, where only one channel is partially read and scale factor is used
    tl = Timelimits(5.0, 15.0)
    (t, data, fs, chanTextLegend) = gantnerread(name, 5, scale=2.0, tl=tl)
    @test length(t) == 100_001
    @test typeof(data) == Vector{Float64}
    @test length(data) == 100_001
    @test data[5] == 0.012449117377400398

    # check gantnerread, where only one channel is partially read and scale factor is 1.0
    tl = Timelimits(5.0, 15.0)
    (t, data, fs, chanTextLegend) = gantnerread(name, 5, scale=1.0, tl=tl)
    @test length(t) == 100_001
    @test typeof(data) == Vector{Float64}
    @test length(data) == 100_001
    @test data[5] == 0.012449117377400398/2.0

    # check gantnerread, where a number of channels are read and scale factor is used
    (t, data, fs, chanTextLegend) = gantnerread(name, 2:4, scale=2.0)
    @test typeof(data) == Matrix{Float64}
    @test size(data) == (200_000, 3)
    @test data[5,3] == 0.028291847556829453
end

@testset "gantnermask" begin
    a = [0.0,3,0,3,0,3,0,3,0,3,0,3,0,3,0,3,0,3,0,3,0,3,0,3,0,3,0,3,0,3,0,3,0,3,0,3]
    b = gantnermask(a,2)
    @test typeof(a) == typeof(b)
    @test all(a .>= b)
    @test all(a .== 3 .* b)
    @test all(gantnermask(a, 2) .== gantnermask(a, 1))
    c = gantnermask(a,1,1)
    @test all(b .== c)
    @test all(gantnermask(a, 2, 5) .== gantnermask(a, 1, 5))
    @test all(gantnermask(a, 2, 3) .== repeat(0:1, inner=3, outer=6))

    c = [0.0, 1, 2, 4, 8, 16, 32]
    @test all(gantnermask(c, 1) .== [0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    @test all(gantnermask(c, 2) .== [0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0])
    @test all(gantnermask(c, 3) .== [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0])
    @test all(gantnermask(c, 4) .== [0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0])
    @test all(gantnermask(c, 5) .== [0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0])
    @test all(gantnermask(c, 6) .== [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0])
    @test all(gantnermask(c, 7) .== [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    @test all(gantnermask(c, 8) .== [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    @test all(gantnermask(c, 9) .== [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    @test all(gantnermask(c, 10) .== [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    
    @test all(gantnermask(c, 1, 1) .== [0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    @test all(gantnermask(c, 2, 1) .== [0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0])
    @test all(gantnermask(c, 3, 1) .== [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0])
    @test all(gantnermask(c, 4, 1) .== [0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0])
    @test all(gantnermask(c, 5, 1) .== [0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0])
    @test all(gantnermask(c, 6, 1) .== [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0])
    @test all(gantnermask(c, 7, 1) .== [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    @test all(gantnermask(c, 8, 1) .== [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    @test all(gantnermask(c, 9, 1) .== [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    @test all(gantnermask(c, 10, 1) .== [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
end