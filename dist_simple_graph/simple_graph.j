abstract aNode # needed to define Edge

type Edge
	n1::aNode
	n2::aNode
	x::Float64
end

show(e::Edge) = print("(--($(e.x))--)")

type Node <: aNode
	edges::DArray{Edge}
	y::Float64

	function Node(y::Real)
		new(darray(Edge, (0,)), y)
	end
end

show(n::Node) = print("(($(n.y)))")

type Graph
	nodes::DArray{Node}
	edges::DArray{Edge}

	function Graph()
		new(darray(Node, (0,)), darray(Edge, (0,)))
	end
end

function dpush{T}(a::DArray{T}, x::T)
	if (length(a) > 0)
		a = [ a, x ]
	else
		a = darray((T,d,da)->[x], T, (1,))
	end
	return a
end

function graph_add_edge(g::Graph, n1::Node, n2::Node, x::Real)
	e = Edge(n1, n2, x)
	n1.edges = dpush(n1.edges, e)
	n2.edges = dpush(n2.edges, e)
	if !contains(g.nodes, n1)
		g.nodes = dpush(g.nodes, n1)
	end
	if !contains(g.nodes, n2)
		g.nodes = dpush(g.nodes, n2)
	end
	g.edges = dpush(g.edges, e)
	return g
end

function generate_graph{T <: Real}(edges::Vector{(Node, Node, T)})
	g = Graph()
	for e = edges
		graph_add_edge(g, e...)
	end
	return g
end

function update_node(nrr::RemoteRef)
	n = take(nrr)
	s = 0.
	for e = n.edges
		s += e.x
	end
	n.y += s
end

function graph_iterate(g::Graph)
	#### This doesn't work: ####
	#@parallel for i = 1 : length(g.nodes)
	#	rr = RemoteRef()
	#	put(rr, g.nodes[i])
	#	update_var(rr)
	#end
	########
	@sync begin
		for i = 1 : length(g.nodes)
			rr = RemoteRef()
			put(rr, g.nodes[i])
			@spawnat owner(g.nodes, i) update_node(rr)
			#@spawn update_node(rr) # using this shows that there are problems if not using RemoteRef
		end
	end
end
