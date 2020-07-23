# Returns a PackWithArray obtained from merging and multiplying given PacksWithArrays
# interiornames has names of unexposed variables
# Any name in interiornames that is not also a name in the packs in pwas will be ignored
function mergemult(pwas::Array{PackWithArray,1}, interiornames::Array{String,1})
    packs = map(x -> x.pack, pwas)
    boolarrays = map(x -> x.array, pwas)
    resultpack = mergepacks(packs, interiornames)
    helperwd = WiringDiagram(packs, resultpack)
    resultarray = multarrays(helperwd, boolarrays)
    return PackWithArray(resultpack, resultarray)
end

# Same as above, but with no unexposed variables
function mergemult(pwas::Array{PackWithArray,1})
    return mergemult(pwas, Array{String}(undef, 0))
end
