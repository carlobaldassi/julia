@everywhere load("simple_graph.j")

n1 = Node(1)
n2 = Node(2)

g = Graph()

graph_add_edge(g, n1, n2, 0.5)

graph_iterate(g)

println("$g")
