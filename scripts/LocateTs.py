#!/usr/bin/env python3 

import numpy as np
import networkx as nx
from ase.autoneb import AutoNEB
from ase.constraints import ExternalForce,FixAtoms,FixBondLengths
from ase.dimer import DimerControl, MinModeAtoms, MinModeTranslate
from ase.io import read, write
from ase.md.velocitydistribution import MaxwellBoltzmannDistribution
from ase.optimize import BFGS,FIRE
from ase.vibrations import Vibrations
#from ase.build import minimize_rotation_and_translation
from ase import units
from createMat import get_G_index
from mopacamk import MOPACamk
from os import system
from shutil import copyfile
from re import search
from sys import argv, exit
from Integrators import Langevin
#from xtb.ase.calculator import XTB
from AMK_parameters import emax, label, task, prog, method, charge, gto3d,cov_rad, brrng
from subprocess import run,PIPE
#from sella import Sella
import networkx.algorithms.isomorphism as iso
from cyclic_graph import cycle

def rotation_matrix_from_points(m0, m1):
    """Returns a rigid transformation/rotation matrix that minimizes the
    RMSD between two set of points.

    m0 and m1 should be (3, npoints) numpy arrays with
    coordinates as columns::

        (x1  x2   x3   ... xN
         y1  y2   y3   ... yN
         z1  z2   z3   ... zN)

    The centeroids should be set to origin prior to
    computing the rotation matrix.

    The rotation matrix is computed using quaternion
    algebra as detailed in::

        Melander et al. J. Chem. Theory Comput., 2015, 11,1055
    """

    v0 = np.copy(m0)
    v1 = np.copy(m1)

    # compute the rotation quaternion

    R11, R22, R33 = np.sum(v0 * v1, axis=1)
    R12, R23, R31 = np.sum(v0 * np.roll(v1, -1, axis=0), axis=1)
    R13, R21, R32 = np.sum(v0 * np.roll(v1, -2, axis=0), axis=1)

    f = [[R11 + R22 + R33, R23 - R32, R31 - R13, R12 - R21],
         [R23 - R32, R11 - R22 - R33, R12 + R21, R13 + R31],
         [R31 - R13, R12 + R21, -R11 + R22 - R33, R23 + R32],
         [R12 - R21, R13 + R31, R23 + R32, -R11 - R22 + R33]]

    F = np.array(f)

    w, V = np.linalg.eigh(F)
    # eigenvector corresponding to the most
    # positive eigenvalue
    q = V[:, np.argmax(w)]

    # Rotation matrix from the quaternion q

    R = quaternion_to_matrix(q)

    return R

def quaternion_to_matrix(q):
    """Returns a rotation matrix.

    Computed from a unit quaternion Input as (4,) numpy array.
    """

    q0, q1, q2, q3 = q
    R_q = [[q0**2 + q1**2 - q2**2 - q3**2,
            2 * (q1 * q2 - q0 * q3),
            2 * (q1 * q3 + q0 * q2)],
           [2 * (q1 * q2 + q0 * q3),
            q0**2 - q1**2 + q2**2 - q3**2,
            2 * (q2 * q3 - q0 * q1)],
           [2 * (q1 * q3 - q0 * q2),
            2 * (q2 * q3 + q0 * q1),
            q0**2 - q1**2 - q2**2 + q3**2]]
    return np.array(R_q)


def minimize_rotation_and_translation(target, atoms, weight,wa):
    """Minimize RMSD between atoms and target.

    Rotate and translate atoms to best match target.  For more details, see::

        Melander et al. J. Chem. Theory Comput., 2015, 11,1055
    """

    p = atoms.get_positions()
    p0 = target.get_positions()

    # centeroids to origin
    c = np.mean(p, axis=0)
    p -= c
    c0 = np.mean(p0, axis=0)
    p0 -= c0

    #EMN
    for x in wa:
       p0[x] *= weight
       p[x]  *= weight
    #EMN

    # Compute rotation matrix
    R = rotation_matrix_from_points(p.T, p0.T)


    #EMN
    for x in wa:
       p0[x] /= weight
       p[x]  /= weight
    #EMN

    atoms.set_positions(np.dot(p, R.T) + c0)


def distort(atomos,mol):
    v1 = mol.get_positions()[atomos[2]] - mol.get_positions()[atomos[1]]
    v2 = mol.get_positions()[atomos[0]] - mol.get_positions()[atomos[2]]
    v3 = mol.get_positions()[atomos[1]] - mol.get_positions()[atomos[0]]
    nv1 = np.linalg.norm(v1) ; nv2 = np.linalg.norm(v2) ; nv3 = np.linalg.norm(v3)
    if abs( round( np.dot(v1 / nv1,v2 / nv2) , 2)) == 1.0:
       l = [nv1,nv2,nv3] ; ml = max(l) ; middle = l.index(ml)
       atd = atomos[middle]
       posit = mol.get_positions()
       a = (v1[1] / v1[0]) ** 2 + 1
       b = v1[2] * v1[1]/ v1[0] ** 2
       c = (v1[2] / (2 * v1[0]) ) ** 2 - 3 / 4
       uy = (- b + np.sqrt( b ** 2 - 4 * a * c ) ) / (2 * a)
       ux = np.sqrt(3 / 4 - uy * uy)
       uz = 0.5
       u = np.array([ux,uy,uz])
       posit[atd] = posit[atd] +  0.8 * u
       mol.set_positions(posit)
       return True
    else: return False

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

def runTrajectory(geom, T, Fric, totaltime, timeStep,breakl,forml):
    global n_images
    ene,forces = Energy_and_forces(geom) 
    mdInt = Langevin(units.kB * T, Fric, forces, geom.get_velocities(), geom, timeStep)
    ene,forces = Energy_and_forces(geom)

    if len(breakl) == 1 and len(forml) == 0: 
        thresh_c = 40 ; thresh_d = 40 ; thresh_r = 40
    else: 
        thresh_c = 6  ; thresh_d = 1  ; thresh_r = 3

    # Run MD trajectory for specified number of steps
    n_stop_criteria = 0; damped = False
    write("traj.xyz",geom.copy(),format="xyz")
    for i in range(0,int(totaltime/dt)):
        ene,forces = Energy_and_forces(geom)
        mdInt.mdStepPos(forces,timeStep,geom)
        ene,forces = Energy_and_forces(geom)
        mdInt.mdStepVel(forces,timeStep,geom,damped)

        #Print current positions to file
        write("traj.xyz",geom.copy(),format="xyz",append=True)
        #check adjacency matrix
        G,ind,jnd,ibn,jbn = get_G_index(geom,1,len(geom),False)
        for n in range(n_dist):
            if G[ind[n]][jnd[n]]['weight'] == 0: G.remove_edge(ind[n],jnd[n])
        criteria = 0
        for ele in breakl: criteria += G.has_edge(ele[0],ele[1])
        for ele in forml:  
            criteria += not G.has_edge(ele[0],ele[1])
            if geom.get_distance(ele[0],ele[1]) < 1: 
                damped = True ; geom.set_constraint()
        if criteria == 0: n_stop_criteria += 1
        if n_stop_criteria >= thresh_c: return G
        elif n_stop_criteria >= thresh_r: geom.set_constraint()
        elif n_stop_criteria == thresh_d: damped = True
    geom.set_constraint()
    return G

def runPOpt(geom,breakl,forml):
    write("traj.xyz",geom.copy(),format="xyz")
    #constraints  
    cons_list = []
    sum_radb = []
    sum_radf = []
    for ele in breakl: 
        cons_list.append([ele[0],ele[1]])
        if cycle(geom,ele[0],ele[1]): sum_radb.append(2.0)
        else: sum_radb.append( (cov_rad[symb[ele[0]]] + cov_rad[symb[ele[1]]]) * 5 )
    for ele in forml:  
        cons_list.append([ele[0],ele[1]])
        sum_radf.append( (cov_rad[symb[ele[0]]] + cov_rad[symb[ele[1]]]) * 1.1 )
    #constraints  
    not_move = []
    if len(forml) == 0: n_of_t_b = len(breakl)
    else:  n_of_t_b = len(forml)
    for i in range(0,50):
        geom.set_constraint() 
        positions = geom.get_positions() 
        #Create vectors and move atoms
        for ele in breakl:
           v = geom.get_positions()[ele[1]] - geom.get_positions()[ele[0]]
           v = v / np.linalg.norm(v)
           if ele[1] not in not_move: positions[ele[1]] +=  0.05 * v
           if ele[0] not in not_move: positions[ele[0]] += -0.05 * v
        for ele in forml:
           v = geom.get_positions()[ele[1]] - geom.get_positions()[ele[0]]
           v = v / np.linalg.norm(v)
           if ele[1] not in not_move: positions[ele[1]] += -0.05 * v
           if ele[0] not in not_move: positions[ele[0]] +=  0.05 * v
        geom.set_positions(positions)

        geom.set_constraint(FixBondLengths(cons_list))

        opt = BFGS(geom, logfile='bfgs.log')
        opt.run(fmax=0.5)
        #Print current positions to file
        write("traj.xyz",geom.copy(),format="xyz",append=True)
        ###Check if the product has been formed
        if len(forml) == 0:
           n_of_b_b = 0
           for i,ele in enumerate(breakl):
              if geom.get_distance(ele[0],ele[1]) > sum_radb[i]: 
                 n_of_b_b += 1
                 not_move.extend([ele[0],ele[1]])
           if n_of_b_b == n_of_t_b: 
              geom.set_constraint() 
              print(n_of_b_b,'bonds have been broken. Stop here...')
              return 
        else:
           n_of_f_b = 0
           for i,ele in enumerate(forml):
              if geom.get_distance(ele[0],ele[1]) < sum_radf[i]: 
                 n_of_f_b += 1
                 not_move.extend([ele[0],ele[1]])
           if n_of_f_b == n_of_t_b: 
              geom.set_constraint() 
              print(n_of_f_b,'bonds have been formed. Stop here...')
              return 
    geom.set_constraint() 
    return

             
inputfile = str(argv[1]) ; line = int(argv[2]) ; run_neb = int(argv[3]); e0 = float(argv[4]) 
system('rm -rf image*.traj')
#Default parameters
n_max,prefix,fmax,fmaxi,temp,fric,totaltime,dt,ExtForce,weight,k_neb,semax = 15,'image',0.1,0.025,0.,0.5,100,1,6,100,2,True
#n_max,prefix,fmax,fmaxi,temp,fric,totaltime,dt,ExtForce,weight = 10,'image',0.1,0.1,0.,0.5,100,1,6,100
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
    if search("Graphto3D ", linei): gto3d = str(linei.split()[1]) 
    if search("BreakRing ", linei): 
        brrng = str(linei.split()[1]) 
        if brrng == "yes": brrng = True
        else: brrng = False 
    if search("tsdirll ", linei): 
        path = str(linei.split()[1]) 
try: 
    print('Path to files:',path)
except:
    path = 'tsdirLL_'+molecule
    print('Path to files:',path)
#check inputfile
if gto3d != 'Traj' and gto3d != 'POpt':
    print('Graphto3D valid values: Traj POpt')
    exit()
#We now read ts_bonds.inp file
tsbfile = open(path+'/ts_bonds.inp', "r")
lines = tsbfile.readlines()
cs = lines[line].split() ; constr = []; breakl = []; forml = []; atoms_rxn = []
tsbfile.close()
for i in range(0,len(cs),3):
    if int(cs[i+1]) not in atoms_rxn: atoms_rxn.append(int(cs[i+1]))
    if int(cs[i+2]) not in atoms_rxn: atoms_rxn.append(int(cs[i+2]))
    if cs[i] == "b":
        c = ExternalForce( int(cs[i+1]) , int(cs[i+2]) ,ExtForce)
        constr.append(c) ; breakl.append([ int(cs[i+1]) , int(cs[i+2]) ])
    elif cs[i] == "f":
        c = ExternalForce( int(cs[i+1]) , int(cs[i+2]) ,-ExtForce)
        constr.append(c) ; forml.append([ int(cs[i+1]) , int(cs[i+2]) ])
#Instantiate rmol
rmol = read(molecule+'.xyz')
#For (1,0) rxns, check the bond does not belong to a ring if brrng is False
if len(breakl) == 1 and len(forml) == 0 and not brrng:
   if cycle(rmol,breakl[0][0],breakl[0][1]): 
      print('Bond',breakl[0][0]+1,'-',breakl[0][1]+1,'belongs to a ring:')
      print('Abort...')
      exit()

n_dist = int( len(rmol) * (len(rmol) - 1) / 2)
natom = len(rmol)
aton   = rmol.get_atomic_numbers()
symb   = rmol.get_chemical_symbols()
if prog == 'mopac': rmol.calc = MOPACamk(method=method+' threads=1 charge='+charge,relscf=0.01)
#elif prog == 'XTB': rmol.calc = XTB(method=method)
#atoms_not_rxn
latoms = [item for item in range(natom)]
atoms_not_rxn = np.setdiff1d(latoms,atoms_rxn)

#Optimization of the molecule
print('Path:',line,cs)
print('')
print('Optimizing reactant...')
opt = BFGS(rmol, trajectory='image000.traj',logfile='bfgs000.log')
opt.run(fmax=fmax)
react = rmol.copy()
write("react.xyz",react)
#e0 = rmol.get_potential_energy()
#if prog == 'XTB':
#    reactfile = open(molecule+'_freq.out', 'w')
#    reactfile.write('Energy= '+str(e0)+'\n')
print('Reactant optimized')


##################G of the reactant
Gr,ind,jnd,ibn,jbn = get_G_index(rmol,1,len(rmol),False)
for n in range(n_dist):
    if Gr[ind[n]][jnd[n]]['weight'] == 0: Gr.remove_edge(ind[n],jnd[n])
A  = nx.adjacency_matrix(Gr) ; Ar = A.toarray()
for z in range(natom): Ar[z][z] = aton[z]
##################G of the expected product
Gp = Gr.copy()
for ele in breakl: Gp.remove_edge(ele[0],ele[1])
for ele in forml:  Gp.add_edge(ele[0],ele[1])
A  = nx.adjacency_matrix(Gp) ; Ap = A.toarray()
for z in range(natom): Ap[z][z] = aton[z]
##################
tag_p = np.array(sorted( [np.round(elem,3) for elem in np.linalg.eigvals(Ap) ] ))
tag_r = np.array(sorted( [np.round(elem,3) for elem in np.linalg.eigvals(Ar) ] ))
if np.linalg.norm(tag_p - tag_r) == 0: weight = 1


n_images = 1 
#For (1,0) rxns, the products are easily generated if brrng is False 
if len(breakl) == 1 and len(forml) == 0 and not brrng:
   #put the products some distance appart
   Goneone = Gr.copy()
   Goneone.remove_edge(breakl[0][0],breakl[0][1])
   frags = []
   for c in nx.connected_components(Goneone):
      pmol = rmol.copy()
      frags.append([atom.index for atom in pmol if atom.index in Goneone.subgraph(c).nodes()])
   positions = []
   v1 = rmol.get_positions()[breakl[0][1]] - rmol.get_positions()[breakl[0][0]]  
   v1 = v1 / np.linalg.norm(v1)
   if breakl[0][1] in frags[0]: signfrag0 = 1
   else: signfrag0 = -1

   for index in range(len(rmol)):
      if index in frags[0]: sign = signfrag0
      else: sign = - signfrag0
      positions.append(rmol.get_positions()[index] + sign * v1 * 2.5)
   rmol.set_positions(positions)
   write('prod_sep.xyz',rmol)
#For (1,0) rxns, if brrng is True, then runPOpt until the bond is 2 Angstroms long 
elif len(breakl) == 1 and len(forml) == 0 and brrng:
   print('Running partial optimizations to transform Graph--> 3D geometry')
   runPOpt(rmol,breakl,forml)
   print('Partial optimizations finished')
else:
#When three atoms involved in the forces are in a line--> distort the geometry and add one more image
   if len(atoms_rxn) == 3:
       if distort(atoms_rxn,rmol): 
           print('Reactant geometry distorted')
           minimize_rotation_and_translation(react,rmol,weight,atoms_not_rxn)
           write('react_distorted.xyz',rmol)
           write('image00'+str(n_images)+'.traj',rmol)
           n_images += 1
           rmol.set_constraint() 
   if gto3d == 'Traj':
      #For the dynamics we give all Hs a mass of 4.0 and apply contraints
      masses = []
      for x in aton:
          if x == 1: masses.append(4.0)
          else: masses.append(None)
      rmol.set_masses(masses=masses) ; rmol.set_constraint(constr)
      ###
      MaxwellBoltzmannDistribution(rmol, temperature_K = temp )
      ##Run a constrained short traj to reach the prod.
      print('Running dynamics with External Force to transform Graph--> 3D geometry')
      G = runTrajectory(rmol,temp,fric,totaltime,dt * units.fs ,breakl,forml)
      print('Dynamics with External Force finished')
   elif gto3d == 'POpt':
      print('Running partial optimizations to transform Graph--> 3D geometry')
      runPOpt(rmol,breakl,forml)
      print('Partial optimizations finished')

print('Optimizing product...')
minimize_rotation_and_translation(react,rmol,weight,atoms_not_rxn)
#For intermediates we first move the structure along the largest negative eigenvector
if nx.is_connected(Gp):
    eigenv, freq = vib_calc(rmol)
    #We first move the structure along the largest negative eigenvector direction 
    positions = rmol.get_positions() + 0.01 * eigenv[0] / np.linalg.norm(eigenv[0])
    rmol.set_positions(positions)
#EMN
if len(breakl) == 1 and len(forml) == 0:
   c = FixAtoms(indices=[breakl[0][0],breakl[0][1]])
   rmol.set_constraint(c)
   k_neb = 20
opt = BFGS(rmol, trajectory='image00'+str(n_images)+'.traj',logfile='bfgs00'+str(n_images)+'.log')
if len(breakl) == 1 and len(forml) == 0: opt.run(fmax=0.5)
else: opt.run(fmax=fmax)
#EMN
prod = rmol.copy()
write("prod.xyz",prod)
print('Product optimized')

###Gx is the Graph coming out of the optimization 
Gx,ind,jnd,ibn,jbn = get_G_index(rmol,1,len(rmol),False)
for n in range(n_dist):
    if Gx[ind[n]][jnd[n]]['weight'] == 0: Gx.remove_edge(ind[n],jnd[n])
A  = nx.adjacency_matrix(Gx) ; Ax = A.toarray()
for z in range(natom): Ax[z][z] = aton[z]
###Check for barrierless processes
Adiff = Ar - Ax
if np.linalg.norm(Adiff) == 0:
    if not nx.is_connected(Gp): print('Final and initial states are the same --> Barrierless process')
    else: print('Final and initial states are the same')
    print('Abort...')
    exit()
###Check that the product is the expected
Adiff = Ap - Ax
if np.linalg.norm(Adiff) != 0:
    print('It seems that the product is not the expected one')
    print('We proceed anyway...')
    #print('Abort...')
    #exit()

###Check that the Gx is isomorphic with Gp
criteria = 0
for ele in breakl: criteria += Gx.has_edge(ele[0],ele[1])
for ele in forml:  criteria += not Gx.has_edge(ele[0],ele[1])
if criteria > 0:
    print('Obtained product is not the expected  --> The product could not be generated')
    print('We proceed anyway...')
    #print('Abort...')
    #exit()
#Adiff = Ap - Ax
#if np.linalg.norm(Adiff) > 0:
#    print('Obtained product is not the expected  --> The product could not be generated')
#    exit()
##################
 
#ep = rmol.get_potential_energy() 
ep = rmol.calc.get_final_heat_of_formation() * units.mol / units.kcal
dE = ep - e0
print('{:s} {:10.4f} {:s}'.format('Product energy rel: ',dE,'kcal/mol'))
print('{:s} {:10.4f} {:s}'.format('Product energy abs: ',ep,'kcal/mol'))

#if nx.is_connected(G):
#dE = dE * units.mol / units.kcal
if dE > emax:
    print('Product energy > emax:',dE,emax)
    print('Abort...')
    exit()

print('')

if not run_neb: exit()
#Run autoneb 
#autoneb = AutoNEB(attach_calculators,
#                  prefix=prefix, 
#                  optimizer='BFGS',
#                  n_simul=1,
#                  n_max=n_max,
#                  fmax=fmaxi,
#                  k=0.1,
#                  parallel=False,
#                  maxsteps=[50,1000])
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
print(' #            E(eV)')
for i in range(n_max):
    pot = autoneb.all_images[i].get_potential_energy()
    write('ts_'+str(i)+'.xyz',autoneb.all_images[i].copy())
    if pot > pot_max and pot !=0 and i != n_max-1: 
        pot_max = pot; imax = i 
        ts = autoneb.all_images[i].copy()
        tsint = autoneb.all_images[i].copy()
        tslet = autoneb.all_images[i].copy()
        write('ts_inp.xyz',ts)
    print('{:2.0f} {:16.2f}'.format(i, pot))
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
