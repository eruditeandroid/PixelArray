# Code for pixel arrays + array multiplication, based on Spivak et al's paper
module PixelArray

# RecipesBase for plotting via JuliaPlots
using RecipesBase

export Port, Pack, PackWithArray, WiringDiagram,
pazeroset, pagraph,
mergepacks, mergemult, mergemultviawds, getsolnset

# Data structures used
include("./datastructures/Port.jl")
include("./datastructures/Pack.jl")
include("./datastructures/PackWithArray.jl")
include("./datastructures/WiringDiagram.jl")

# Functions for creating arrays
include("./arraycreation/createauxpack.jl")
include("./arraycreation/getrange.jl")
include("./arraycreation/pazeroset.jl")
include("./arraycreation/pagraph.jl")

# Function for multiplying arrays
include("./arraymultiplication/multarrays.jl")

# Functions for merging PacksWithArrays
include("./pwamerging/mergepacks.jl")
include("./pwamerging/mergemult.jl")
include("./pwamerging/mergemultviawds.jl")

# Functions for graphically displaying PacksWithArrays
include("./pwaplotting/findticks.jl")
include("./pwaplotting/pwaplotter.jl")

# Miscellaneous functions
include("./misc/getsolnset.jl")
include("./misc/pixelmin.jl")

end # module
