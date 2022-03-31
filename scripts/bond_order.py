#!/usr/bin/env python3 

from mopacamk import MOPACamk
from ase.io import read, write
from re import search

inp = open('amk.dat', "r")
method = 'pm7'
for line in inp:
    if search("LowLevel ", line) and str(line.split()[1]) == 'mopac': method = ' '.join([str(elem) for elem in line.split()[2:] ])
    if search("charge ", line): charge = str(line.split()[1]) 
       
geom = read('mingeom')
geom.calc = MOPACamk(label='bo', method=method+' charge='+charge, task='1SCF BONDS INT THREADS=1', relscf=0.01)
geom.get_potential_energy()
bofile = open("bond_order.txt", "w")
for item in geom.calc.get_bond_order():
    bofile.write(item+' ')
bofile.write('\n')
