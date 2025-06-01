#
# This file is a part of MolecularGraph.jl
# Licensed under the MIT License http://opensource.org/licenses/MIT
#

export
    connectedcomponents, connectedmembership,
    findbiconnected, cutvertices, bridges, edgebiconnectedcomponents


"""
    connectedcomponents(graph::UndirectedGraph) -> Vector{Set{Int}}

Compute connectivity and return sets of the connected components.
"""
function connectedcomponents(graph::UndirectedGraph)
    nodes = nodeset(graph)
    components = Set{Int}[]
    while !isempty(nodes)
        root = pop!(nodes)
        tree = Set(keys(dfstree(adjacencies, graph, root)))
        push!(components, tree)
        setdiff!(nodes, tree)
    end
    return components
end

"""
    connectedmembership(graph::UndirectedGraph) -> Vector{Int}

Return connected component membership array.
"""
function connectedmembership(graph::UndirectedGraph)
    mem = zeros(Int, nodecount(graph))
    for (i, conn) in enumerate(connectedcomponents(graph))
        for n in conn
            mem[n] = i
        end
    end
    return mem
end


struct BiconnectedState{T<:UndirectedGraph}
    graph::T

    pred::Dict{Int,Int}
    level::Dict{Int,Int}
    low::Dict{Int,Int}

    cutvertices::Set{Int}
    bridges::Vector{Int}
    biconnected::Vector{Set{Int}} # biconnected edges

    function BiconnectedState{T}(graph) where {T<:UndirectedGraph}
        new(graph, Dict(), Dict(), Dict(), Set(), [], [])
    end
end
BiconnectedState(graph::UndirectedGraph) = BiconnectedState{typeof(graph)}(graph)


function dfs!(state::BiconnectedState, n::Int)
    state.pred[n] = n
    dfs!(state, 1, n)
end

function dfs!(state::BiconnectedState, depth::Int, n::Int)
    state.level[n] = depth
    state.low[n] = depth
    childcnt = 0
    compbuf = Set{Int}()
    for (ninc, nadj) in neighbors(state.graph, n)
        if !haskey(state.level, nadj)
            @debug "new node: $(nadj)"
            childcnt += 1
            state.pred[nadj] = n
            comp = dfs!(state, depth + 1, nadj)
            push!(comp, ninc)
            if state.low[nadj] >= state.level[n]
                @debug "articulation point: $(n)"
                if state.low[nadj] > state.level[n]
                    @debug "bridge $(ninc)"
                    push!(state.bridges, ninc) # except for bridgehead
                end
                push!(state.biconnected, comp)
                push!(state.cutvertices, n)
            else
                union!(compbuf, comp)
            end
            state.low[n] = min(state.low[n], state.low[nadj])
        elseif state.pred[n] != nadj
            @debug "cycle found: $(n)"
            state.low[n] = min(state.low[n], state.level[nadj])
            push!(compbuf, ninc)
        end
    end
    if depth == 1 && childcnt < 2
        @debug "revert: $(n)"
        delete!(state.cutvertices, n)
    end
    return compbuf
end


function findbiconnected(graph::UndirectedGraph)
    state = BiconnectedState(graph)
    nodes = nodeset(graph)
    while !isempty(nodes)
        dfs!(state, pop!(nodes))
        setdiff!(nodes, keys(state.level))
    end
    return state
end


"""
    cutvertices(graph::UndirectedGraph) -> Set{Int}
    cutvertices(state::BiconnectedState) -> Set{Int}

Compute biconnectivity and return cut vertices (articulation points).
"""
cutvertices(graph::UndirectedGraph) = findbiconnected(graph).cutvertices
cutvertices(state::BiconnectedState) = state.cutvertices


"""
    bridges(graph::UndirectedGraph) -> Set{Int}
    bridges(state::BiconnectedState) -> Set{Int}

Compute biconnectivity and return bridges.
"""
bridges(graph::UndirectedGraph) = findbiconnected(graph).bridges
bridges(state::BiconnectedState) = state.bridges


"""
    edgebiconnectedcomponents(graph::UndirectedGraph) -> Vector{Vector{Int}}

Compute sets of biconnected component edges.
"""
edgebiconnectedcomponents(graph::UndirectedGraph) = findbiconnected(graph).biconnected
edgebiconnectedcomponents(state::BiconnectedState) = state.biconnected
