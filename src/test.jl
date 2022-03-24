function f(a,b;c=0)
    if ~@isdefined c
        c = 0
    end
    s = a + b + c
end

struct Timelimits
    st::Float64
    fin::Float64
end

function g(ti::AbstractVector;...)
    if ~@isdefined(tl)
        tl = Timelimits(ti[begin], ti[end])
        println("Executing if statement")
    end

    #rest of function body
    println("Start is $(tl.st) and finish is $(tl.fin)")
end