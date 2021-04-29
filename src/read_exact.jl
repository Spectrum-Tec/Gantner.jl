#=
The commands below are a subset of the file read_exact developed for matlab.  It aims to
expose similar functionality, but at this time only for reading files, not for
reading buffers directly from the Gantner system.  It uses giutility.dll on
Windows machines to do the work.  

This work was inspired from https://nextcloud.gantner-instruments.com/s/fGismwHwQynM9rE
=#

# location of shared library is in local directory
const giutility = joinpath(@__DIR__, "giutility.dll")

"""
    gantOpenFile(filename::String)
Open the gantner .dat file
"""
function gantOpenFile(filename::String) #, HCLIENT, HCONNECTION)
    resultDict = Dict{Int32, String}(
        0 => "OK",
        1 => "ERROR",
        2 => "CONNECTION_ERROR",
        3 => "INIT_ERROR",
        4 => "LIMIT_ERROR",
        5 => "SYNC_CONF_ERROR",
        6 => "MULTYUSED_ERROR",
        7 => "INDEX_ERROR",
        8 => "FILE_ERROR",
        9 => "NOT_READY",
        10 => "EXLIB_MISSING",
        11 => "NOT_CONNECTED",
        12 => "NO_FILE",
        13 => "CORE_ERROR",
        14 => "POINTER_INVALID")

    HCLIENT = HCONNECTION = Ref{Int32}(0)  # Initalize values

    ret = ccall((:_CD_eGateHighSpeedPort_DecodeFile_Select, giutility),
    Cint,(Ref{Cint},Ref{Cint},Cstring),HCLIENT,HCONNECTION,filename)

    # @show(filename, HCLIENT, HCONNECTION, ret)

    if ret != 0
        error("File did not open, Return Code $ret meaning $(resultDict[ret])")
    end
    return HCLIENT[], HCONNECTION[]
end

"""
    gantCloseFile(HCLIENT::Integer, HCONNECTION::Integer)
Close the file that has been opened.  And probably data streams as well.
"""
function gantCloseFile(HCLIENT::Integer, HCONNECTION::Integer)

    channelCount = Ref{Int32}(-1)

    ret = ccall((:_CD_eGateHighSpeedPort_Close, giutility),
    Cint,(Cint,Cint),HCLIENT, HCONNECTION)

    HCLIENT = HCONNECTION = Int32(-1)  # Initalize values

    # @show(HCONNECTION, channelCount, ret)

  if ret != 0
    error("Channel numbers not read, Return Code $ret")
  end
  return HCLIENT[], HCONNECTION[]
end

"""
    gantChanNumRead(HCONNECTION::Integer)
Get the number of channels
"""
function gantChanNumRead(HCONNECTION::Integer)

    DADI_INPUT = 0   # input channels
    channelCount = Ref{Int32}(0)

    ret = ccall((:_CD_eGateHighSpeedPort_GetNumberOfChannels, giutility),
    Cint,(Cint,Cint,Ref{Cint}),HCONNECTION,DADI_INPUT,channelCount)

    # @show(HCONNECTION, channelCount, ret)

  if ret != 0
    error("Channel numbers not read, Return Code $ret")
  end
  return channelCount[]
end

"""
    gantNumSamples(HCLIENT::Integer, HCONNECTION::Integer)
Get the number of samples per channel
"""
function gantNumSamples(HCLIENT::Integer, HCONNECTION::Integer)
    # read the number of samples per channel in the file
    numValues = ccall((:_CD_eGateHighSpeedPort_GetBufferFrames_All, giutility),
    Cint, (Cint, Cint), HCONNECTION, HCLIENT)

   return numValues
end

"""
    gantSampleRate(HCONNECTION::Integer)
Get the sample rate
"""
function gantSampleRate(HCONNECTION::Integer)

    fs = Ref{Float64}(0)
    channelInfo = ""

    ret = ccall((:_CD_eGateHighSpeedPort_GetDeviceInfo, giutility),
    Cint,(Cint,Cint,Cint,Ref{Cdouble},Cstring),HCONNECTION,16,1,fs,channelInfo)

    # @show(HCONNECTION, fs, channelInfo, ret)

  if ret != 0
    error("Channel sample rate not read, Return Code $ret")
  end
  return fs[]
end

"""
    gantChanName(HCONNECTION::Integer, channelindex::Integer)
Get the channel name
"""
function gantChanName(HCONNECTION::Integer, channelindex::Integer)

    CHINFO_NAME = 0  # type of info = name
    DADI_INPUT = 0   # input channels
    info = Vector{UInt8}(undef, 1024)  # initialize info

    ret = ccall((:_CD_eGateHighSpeedPort_GetChannelInfo_String, giutility),
    Cint,(Cint,Cint,Cint,Cint,Ptr{Cchar}),
    HCONNECTION,CHINFO_NAME,DADI_INPUT,channelindex-1,info)

    # @show(HCONNECTION, channelindex, info, ret)

  if ret != 0
    error("Channel sample rate not read, Return Code $ret")
  end
  return unsafe_string(pointer(info))
end

"""
    gantChanDataRead(HCLIENT::Integer, HCONNECTION::Integer, channelindex::Integer)
Get the data, using logic of read_exact.c
This logic seems convoluted but think it is a workaround to ideosyncracies in
the giutility.dll file.
"""
function gantChanDataRead(HCLIENT::Integer, HCONNECTION::Integer, channelindex::Integer)
    HSPdict = Dict{Int,String}(
    0 => "HSP_OK",
    1 => "HSP_ERROR",
    2 => "HSP_CONNECTION_ERROR",
    3 => "HSP_INIT_ERROR",
    4 => "HSP_LIMIT_ERROR",
    5 => "HSP_SYNC_CONF_ERROR",
    6 => "HSP_MULTYUSED_ERROR",
    7 => "HSP_INDEX_ERROR",
    8 => "HSP_FILE_ERROR",
    9 => "HSP_NOT_READY")

    HSP_OK = 0

    numChan = gantChanNumRead(HCONNECTION)
    #@show(numChan)

    if 1 > channelindex || channelindex > numChan
        error("Channel $channelindex is not in the file")
    end

    # read_exact gets the sample rate and timestep

    # read the number of values in the file
    numValues = ccall((:_CD_eGateHighSpeedPort_GetBufferFrames_All, giutility),
    Cint, (Cint, Cint), HCONNECTION, HCLIENT)
    #@show(numValues)

    if numValues == 0
        error("No Data in file...")
    end
    Data = zeros(numValues)

    frameSize = Ref{Int32}(0)
    ret = ccall((:_CD_eGateHighSpeedPort_LoadBufferData, giutility),
    Cint, (Cint, Ref{Cint}), HCONNECTION, frameSize)
    index = 1
    found = 0
    finished = 0

    while ret == HSP_OK
        value = Ref{Float64}(0)

        # Load next value from buffer
        for i = 1:frameSize[]
            # read channel value
            ret = ccall((:_CD_eGateHighSpeedPort_ReadBuffer_Single, giutility),
            Cint, (Cint,Cint,Cint, Ref{Cdouble}), HCONNECTION,HCLIENT,channelindex-1, value)

            if ret != HSP_OK
                #display("error at read buffer single... CHind: $channelindex returncode: $(HSPdict[ret])")
                found = 1
                break
            end

            # @show(value[])
            Data[index] = value[]
            index += 1

            # load next value
            ret = ccall((:_CD_eGateHighSpeedPort_ReadBuffer_NextFrame, giutility),
            Cint, (Cint, Cint), HCONNECTION, HCLIENT)
            if ret != HSP_OK
                #@show(i, ret)
                #display("Error at next frame.... returncode: $ret, $(HSPdict[ret])")
                break
            end

        end
        if found == 1
            break
        end

        # load next data -> if no data available: ret = 1
        ret = ccall((:_CD_eGateHighSpeedPort_LoadBufferData, giutility),
        Cint, (Cint, Ref{Cint}), HCONNECTION, frameSize)

        if ret != HSP_OK
            finished = 1
        end
    end
    if finished == 1
        ret = 0
    end

    # rewind the file
    ret = ccall((:_CD_eGateHighSpeedPort_Rewind, giutility),
    Cint, (Cint, Cint, Cint), HCONNECTION, HCLIENT, numValues)
    return Data
end

#=
"""
    gantChanDataRead(HCLIENT::Integer, HCONNECTION::Integer, channelindex::Integer)
Get the data.  This was an attempt to make the logic from read_exact more
straightforward.  However the return codes from giutility.dll are strange so
it gives funny error messages that I have not fully figured out.
"""
function gantChanDataRead(HCLIENT::Integer, HCONNECTION::Integer, channelindex::Integer)
    HSPdict = Dict{Int,String}(
    0 => "HSP_OK",
    1 => "HSP_ERROR",
    2 => "HSP_CONNECTION_ERROR",
    3 => "HSP_INIT_ERROR",
    4 => "HSP_LIMIT_ERROR",
    5 => "HSP_SYNC_CONF_ERROR",
    6 => "HSP_MULTYUSED_ERROR",
    7 => "HSP_INDEX_ERROR",
    8 => "HSP_FILE_ERROR",
    9 => "HSP_NOT_READY")

    HSP_OK = 0

    numChan = gantChanNumRead(HCONNECTION)

    @show(numChan)

    if 1 > channelindex || channelindex > numChan
        error("Channel $channelindex is not in the file")
    end

    # read_exact gets the sample rate and timestep

    # read the number of values in the file
    numValues = ccall((:_CD_eGateHighSpeedPort_GetBufferFrames_All, "./giutility.dll"),
    Cint, (Cint, Cint), HCONNECTION, HCLIENT)

    if numValues == 0
        error("No Data in file...")
    end

    @show(numValues)

    Data = zeros(numValues)

    value = Ref{Float64}(0)
    frameSize = 0  # Initialize to keep in scope
    for i = 1:numValues
        # Load next value from buffer
        if i == 1 || i % frameSize == 2 # works because i == 1 evaluated first
            frameSize = Ref{Int32}(0)
            ret = ccall((:_CD_eGateHighSpeedPort_LoadBufferData, "./giutility.dll"),
            Cint, (Cint, Ref{Cint}), HCONNECTION, frameSize)
            if ret != HSP_OK
                display("error at load next data -> if no data available ret = 1, ret: $ret")
            end
            frameSize = frameSize[]
            @show(i,frameSize)
        else
            ret = ccall((:_CD_eGateHighSpeedPort_ReadBuffer_NextFrame, "./giutility.dll"),
            Cint, (Cint, Cint), HCONNECTION, HCLIENT)
            if ret != HSP_OK
                @show(i, ret)
                display("Error at next frame.... returncode: $ret, $(HSPdict[ret])")
            end
        end
        # read channel value
        ret = ccall((:_CD_eGateHighSpeedPort_ReadBuffer_Single, "./giutility.dll"),
        Cint, (Cint,Cint,Cint, Ref{Cdouble}), HCONNECTION,HCLIENT,channelindex-1, value)

        if ret != HSP_OK
            display("error at read buffer single... CHind: $channelindex returncode: $(HSPdict[ret])")
        end

        # @show(value[])

        Data[i] = value[]

    end
    @show(i)
    # load next data -> if no data available: ret = 1

    # rewind the file
    ret = ccall((:_CD_eGateHighSpeedPort_Rewind, "./giutility.dll"),
    Cint, (Cint, Cint, Cint), HCONNECTION, HCLIENT, numValues)
    return Data
end
=#
