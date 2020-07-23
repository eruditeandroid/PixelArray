# Check that the zero set of X - Y with a low tolerance (relative to bin size)
# is the identity matrix
function test_pazeroset_identity()
    # Create useful variables (these could be args if we really wanted)
    n = 10
    tol = 0.01

    # Create identity matrix
    idmat = falses(n, n)
    for i = 1:n
        idmat[i, i] = true
    end

    # Create zeroset of X - Y
    port = Port(-1, 1, n)
    packXY = Pack(Dict("X"=>port, "Y"=>port), ["X", "Y"])
    arr = pazeroset(packXY, (x, y) -> x - y, tol)

    return arr == idmat
end
