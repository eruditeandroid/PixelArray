# Performs a sequence of mergemults specified by the given WDs (in order)
# Outer pack of final WD in wds should correspond to final / result pack of multiplication
# Returns a PackWithArray representing the outer pack of the final wiring diagram
# in the sequence as well as the corresponding multiplied array
function mergemultviawds(pwas::Array{PackWithArray,1}, wds::Array{WiringDiagram,1})
    if !allunique(map(x -> x.pack, pwas))
        error("Packs are not unique.")
    end

    padict = Dict{Pack,BitArray}(map(x -> (x.pack, x.array), pwas))
    for i in eachindex(wds)
        inputarrays = map(x -> padict[x], wds[i].innerpacks)
        outputarray = multarrays(wds[i], inputarrays)
        padict[wds[i].outerpack] = outputarray
    end
    return PackWithArray(wds[end].outerpack, padict[wds[end].outerpack])
end
