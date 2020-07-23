# Check that taking graph of function with too few args throws an error
function test_pagraph_toofew()
    # Create useful variable (this could be an arg if we really wanted)
    n = 10

    errorthrown = false

    # Try to find graph of a function with 1 input over a 3-variable pack
    port = Port(-1, 1, n)
    packXYZ = Pack(Dict("X"=>port, "Y"=>port, "Z"=>port), ["X", "Y", "Z"])
    try
        arr = pagraph(packXYZ, (x) -> 0, "Z")
    catch Error
        errorthrown = true
    end

    return errorthrown
end
