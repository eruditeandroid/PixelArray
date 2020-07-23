# Merges packs into one larger pack, hiding interior ports (not shared with other packs)
# Name order is that of packs[1] followed by that of packs[2] followed by that of packs[3]...
# Elements of interiornames which are not in any packs[i].ports are ignored
function mergepacks(packs::Array{Pack,1}, interiornames::Array{String,1})
    ports = Dict(union(map(x -> x.ports, packs)...))
    for pack in packs
        if !issubset(pack.ports,ports)
            error("Dimension mismatch between ports.")
        end
    end
    for name in interiornames
        delete!(ports, name)
    end
    orderednames = setdiff(union(map(x -> x.orderednames, packs)...), interiornames)
    return Pack(ports, orderednames)
end

# Same as above, but with no unexposed variables
function mergepacks(packs::Array{Pack,1})
    return mergepacks(packs, Array{String}(undef, 0))
end
