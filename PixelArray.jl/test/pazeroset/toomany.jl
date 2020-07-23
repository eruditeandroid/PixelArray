# Check that taking zero set of function with too many args throws an error
function test_pazeroset_toomany()
    # Create useful variables (these could be args if we really wanted)
    n = 10
    tol = 0.01

    errorthrown = false

    # Try to find zero set of a function with 3 inputs over a 2-variable pack
    port = Port(-1, 1, n)
    packXY = Pack(Dict("X"=>port, "Y"=>port), ["X", "Y"])
    try
        arr = pazeroset(packXY, (x, y, z) -> 0, tol)
    catch Error
        errorthrown = true
    end

    return errorthrown
end
