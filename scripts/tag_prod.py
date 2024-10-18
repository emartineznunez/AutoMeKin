#!/usr/bin/env python3
import numpy as np
import networkx as nx
from createMat import get_G_index
from ase.io import read
from sys import argv


'''
Program to match PM7 minima with ab initio minima
'''
            
#opt_start is the optimized initial structure
fname  = argv[1]
rmol   = read(fname)
natom  = len(rmol)

#Setting up initial stuff
aton   = rmol.get_atomic_numbers()

try:
    G,ind,jnd,ibn,jbn = get_G_index(rmol,1,natom,False)
#    A   = nx.adjacency_matrix(G) ; Ap  = A.toarray()
    Ap   = nx.to_numpy_array(G) 
    for z in range(natom): Ap[z][z] = aton[z]
    tag = sorted( [np.round(elem.real,3) for elem in np.linalg.eigvals(Ap) ] )
except:
    tag = np.zeros(natom) 

for ele in tag: print("%.3f" % ele, end=' ')
print("")
