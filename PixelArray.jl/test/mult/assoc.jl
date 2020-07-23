# Check that matrix multiplication is associative
function test_mult_assoc()
    # Create useful variable (this could be an arg if we really wanted)
    n = 10

    # Create random pixel arrays and packs, PWAs for them
    port = Port(-1, 1, n)
    packWX = Pack(Dict("W"=>port, "X"=>port), ["W", "X"])
    packXY = Pack(Dict("X"=>port, "Y"=>port), ["X", "Y"])
    packYZ = Pack(Dict("Y"=>port, "Z"=>port), ["Y", "Z"])
    arrWX = bitrand(n, n)
    arrXY = bitrand(n, n)
    arrYZ = bitrand(n, n)
    pwaWX = PackWithArray(packWX, arrWX)
    pwaXY = PackWithArray(packXY, arrXY)
    pwaYZ = PackWithArray(packYZ, arrYZ)

    # Multiply in two different orders (hiding x and y)
    result1 = mergemult([pwaWX; mergemult([pwaXY, pwaYZ], ["Y"])], ["X"])
    result2 = mergemult([mergemult([pwaWX, pwaXY], ["X"]); pwaYZ], ["Y"])

    return result1.array == result2.array
end
