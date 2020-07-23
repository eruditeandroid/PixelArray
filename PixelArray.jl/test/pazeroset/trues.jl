# Check that the zero set of 0 (constant function of 2 vars) has all entries true
function test_pazeroset_trues()
    # Create useful variables (these could be args if we really wanted)
    n = 10
    tol = 0.01

    # Create zeroset of constant function 0
    port = Port(-1, 1, n)
    packXY = Pack(Dict("X"=>port, "Y"=>port), ["X", "Y"])
    arr = pazeroset(packXY, (x, y) -> 0, tol)

    return arr == trues(n, n)
end
