# Check that multiplying the zero array by any array gives the zero array
function test_mult_zero()
    # Create useful variable (this could be an arg if we really wanted)
    n = 10

    # Create pixel arrays (one random, one zero) and packs, PWAs for them
    port = Port(-1, 1, n)
    packXY = Pack(Dict("X"=>port, "Y"=>port), ["X", "Y"])
    packYZ = Pack(Dict("Y"=>port, "Z"=>port), ["Y", "Z"])
    arrYZ = bitrand(n, n)
    pwaXY = PackWithArray(packXY, falses(n, n))
    pwaYZ = PackWithArray(packYZ, arrYZ)

    # Multiply PWAs together, hiding Y
    pwaXZ = mergemult([pwaXY; pwaYZ], ["Y"])

    return pwaXZ.array == falses(n, n)
end
