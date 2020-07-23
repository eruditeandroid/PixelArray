# Creates a pixel array for the equation f = 0 on the given pack
# Ports in pack must be same as args of f and in same order
function pazeroset(pack::Pack, f::Function, tol::Float64)
    # Range for each variable in input to f
    varranges = map(x -> getrange(pack.ports[x]), pack.orderednames)
    # Array of inputs is cartesian product of ranges for each variable
    finputs = collect(Iterators.product(varranges...))
    # Compute pixel array
    result::BitArray = map(finputs) do x
        # This seems to be a small amount faster than calculating abs(f(x...))
        -tol < f(x...) < tol
    end
    return result
end

# Creates a pixel array for the equation f = 0 (where some inputs to f are fixed) on the given pack
# Input pack should have no ports corresponding to fixed variables
# Args of f with indices in keys(fixed) are set to corresponding entries in values(fixed)
function pazeroset(pack::Pack, f::Function, tol::Float64, fixed::Dict{Int64,Float64})
    # Create a new pack treating the fixed variables as ports with resolution 1
    auxpack = createauxpack(pack, fixed)
    # Use pazeroset to get a higher-dimensional array than we want, then remove extra dimensions
    expandedresult = pazeroset(auxpack, f, tol)
    result = dropdims(expandedresult, dims=(keys(fixed)...,))
    return result
end
