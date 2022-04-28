using BenchmarkTools
using Revise

n = 2_000_000
function scaletryglobalfor(scale)
    try
        # open file to obtain data
        global data=rand(n)
     
        @inbounds for (j, value) in enumerate(data)
            global data[j] = scale * value;
        end

    finally
        #close file
    end
    data
end

function scaleglobalfor(scale)
    global data=rand(n)
    @inbounds for (i,value) in enumerate(data)
        global data[i] = scale * value
    end
    data
end

function scalefor(scale)
    data=rand(n)
    @inbounds for (i,value) in enumerate(data)
        data[i] = scale * value
    end
    data
end

function scaledotfor(scale)
    data=rand(n)
    @inbounds for i in 1:length(data)
        data[i] *= scale
    end
    data
end


function scaletryglobalbroadcast(scale)
    global data=rand(n)
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

function scalebroadcast(scale)
    data=rand(n)
    data .*= scale
end

@btime scaletryglobalfor(2.2);
@btime scaleglobalfor(2.2);
@btime scalefor(2.2);
@btime scaledotfor(2.2);
@btime scaletryglobalbroadcast(2.2);
@btime scaleglobalbroadcast(2.2);
@btime scalebroadcast(2.2);



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
    
    
    