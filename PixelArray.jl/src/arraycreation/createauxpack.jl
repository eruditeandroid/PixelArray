# Creates an "auxiliary pack" for creating pixel arrays for problems with fixed inputs to the function
# Result is a copy of input pack with length(fixed) new variables adjoined at positions from keys(fixed)
# These adjoined variables all have resolution 1 and take on a fixed value from values(fixed)
# Adjoined variables satisfy result.ports[]
function createauxpack(pack::Pack, fixed::Dict{Int64,Float64})
    # Create values stored in auxiliary pack, inheriting what we can from pack
    auxorderednames = Array{String}(undef, length(pack.orderednames) + length(keys(fixed)))
    auxports = copy(pack.ports)
    # Add fixed variables to what will become result.ports, result.orderednames
    for kv in fixed
        name = "fixedvar_aux$(kv[1])"
        if haskey(auxports, name)
            error("Variables in pack should not have names starting with 'fixedvar_aux'.")
        end
        auxorderednames[kv[1]] = name
        auxports[name] = Port(kv[2],kv[2],1) # 1-resolution port for val <= x <= val
    end
    # Add original variables to what will become result.orderednames
    orderednamesindex = 1
    for i in 1:length(auxorderednames)
        if !haskey(fixed, i)
            auxorderednames[i] = pack.orderednames[orderednamesindex]
            orderednamesindex += 1
        end
    end
    result = Pack(auxports, auxorderednames)
    return result
end
