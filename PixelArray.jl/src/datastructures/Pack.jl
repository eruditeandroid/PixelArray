# Structure representing a collection of variables for a single equation / relation
struct Pack
    ports::Dict{String,Port} # ports labeled with variable names
    orderednames::Array{String,1} # order for keys to ports
end

# Constructs a pack from ports, putting the names in arbitrary order
function Pack(ports::Dict{String,Port})
    return Pack(ports, collect(keys(ports)))
end
