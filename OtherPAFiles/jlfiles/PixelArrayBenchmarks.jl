# This isn't actually a module so it should be moved somewhere else on a later
# reorganization of the code here.

using PixelArray, Test, Random

# Benchmark time it takes to find zero set of function f(X1...XN) = X1
# over a pack of size (res)^N (various N used)
function benchmark_pazeroset(res::Int, ntrials::Int)
    # Set variables which will be useful later
    times = fill(0.0, ntrials)
    tol = 0.01

    # Run through trials for increasing number of variables
    for nports = 1:ntrials
        # Create ports, packs for use soon
        port = Port(-0.5, res + 0.5, res)
        varnames = map(i -> "X$(i)", 1:nports)
        portdict = Dict{String,Port}()
        for i = 1:nports
            portdict[varnames[i]] = port
        end
        pack = Pack(portdict, varnames)

        # Compute time necessary to run pazeroset on given function, pack
        times[nports] = @elapsed begin
            pazeroset(pack, (x...) -> x[1], tol)
        end
    end

    for i in 1:length(times)
        println("# of Ports: $(i) | Time: $(times[i])")
    end
end

# Benchmark time it takes to find zero set of "function" f(X1...XN) = random in {0, 1}
# over a pack of size (res)^N (various N used)
function benchmark_pazeroset_random(res::Int, ntrials::Int)
    # Set variables which will be useful later
    times = fill(0.0, ntrials)
    tol = 0.01

    # Run through trials for increasing number of variables
    for nports = 1:ntrials
        # Create ports, packs for use soon
        port = Port(0.0, 1.0, res)
        varnames = map(i -> "X$(i)", 1:nports)
        portdict = Dict{String,Port}()
        for i = 1:nports
            portdict[varnames[i]] = port
        end
        pack = Pack(portdict, varnames)

        # Compute time necessary to run pazeroset on given function, pack
        times[nports] = @elapsed begin
            pazeroset(pack, (x...) -> rand(Bool), tol)
        end
    end

    for i in 1:length(times)
        println("# of Ports: $(i) | Time: $(times[i])")
    end
end

# Benchmark time it takes to find graph of function X1 = f(X2...XN) = 0
# over a pack of size (res)^N (various N used)
function benchmark_pagraph(res::Int, ntrials::Int)
   # Set variables which will be useful later
   times = fill(0.0, ntrials)

   # Run through trials for increasing number of variables
   for nports = 1:ntrials
       # Create ports, packs for use soon
       port = Port(-0.5, res + 0.5, res)
       varnames = map(i -> "X$(i)", 1:nports)
       portdict = Dict{String,Port}()
       for i = 1:nports
           portdict[varnames[i]] = port
       end
       pack = Pack(portdict, varnames)

       # Compute time necessary to run pagraph on given function, pack
       times[nports] = @elapsed begin
           pagraph(pack, (x...) -> 0.0, "X1")
       end
   end

   for i in 1:length(times)
       println("# of Ports: $(i) | Time: $(times[i])")
   end
end

# Benchmark time it takes to find graph of a "function" which returns random values
# over a pack of size (res)^N (various N used)
function benchmark_pagraph_random(res::Int, ntrials::Int)
    # Set variables which will be useful later
    times = fill(0.0, ntrials)

    # Run through trials for increasing number of variables
    for nports = 1:ntrials
        # Create ports, packs for use soon
        port = Port(0.0, 1.0, res)
        varnames = map(i -> "X$(i)", 1:nports)
        portdict = Dict{String,Port}()
        for i = 1:nports
            portdict[varnames[i]] = port
        end
        pack = Pack(portdict, varnames)

        # Compute time necessary to run pagraph on given function, pack
        times[nports] = @elapsed begin
            pagraph(pack, (x...) -> rand(), "X1")
        end
    end

    for i in 1:length(times)
        println("# of Ports: $(i) | Time: $(times[i])")
    end
 end

# Benchmark time it takes to multiply two N-dimensional arrays over the same variables
# After multiplication all variables are hidden
function benchmark_mult_samevars(res::Int, ntrials::Int)
    # Set variables which will be useful later
    times = fill(0.0, ntrials)

    # Run through trials for increasing number of variables
    for nports = 1:ntrials
        # Create ports, packs, PWAs for use soon
        port = Port(-1.0, 1.0, res)
        varnames = map(i -> "X$(i)", 1:nports)
        portdict = Dict{String,Port}()
        for i = 1:nports
            portdict[varnames[i]] = port
        end
        pack = Pack(portdict, varnames)
        pwa1 = PackWithArray(pack, bitrand(fill(res, nports)...))
        pwa2 = PackWithArray(pack, bitrand(fill(res, nports)...))

        times[nports] = @elapsed begin
            mergemult([pwa1, pwa2], varnames)
        end
    end

    for i in 1:length(times)
        println("# of Ports: $(i) | Time: $(times[i])")
    end
end

# Benchmark time it takes to multiply two N-dimensional arrays over disjoint sets of variables
# After multiplication all variables are hidden
function benchmark_mult_diffvars(res::Int, ntrials::Int)
    # Set variables which will be useful later
    times = fill(0.0, ntrials)

    # Run through trials for increasing number of variables
    for halfnports = 1:ntrials
        # Create ports, packs, PWAs for use soon
        port = Port(-1.0, 1.0, res)
        varnamesX = map(i -> "X$(i)", 1:halfnports)
        varnamesY = map(i -> "Y$(i)", 1:halfnports)
        portdictX = Dict{String,Port}()
        portdictY = Dict{String,Port}()
        for i = 1:halfnports
            portdictX[varnamesX[i]] = port
            portdictY[varnamesY[i]] = port
        end
        packX = Pack(portdictX, varnamesX)
        packY = Pack(portdictY, varnamesY)
        pwaX = PackWithArray(packX, bitrand(fill(res, halfnports)...))
        pwaY = PackWithArray(packY, bitrand(fill(res, halfnports)...))

        times[halfnports] = @elapsed begin
            mergemult([pwaX, pwaY], union(varnamesX, varnamesY))
        end
    end

    for i in 1:length(times)
        println("# of Ports: $(2*i) | Time: $(times[i])")
    end
end
