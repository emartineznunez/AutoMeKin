#!/usr/bin/env python3
from networkx import simple_cycles, DiGraph
from sys import argv
from ase.io import read
from AMK_parameters import cov_rad 

def cycle(rmol,a,b):
    '''
    Nodes a and b belong to the same cycle (if present) in the graph? 
    '''
    symb  = rmol.get_chemical_symbols()
    G = DiGraph()
    for i in range(len(rmol)):
        for j in range(i+1,len(rmol)):
            if rmol.get_distance(i,j) < 1.32 * ( cov_rad[symb[i]] + cov_rad[symb[j]] ):
               G.add_edge(i,j); G.add_edge(j,i)

    for lista in list(simple_cycles(G)):
        if a in lista and b in lista and len(lista) > 2: return True
    return False

if __name__ == '__main__':
    rmol = read(str(argv[1]))
    a = int(argv[2]) - 1
    b = int(argv[3]) - 1
    if len(rmol) == 1: exit() 
    else: print(cycle(rmol,a,b))
