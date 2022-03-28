function scaletry(scale)
    try
        # open file to obtain data
        global data=rand(200_000)
     
        @inbounds for (j, value) in enumerate(data)
            global data[j] = scale * value;
        end

    finally
        #close file
    end
    data
end

function scaleglobalfor(scale)
    global data=rand(200_000)
    @inbounds for (i,value) in enumerate(data)
        global data[i] = scale * value
    end
    data
end

function scalefor(scale)
    data=rand(200_000)
    @inbounds for (i,value) in enumerate(data)
        data[i] = scale * value
    end
    data
end


function scaletrybroadcast(scale)
    data=rand(200_000)
    try
        global data .*= scale
    finally
        # close file
    end
    data
end

function scaleglobalbroadcast(scale)
    data=rand(200_000)
    try
        global data .*= scale
    finally
        # close file
    end
    data
end

function scalebroadcast(scale)
    data=rand(200_000)
    data .*= scale
end

@btime scaletry(2.2);
@btime scaleglobalfor(2.2);
@btime scalefor(2.2);
@btime scaletrybroadcast(2.2);
@btime scaleglobalbroadcast(2.2);
@btime scalebroadcast(2.2);
