# Creates a pixel array representing the graph of f, as suggested by David Spivak
# Makes use of the fact that we're plotting a graph to shave off a dimension's worth of work
# Input consists of a pack for input and output of function, function f: R^(n-1) --> R,
# and string representing name of output variable
function pagraph(pack::Pack, f::Function, outputname::String)
    # Find dimension corresponding to output
    outputdim = findfirst(x -> x == outputname, pack.orderednames)
    if outputdim === nothing
        error("Specified output must be a port in the given pack.")
    end

    # Extract values associated with output
    outputlowerbd = pack.ports[outputname].lowerbd
    outputupperbd = pack.ports[outputname].upperbd
    outputresolution = pack.ports[outputname].resolution
    outputstepsize = (outputupperbd - outputlowerbd) / outputresolution

    # Create new collections of names and associated values for the input to f
    inputorderednames = setdiff(pack.orderednames, [outputname])
    inputvarranges = map(x -> getrange(pack.ports[x]), inputorderednames)
    finputs = collect(Iterators.product(inputvarranges...))

    # Create permutations to / from normal form with output as last variable
    # Other variables in normal form have same order
    proper2normal = reverse(union([outputdim], reverse(1:length(pack.orderednames))))

    # Create an array of falses, to be filled in with sparse trues later on
    # Created in normal form to avoid indexing difficulties
    dims = map(x -> pack.ports[x].resolution, pack.orderednames)
    normalresult = falses(dims[proper2normal]...)

    # For each pixel in input space, compute f of the center of that pixel
    # Determine the corresponding pixel in input + output space and set that to true
    map(CartesianIndices(finputs)) do i
        outputpix = ceil(Int, (f(finputs[i]...) - outputlowerbd) / outputstepsize)
        if 1 <= outputpix <= outputresolution
            normalresult[i, outputpix] = true
        end
    end

    result = permutedims(normalresult, invperm(proper2normal))
    return result
end

# Creates a pixel array for the graph of f (where some inputs to f are fixed) on the given pack
# pack should have no ports for fixed variables
# Args of f with indices in keys(fixed) are set to values(fixed)
function pagraph(pack::Pack, f::Function, outputname::String, fixed::Dict{Int64,Float64})
    # Create a new pack treating the fixed variables as ports with resolution 1
    auxpack = createauxpack(pack, fixed)
    # Check to make sure user hasn't set outputname to "fixedvar_aux$(something)" to mess with us
    if length(outputname) >= 12 && outputname[1:12] == "fixedvar_aux"
        error("outputname should not start with 'fixedvar_aux'.")
    end
    # Use pagraph to get a higher-dimensional array than we want, then remove extra dimensions
    expandedresult = pagraph(auxpack, f, outputname)
    result = dropdims(expandedresult, dims=(keys(fixed)...,))
    return result
end
