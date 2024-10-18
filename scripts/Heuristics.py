#!/usr/bin/env python3
import numpy as np
import networkx as nx
import re
from os.path import isfile
from itertools import combinations,product
from mopacamk import MOPACamk
from ase.optimize import BFGS
from ase.io import read
from ase.units import kcal, mol, Bohr
from AMK_parameters import nbonds,prog,method,task,relscf,active,max_val,min_val,startd,label,comb22,cov_rad,Crossb,MaxBoB,MaxBoF,MaxBO
from createMat import get_G_index
#from xtb.ase.calculator import XTB
#from xtb.interface import Calculator,Param,Environment
from multiprocessing import Pool
from collections import Counter
from sys import argv
import time


def closestDistanceBetweenLines(a0,a1,b0,b1,clampAll=False,clampA0=False,clampA1=False,clampB0=False,clampB1=False):
    ''' Given two lines defined by numpy.array pairs (a0,a1,b0,b1)
        Return the closest points on each segment and their distance
    '''
    # If clampAll=True, set all clamps to True
    if clampAll: clampA0=True; clampA1=True; clampB0=True; clampB1=True
    # Calculate denomitator
    A = a1 - a0; B = b1 - b0
    magA = np.linalg.norm(A); magB = np.linalg.norm(B)
    _A = A / magA; _B = B / magB
    cross = np.cross(_A, _B);
    denom = np.linalg.norm(cross)**2
    # If lines are parallel (denom=0) test if lines overlap.
    # If they don't overlap then there is a closest point solution.
    # If they do overlap, there are infinite closest positions, but there is a closest distance
    if not denom:
        d0 = np.dot(_A,(b0-a0))
        # Overlap only possible with clamping
        if clampA0 or clampA1 or clampB0 or clampB1:
            d1 = np.dot(_A,(b1-a0))
            # Is segment B before A?
            if d0 <= 0 >= d1:
                if clampA0 and clampB1:
                    if np.absolute(d0) < np.absolute(d1): return a0,b0,np.linalg.norm(a0-b0)
                    return a0,b1,np.linalg.norm(a0-b1)
            # Is segment B after A?
            elif d0 >= magA <= d1:
                if clampA1 and clampB0:
                    if np.absolute(d0) < np.absolute(d1): return a1,b0,np.linalg.norm(a1-b0)
                    return a1,b1,np.linalg.norm(a1-b1)
        # Segments overlap, return distance between parallel segments
        return None,None,np.linalg.norm(((d0*_A)+a0)-b0)
    # Lines criss-cross: Calculate the projected closest points
    t = (b0 - a0);
    detA = np.linalg.det([t, _B, cross])
    detB = np.linalg.det([t, _A, cross])
    t0 = detA/denom; t1 = detB/denom
    pA = a0 + (_A * t0) # Projected closest point on segment A
    pB = b0 + (_B * t1) # Projected closest point on segment B
    # Clamp projections
    if clampA0 or clampA1 or clampB0 or clampB1:
        if clampA0 and t0 < 0: pA = a0
        elif clampA1 and t0 > magA: pA = a1
        if clampB0 and t1 < 0: pB = b0
        elif clampB1 and t1 > magB: pB = b1
        # Clamp projection A
        if (clampA0 and t0 < 0) or (clampA1 and t0 > magA):
            dot = np.dot(_B,(pA-b0))
            if clampB0 and dot < 0: dot = 0
            elif clampB1 and dot > magB: dot = magB
            pB = b0 + (_B * dot)
        # Clamp projection B
        if (clampB0 and t1 < 0) or (clampB1 and t1 > magB):
            dot = np.dot(_A,(pB-a0))
            if clampA0 and dot < 0: dot = 0
            elif clampA1 and dot > magA: dot = magA
            pA = a0 + (_A * dot)
    return np.linalg.norm(pA-pB),pA,pB

def CheckMove(G):
#check valency
    for k in active:
        if G.degree(k) not in range(min_val[symb[k]],max_val[symb[k]]+1): return False
#Check dissociations leading to >=2 atoms 
    nd = 0
    for i in range(natom):
        if G.degree(i) == 0: nd += 1
    if nd >= 2: return False

    return True


def check_cross_bonds(posit,i0,j0,i1,j1):
#check bond formation is possible--> d_ij < startd and path does not cross an existing bond
    a0 = np.array(posit[i0]); a1 = np.array(posit[j0])
    b0 = np.array(posit[i1]); b1 = np.array(posit[j1])
    d34ref = np.linalg.norm(b0 - b1)
    d12ref = np.linalg.norm(a0 - a1)
    dmin,pA,pB = closestDistanceBetweenLines(a0,a1,b0,b1)
    d1 = np.linalg.norm(pA - a0); d2 = np.linalg.norm(pA - a1)
    d3 = np.linalg.norm(pB - b0); d4 = np.linalg.norm(pB - b1)
    dm = min(d1,d2,d3,d4); d34 = d3 + d4; d12 = d1 + d2
    diff12 = (abs(d12 - d12ref) / d12ref) * 100
    diff34 = (abs(d34 - d34ref) / d34ref) * 100
#Check if the intersect crosses a bond
    if dm>0.1 and diff34<10 and diff12<10 and dmin<0.1: cs = True 
    else: cs = False 
    return cs

def comb_process(comb):
    global nts 
    stfile.write('('+str(len(comb[0]))+','+str(len(comb[1]))+') Combination:'+str(comb)+'\n')
    # copy original G
    G = G_orig.copy()
    for ele in comb[0]: G.add_edge(ind[ele],jnd[ele])
    for ele in comb[1]: G.remove_edge(ind[ele],jnd[ele])
    ##Check valencies and stuff
    if CheckMove(G):
        Ap  = nx.to_numpy_array(G) 
        for z in range(natom): Ap[z][z] = aton[z]
        Ats = 0.5 * (Ar + Ap)
        tag = sorted( [np.round(elem,3) for elem in np.linalg.eigvals(Ats) ] )
        if tag not in dict_ts.values():
            nts += 1 ; dict_ts[str(nts)] = tag
            bfbonds = ''
            for ele in comb[0]: bfbonds=bfbonds+' f '+str(ind[ele])+' '+str(jnd[ele])
            for ele in comb[1]: bfbonds=bfbonds+' b '+str(ind[ele])+' '+str(jnd[ele])
            tsfile.write(bfbonds+'\n')

'''
Program to obtain all combinations of bonds that can be formed/broken
within a number of active atoms and with a max of nbonds involved
active: Active atoms 
method: Any of the semiempirical methods of MOPAC2016 
nbonds: Max number of bonds involved
startd: Initial max dist between a couple of atoms to make a bond
'''
with open('amk.dat') as inp:
    lines = inp.readlines()
    for line in lines:
        if line.find('active')    !=-1: active = [int(x) - 1 for x in re.sub('[^0-9]',' ', line).split(' ') if x != '' ]
        if line.find('molecule')  !=-1: molecu = str(line.split()[1])
        if line.find('LowLevel')  !=-1: prog   = str(line.split()[1])
        if line.find('LowLevel')  !=-1: method = ' '.join([str(elem) for elem in line.split()[2:] ])
        if line.find('charge')    !=-1: charge = str(line.split()[1])
        if line.find('nbonds')    !=-1: nbonds = float(line.split()[1]) 
        if line.find('startd')    !=-1: startd = float(line.split()[1]) 
        if line.find('comb22')    !=-1: 
            comb22 = str(line.split()[1]) 
            if comb22 == "yes":  comb22  = True
            else: comb22 = False
        if line.find('crossb')    !=-1: 
            Crossb = str(line.split()[1]) 
            if Crossb == "yes":  Crossb  = True
            else: Crossb = False
        if line.find('MaxBoF')    !=-1: MaxBoF = int(line.split()[1]) 
        if line.find('MaxBoB')    !=-1: MaxBoB = int(line.split()[1]) 
        if line.find('MaxBO')     !=-1: MaxBO  = float(line.split()[1]) 
        if line.find('neighbors') !=-1: 
            atom = str(line.split()[1]) 
            vale = [int(x) for x in re.sub('[^0-9]',' ', line).split(' ') if x != '' ]
            min_val[atom] = vale[0]; max_val[atom] = vale[1]

if len(argv) == 3:
    MaxBoF = int(argv[1]) 
    MaxBoB = int(argv[2])

#opt_start is the optimized initial structure
rmol   = read(molecu+'.xyz')
natom  = len(rmol)
if len(active) == 0: active = [item for item in range(natom)]

#Setting up initial stuff
symb   = rmol.get_chemical_symbols()
aton   = rmol.get_atomic_numbers()
d      = rmol.get_all_distances(mic=False, vector=False)
posit  = rmol.get_positions()
n_dist = int( natom * (natom - 1) / 2)

#
act_dist = []
G,ind,jnd,ibn,jbn = get_G_index(rmol,1,natom,False)
for i in range(n_dist):
    if G[ind[i]][jnd[i]]['weight'] == 0: G.remove_edge(ind[i],jnd[i]) 
    if ind[i] in active and jnd[i] in active: act_dist.append(i)

#Checking that all neighbors are correctly set
stfile   = open('tsdirLL_'+molecu+'/ck_stats.log', 'w')
tsfile   = open('tsdirLL_'+molecu+'/ts_bonds.inp','w')
cbfile   = open('tsdirLL_'+molecu+'/cb_bonds.inp','w')

for i in active:
    if symb[i] not in list(min_val.keys()): 
       stfile.write('Define neighbors for element: '+symb[i]+'\n')
       min_val[symb[i]] = 1
       max_val[symb[i]] = 0
       for j in range(natom):
          if symb[j] == symb[i] and G.degree[j] > max_val[symb[i]]: max_val[symb[i]] = G.degree[j]

#rmol.calc is an instance of the mopac calculation
#Determine initial energy e0 and bond order matrix bo
if prog == 'mopac': rmol.calc = MOPACamk(method=method+' threads=1 charge='+charge,task=task)
#elif prog == 'XTB': rmol.calc = XTB(method=method)
opt = BFGS(rmol,logfile='bfgs.log')
opt.run(fmax=1, steps=50)
e0     = rmol.get_potential_energy() * mol / kcal
if prog == 'mopac': bo = [float(item) for item in rmol.calc.get_bond_order()]
#elif prog == 'XTB': 
#    calc = Calculator(Param.GFN2xTB,aton,rmol.get_positions() / Bohr) 
#    calc.set_verbosity(0)
#    res = calc.singlepoint()
#    bo = res.get_bond_orders()
#    bo = list(bo[np.triu_indices(natom, k = 1)])

#Obtaining initial Adjacency and indexes 
act_break = []; act_form = [] 
for i in act_dist:
    if G.has_edge(ind[i],jnd[i]): 
        if bo[i] < MaxBO: act_break.append(i)
    else: 
#check bond formation is possible--> d_ij < startd and path does not cross an existing bond
        dij = d[ind[i]][jnd[i]] 
        i0 = ind[i]; j0 = jnd[i]
        add_bond = True
        for ib in range(len(ibn)):
            i1 = ibn[ib]; j1 = jbn[ib]
            if check_cross_bonds(posit,i0,j0,i1,j1) and Crossb: 
                add_bond = False
                cbfile.write('\nformation of 1  bond:\n')
                cbfile.write('bond: '+str(i0)+'-'+str(j0)+' with bond: '+str(i1)+'-'+str(j1)+'\n')
                cbfile.write('Geometry:\n')
                for inat in range(natom):
                    cbfile.write(symb[inat]+' '+str(posit[inat][0])+' '+str(posit[inat][1])+' '+str(posit[inat][2])+'\n')
                break
        if add_bond and dij < startd: act_form.append(i)

G_orig = G.copy() 
Ar  = nx.to_numpy_array(G) 
for z in range(natom): Ar[z][z] = aton[z]
nts = 0 ; dict_ts = {} 

#Make all possible combinations
ListaB = []; ListaF = []
for i in range(MaxBoF+1):
    listaf = [list(x) for x in combinations(act_form , i)]
#check formations of 2 bonds
    if i == 2:
        for lf in listaf:
            i0 = ind[lf[0]]; j0 = jnd[lf[0]]; i1 = ind[lf[1]]; j1 = jnd[lf[1]]
            if check_cross_bonds(posit,i0,j0,i1,j1) and Crossb: 
                listaf.remove(lf)
                cbfile.write('\nformation of 2 bonds:\n')
                cbfile.write('bond: '+str(i0)+'-'+str(j0)+' with bond: '+str(i1)+'-'+str(j1)+'\n')
                cbfile.write('Geometry:\n')
                for inat in range(natom):
                    cbfile.write(symb[inat]+' '+str(posit[inat][0])+' '+str(posit[inat][1])+' '+str(posit[inat][2])+'\n')
    ListaF.append(listaf)
    for j in range(MaxBoB+1):
        if i == j == 2 and not comb22: break
        ListaB.append ( [list(x) for x in combinations(act_break , j)] )
        if i > 0 or j > 0: 
            for x in product(ListaF[i][:],ListaB[j][:]): comb_process(list(x))
print(nts)
