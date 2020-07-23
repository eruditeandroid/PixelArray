# Returns minimum absolute value of f obtained at centers of "pixels" in pack
# Not used in anything else but could be used to check that pazeroset is working
function pixelmin(pack::Pack, f::Function, tol::Float64)
    lowerbds = map(x -> pack.ports[x].lowerbd, pack.orderednames)
    upperbds = map(x -> pack.ports[x].upperbd, pack.orderednames)
    resolutions = map(x -> pack.ports[x].resolution, pack.orderednames)
    stepsize = (upperbds - lowerbds) ./ resolutions
    return minimum(map(i -> abs(f(((stepsize .* (i.I .- (1/2))) .+ lowerbds)...)), CartesianIndices((resolutions...,))))
end
