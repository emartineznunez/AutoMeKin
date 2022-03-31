#!/usr/bin/env python3
from networkx import Graph, adjacency_matrix
from sys import argv
from ase.io import read
import numpy as np
from AMK_parameters import cov_rad, vdw_rad

def get_G_index(rmol,weig,na,prt):
    '''
    Determine Adjacency matrix for rmol. Posibilities:
    weig = 1 (integers); weig = 2 (floats); weig = 3 (both)
    '''
    symb  = rmol.get_chemical_symbols()
    ind   = []; jnd = []; ibn   = []; jbn = []
    G1    = Graph() ; G2 = Graph()
    for i in range(len(rmol)):
        for j in range(i+1,len(rmol)):
            d = rmol.get_distance(i,j)
            ind.append(i); jnd.append(j)
            if j < na or i >= na: sum_rad = cov_rad[symb[i]] + cov_rad[symb[j]]
            else:                 sum_rad = vdw_rad[symb[i]] + vdw_rad[symb[j]] 
            if prt: sm.write(str(round(1.2 * sum_rad,5) )+' \n' )
            if weig !=2:
                if d < 1.32 * sum_rad:
                   G1.add_edge(i,j,weight=1)
                   ibn.append(i); jbn.append(j)
                else: G1.add_edge(i,j,weight=0)
            if weig >=2:
                weight = round( (1 - (d / 1.32 / sum_rad) ** 6) / \
                (1 - (d / 1.32 / sum_rad) ** 12),5)
                G2.add_edge(i,j,weight=weight)
    #Printing connectivity matrix(ces)
    if prt and weig >=2:
        A = adjacency_matrix(G2) 
        for line in np.matrix(A.A): np.savetxt(cm, line, fmt='%.5f')
    if prt and weig !=2:
        A = adjacency_matrix(G1) 
        for line in np.matrix(A.A): np.savetxt(cm, line, fmt='%.0f')
    return G1,ind,jnd,ibn,jbn

if __name__ == '__main__':
    cm = open('ConnMat', "w") ; sm = open('ScalMat', "w")
    rmol = read(str(argv[1]))
    if len(argv) == 4: na = int(argv[3])
    else: na = len(rmol) 
    if len(rmol) == 1: cm.write('0\n')
    else: get_G_index(rmol,int(argv[2]),na,True)
