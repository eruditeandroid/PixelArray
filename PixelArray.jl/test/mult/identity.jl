# Check that multiplying any matrix by the identity gives back that matrix
function test_mult_identity()
    n = 10

    # Create identity matrix
    idmat = falses(n, n)
    for i = 1:n
        idmat[i, i] = true
    end

    # Create PacksWithArrays for identity on pack with variables X, Y
    # and a random BitArray (with correct dimensions) on pack with variables
    port = Port(-1, 1, n)
    packXY = Pack(Dict("X"=>port, "Y"=>port), ["X", "Y"])
    packYZ = Pack(Dict("Y"=>port, "Z"=>port), ["Y", "Z"])
    pwaXY = PackWithArray(packXY, idmat)
    arrYZ = bitrand(n, n)
    pwaYZ = PackWithArray(packYZ, arrYZ)

    # Compute product of the PacksWithArrays, hiding Y
    pwaXZ = mergemult([pwaXY; pwaYZ], ["Y"])

    return pwaXZ.array == arrYZ
end
