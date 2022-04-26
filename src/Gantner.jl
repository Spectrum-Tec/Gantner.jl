module Gantner

using Dates
#using Infiltrator

export gantnerread, gantnerinfo, gantnermask, Timelimits
include("read_exact.jl")

#=
This function implements the read_exact.mex functionality to read a Gantner created .dat file.  
It utilizes the Julia ccall command to use the functionality of the giutility.dll file.  As this
is a windows specific file, this utility only works for Windows operating system.

Additional read_exact.mex functionality can be added as required

Optional partial data reads has been implemented for single channel reads.  Use this as a base
for adding this capability for all channel or multiple channel reading of data if required.
=#

struct Timelimits
    st::Float64
    fin::Float64
end

# MWE for initializing variables to get rid of globals
function trial()
# initialize variables
fs = 0.0
ti = AbstractVector{Float64}
data = Vector{Float64}

try
    # open file to read
    numvalues = rand(100:200, 1)[1]  # number of values from file
    fs = 512.0  # read from file

    if rand(1:2,1)[1] == 1
        ti = range(0, step=1/fs, length=numvalues) # generate lazy values
    else
        ti = collect(range(0, step=1/fs, length=numvalues)) # read actual values from file
    end

    data = rand(numvalues)
finally 
    #close file
end
return ti, data, fs
end



"""
    gantnerread(filename :: String; scale :: Real = 1.0, lazytime :: Bool = true)
Read all data channels of data in a Gantner *.dat file.

The first channel of the .dat file is time data. This is ignored by default and returned in ti if lazytime=false.
scale - convert data in volts in .dat file to EU. If it is a scaler then use for all channels, otherwise if vector 
            it must be the length of the number of channels
If lazytime = false this data will be read and returned as ti.  
If lazytime = true this data will be reconstructed  (The default)

Program returns 
ti - time of sample;
data - Array of all the data channels;
fs - sampling rate [Hz]
chanlegendtext - the legend text associated with each channel Vector{String}

This is a subset of the read_exact.c which is the base of the read_exact mex
file used for matlab.  This subset is only for reading data from a file.
"""
function gantnerread(filename::String; scale::Union{Vector{<:Float64},Float64} = 1.0, lazytime::Bool = true)
    gClient = gConnection = 0
    fs = 0.0
    chanlegendtext = Vector{String}()
    ti = AbstractVector{Float64}
    data = Array{Float64}
    try
    gClient, gConnection = gantOpenFile(filename); # open file
    #read number of channels
    numchannels = gantChanNumRead(gConnection) - 1;
    numvalues = gantNumSamples(gClient, gConnection)

    # If typeof scale is Float64 or length is 1 then apply this factor to all channels
    if typeof(scale) == Float64  || length(scale) == 1
        scale = scale * ones(Float64, numchannels)
    end

    # check to see is scale is the same length at the number of channels
    if length(scale) != numchannels
        error("Data has $numchannels channels, ensure scale is a $numchannels vector")
    end

    fs = gantSampleRate(gConnection);
    # global data = zeros(Float64, numvalues, numchannels-1)
    data = Array{Float64}(undef, numvalues, numchannels)
    if lazytime
        ti = range(0, step = 1.0/fs, length = numvalues)
    else
        ti = gantChanDataRead(gClient, gConnection, 1) # time data assumed in column 1
    end

    for i=1:numchannels
        #read channel name
        push!(chanlegendtext, gantChanName(gConnection, i+1))
        #read channel data
        data[:,i] = gantChanDataRead(gClient, gConnection, i+1)
        #for (j, value) in enumerate(data)
        #    global data[j, i] = scale[i] * value;
        #end
        data[:,i] .*= scale[i]
    end
        
    finally
        #close file
        gantCloseFile(gClient, gConnection)
    end
    return (ti, data, fs, chanlegendtext)
end

"""
    gantnerread(filename :: String; channel:: AbstractVector{Int}, scale :: Real = 1.0, lazytime :: Bool = true)

Read specified data channels of data in a Gantner *.dat file.

The first channel of the .dat file is time data. This is ignored by default and returned in ti if lazytime=false.
channel - the data channels to read
scale - convert data in volts in .dat file to EU. If it is a scaler then use for all channels, otherwise if vector 
            it must be the length(channel)
If lazytime = false this data will be read and returned as ti.  
If lazytime = true this data will be reconstructed  (The default)

Program returns 
ti - time of sample;
data - Array of all the data channels;
fs - sampling rate [Hz]
chanlegendtext - the legend text associated with each channel Vector{String}

This is a subset of the read_exact.c which is the base of the read_exact mex
file used for matlab.  This subset is only for reading data from a file.
"""
function gantnerread(filename::String, channel::AbstractVector{Int}; scale::Union{Vector{<:Float64},Float64} = 1.0, lazytime::Bool = true)
    gClient = gConnection = 0
    fs = 0.0
    chanlegendtext = Vector{String}()
    ti = AbstractVector{Float64}
    data = Array{Float64}
    try
        gClient, gConnection = gantOpenFile(filename); # open file
        #read number of channels
        numchannels = length(channel)
        numchanneldat = gantChanNumRead(gConnection) - 1;
        numvalues = gantNumSamples(gClient, gConnection)

        # ensure the specified channels are in the data file
        if !issubset(channel, 1:numchanneldat)
            error("Specified channel(s) not in data file")
        end

        # If typeof scale is Float64 or length is 1 then apply this factor to all channels
        if typeof(scale) == Float64  || length(scale) == 1
            scale = scale * ones(Float64, numchannels)
        end

        # check to see is scale is the same length at the number of channels
        if length(scale) != numchannels
            error("Data has $numchannels channels, ensure scale is a $numchannels vector")
        end

        fs = gantSampleRate(gConnection);
        chanlegendtext = Vector{String}(undef, numchannels)
        # global data = zeros(Float64, numvalues, numchannels-1)
        data = Array{Float64}(undef, numvalues, numchannels)
        if lazytime
            ti = range(0, step = 1.0/fs, length = numvalues)
        else
            ti = gantChanDataRead(gClient, gConnection, 1) # time data assumed in column 1
        end

        for (i, ii) in enumerate(channel)
            #read channel name
            chanlegendtext[i] = gantChanName(gConnection, ii+1)

            #read channel data
            data[:,i] = gantChanDataRead(gClient, gConnection, ii+1)
            #for (j, value) in enumerate(data[:,i])
            #    global data[j, i] = scale[i] * value;
            #end
            data[:,i] .*= scale[i]
        end

    finally
        #close file
        gantCloseFile(gClient, gConnection)
    end
    return (ti, data, fs, chanlegendtext)
end

"""
gantnerread(filename::String, channel::Integer; scale::AbstractFloat = 1.0, tl::Union{Timelimits,Nothing}=nothing, lazytime::Bool = true)
Read specified data channel (one channel) of data in a Gantner *.dat file.

channel - is the channel number to read the data from.  When channel is 0 the gantner time data is returned in data.
The first channel of the .dat file is time data. This is ignored by default and returned in ti if lazytime=false.
scale - convert data in volts in .dat file to EU
tl - optional time limits of data to read. Ex. tl = Timelimits(5.0, 15.0); for all data don't set it.
If lazytime = false this data will be read and returned as ti.  
If lazytime = true this data will be reconstructed.

Program returns 
ti - time of sample;
data - data in specified channel;
fs - sampling rate [Hz]
chanlegendtext - the legend text associated with each channel Vector{String}

This is a subset of the read_exact.c which is the base of the read_exact mex
file used for matlab.  This subset is only for reading data from a file.
"""
function gantnerread(filename::String, channel::Integer; scale::AbstractFloat = 1.0, tl::Union{Timelimits,Nothing}=nothing, lazytime::Bool = true)
    gClient = gConnection = 0
    fs = 0.0
    chanlegendtext = ""
    ti = AbstractVector{Float64}
    data = Array{Float64}
 
    try
        gClient, gConnection = gantOpenFile(filename); # open file
        
        #read number of channels
        numchanneldat = gantChanNumRead(gConnection) - 1;
        numvaluesinfile = gantNumSamples(gClient, gConnection)
        fs = gantSampleRate(gConnection);

        # ensure the specified channels are in the data file
        if !issubset(channel, 1:numchanneldat)
            error("Specified channel not in data file")
        end

        if lazytime
            ti = range(0.0, step = 1.0/fs, length = numvaluesinfile)
        else
            ti = gantChanDataRead(gClient, gConnection, 1) # time data in column 1
        end

        if tl === nothing  # all data in file
            indexst = 1
            indexfin = numvaluesinfile
            numvalues = numvaluesinfile
        else
            if lazytime  # simple fast calculation
                indexst = ceil(Int, tl.st * fs)
                indexfin = floor(Int, tl.fin * fs)
                numvalues = indexfin - indexst + 1
                ti = (indexst:indexfin)/fs
            else  # more complex calcuation
                indexst = findfirst(tl.st >= ti)
                indexfin = findfirst(tl.fin >= ti)
                numvalues = indexfin - indexst + 1
                ti = ti[indexst:indexfin]
            end
        end

        #read channel name
        chanlegendtext = gantChanName(gConnection, channel + 1)

        #read channel data
        # using @view in the following line saves half the memory but creates a SubArray (not sure of the implications)
        data = gantChanDataRead(gClient, gConnection, channel + 1)[indexst:indexfin]
        # @infiltrate
        if scale != 1.0
            # the for loop should be faster than broadcasting but I think the global slows it down
            #@inbounds for (j, value) in enumerate(data)
            #    global data[j] = scale * value;
            #end
            data .*= scale
        end
        
    finally
        #close file
        gantCloseFile(gClient, gConnection)
    end
    return (ti, data, fs, chanlegendtext)
end

"""
    gantnerinfo(filename)
Read the information in a Gantner *.dat file.

Returns 
numchannels (We only count the data not the time Vector in the .dat file);
numvalues - per channel;
fs - sampling rate;
chanlegendtext - legend text associated with each channel
starttime - finish time - length of recording
finishtime - the timestamp when the file was created (last written)
"""
function gantnerinfo(filename :: String)
    gClient = gConnection = 0
    numchannels = numvalues = 0
    fs = 0.0
    chanlegendtext = Vector{String}()
    starttime = finishtime = unix2datetime(0)
    try
        gClient, gConnection = gantOpenFile(filename); # open file
       
        #read number of channels
        numchannels = gantChanNumRead(gConnection) - 1;
        numvalues = gantNumSamples(gClient, gConnection)

        fs = gantSampleRate(gConnection);
        for i=1:numchannels
            #read channel name
            push!(chanlegendtext, gantChanName(gConnection, i + 1))
        end

        # obtain file start & finish time
        # note that ctime is the local time the file was created on the local file system
        finishtime = unix2datetime(ctime(filename) + (datetime2unix(now()) - datetime2unix(now(UTC))))
        starttime = finishtime - Dates.Second(round(Int64, numvalues/fs))

    finally
        #close file
        gantCloseFile(gClient, gConnection)
    end
    return (numchannels, numvalues, fs, chanlegendtext, starttime, finishtime)
end

"""
    gantnermask(data, bit::Integer)
take the input data which has a digitial tach channel embedded within it.  This will extract the information from the specified bit and return this information.
Assume data is a Vector{Float64} or Array{Float64,1}
bit - the bit number from the least significant bit that contains the data
"""
function gantnermask(data::Vector{Float64}, bit::Integer)
    mask = one(UInt) << (bit - 1)
    # @show(mask)
    datanew = typeof(data)(undef,size(data))
    for (i, x) in enumerate(data)
        # @show(i, x, bitstring(Int(x)))
        x = UInt(x) & mask
        x = x >> (bit - 1)
        datanew[i] = x
        # @show(x, Float64(x), datanew[i])
    end
    return datanew
end


"""
    gantnermask(data, bit::Integer, pprdivide::Integer)
take the input data which has a digitial tach channel embedded within it.  This will extract the information from the specified bit and return this information.
Assume data is a Vector{Float64} or Array{Float64,1}
bit - the bit number from the least significant bit that contains the data
pprdivide - the tach pulse divide by ratio
"""
function gantnermask(data::Vector{Float64}, bit::Integer, pprdivide::Integer)
    mask = one(UInt) << (bit - 1)
    datanew = typeof(data)(undef,size(data))
    datanew[1] = xnew = Bool(0)
    count = 0

    x = UInt(data[1]) & mask        # perform masking
    xi = Bool(x >> (bit - 1))       # shift bit to LSB
    # println(xi)

    for (i, x) in enumerate(data[begin+1:end])
        xi_1 = xi
        x = UInt(x) & mask          # perform masking
        xi = Bool(x >> (bit - 1))   # shift bit to LSB
        # println(i, "\t", x, "\t", xi, "\t", xi_1)
        # check for trigger
        if xor(xi, xi_1)
            count += 1
            # @show(count)
            if count == pprdivide
                xnew = !xnew
                count = 0
            end
        end
        datanew[i+1] = xnew
    end
    return datanew
end

end # module