# Check that the zero set of X + Y for X, Y both positive has no true entries
function test_pazeroset_falses()
    # Create useful variables (these could be args if we really wanted)
    n = 10
    tol = 0.01

    # Create zeroset of X + Y where both are positive
    port = Port(1, 2, n)
    packXY = Pack(Dict("X"=>port, "Y"=>port), ["X", "Y"])
    arr = pazeroset(packXY, (x, y) -> x + y, tol)

    return arr == falses(n, n)
end
