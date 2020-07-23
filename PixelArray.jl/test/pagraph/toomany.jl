# Check that taking graph of function with too many args throws an error
function test_pagraph_toomany()
    # Create useful variable (this could be an arg if we really wanted)
    n = 10

    errorthrown = false

    # Try to find graph of a function with 2 inputs over a 2-variable pack
    port = Port(-1, 1, n)
    packXY = Pack(Dict("X"=>port, "Y"=>port), ["X", "Y"])
    try
        arr = pagraph(packXY, (x, y) -> 0, tol)
    catch Error
        errorthrown = true
    end

    return errorthrown
end
