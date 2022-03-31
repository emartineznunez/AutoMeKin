#!/usr/bin/env python3
from ase.io import read
import re
import sys
import os

molecule=str(sys.argv[1])
final=str(sys.argv[2])
filename='final.log'

rmol = read(molecule+'.xyz')
formula = rmol.get_chemical_formula(mode='hill')
fw = open(final+'/convergence.txt', 'w')

if os.path.isfile(filename):
   print(filename,'exists and convergence.txt will be created')
else:
   print(filename,'does not exist and convergence.txt will be empty')
   fw.write('           SYSTEM:  '+formula+'\n')
   fw.write('No convergence information \n')
   exit()

f = open(filename,'r')
i = 0
while 1:
	i = i + 1
	line = f.readline()
	if not line: break
	if re.search("Iter # ",line): number = i
f.close()


f = open(filename, 'r')
f.seek(0)

i = 0
while 1:
	i = i + 1
	line = f.readline()
	if i == number:
		fw.write('           SYSTEM:  '+formula+'\n')
		fw.write('#################################################### \n')
		fw.write('#                                                  # \n')
		fw.write('#   Number of trajectories and transition states   # \n')
		fw.write('#                                                  # \n')
		fw.write('#################################################### \n \n ')
		fw.write('Iter #          TSs       ntrajs \n')
	if i > number:
		if len(line.split()) >= 3:
			n_iter = int(line.split()[0])
			ts_number = int(line.split()[1])
			traj_number = int(line.split()[2])
			fw.write('{0:>7}{1:>13}{2:>13} \n'.format(n_iter, ts_number, traj_number))
		else:
			f.close()    
			fw.close()
			sys.exit()
			
			
		  
		


