"""
Plot example file, and create a matlab file for good measure.  If you are not interested in the 
matlab file comment out those sections.
"""

# Pkg.add("Plots")  # uncomment for first run
# Pkg.add("Revise")  # uncomment for first run
# using Revise
using MAT
using HDF5
using Plots
using Gantner

# load file data
name = joinpath(@__DIR__, "data.dat")
(t, time, chanTextLegend) = gantnerread(name)
# t = range(0, length=size(Time, 1), step=1/fs)

plotly()       # use for general purpose plotting and looking for peaks
plot(t, time, label = reshape(chanTextLegend, 1, :))
xlabel!("Time [s]")
ylabel!("Amp")
title!(name)
ylims!(0, 1.2)
xlims!(0,0.3)


# base, ext = split(filename, ".")
# fnamemat = "$base.mat"
# command from .julia/packages/MAT/.../README.md
matwrite(joinpath(@__DIR__, "data.mat"), Dict(
	"t" => collect(t),
	"Time" => time);
	compress = true)

# delete data.mat when done
sleep(10)
rm(joinpath(@__DIR__, "data.mat"))
