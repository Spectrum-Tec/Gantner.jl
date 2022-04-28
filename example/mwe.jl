using BenchmarkTools
using Revise
using LoopVectorization

# Some trials to ensure that the scaling algorithm is as efficient as possible
# broadcasting is two orders of magnitude faster

n = 2_000_000
data=rand(n)
sc = 0.999999999999
function scaletryglobalfor(scale)
    try
        # open file to obtain data
     
        @inbounds for (i, value) in enumerate(data)
            global data[i] = scale * value;
        end

    finally
        #close file
    end
    data
end

function scaleglobalfor(scale)
    @inbounds for (i,value) in enumerate(data)
        global data[i] = scale * value
    end
    data
end

function scalefor(datalocal, scale)
    @inbounds for (i,value) in enumerate(datalocal)
        datalocal[i] = scale * value
    end
    datalocal
end

function scaledotfor(datalocal, scale)
     @inbounds for i in 1:length(datalocal)
        datalocal[i] *= scale
    end
    datalocal
end

function scaledotforloopvectorized(datalocal, scale)
    @turbo for i in 1:length(datalocal)
       datalocal[i] *= scale
   end
   datalocal
end

function scaletryglobalbroadcast(scale)
    try
        global data .*= scale
    finally
        # close file
    end
    data
end

function scaleglobalbroadcast(scale)
    global data=rand(n)
    global data .*= scale
    data
end

function scalebroadcast(datalocal, scale)
    datalocal .*= scale
end

@btime a = scaletryglobalfor(sc); a[1]
@btime a = scaleglobalfor(sc); a[1]
@btime a = scalefor(data, sc); a[1]
@btime a = scaledotfor(data, sc); a[1]
@btime a = scaledotforloopvectorized(data, sc); a[1]
@btime a = scaletryglobalbroadcast(sc); a[1]
@btime a = scaleglobalbroadcast(sc); a[1]
@btime a = scalebroadcast(data, sc); a[1]



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
    
    
    