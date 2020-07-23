# Structure representing a single real (Float64) variable
# Future work: generalize this to other FloatXXs / variable types???
struct Port
    lowerbd::Float64
    upperbd::Float64
    resolution::Int64
end
