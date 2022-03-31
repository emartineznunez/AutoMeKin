#!/usr/bin/env python3 

import numpy as np
import networkx as nx
from ase.autoneb import AutoNEB
from ase.constraints import ExternalForce,FixAtoms
from ase.dimer import DimerControl, MinModeAtoms, MinModeTranslate
from ase.io import read, write
from ase.md.velocitydistribution import MaxwellBoltzmannDistribution
from ase.optimize import BFGS,FIRE
from ase.vibrations import Vibrations
from ase import units
from createMat import get_G_index
from mopacamk import MOPACamk
from os import system
from shutil import copyfile
from re import search
from sys import argv, exit
from Integrators import Langevin
#from xtb.ase.calculator import XTB
from AMK_parameters import emax, label, task, prog, method, charge
from subprocess import run,PIPE
#from sella import Sella
import networkx.algorithms.isomorphism as iso

def vib_calc(ts):
    vib = Vibrations(ts)
    vib.run(); vib.summary(); vib.clean()
    freq = vib.get_frequencies()
    eigenv = []
    for i in range(len(freq)):
        eigenv.append(vib.get_mode(i))
    return eigenv,freq

def attach_calculators(images):
    for image in images:  
        if prog == 'mopac': image.calc = MOPACamk(method=method+' threads=1 charge='+charge,relscf=0.01)
#        elif prog == 'XTB': image.calc = XTB(method=method)

def Energy_and_forces(geom):
    # Get forces and energy from designated potential
    try: ene = geom.get_potential_energy()
    except: exit()
    forces = geom.get_forces()
    return ene,forces

             
inputfile = 'amk.dat' 
#Default parameters
n_max,prefix,fmax,fmaxi,temp,fric,totaltime,dt,ExtForce,weight,k_neb,semax = 12,'image',0.1,0.025,0.,0.5,100,1,6,100,2,True
#Here we should read inputfile
for linei in open(inputfile,'r'):
    if search("LowLevel ", linei): prog   = str(linei.split()[1]) 
    if search("LowLevel ", linei): method = ' '.join([str(elem) for elem in linei.split()[2:] ])
    if search("molecule ", linei): molecule = str(linei.split()[1])
    if search("Energy ", linei) and semax: emax = 1.5 * float(linei.split()[1]) 
    if search("Temperature ", linei) and semax: 
       temperature = float(linei.split()[1])
       E = int(0.064 * temperature + 0.002 * temperature * np.log(temperature))
       emax = 1.5 * max(E,100) 
    if search("MaxEn ", linei):
       emax = 1.5 * float(linei.split()[1])
       semax = False
    if search("ExtForce ", linei): ExtForce = float(linei.split()[1]) 
    if search("fmaxi ", linei): fmaxi = float(linei.split()[1]) 
    if search("charge ", linei): charge = str(linei.split()[1]) 
    if search("tsdirll ", linei): 
        path = str(linei.split()[1]) 
try: 
    print('Path to files:',path)
except:
    path = 'tsdirLL_'+molecule
    print('Path to files:',path)

#image001.traj and image001.traj have been already created
rmol = read('react.xyz')
pmol = read('prod.xyz')
n_dist = int( len(rmol) * (len(rmol) - 1) / 2)
natom = len(rmol)
aton   = rmol.get_atomic_numbers()
symb   = rmol.get_chemical_symbols()

print('Running NEB...')
#Run autoneb 
autoneb = AutoNEB(attach_calculators,
                  prefix=prefix, 
                  optimizer='BFGS',
                  n_simul=1,
                  n_max=n_max,
                  climb=False,
                  fmax=fmaxi,
                  k=k_neb,
                  parallel=False,
                  maxsteps=100)
try: 
    autoneb.run()
except Exception as e:
    print(e)
    print('ERROR in autoneb calculation')
    exit()

#Get max value along the NEB
pot_max = -np.Inf
print('')
print('#      E(kcal/mol)')
for i in range(n_max):
    pot = autoneb.all_images[i].get_potential_energy()
    write('ts_'+str(i)+'.xyz',autoneb.all_images[i].copy())
    if pot > pot_max and pot !=0 and i != n_max-1: 
        pot_max = pot; imax = i 
        ts = autoneb.all_images[i].copy()
        tsint = autoneb.all_images[i].copy()
        tslet = autoneb.all_images[i].copy()
        write('ts_inp.xyz',ts)
    print('{:1.0f} {:16.2f}'.format(i, pot))
print('selected image',imax)
if imax == n_max-2:
    print('The highest energy point corresponds to products')
    exit()

#TS initial guess is the maximum along the NEB

#TS optimization
if prog == 'mopac':
    # Use mopac TS optimizer
    print("Trying opt in XYZ coordinates")
    ts.calc = MOPACamk(method=method+' threads=1 charge='+charge,relscf = 0.01,label = 'ts',task = 'ts precise cycles=1000 t=500 ddmax=0.1 denout',freq=True)
    try: 
        print('{:s} {:10.4f}'.format('TS optimized energy:',ts.get_potential_energy()))
        print('Lowest vibrational frequencies:',[float(x) for x in ts.calc.get_freqs()])
        p  = run("check_ts_structure.sh > ts.log",shell=True)
        print(p)
    except Exception as e: 
        p0 = run("cp ts.out ts_xyz.out",shell=True)
        print('ERROR in MOPAC "ts" calculation in XYZ coordinates:',e)
        ts_int = False; ts_let0 = False ; ts_let1 = False
        for linei in open('ts.out','r'):
            if search("Too many variables", linei): ts_int = True
        if ts_int:
            print("Trying now opt in internal coordinates")
            tsint.calc = MOPACamk(method=method+' threads=1 charge='+charge,relscf = 0.01,label = 'ts',task = 'ts int precise cycles=1000 t=500 ddmax=0.1 denout',freq=True)
            try:
                print('{:s} {:10.4f}'.format('TS optimized energy:',tsint.get_potential_energy()))
                print('Lowest vibrational frequencies:',[float(x) for x in tsint.calc.get_freqs()])
                p  = run("check_ts_structure.sh > ts.log",shell=True)
                print(p)
                exit()
            except Exception as e:
                p0 = run("cp ts.out ts_int.out",shell=True)
                print('ERROR in MOPAC "ts int" calculation:',e) 
        for linei in open('ts.out','r'):
            if search("NUMERICAL PROBLEMS IN BRACKETING LAMDA", linei): ts_let0 = True
            if search("Error", linei): ts_let1 = True
        if ts_let0 and ts_let1:     
            print("Trying now opt with let") 
            if ts_int: 
                tslet.calc = MOPACamk(method=method+' threads=1 charge='+charge,relscf = 0.01,label = 'ts',task = 'ts let int precise cycles=1000 t=500 ddmax=0.1 denout',freq=True)
            else: 
                tslet.calc = MOPACamk(method=method+' threads=1 charge='+charge,relscf = 0.01,label = 'ts',task = 'ts let precise cycles=1000 t=500 ddmax=0.1 denout',freq=True)
            try:
                print('{:s} {:10.4f}'.format('TS optimized energy:',tslet.get_potential_energy()))
                print('Lowest vibrational frequencies:',[float(x) for x in tslet.calc.get_freqs()])
                p  = run("check_ts_structure.sh > ts.log",shell=True)
                print(p)
                exit()
            except Exception as e:
                p0 = run("cp ts.out ts_let.out",shell=True)
                print('ERROR in MOPAC "ts let" calculation:',e)
###############################
#elif prog == 'XTB':
    #Dimer method for XTB (no internal optimizer)
    #vib calc. to get the lowest frequency mode
#    ts.calc = XTB(method=method)
#    eigenv, freq = vib_calc(ts)
#    lfm0 = eigenv[0] ; lfm1 = eigenv[1]
#    print(lfm0)
#    print(lfm1)
#    print(freq)
#    #We first move the ts structure in the second negative eigenvector direction to avoid second order saddles
#    positions = ts.get_positions() + 0.01 * lfm1 / np.linalg.norm(lfm1)
#    ts.set_positions(positions)
#
#    #set up the dimer calc
#    d_control = DimerControl(initial_eigenmode_method = 'displacement', \
#            displacement_method = 'vector', logfile = None, mask=[True]*len(rmol))
#
#    d_atoms = MinModeAtoms(ts, d_control)
#
#    displacement_vector =  0.1 * lfm0 / np.linalg.norm(lfm0)
#    d_atoms.displace(displacement_vector = displacement_vector)
#
#    dim_rlx=MinModeTranslate(d_atoms, trajectory='dimer_method_traj', logfile=None)
#    try:
#        dim_rlx.run(fmax=0.001,steps=1000)
#    except Exception as e: 
#        print('ERROR in dimer calculation')
#        exit()
#
#    try:
#        eigenv,freq = vib_calc(ts)
#        ets = ts.get_potential_energy()
#        print('TS optimized energy :',ets)
#        tsfile  = open('ts.out', 'w')
#        moldenfile  = open('ts.molden', 'w')
#        moldenfile.write('[Molden Format]'+'\n\n')
#        tsfile.write('Energy= '+str(ets)+'\n')
#        tsfile.write('Freq:'+'\n')
#        moldenfile.write('[FREQ]'+'\n')
#        for i,x in enumerate(freq):
#            if i == 0: tsfile.write(str(-x.imag)+'\n')
#            elif i >6: tsfile.write(str(x.real)+'\n')
#            if i == 0: moldenfile.write(str(-x.imag)+'\n')
#            elif i >6: moldenfile.write(str(x.real)+'\n')
#        tsfile.write('Gibbs free energy: [0.]'+'\n')
#        tsfile.write('ZPE: [0.]'+'\n')
#        tsfile.write(str(natom)+'\nFinal structure:'+'\n')
#        moldenfile.write('\n[FR-COORD]'+'\n')
#        posit = ts.get_positions() 
#        for i,ele in enumerate(symb):
#            tsfile.write(str(ele)+' '+str(posit[i][0])+' '+str(posit[i][1])+' '+str(posit[i][2])+'\n')
#            moldenfile.write(str(ele)+' '+str(posit[i][0]/units.Bohr)+' '+str(posit[i][1]/units.Bohr)+' '+str(posit[i][2]/units.Bohr)+'\n')
##        moldenfile.write('\n\n[FR-NORM-COORD]'+'\n')
#        for i in range(len(freq)-6):
#            moldenfile.write('vibration '+str(i+1)+'\n')
#            if i == 0: ifreq = i
#            else: ifreq = i + 6
#            for j in range(natom):
#                moldenfile.write(str(eigenv[ifreq][j][0]/units.Bohr)+' '+str(eigenv[ifreq][j][1]/units.Bohr)+' '+str(eigenv[ifreq][j][2]/units.Bohr)+'\n')
#        tsfile.close()
#        moldenfile.close()
#        write('ts_opt.xyz',ts)
#        p = run("check_ts_structure.sh > ts.log",shell=True)
#    except Exception as e: 
#        print('ERROR in the calculation')
#        exit()
#  
