export RPCGPChromo, node_genes, get_positions

# PCGP with mutated positions and constant scalar inputs and evolved params,
# only allowing self-recursion

type RPCGPChromo <: Chromosome
    genes::Array{Float64}
    nodes::Array{CGPNode}
    outputs::Array{Int64}
    order::Array{Int64}
    nin::Int64
    nout::Int64
end

function RPCGPChromo(genes::Array{Float64}, nin::Int64, nout::Int64)::RPCGPChromo
    num_nodes = Int64(ceil((length(genes)-nin-nout)/5))
    nodes = Array{CGPNode}(nin+num_nodes)
    rgenes = reshape(genes[(nin+nout+1):end], (5, num_nodes))'
    positions = [genes[1:nin]; rgenes[:, 1]]
    order = collect(1:length(positions))
    sort!(order, by=i->positions[i])
    fc = [rgenes[:, 2]'; rgenes[:, 3]']
    for i in 1:num_nodes
        o = order[i]-1
        if o > 0
            fc[:, i] .*= positions[order[i]]
        else
            fc[:, i] .= positions[i]
        end
    end
    connections = [zeros(Int64, 2, nin) snap(fc, positions)]
    outputs = snap(genes[nin+(1:nout)], positions)
    f = Config.functions[Int64.(ceil.(rgenes[:, 4]*length(Config.functions)))]
    functions = [[x->x[i] for i in 1:nin];f]
    params = [zeros(nin); 2.0*rgenes[:, 5]-1.0]
    active = find_active(nin, outputs, connections)
    for i in 1:(nin+num_nodes)
        nodes[i] = CGPNode(connections[:, i], functions[i], active[i], params[i])
    end
    RPCGPChromo(genes, nodes, outputs, order, nin, nout)
end

function RPCGPChromo(nin::Int64, nout::Int64)::RPCGPChromo
    RPCGPChromo(rand(nin+nout+5*Config.num_nodes), nin, nout)
end

function RPCGPChromo(c::RPCGPChromo)::RPCGPChromo
    mutate_genes(c)
end

function node_genes(c::RPCGPChromo)
    5
end

function get_positions(c::RPCGPChromo)
    [c.genes[1:c.nin]; c.genes[(c.nin+c.nout+1):5:end]]
end