#!/usr/bin/env python3 

from numpy import zeros
from os import system
from sys import argv
from mopacamk import MOPACamk
from ase.constraints import ExternalForce,Hookean
from ase.io import read, write
from ase.md.velocitydistribution import (MaxwellBoltzmannDistribution,Stationary, ZeroRotation)
from ase import units
from Langevin import Langevin
from re import search
from entos import Qcore_calc
from AMK_parameters import charge
from createMat import get_G_index

def Energy_and_forces(prog,geom):
    # Get forces and energy from designated potential
    if prog == 'mopac':
        try: ene = geom.get_potential_energy()
        except: exit()
        forces = geom.get_forces()
    elif prog == 'qcore':
        write("grad.xyz",geom.copy(),format="xyz")
        e,grad,freq,imag_nm,gibbs,zpe,charges = Qcore_calc('grad.dat')
        ene = e * units.Hartree
        forces = - grad * units.Hartree / units.Bohr
    return ene,forces

def runTrajectory(geom, T, Fric, totaltime, dt, adapLimit,window,post_proc):
#r0 is a list with the initial distances
    r0 = geom.get_all_distances(mic=False, vector=False)
    size = len(geom.get_positions())
    n_dist = int( size * (size - 1) / 2)
    G,ind,jnd,ibn,jbn = get_G_index(geom,1,size,False)
    bonds = []
    for i in range(n_dist):
        if G[ind[i]][jnd[i]]['weight'] == 1: bonds.append(i)  
           
    timeStep = dt * units.fs
    numberOfSteps = int(totaltime/dt)
    BXDElower = 0
    BXDEupper = 0

    #get starting geometry for reference
    start = geom.copy()
    vel = geom.get_velocities()

    # Open files for saving data
    if post_proc == 'bots':
        bofile = open("bond_order.txt", "w")
    # Initialise constraints to zero
    e_del_phi = 0
    j = 0
    hits = 0
    Frag = False 

    # Get current potential energy and check if BXD energy constraints are implemented
    ene,forces = Energy_and_forces(prog,geom)
    e0=ene

    BXDElower = ene - 10.0
    BXDEupper = ene + 5000

    maxEne = ene
    # Then set up reaction criteria or connectivity map
    mdInt = Langevin(units.kB * T, Fric, forces, geom.get_velocities(), geom, timeStep)

    #Get forces
    Xene,forces = Energy_and_forces(prog,geom) 


    # Run MD trajectory for specified number of steps
    for i in range(0,numberOfSteps):


        # Get forces and energy from designated potential
        ene,Xforces = Energy_and_forces(prog,geom)

        # Check for boundary hit on lower BXDE
        if ene < BXDElower:
            hits += 1
            eBounded = True
            geom.set_positions(mdInt.oldPos)
            Xene,e_del_phi = Energy_and_forces(prog,geom)
        else:
            eBounded = False
            hits = 0

#hits is a new variable to escape from trappings
        if hits >= 10:
            BXDElower = ene - 0.1
            print("****Getting out of a trapping state")
            up = (BXDElower-e0)*23.06 ; lo = (BXDEupper-e0)*23.06
            print('****New box:', "%10.2f" % up,'-', "%10.2f" % lo )
            hits = 0
#hits is a new variable to escape from trappings

        #check if we have passed upper boundary
        if ene > BXDEupper:
            j = 0
            BXDElower = BXDEupper - 0.1
            BXDEupper = BXDElower + 50000
            up = (BXDElower-e0)*23.06 ; lo = (BXDEupper-e0)*23.06
            print('****New box:', "%10.2f" % up,'-', "%10.2f" % lo )
        if j < adapLimit and eBounded == False:
            j += 1
            if ene > maxEne:
                maxEne = ene
        elif j == adapLimit:
            j += 1
            BXDEupper = maxEne
        elif j > adapLimit:
            j += 1
            if (j/adapLimit)%4==0:
               diff = BXDEupper - BXDElower
               BXDEupper = BXDEupper - diff / 2
               up = (BXDElower-e0)*23.06 ; lo = (BXDEupper-e0)*23.06
               print('****New box:', "%10.2f" % up,'-', "%10.2f" % lo )

        if eBounded is True:
            mdInt.constrain(e_del_phi)

        mdInt.mdStepPos(forces,timeStep,geom)
        Xene,forces = Energy_and_forces(prog,geom)
        mdInt.mdStepVel(forces,timeStep,geom)

        #Print current positions to file
        idt1 = int(1/dt)
        idt2 = int(20/dt)
        if i % idt1 == 0:
            write("traj.xyz",geom.copy(),format="xyz",append=True)
            e = ( ene - e0 ) * 23.06
            up = (BXDElower-e0)*23.06 ; lo = (BXDEupper-e0)*23.06
            print('Step:', "%4.0f" % int(i*dt),' E:', "%6.2f" % e,' box:',"%10.2f" % up,'-',"%10.2f" % lo )
#read bond orders and write them to file bond_order.txt
            if post_proc == 'bots':
                for item in geom.calc.get_bond_order():
                    bofile.write(item+' ')
                bofile.write('\n')
        if i % idt2 == 0:
            dist = geom.get_all_distances(mic=False, vector=False) 
            for ele in bonds:
                if dist[ind[ele]][jnd[ele]] >= 5 * r0[ind[ele]][jnd[ele]]:
                    print("Fragmentation")
                    print(ind[ele]+1,jnd[ele]+1,dist[ind[ele]][jnd[ele]],r0[ind[ele]][jnd[ele]])
                    Frag = True
        if Frag is True: break
       

#remove traj.xyz if it exists
system('rm -rf traj.xyz')

inputfile = str(argv[1])
xyzfile="opt_start.xyz"
temp,fric,totaltime,dt,adap,window,method,post_proc,prog,Hookean_ = 1000,0.5,5000,0.5,100,500,'pm7','bbfs','mopac',False
inp = open(inputfile, "r")
for line in inp:
    if search("temp ", line):
        temp = float(line.split()[1])
    if search("post_proc ", line):
        post_proc = str(line.split()[1])
    if search("Friction", line):
        fric = float(line.split()[1])
    if search("fs", line):
        totaltime = int(line.split()[1])
    if search("Dt", line):
        dt = float(line.split()[1])
    if search("AdaptiveLimit", line):
        adap = int(line.split()[1])
    if search("Window", line):
        window = int(line.split()[1])
        window = int(window/dt)
    if search("LowLevel ", line):
        method = ' '.join([str(elem) for elem in line.split()[2:] ]) 
    if search("LowLevel ", line):
        prog  = str(line.split()[1])
    if search("charge ", line): 
        charge = str(line.split()[1]) 
    if search("Hookean ", line):
        Hookean_ = True
        Hat1  = int(line.split()[1]) - 1
        Hat2  = int(line.split()[2]) - 1
        Hrt   = float(line.split()[3])
        Hk    = float(line.split()[4])
rmol = read(xyzfile)
if prog == 'mopac': rmol.calc = MOPACamk(label='bxde', method=method, task='1SCF GRADIENTS charge='+charge+' BONDS PRTXYZ THREADS=1', relscf=0.01)

print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
print("    BXDE input parameters    ")
print("    Temperature(K) = ",temp)
print("    Friction       = ",fric)
print("    Totaltime(fs)  = ",totaltime)
print("    Delta_t(fs)    = ",dt)

#For the dynamics we give all Hs a mass of 4.0 and apply contraints
masses = []
for x in rmol.get_atomic_numbers():
    if x == 1: masses.append(4.0)
    else: masses.append(None)
rmol.set_masses(masses=masses) 

if Hookean_:
    c = Hookean(a1=Hat1,a2=Hat2,rt=Hrt,k=Hk)
    rmol.set_constraint(c)
    print("    Hookean a1,a2  = ",Hat1+1,Hat2+1)
    print("    Hookean rt     = ",Hrt)
    print("    Hookean k      = ",Hk)
print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXX")

MaxwellBoltzmannDistribution(rmol, temperature_K = temp )
runTrajectory(rmol,temp,fric,totaltime,dt,adap,window,post_proc)

