# Given a port returns the range of values taken by the associated variable
function getrange(port::Port)
    stepsize = (port.upperbd - port.lowerbd) / port.resolution
    result = range(port.lowerbd + stepsize / 2.0, length=port.resolution, step=stepsize)
end
