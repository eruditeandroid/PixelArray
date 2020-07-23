# Multiplies boolean arrays according to wiring diagram
# boolarrays should be an array of boolean multi-dimensional arrays
# Entries in boolarrays correspond to inner packs in wd, indexed in the same order
# Based on Algorithm 1 in Spivak et al's paper
function multarrays(wd::WiringDiagram, boolarrays::Array{<:BitArray,1})
    # Check that port & array dimensions match up
    for i in 1:length(boolarrays)
        pack = wd.innerpacks[i]
        if map(x -> pack.ports[x].resolution, (pack.orderednames...,)) != size(boolarrays[i])
            error("Dimensions of pack number $(i) and corresponding boolean array don't match.")
        end
    end

    # Rearrange arrays so that each has a dimension for each port (some may be singletons)
    # and so that the dimensions for given ports are the same across different arrays
    compatarrays = map(1:length(boolarrays)) do i
        # Create intermediate array with one dimension added for each variable
        intermediate = reshape(boolarrays[i], size(boolarrays[i])..., fill(1, length(wd.orderedlinks) - ndims(boolarrays[i]))...)

        # Create a permutation that takes port positions in links to corresponding dimensions in intermediate
        # The inverse of this sends dimensions in intermediate to the desired positions
        # Explicit casting is necessary since indexin can also return Nothing values (doesn't do so here)
        links2interm::Array{Int64,1} = union(indexin(wd.innerpacks[i].orderednames, wd.orderedlinks), 1:length(wd.orderedlinks))
        interm2links = invperm(links2interm)

        # Put dimensions in right / compatible order
        return permutedims(intermediate, interm2links)
    end

    # Run through generalized array multiplication
    afterand::BitArray = broadcast(&, compatarrays...) # broadcast handles what was once handled by expandarray
    droppeddims = findall(!in(wd.outerpack.orderednames), wd.orderedlinks)
    afteror = any(afterand; dims=Tuple(droppeddims))

    # Permute and drop dimensions to get result in desired form
    # Explicit casting is necessary here, see above
    afteror2result::Array{Int64,1} = union(indexin(wd.outerpack.orderednames, wd.orderedlinks), 1:length(wd.orderedlinks))
    resulthighdim = permutedims(afteror, afteror2result)
    result = dropdims(resulthighdim; dims=Tuple((length(wd.outerpack.orderednames)+1):length(wd.orderedlinks)))
    return result
end
