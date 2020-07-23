# Check that the graph of Y = -X for X, Y both restricted to positive values
# has no true entries
function test_pagraph_falses()
    # Create useful variable (this could be an arg if we really wanted)
    n = 10

    # Create zeroset of X + Y
    port = Port(1, 2, n)
    packXY = Pack(Dict("X"=>port, "Y"=>port), ["X", "Y"])
    arr = pagraph(packXY, x -> -x, "Y")

    return arr == falses(n, n)
end
