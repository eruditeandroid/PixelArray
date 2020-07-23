# Check that multiplying arrays over the same variables and hiding none operates
# as a bitwise AND on the arrays
function test_mult_and()
    # Create useful variable (this could be an arg if we really wanted)
    n = 10

    # Create random pixel arrays over the same variable and packs, PWAs for them
    port = Port(-1, 1, n)
    pack = Pack(Dict("X"=>port, "Y"=>port), ["X", "Y"])
    arr1 = bitrand(n, n)
    arr2 = bitrand(n, n)
    pwa1 = PackWithArray(pack, arr1)
    pwa2 = PackWithArray(pack, arr2)

    # Multiply PWAs together, hiding nothing
    pwa3 = mergemult([pwa1; pwa2])

    return pwa3.array == (arr1 .& arr2)
end
