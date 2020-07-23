# Structures and functions for solving power flow problems via pixel arrays
# Convention: P > 0 corresponds to consumption, θ is in radians
# Parallelization removed; to restore it use @everywhere on the module and pmap in getpfpwas

module PixelArrayPowerFlow

using PixelArray, DelimitedFiles

export Network, PackSetupParams, importnetwork, setbounds, getpfpwas, hidePQ, clustertree

#--------------------------------------------------------------------------------------------------
# Types describing network structure
#--------------------------------------------------------------------------------------------------

abstract type BusParams
end

struct PQParams <: BusParams
    P::Float64
    Q::Float64
end

struct PVParams <: BusParams
    P::Float64
    V::Float64
end

struct SlackParams <: BusParams
    V::Float64
    θ::Float64
end

struct FreeParams <: BusParams
end

struct Gen
    # Better for our purposes to have buses point to gens rather than the other way around
    Pmin::Float64
    Pmax::Float64
    Qmin::Float64
    Qmax::Float64
end

struct Bus
    id::Int64
    Vmin::Float64
    Vmax::Float64
    θmin::Float64
    θmax::Float64
    Bshunt::Float64
    Gshunt::Float64
    gen::Union{Gen, Nothing}
    params::BusParams
end

struct Branch
    frombus::Bus
    tobus::Bus
    Bshunt::Float64
    R::Float64
    X::Float64
    tap::Float64 # is this the same as akm???
    shift::Float64
end

struct Network
    branches::Array{Branch,1}
    buses::Array{Bus,1}
    gens::Array{Gen,1}
    basemva::Float64
end

# Parameters for setting up packs in getpfpwas, getpfpacks
struct PackSetupParams
    Pres::Int64
    Qres::Int64
    Vres::Int64
    θres::Int64
end

#--------------------------------------------------------------------------------------------------
# Function for importing a network into Julia given a folder of CSV files specifying network data
#--------------------------------------------------------------------------------------------------

# Given a path to a folder containing files gen.csv, bus.csv, and branch.csv
# imports all gens / branches / buses in that folder and combines them into a network
# for later use in solving power flow problems
# Files should be organized similarly to output from matpower_2_aql.m
# Also takes optional argument (default = 100.0) specifying base MVA of system
# as well as optional arguments (default -π/6, π/6) specifying θ range of all buses in system
function importnetwork(folderpath::AbstractString, basemva::Float64=100.0, θmin::Float64=-π/6, θmax::Float64=π/6)
    # Import generators
    gencsv = readdlm(folderpath * "/gen.csv", ',')
    genlabels = gencsv[1,:]
    gendata = gencsv[2:end,:]
    geninputcols = indexin(["PMIN", "PMAX", "QMIN", "QMAX"], genlabels)
    othergencols = indexin(["GEN_BUS","PG","QG"], genlabels)
    gens = map(i -> Gen(map(j -> gendata[i,j], geninputcols)...), 1:size(gendata)[1])

    # Determine gen. assignments for each bus
    genbusindex = othergencols[1]
    busgenkvpairs = map(i -> (gendata[i,genbusindex], i), 1:length(gens))
    busgendict = Dict(busgenkvpairs)

    # Import buses
    buscsv = readdlm(folderpath * "/bus.csv", ',')
    buslabels = buscsv[1,:]
    busdata = buscsv[2:end,:]
    businputcols1 = indexin(["BUS_I", "VMIN", "VMAX"], buslabels)
    businputcols2 = indexin(["GS", "BS"], buslabels)
    otherbuscols = indexin(["BUS_TYPE", "PD", "QD", "VM", "VA"], buslabels)
    bustypeindex = otherbuscols[1]
    buses = Array{Bus}(undef, size(busdata)[1])
    for i in 1:length(buses)
        if haskey(busgendict, i)
            gen = gens[busgendict[i]]
        else
            gen = nothing
        end
        if busdata[i,bustypeindex] == 1 # PQ bus
            if gen === nothing
                P = busdata[i,otherbuscols[2]]
                Q = busdata[i,otherbuscols[3]]
            else
                P = -gendata[busgendict[i],othergencols[2]] + busdata[i,otherbuscols[2]]
                Q = -gendata[busgendict[i],othergencols[2]] + busdata[i,otherbuscols[3]]
            end
            params = PQParams(P,Q)
        elseif busdata[i,bustypeindex] == 2 # PV bus
            P = gendata[busgendict[i],othergencols[2]] - busdata[i,otherbuscols[2]]
            V = busdata[i,otherbuscols[4]]
            params = PVParams(P,V)
        elseif busdata[i,bustypeindex] == 3 # Slack bus
            V = busdata[i,otherbuscols[4]]
            θ = busdata[i,otherbuscols[5]]
            params = SlackParams(V,θ)
        elseif busdata[i,bustypeindex] == -1 # Free bus
            params = FreeParams()
        end
        buses[i] = Bus(map(j -> busdata[i,j], businputcols1)..., θmin, θmax, map(j -> busdata[i,j], businputcols2)..., gen, params)
    end

    # Import branches
    branchcsv = readdlm(folderpath * "/branch.csv", ',')
    branchlabels = branchcsv[1,:]
    branchdata = branchcsv[2:end,:]
    branchinputcols = indexin(["BR_B","BR_R","BR_X","TAP","SHIFT"], branchlabels)
    otherbranchcols = indexin(["F_BUS","T_BUS"], branchlabels)
    # If TAP in input is zero replace it with 1 (for some reason Matpower likes to save TAP = 1 as zero)
    tapindex = branchinputcols[4]
    branchdata[:,tapindex] = map(x -> x == zero(x) ? one(x) : x, branchdata[:,tapindex])
    # Compute other variables and store in branch form
    frombuses = map(i -> buses[branchdata[i,otherbranchcols[1]]], 1:size(branchdata)[1])
    tobuses = map(i -> buses[branchdata[i,otherbranchcols[2]]], 1:size(branchdata)[1])
    branches = map(i -> Branch(frombuses[i],tobuses[i],map(j -> branchdata[i,j],branchinputcols)...), 1:size(branchdata)[1])

    return Network(branches, buses, gens, basemva)
end

#--------------------------------------------------------------------------------------------------
# Functions for modifying variables attached to an existing network
#--------------------------------------------------------------------------------------------------

# Sets variable of given type ("P", "Q", "V", "θ") on network n attached to n.buses[given i]
# to specified lower / upper bounds (at least one must be specified)
# Input "TH" is also possible instead of "θ" if ASCII is preferable
function setbounds(n::Network, var::String, busindex::Int; lowerbd::Union{Float64,Nothing}=nothing, upperbd::Union{Float64,Nothing}=nothing)
    # Check for errors in bounds
    if lowerbd === nothing && upperbd === nothing
        error("At least one value attached to the given variable must be set.")
    elseif lowerbd != nothing && upperbd != nothing && upperbd <= lowerbd
        error("Lower bound must be strictly less than upper bound.")
    elseif (var == "P" || var == "Q") && (bus.gen === nothing)
        error("Cannot set P or Q of a bus with no generator attached.")
    elseif var != "P" && var != "Q" && var != "V" && var != "θ" && var != "TH"
        error("Specified variable does not exist.")
    end

    # Find desired bus
    bus = n.buses[busindex]

    # Set bounds for the specified variable
    if lowerbd != nothing
        if var == "P"
            bus.gen.Pmin = lowerbd
        elseif var == "Q"
            bus.gen.Qmin = lowerbd
        elseif var == "V"
            bus.Vmin = lowerbd
        elseif var == "θ" || var == "TH"
            bus.θmin = lowerbd
        end
    elseif upperbd != nothing
        if var == "P"
            bus.gen.Pmax = upperbd
        elseif var == "Q"
            bus.gen.Qmax = upperbd
        elseif var == "V"
            bus.Vmax = upperbd
        elseif var == "θ" || var == "TH"
            bus.θmax = upperbd
        end
    end
end

#--------------------------------------------------------------------------------------------------
# Functions for automatically generating arrays of PacksWithArrays from networks
#--------------------------------------------------------------------------------------------------

# Returns a pair of PacksWithArrays for each entry in n.buses
# Result is array with size 2 * length(n.buses)
# P equation for bus i corresponds to spot 2i - 1, Q equation corresponds to spot 2i
function getpfpwas(n::Network, psp::PackSetupParams, tol)
    packs = getpfpacks(n, psp)
    result = Array{PackWithArray}(undef, 2 * length(n.buses))
    resultpqtuples = map(i -> getpwasforbus(n, i, packs[2i-1], packs[2i], tol), 1:length(n.buses))
    for i in 1:length(resultpqtuples)
        result[2i-1] = resultpqtuples[i][1]
        result[2i] = resultpqtuples[i][2]
    end
    return result
end

# Returns a 1-D array of packs (for solving power flow via pixel arrays)
# Result has 2 packs for each bus (both adjacent) - one for P equation, one for Q equation
# P equation for bus in position i corresponds to spot 2i - 1, Q equation corresponds to spot 2i
# For each bus, orderednames has that bus's variables first, followed by variables in order Pi, Qi, Vi, θi, Pi+1...
# For now angles are restricted to be between -π/6 and π/6
function getpfpacks(n::Network, psp::PackSetupParams)
    # General setup
    result = Array{Pack,1}(undef, 2*length(n.buses))
    Pports = Array{Port,1}(undef, length(n.buses))
    Qports = Array{Port,1}(undef, length(n.buses))
    Vports = Array{Port,1}(undef, length(n.buses))
    θports = Array{Port,1}(undef, length(n.buses))
    adjmat = getadjacencymatrix(n)
    portkvarray = Array{Tuple{String,Port}}(undef, 0)
    orderednames = Array{String}(undef, 0)

    # Anonymous functions to avoid too much code copying
    pushPport = i -> begin
        name = "P$(n.buses[i].id)"
        push!(orderednames, name)
        push!(portkvarray, (name, Pports[i]))
    end
    pushQport = i -> begin
        name = "Q$(n.buses[i].id)"
        push!(orderednames, name)
        push!(portkvarray, (name, Qports[i]))
    end
    pushVport = i -> begin
        name = "V$(n.buses[i].id)"
        push!(orderednames, name)
        push!(portkvarray, (name, Vports[i]))
    end
    pushθport = i -> begin
        name = "θ$(n.buses[i].id)"
        push!(orderednames, name)
        push!(portkvarray, (name, θports[i]))
    end
    pushportsfrombus = i -> begin
        if n.buses[i].params isa PQParams
            pushVport(i)
            pushθport(i)
        elseif n.buses[i].params isa PVParams
            pushθport(i)
        elseif n.buses[i].params isa SlackParams
            # do nothing
        elseif n.buses[i].params isa FreeParams
            pushVport(i)
            pushθport(i)
        end
    end

    # Instantiate all ports
    for i in 1:length(n.buses)
        bus = n.buses[i]
        if bus.params isa PQParams
            Vports[i] = Port(bus.Vmin, bus.Vmax, psp.Vres)
            θports[i] = Port(bus.θmin, bus.θmax, psp.θres)
        elseif bus.params isa PVParams
            Qports[i] = Port(bus.gen.Qmin, bus.gen.Qmax, psp.Qres)
            θports[i] = Port(bus.θmin, bus.θmax, psp.θres)
        elseif bus.params isa SlackParams
            Pports[i] = Port(bus.gen.Pmin, bus.gen.Pmax, psp.Pres)
            Qports[i] = Port(bus.gen.Qmin, bus.gen.Qmax, psp.Qres)
        elseif bus.params isa FreeParams
            Pports[i] = Port(bus.gen.Pmin, bus.gen.Pmax, psp.Pres)
            Qports[i] = Port(bus.gen.Qmin, bus.gen.Qmax, psp.Qres)
            Vports[i] = Port(bus.Vmin, bus.Vmax, psp.Vres)
            θports[i] = Port(bus.θmin, bus.θmax, psp.θres)
        end
    end

    # Create packs out of ports
    for i in 1:length(n.buses)
        # Reinitialize parameters for constructor
        portkvarray = Array{Tuple{String,Port}}(undef, 0)
        orderednames = Array{String}(undef, 0)
        # Handle ports for this bus
        pushportsfrombus(i)
        # Handle ports for other buses
        for j in 1:length(n.buses)
            if adjmat[i,j] == true
                pushportsfrombus(j)
            end
        end
        # Create pack input data for each equation
        bus = n.buses[i]
        if bus.params isa PQParams
            Peqports = Dict{String,Port}(portkvarray)
            Porderednames = copy(orderednames)
            Qeqports = Dict{String,Port}(portkvarray)
            Qorderednames = copy(orderednames)
        elseif bus.params isa PVParams
            Peqports = Dict{String,Port}(portkvarray)
            Porderednames = copy(orderednames)
            Qeqports = Dict{String,Port}(union([("Q$(bus.id)", Qports[i])], portkvarray))
            Qorderednames = union(["Q$(bus.id)"], orderednames)
        elseif bus.params isa SlackParams
            Peqports = Dict{String,Port}(union([("P$(bus.id)", Pports[i])], portkvarray))
            Porderednames = union(["P$(bus.id)"], orderednames)
            Qeqports = Dict{String,Port}(union([("Q$(bus.id)", Qports[i])], portkvarray))
            Qorderednames = union(["Q$(bus.id)"], orderednames)
        elseif bus.params isa FreeParams
            Peqports = Dict{String,Port}(union([("P$(bus.id)", Pports[i])], portkvarray))
            Porderednames = union(["P$(bus.id)"], orderednames)
            Qeqports = Dict{String,Port}(union([("Q$(bus.id)", Qports[i])], portkvarray))
            Qorderednames = union(["Q$(bus.id)"], orderednames)
        end
        # Create and store packs
        result[2i-1] = Pack(Peqports, Porderednames)
        result[2i] = Pack(Qeqports, Qorderednames)
    end
    return result
end

# Returns pair of PacksWithArrays for P, Q equations for a given bus (corresponding to busindex)
# Also wants packs for these equations
function getpwasforbus(n::Network, busindex::Int, Ppack::Pack, Qpack::Pack, tol::Float64)
    bus = n.buses[busindex]
    adjbranches = getadjacentbranches(n, bus)

    # Create functions for power flow at the bus
    Peq = getPeqfree(n, bus, adjbranches)
    Qeq = getQeqfree(n, bus, adjbranches)

    # Give values to fixed inputs into functions
    Pfixedvars = Dict{Int64,Float64}()
    Qfixedvars = Dict{Int64,Float64}()
    if bus.params isa PQParams
        Pfixedvars[1] = bus.params.P
        Qfixedvars[1] = bus.params.Q
    elseif bus.params isa PVParams
        Pfixedvars[1] = bus.params.P
        Pfixedvars[2] = bus.params.V
        Qfixedvars[2] = bus.params.V
    elseif bus.params isa SlackParams
        Pfixedvars[2] = bus.params.V
        Pfixedvars[3] = bus.params.θ
        Qfixedvars[2] = bus.params.V
        Qfixedvars[3] = bus.params.θ
    elseif bus.params isa FreeParams
        # Do nothing
    end
    for j in 1:length(adjbranches)
        otherbus = adjbranches[j].tobus
        if otherbus.params isa PVParams
            Pfixedvars[2j+2] = otherbus.params.V
            Qfixedvars[2j+2] = otherbus.params.V
        elseif otherbus.params isa SlackParams
            Pfixedvars[2j+2] = otherbus.params.V
            Pfixedvars[2j+3] = otherbus.params.θ
            Qfixedvars[2j+2] = otherbus.params.V
            Qfixedvars[2j+3] = otherbus.params.θ
        end
    end

    # Create PacksWithArrays for the given bus
    result = (PackWithArray(Ppack, pazeroset(Ppack, Peq, tol, Pfixedvars)),
        PackWithArray(Qpack, pazeroset(Qpack, Qeq, tol, Qfixedvars)))

    #=
    if !(any(result[1][2]) && any(result[2][2]))
        error("No solution found. Suggestion: increase the resolution of one or more variables.")
    end

    println("Bus $busindex sent to PacksWithArrays.")
    =#

    return result
end

#--------------------------------------------------------------------------------------------------
# Functions for finding adjacency matrices / branches adjacent to a given bus as necessary
#--------------------------------------------------------------------------------------------------

# Returns adjacency matrix for the given network (viewed as a graph with vertices = buses, edges = branches)
function getadjacencymatrix(n::Network)
    halfmatrix = falses(length(n.buses),length(n.buses))
    fromindices = indexin(map(x -> x.frombus, n.branches), n.buses)
    toindices = indexin(map(x -> x.tobus, n.branches), n.buses)
    for i in 1:length(fromindices)
        halfmatrix[fromindices[i],toindices[i]] = true
    end
    result = broadcast(|, halfmatrix, halfmatrix')
    return result
end

# Returns an array of branches adjacent to a given bus.
# Uses flipbranch to make all branches in array have that bus as from_bus
function getadjacentbranches(n::Network, bus::Bus)
    fliptofrom = br::Branch -> begin
        if br.frombus == bus
            return br
        else
            return flipbranch(br)
        end
    end
    result = map(fliptofrom, filter(br -> (br.frombus == bus || br.tobus == bus), n.branches))
    return result
end

# Gets indices of buses adjacent to the given bus
function getadjacentindices(n::Network, busindex::Integer)
    return findall(getadjacencymatrix(n)[busindex,:])
end

# Given a branch from bus A to B, returns the interpretation of that branch going from B to A
# Tap & shift are reversed
function flipbranch(br::Branch)
    if br.tap == 0
        return Branch(br.tobus, br.frombus, br.Bshunt, br.R, br.X, br.tap, -br.shift)
    else
        return Branch(br.tobus, br.frombus, br.Bshunt, br.R, br.X, 1 / br.tap, -br.shift)
    end
end

#--------------------------------------------------------------------------------------------------
# Functions for automatically generating power flow equations from networks
#--------------------------------------------------------------------------------------------------

# Returns a function ΣPkm - Pk which when set equal to zero gives the real power flow equation for bus
# Arguments are (in order) P, V, θ from this bus, then V, θ (next to each other) from each adjacent bus
# in the order of ports from getpowerflowpacks
# Result is per unit
# Equations come from Kundur 1994, eq. 6.101
# No tap / phase data is included (for now)
function getPeqfree(n::Network, bus::Bus, adjbranches::Array{Branch, 1})
    brG = map(br -> br.R / (br.R^2 + br.X^2), adjbranches)
    brB = map(br -> - br.X / (br.R^2 + br.X^2), adjbranches)
    function Peq(x...)
        result = -(x[1] / n.basemva) + (bus.Gshunt * x[2]^2)
        # Add power along branches
        result += x[2] * sum(i -> x[2i+2] * ((brG[i] * cos(x[2i+3] - x[3])) + (brB[i] * sin(x[2i+3] - x[3]))), 1:length(adjbranches))
        return result
    end
    return Peq
end

# Returns a function ΣQkm - Qk which when set equal to zero gives the real power flow equation for bus
# Arguments are (in order) P, V, θ from this bus, then V, θ (next to each other) from each adjacent bus
# in the order of ports from getpowerflowpacks
# Result is per unit
# Equations come from Kundur 1994, eq. 6.101
# No tap / phase data is included (for now)
function getQeqfree(n::Network, bus::Bus, adjbranches::Array{Branch, 1})
    brG = map(br -> br.R / (br.R^2 + br.X^2), adjbranches)
    brB = map(br -> - br.X / (br.R^2 + br.X^2), adjbranches)
    function Qeq(x...)
        result = -(x[1] / n.basemva) - (bus.Bshunt * x[2]^2)
        # Add power along branches
        result += x[2] * sum(i -> x[2i+2] * ((brG[i] * sin(x[2i+3] - x[3])) - (brB[i] * cos(x[2i+3] - x[3]))), 1:length(adjbranches))
        return result
    end
    return Qeq
end


#--------------------------------------------------------------------------------------------------
# Functions for automatically multiplying results of getpfpwas(...)
#--------------------------------------------------------------------------------------------------

# Hides P and Q for all n.buses[i] in network where i is in hideindices
function hidePQ(n::Network, pwas::Array{PackWithArray,1}, hideindices::Array{Int,1})
    result = copy(pwas)
    for i in hideindices
        bus = n.buses[i]
        if bus.params isa PQParams
            # nothing to hide
        elseif bus.params isa PVParams
            result[2i] = mergemult([pwas[2i]],["Q$(n.buses[i].id)"])
        elseif bus.params isa SlackParams
            result[2i-1] = mergemult([pwas[2i-1]],["P$(n.buses[i].id)"])
            result[2i] = mergemult([pwas[2i]],["Q$(n.buses[i].id)"])
        elseif bus.params isa FreeParams
            result[2i-1] = mergemult([pwas[2i-1]],["P$(n.buses[i].id)"])
            result[2i] = mergemult([pwas[2i]],["Q$(n.buses[i].id)"])
        end
    end
    return result
end

# Assuming network is a tree with the given head, merge and multiply it recursively
# Hides V, θ of all non-head nodes; does nothing about P and Q (call hidePQ if you want to do that)
# parentindex gives the parent of the current entry (if called via recursion) or 0 if this is the head of the whole tree
function clustertree(n::Network, pwas::Array{PackWithArray,1}, headindex::Integer, parentindex::Integer=0)
    childrenindices = setdiff(getadjacentindices(n, headindex), [parentindex])
    if isempty(childrenindices)
        # Base case: merge P, Q equations of leaf
        result = mergemult([pwas[2headindex-1],pwas[2headindex]])
    else
        # Recursively compute clustered children, then merge this with children hiding their Vs and θs
        clusteredchildren = map(i -> clustertree(n, pwas, i, headindex), childrenindices)
        # Merge with first child separately
        result = mergemult([pwas[2headindex-1],clusteredchildren[1]])
        result = mergemult([result, pwas[2headindex]],["V$(childrenindices[1])","θ$(childrenindices[1])"])
        for i in 2:length(clusteredchildren)
            result = mergemult([result, clusteredchildren[i]],["V$(childrenindices[i])","θ$(childrenindices[i])"])
        end
    end
    return result
end

end
