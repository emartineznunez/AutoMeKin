#!/usr/bin/env python3
import sys
import networkx as nx
from matplotlib.cbook import flatten

rxnf = str(sys.argv[1])
min0 = int(sys.argv[2])
emax = float(sys.argv[3])

G = nx.Graph()
inp = open(rxnf, "r")
for line in inp:
   if str(line.split()[0]) == "TS" and float(line.split()[4]) < emax:
      node1 = int(line.split()[7])
      G.add_node(node1)
      if str(line.split()[9]) == "MIN":
         node2 = int(line.split()[10])
         G.add_node(node2)
         G.add_edge(node1,node2)
inp.close()

islands = [0]
if not nx.is_connected(G):
   for c in nx.connected_components(G):
      if min0 not in G.subgraph(c).nodes(): islands.append(list(G.subgraph(c).nodes()))
islands=list(flatten(islands))

inp = open(rxnf, "r")
for line in inp:
   if str(line.split()[0]) == "TS":
      if float(line.split()[4]) < emax:
         min1 = int(line.split()[7])
         min2 = 0
         if str(line.split()[9]) == "MIN": min2 = int(line.split()[10])
         if min1 not in islands or min2 not in islands: print(line,end='')
   else:
      print(line,end='')
inp.close()


