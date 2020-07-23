# Check that zero set of f(X1...XN) = X1 (N large) is as expected
function test_pazeroset_manyinputs()
    # Create useful variables (these could be args if we really wanted)
    res = 2
    nports = 5 # making this larger could be a good test of scaling
    tol = 0.01

    # Create expected zero set
    expected = falses(fill(res, nports)...)
    expected[1, fill(Colon(), nports-1)...] = trues(fill(res, nports-1)...)

    # Create pack for X1...XN taking on possible values 0, 1
    port = Port(-1, 3, res) # variable can take on 0 or 1 only
    varnames = map(i -> "X$(i)", 1:nports)
    portdict = Dict{String,Port}()
    for i = 1:nports
        portdict[varnames[i]] = port
    end
    pack = Pack(portdict, varnames)

    # Create zero set for f(X1...XN) = X1 using pazeroset
    arr = pazeroset(pack, (x...) -> x[1], tol)

    return arr == expected
end
