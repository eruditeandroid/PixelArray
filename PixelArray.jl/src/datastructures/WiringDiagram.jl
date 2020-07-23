struct WiringDiagram
    innerpacks::Array{Pack,1}
    outerpack::Pack
    links::Dict{String,Port} # contains all ports appearing in earlier packs
    orderedlinks::Array{String,1} # order for keys to links
end

# Constructs a wiring diagram from inner packs and a single outer pack
# Automatically populates links and orderedlinks, putting orderedlinks in order
# using order of outerpack, then order of innerpacks in their own order
function WiringDiagram(innerpacks::Array{Pack,1}, outerpack::Pack)
    links = merge(outerpack.ports, map(x -> x.ports, innerpacks)...)
    for pack in union(innerpacks, [outerpack])
        if !issubset(Set(pack.ports),Set(links))
            error("Dimension mismatch between ports.")
        end
    end
    orderedlinks = union(outerpack.orderednames, map(x -> x.orderednames, innerpacks)...)
    return WiringDiagram(innerpacks, outerpack, links, orderedlinks)
end
