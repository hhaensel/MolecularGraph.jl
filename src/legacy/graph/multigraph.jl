#
# This file is a part of MolecularGraph.jl
# Licensed under the MIT License http://opensource.org/licenses/MIT
#

export
    hasselfloop, hasmultiedge, issimplegraph


function hasselfloop(graph::Union{OrderedGraph,OrderedDiGraph})
    for (u, v) in edgesiter(graph)
        u == v && return true
    end
    return false
end


function hasmultiedge(graph::Union{OrderedGraph,OrderedDiGraph})
    for nbr in neighborsiter(graph)
        length(nbr) == length(Set(values(nbr))) || return true
    end
    return false
end


issimplegraph(graph::Union{OrderedGraph,OrderedDiGraph}
    ) = !hasselfloop(graph) && !hasmultiedge(graph)
