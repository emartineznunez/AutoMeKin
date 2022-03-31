#!/usr/bin/env python3 

import networkx as nx
import sys

tag=str(sys.argv[1])
molecule=str(sys.argv[2])

tdir='tsdir'+tag+'_'+molecule
f=tdir+'/rxn_all.txt'
G = nx.read_edgelist(f, data=(('weight',float),))

fma = open(tdir+'/min_diss.inp', 'w')
for x in list(G.nodes): fma.write(x+'\n')
fma.close()      

