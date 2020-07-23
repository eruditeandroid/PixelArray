# Check that the graph of "Y = X" is the identity matrix
# (where X and Y have the same lower / upper bounds and resolution)
function test_pagraph_identity()
    # Create useful variable (this could be an arg if we really wanted)
    n = 10

    # Create identity matrix
    idmat = falses(n, n)
    for i = 1:n
        idmat[i, i] = true
    end

    # Create zeroset of X - Y
    port = Port(-1, 1, n)
    packXY = Pack(Dict("X"=>port, "Y"=>port), ["X", "Y"])
    arr = pagraph(packXY, identity, "Y")

    return arr == idmat
end
