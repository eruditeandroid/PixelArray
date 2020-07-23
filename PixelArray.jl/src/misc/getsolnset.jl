# Returns set of values in R^n corresponding to the center of a "true" entry in the array in input
# For our purposes, this gives solutions to f = 0 where f is the function / set of functions defining input
function getsolnset(pwa::PackWithArray)
    pack = pwa.pack
    boolarray = pwa.array
    lowerbds = map(x -> pack.ports[x].lowerbd, pack.orderednames)
    upperbds = map(x -> pack.ports[x].upperbd, pack.orderednames)
    resolutions = map(x -> pack.ports[x].resolution, pack.orderednames)
    stepsize = (upperbds - lowerbds) ./ resolutions
    solnset = Set{NTuple{length(pack.orderednames),Float64}}()
    for i in CartesianIndices((resolutions...,))
        if boolarray[i]
            pixelcenter = (stepsize .* i.I) + lowerbds - (stepsize / 2)
            union!(solnset, [(pixelcenter...,)])
        end
    end
    return solnset
end
