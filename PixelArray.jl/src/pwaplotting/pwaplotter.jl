# Recipe for plotting a given 2-D PackWithArray as a heatmap with labeled axes
# No need to call this function, just import JuliaPlots and use plot(yourpwa)
# numxticks, numyticks specify ticks along x, y axes
@recipe function pwaplotter(pwa::PackWithArray; numxticks = 5, numyticks = 5)
    # Check for errors in input (errors in numxticks, numyticks handled by findticks)
    if ndims(pwa.array) != 2
        error("Input must be 2-dimensional.")
    end

    # These are flipped from the pwa.pack order to correspond with heatmap results
    # See the original pixel array paper for a discussion of matrix indexing vs. graphing conventions
    xname = pwa.pack.orderednames[2]
    xport = pwa.pack.ports[xname]
    yname = pwa.pack.orderednames[1]
    yport = pwa.pack.ports[yname]

    # Set attributes for plot (must be a heatmap, all others optional)
    seriestype := :heatmap
    colorbar --> false
    aspect_ratio --> :equal
    xlabel --> xname
    xticks --> findticks(xport, numxticks)
    ylabel --> yname
    yticks --> findticks(yport, numyticks)

    # Send array attached to pwa to plot(...)
    pwa.array
end
