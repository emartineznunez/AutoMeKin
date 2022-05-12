#!/usr/bin/env python3

'''
Program to calculate the IRC
using the DVV method:
J. Phys. Chem. A 2002, 106, 165-169 
Initial coord and velocities
Units (a.u.): 
coordinates: Bohr
velocities: Bohr / time
grad: hartree / Bohr
'''

from ase.io import read,write
from ase.units import Bohr
from entos import Qcore_calc
from sys import argv
from re import search
import numpy as np


nsteps = 500 # total number of steps
kick = 0.05 # angstroms
#read xyz name from DVV.dat
path=str(argv[1])
molecule = path+'_opt'
       
aut = 0.02418884254 # fs  = 1 atomic unit
aum = 9.1093837015e-31 # Kg = 1 atomic unit
uma = 1.6605402E-27 # kg
kcal = 627.509
v0 = 0.04  # au / fs
delta0 = 0.003 # bohr

#Reading input structure (opt.xyz already optimized). 
rmol0 = read(molecule + '.xyz')
rmol  = read(molecule + '.xyz')
natom = len(rmol)
masses = np.array(rmol.get_masses()) * uma / aum

#We first determine e0 and the eigenvector of the imaginary freq
thermofile = path+'_thermo.dat'
gradfile = path+'_grad.dat'
gradxyz  = path+'_grad.xyz'
e0,dum2,dum3,imag_nm,dum4,dum5,dum6 = Qcore_calc(thermofile)
forward=path+'_forward.xyz'
reverse=path+'_reverse.xyz'
forward_last=path+'_forward_last.xyz'
reverse_last=path+'_reverse_last.xyz'
write(forward,rmol)
write(reverse,rmol)

#Perform DVV in both directions
for sign in range(-1,3,2):
    pot = 0
    kin = 0
    gradient = 0
    deltat = [1] * 3  # atomic units
    print("")
    print("   DVV with sign: ",sign)
    print("   Time (fs)   Epot(kcal)   EKin(kcal)   ETot(kcal)      Dt(fs)    Grad(kcal/bohr)")
    print("  Opt TS geo     %8.2f     %8.2f     %8.2f      %6.4f         %10.4f" % (pot * kcal, kin * kcal, (pot + kin) * kcal, deltat[0] * aut, gradient * kcal)  )
    x = np.array(rmol0.get_positions())
    x = x + sign * kick * np.reshape(imag_nm ,(natom,3))
    rmol.set_positions(x)
    write(gradxyz,rmol)
    if sign == -1:
        write(forward,rmol,append=True)
        write(forward_last,rmol)
    else:
        write(reverse,rmol,append=True)
        write(reverse_last,rmol)

    x = x / Bohr
    v = np.zeros( (natom,3) )
#calculate gradient of initial point
    dum,grad,dum2,dum3,dum4,dum5,dum6 = Qcore_calc(gradfile)
    a = - grad / masses[:,None]
    e = 0

    for i in range(nsteps):
        a_old = a
        e_old = e
        x = x + v * deltat[i] + 1 / 2 * a_old * deltat[i] ** 2
 
        rmol.set_positions(x * Bohr)

        write(gradxyz,rmol)
        if sign == -1:
            write(forward,rmol,append=True)
            write(forward_last,rmol)
        else:
            write(reverse,rmol,append=True)
            write(reverse_last,rmol)
###
        try: e,grad,dum2,dum3,dum4,dum5,dum6 = Qcore_calc(gradfile)
        except: break
###
        a = - grad / masses[:,None]
        v = v + 1 / 2 * (a_old + a) * deltat[i]
###For deltat
        if i == 0:
            am2 = a ; vm2 = v ; xm2 = x 
        elif i == 1:
            am1 = a ; vm1 = v ; xm1 = x
        elif i >= 2: 
            x_prime = xm2 + vm2 * (deltat[i-1] + deltat[i])  + 1 / 2 * am2 * (deltat[i-1] + deltat[i]) ** 2
            am2 = am1 ; vm2 = vm1 ; xm2 = xm1
            am1 = a   ; vm1 = v   ; xm1 = x

            diff = x - x_prime 
            delta_i = np.linalg.norm(diff)
            dt = deltat[i] * (delta0 / delta_i) ** 1/3
            if dt < 1: dt = 1
            if dt > 100: dt = 100
            deltat.append(dt)
###For deltat

#Velocity damping
        vm = np.linalg.norm(v) / aut
        if vm > v0: v = v / vm * v0
#Velocity damping
        gradient = np.linalg.norm(grad)
        pot = e - e0
        fin1 = e - e_old > 1e-5 
        fin2 = i == nsteps -1
        fin3 = i > 5 and (gradient * kcal) < 1e-2
        if fin1 or fin2 or fin3: 
            if fin1: print('END of this path: e > e_old')
            if fin2: print('END of this path: n_steps exceeded')
            if fin3: print('END of this path: Grad below threshold')
            if sign == -1:
                write(forward_last,rmol)
            else:
                write(reverse_last,rmol)
                print(' == QCORE DONE ==')  
            break    
 
        kin = np.sum(1 / 2 * masses[:,None] * v * v)
        print("     %7.4f     %8.2f     %8.2f     %8.2f      %6.4f         %10.4f" % (i * aut, pot * kcal, kin * kcal, (pot + kin) * kcal, deltat[i] * aut, gradient * kcal)  )
