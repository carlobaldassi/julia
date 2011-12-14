abstract aNode # needed to define Edge

type Edge
	n1::aNode
	n2::aNode
	x::Float64
end

show(e::Edge) = print("(--($(e.x))--)")

type Node <: aNode
	edges::Vector{Edge}
	y::Float64

	function Node(y::Real)
		new({}, y)
	end
end

show(n::Node) = print("(($(n.y)))")

type Graph
	nodes::Vector{Node}
	edges::Vector{Edge}

	function Graph()
		new({}, {})
	end
end

function graph_add_edge(g::Graph, n1::Node, n2::Node, x::Real)
	e = Edge(n1, n2, x)
	push(n1.edges, e)
	push(n2.edges, e)
	if !contains(g.nodes, n1)
		push(g.nodes, n1)
	end
	if !contains(g.nodes, n2)
		push(g.nodes, n2)
	end
	push(g.edges, e)
	return g
end

function update_var(n::Node)
	s = 0.
	for e = n.edges
		s += e.x
	end
	n.y += s
end

function graph_iterate(g::Graph)
	@parallel for i = 1 : length(g.nodes)
		update_var(g.nodes[i])
	end
end
