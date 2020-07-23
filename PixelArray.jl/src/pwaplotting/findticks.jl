# Computes tick values for plotting axis based on given port
# Returns a tuple consisting of a range and an array of strings for each element of the range
# When input as xticks = ... in plot(...) gives equal-spaced ticks with correct values
function findticks(port::Port, numticks::Int; roundingdigits::Int = 2)
    # Check for errors in input (specifically numticks)
    if numticks < 2
        error("Cannot plot with less than 2 ticks on an axis.")
    elseif numticks > port.resolution
        error("Cannot plot with more ticks than resolution of port.")
    end

    # Compute value of port variable at numticks equal-spaced ticks
    tickstep = port.resolution / (numticks - 1)
    tickvalues = fill("", port.resolution)
    tickvalues[1] = "$(port.lowerbd)"
    for i = 2:(numticks-1)
        totalsteps = (i-1) * tickstep
        value = port.lowerbd + (totalsteps / port.resolution) * (port.upperbd - port.lowerbd)
        tickvalues[floor(Int, totalsteps) + 1] = "$(round(value, digits = roundingdigits))"
    end
    tickvalues[end] = "$(port.upperbd)"

    # Form and return result
    result = (1:port.resolution, tickvalues)
    return result
end
