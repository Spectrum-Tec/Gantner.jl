using Test, Gantner

name = joinpath(@__DIR__, "..\\example", "data.dat")

# check gantnerinfo
nc, nv, fs, chanlegendtext = gantnerinfo(name)
@test nc == 6
@test nv == 200_000
@test fs == 10_000.0
@test chanlegendtext == ["Trig Condition", "DI_01a", "FI_01a", "2nd MUX AI_01", "1st MUX AI_03"]

#check gantnerread for all channels
(t, time, chanTextLegend) = gantnerread(name)
@test t == 0.0:0.0001:19.9999
@test time[2,5] == 0.001806761370971799

# check gantnerread where the time is read, rather than recreated
(t, time, chanTextLegend) = gantnerread(name; lazytime = false)
@test t[1] == 44210.79703523496

# check gantnerread, where only one channel is read
(t, time, chanTextLegend) = gantnerread(name, 6)
@test typeof(time) == Vector{Float64}
@test length(time) == 200_000
@test time[5] == -0.004325194749981165