module Gantner

using Dates

export gantnerread, gantnerinfo, gantnermask

"""
This function implements the read_exact.mex functionality to read a Gantner created .dat file.  
It utilizes the Julia ccall command to use the functionality of the giutility.dll file.  As this
is a windows specific file, this utility only works for Windows operating system.

Additional read_exact.mex functionality can be added as required
"""

include("read_exact.jl")


"""
    gantnerread(filename :: String; lazytime :: Bool = true)
Read all data channels of data in a Gantner *.dat file.

The first channel of the data file is expected to be the time data.  
If lazytime = false this data will be read and returned as ti.  
If lazytime = true this data will be reconstructed.

Program returns 
ti - time of sample;
data - Array of all the data channels;
fs - sampling rate [Hz]
chanlegendtext - the legend text associated with each channel Vector{String}

This is a subset of the read_exact.c which is the base of the read_exact mex
file used for matlab.  This subset is only for reading data from a file.
"""
function gantnerread(filename :: String; lazytime :: Bool = true)
    gClient = gConnection = 0
    try
        gClient, gConnection = gantOpenFile(filename); # open file
        #read number of channels
        numchannels = gantChanNumRead(gConnection);
        numvalues = gantNumSamples(gClient, gConnection)

        global fs = gantSampleRate(gConnection);
        global chanlegendtext = Vector{String}(undef, numchannels-1)
        # global data = zeros(Float64, numvalues, numchannels-1)
        global data = Array{Float64}(undef, numvalues, numchannels-1)
        if lazytime
            global ti = range(0, step = 1.0/fs, length = numvalues)
        else
            global ti = gantChanDataRead(gClient, gConnection, 1) # time data assumed in column 1
        end

        for i=2:numchannels
            #read channel name
            chanlegendtext[i-1] = gantChanName(gConnection, i)

            #read channel data
            datachuck = gantChanDataRead(gClient, gConnection, i)
            for (j, value) in enumerate(datachuck)
                global data[j, i-1] = value;
            end
        end

    finally
        #close file
        gantCloseFile(gClient, gConnection)
    end
    return (ti, data, fs, chanlegendtext)
end

"""
    gantnerread(filename :: String, channel :: Integer; lazytime :: Bool = true)
Read specified data channel (one channel) of data in a Gantner *.dat file.

The first channel of the data file is expected to be the time data.  
channel - is the channel number to read the data from.  
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
function gantnerread(filename :: String, channel :: Integer; lazytime :: Bool = true)
    gClient = gConnection = 0
    try
        gClient, gConnection = gantOpenFile(filename); # open file
        #read number of channels
        numchannels = gantChanNumRead(gConnection);
        numvalues = gantNumSamples(gClient, gConnection)

        global fs = gantSampleRate(gConnection);
        global chanlegendtext = Vector{String}(undef, 1)
        # global data = zeros(Float64, numvalues, 1)
        global data = Vector{Float64}(undef, numvalues)
        if lazytime
            global ti = range(0, step = 1.0/fs, length = numvalues)
        else
            global ti = gantChanDataRead(gClient, gConnection, 1) # time data assumed in column 1
        end

        #read channel name
        chanlegendtext = gantChanName(gConnection, channel)

        #read channel data
        datachuck = gantChanDataRead(gClient, gConnection, channel)
        for (j, value) in enumerate(datachuck)
            global data[j] = value;
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
numchannels;
numvalues - per channel;
fs - sampling rate;
chanlegendtext - legend text associated with each channel
starttime - the time the file was created
"""
function gantnerinfo(filename :: String)
    gClient = gConnection = 0
    try
        gClient, gConnection = gantOpenFile(filename); # open file
        # obtain file start time
        global starttime = unix2datetime(ctime(filename))

        #read number of channels
        global numchannels = gantChanNumRead(gConnection);
        global numvalues = gantNumSamples(gClient, gConnection)

        global fs = gantSampleRate(gConnection);
        global chanlegendtext = Vector{String}(undef, numchannels-1)
        for i=2:numchannels
            #read channel name
            chanlegendtext[i-1] = gantChanName(gConnection, i)
        end

    finally
        #close file
        gantCloseFile(gClient, gConnection)
    end
    return (numchannels, numvalues, fs, chanlegendtext, starttime)
end

"""
    gantnermask(data, bit::Integer)
take the input data which has a digitial tach channel embedded within it.  This will extract the information from the specified bit and return this information.
Assume data is a Vector{Float64} or Array{Float64,1}
bit - the bit number from the least significant bit that contains the data
"""
function gantnermask(data, bit::Integer)
    datanew = typeof(data)(undef,size(data))
    for (i, x) in enumerate(data)
        x = Integer(x) & Integer(bit)
        x = x >> (bit - 1)
        datanew[i] = x
    end
    return datanew
end


"""
    gantnermask(data, bit::Integer, pprdivide::Integer)
take the input data which has a digitial tach channel embedded within it.  This will extract the information from the specified bit and return this information.
Assume data is a Vector{Float64} or Array{Float64,1}
bit - the bit number from the least significant bit that contains the data
pprdivide - the tach pulse divide by ratio
 _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
"""
function gantnermask(data, bit::Integer, pprdivide::Integer)
    datanew = typeof(data)(undef,size(data))
    datanew[1] = xnew = Bool(0)
    count = 0

    x = Integer(data[1]) & Integer(bit)   # perform masking
    xi = Bool(x >> (bit - 1))             # shift bit to LSB
    # println(xi)

    for (i, x) in enumerate(data[begin+1:end])
        xi_1 = xi
        x = Integer(x) & Integer(bit)   # perform masking
        xi = Bool(x >> (bit - 1))       # shift bit to LSB
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