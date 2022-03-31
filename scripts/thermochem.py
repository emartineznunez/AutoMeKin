#!/usr/bin/env python3

""" 
This script computes thermodynamic properties from the data given in file basename
and for the temperature specified as the second argument:                           

themochem.py basename temperature calc

"""

import os.path
import sys
import re
import math
from numpy import *
from scipy.linalg import *

basename = str(sys.argv[1])
temperature = float(sys.argv[2])
calc = str(sys.argv[3])

symbol_list = ['H','He','Li','Be','B','C','N','O','F','Ne','Na','Mg','Al','Si','P','S','Cl','Ar','K','Ca','Sc','Ti','V','Cr','Mn','Fe','Co','Ni','Cu','Zn','Ga','Ge','As','Se','Br','Kr','Rb','Sr','Y','Zr','Nb','Mo','Tc','Ru','Rh','Pd','Ag','Cd','In','Sn','Sb','Te','I','Xe','Cs','Ba','La','Ce','Pr','Nd','Pm','Sm','Eu','Gd','Tb','Dy','Ho','Er','Tm','Yb','Lu','Hf','Ta','W','Re','Os','Ir','Pt','Au','Hg','Tl','Pb','Bi','Po','At','Rn','Fr','Ra','Ac','Th','Pa','U','Np','Pu','Am','Cm','Bk','Cf','Es','Fm','Md','No','Lr','D']
mass_list = [1.00790,  4.00260,  6.94000,  9.01218,10.81000, 12.01100, 14.00670, 15.99940, 18.99840, 20.17900, 22.98977, 24.30500, 26.98154, 28.08550,30.97376, 32.06000, 35.45300, 39.94800, 39.09830,40.08000, 44.95590, 47.90000, 50.94150, 51.99600,54.93800, 55.84700, 58.93320, 58.71000, 63.54600,65.38,69.73500, 72.59000, 74.92160, 78.96000,79.90400, 83.80000, 85.46780, 87.62000, 88.90590,91.22000, 92.90640, 95.94000, 98.90620, 101.0700,102.9055,106.4000, 107.8680, 112.4100, 114.8200,118.6900, 121.7500, 127.6000, 126.9045, 131.3000,132.9054, 137.3300,138.9063,139.9054,140.9076,141.9077,144.9127,151.9197,152.9212,157.9241,158.9253,163.9292,164.9303,165.9303,168.9342,173.9389,174.9408,179.9465,180.9480,183.9509,186.9557,191.9615,192.9629,194.9648,196.9665,201.9706,204.9744,207.9766,208.9804,208.9824,209.9871,222.0176,223.0197,226.0254,227.0278,232.0381,231.0359,238.0508,237.0482,244.0642,243.0614,247.0703,247.0703,251.0796,252.0829,257.0751,258.0986,259.1009,260.1053,2.014102]
molecular_mass = 0.0

########################### Fundamental constants and conversion factors
a0 = 0.5291772108         # in Angstrom
k_B = 1.3806505e-23       # J/K
h = 6.6260693e-34         # J s
N_A = 6.0221415e23        # Avogadro number
R = 8.31447               # J/K/mol
m_u = 1.66053886e-27      # atomic mass constant in kg
c = 2.99792558e8          # speed of light in m/s
                          #
atm2pa = 101325           # 1 atm to N/m**2
J2Eh   = 2.293712317e17   # J to Hartree
Eh2kcal = 627.51          # Eh to kcal/mol
########################### 

def rotational_temperature(moment_of_inertia):
#   moment of inertia in SI units
    theta_R = h*h/(8*math.pi*math.pi*k_B*moment_of_inertia)
    return theta_R

dataFile = basename 
dFile = open(dataFile, 'r')

i = 0
for line in dFile:
    i = i + 1
    if len(line.strip()) == 0 : break
    columns = line.split()
    if i == 1: 
       number_of_atoms = int(columns[0])
# We do not want to work with index 0
       atomic_symbol = [0]*(number_of_atoms+1)
       x = [0]*(number_of_atoms+1)
       y = [0]*(number_of_atoms+1)
       z = [0]*(number_of_atoms+1)
       mass = [0]*(number_of_atoms+1)
       frequency = [0]*(3*number_of_atoms-4)
    elif i == 2:
       if calc == 'll':
          electronic_energy = float(columns[1])/Eh2kcal
       elif calc == 'hl':
          electronic_energy = float(columns[1])
       zpe_kcal = float(columns[3])
       zpe_kJ   = zpe_kcal*4.184
       zpe_au   = zpe_kJ*1000*J2Eh/N_A
       if len(columns) == 8:      # Symmetry number
          sigma = int(columns[7])
       else:
          sigma = 1  
    elif i > 2 and i < number_of_atoms+3:
       j = i - 2
       atomic_symbol[j] = str(columns[0])
       if atomic_symbol[j].islower():
          atomic_symbol[j] = atomic_symbol[j].upper()
       mass[j] = mass_list[symbol_list.index(atomic_symbol[j])]
       molecular_mass = molecular_mass + mass[j]
# Cartesian coordinates in atomic units
       x[j] = float(columns[1])/a0
       y[j] = float(columns[2])/a0
       z[j] = float(columns[3])/a0
    else:
       k = i - (number_of_atoms+2)
       frequency[k] = float(columns[0])

dFile.close()
#New for atoms
#EMN
if number_of_atoms > 1:
   number_of_frequencies = k

#EMN
# Read multiplicity from amk.dat file
if len(sys.argv) == 5:
   multiplicity = float(sys.argv[4])
elif os.path.isfile('amk.dat'):
   f_mult = open('amk.dat', 'r')
   for line in f_mult:
      if re.search("mult ",line,re.IGNORECASE):
         multiplicity = int(line.split()[1]) 
         print(' ')
         print('######################################################################################  \n')
         print(' Multiplicity = ', multiplicity, ' read from file amk.dat \n')
else:
   multiplicity = 1
   print('######################################################################################  \n')

#EMN
print('Multiplicity',multiplicity)
#Calculation of the moments of inertia (in atomic units)
if number_of_atoms == 1:
   print('No rotational contribution')
elif number_of_atoms == 2:
   reduced_mass = mass[1]*mass[2]/(mass[1]+mass[2])
   distance_square = (x[2]-x[1])**2 + (y[2]-y[1])**2 + (z[2]-z[1])**2  
   Ia = reduced_mass*distance_square
   linear = True
   moment_of_inertia = Ia
   moment_of_inertia_SI = moment_of_inertia*m_u*a0*a0*1.0e-20
else:
   my2z2 = 0.0
   mx2z2 = 0.0
   mx2y2 = 0.0
   mxy   = 0.0
   mxz   = 0.0
   myz   = 0.0
   mx    = 0.0
   my    = 0.0
   mz    = 0.0
   for i in range(1,number_of_atoms+1):
       my2z2 = my2z2 + mass[i]*(y[i]*y[i]+z[i]*z[i])
       mx2z2 = mx2z2 + mass[i]*(x[i]*x[i]+z[i]*z[i])
       mx2y2 = mx2y2 + mass[i]*(x[i]*x[i]+y[i]*y[i])
       mxy = mxy + mass[i]*x[i]*y[i]
       mxz = mxz + mass[i]*x[i]*z[i]
       myz = myz + mass[i]*y[i]*z[i]
       mx = mx + mass[i]*x[i]
       my = my + mass[i]*y[i]
       mz = mz + mass[i]*z[i]
# Inertia tensor elements in atomic units
   Ixx = my2z2 - my*my/molecular_mass - mz*mz/molecular_mass
   Iyy = mx2z2 - mx*mx/molecular_mass - mz*mz/molecular_mass
   Izz = mx2y2 - mx*mx/molecular_mass - my*my/molecular_mass
   Ixy = mx*my/molecular_mass - mxy
   Ixz = mx*mz/molecular_mass - mxz
   Iyz = my*mz/molecular_mass - myz

   I = matrix([[Ixx, Ixy, Ixz], [Ixy, Iyy, Iyz], [Ixz, Iyz, Izz]])
   L, V = eig(I)
   Ia = L.real[0]
   Ib = L.real[1]
   Ic = L.real[2]
   Ia_SI = Ia*m_u*a0*a0*1.0e-20
   Ib_SI = Ib*m_u*a0*a0*1.0e-20
   Ic_SI = Ic*m_u*a0*a0*1.0e-20
   if Ia < 2.0 or Ib < 2.0 or Ic < 2.0: 
      linear = True
      moment_of_inertia = (Ia+Ib+Ic)/2
      moment_of_inertia_SI = moment_of_inertia*m_u*a0*a0*1.0e-20
   else:
      linear = False

''' Partition functions and thermodynamic functions.
    The electronic contribution is not included in this script.
'''

# Contributions from translation                    
# Translational partition function q_t = (2*pi*total_mass*k_B*T/h/h)**1.5*k_B*T/P
q_t = (2*math.pi*molecular_mass*m_u*k_B*temperature/h/h)**1.5*k_B*temperature/atm2pa

# Translational entropy, S_t, in J/K/mol
S_t = R*(math.log(q_t)+2.5)
# Internal energy (tanslational), E_t, in J/mol
E_t = 1.5*R*temperature 

# Contributions from rotation. 
if number_of_atoms == 1:
   print('No rotational contribution')
   E_r=0
   S_r=0
elif linear:
   q_r = temperature/(sigma*rotational_temperature(moment_of_inertia_SI))
   S_r = R*(math.log(q_r) + 1.0)
   E_r = R*temperature
else:
   q_r = math.sqrt(math.pi)*(temperature**1.5/math.sqrt(rotational_temperature(Ia_SI)*rotational_temperature(Ib_SI)*rotational_temperature(Ic_SI)))
   q_r = q_r/sigma 
   S_r = R*(math.log(q_r)+1.5)
   E_r = 1.5*R*temperature

# Contributions from vibration
if number_of_atoms == 1:
   print('No vibrational contribution')
   E_v     = 0.0
   S_v     = 0.0
else:
# theta_v[] = Vibrational temperatures
   theta_v = [0]*(number_of_frequencies+1)
   q_v_bot = 1.0
   q_v_v0  = 1.0
   E_v     = 0.0
   S_v     = 0.0
   for i in range(1,number_of_frequencies+1): 
       theta_v[i] = h*c*frequency[i]*100/k_B 
       q_v_bot = -q_v_bot*math.exp(-theta_v[i]/temperature/2)/math.expm1(-theta_v[i]/temperature)
       q_v_v0  = -q_v_v0/math.expm1(-theta_v[i]/temperature)
       S_v = S_v + R*(theta_v[i]/temperature/math.expm1(theta_v[i]/temperature) - math.log(1-math.exp(-theta_v[i]/temperature)))
#   This E_v is the vibrational energy including ZPE
       E_v = E_v + R*(theta_v[i]*(0.5+(1/math.expm1(theta_v[i]/temperature))))

# Removing ZPE contribution (E_v in kJ/mol)
E_v = E_v/1000 - zpe_kJ

E_t = E_t/1000 
E_r = E_r/1000
E_corr = E_t + E_r + E_v                        # kJ/mol
E_corr_kcal = E_corr/4.184                      # kcal/mol 
E_corr_au = E_corr*1000*J2Eh/N_A                # hartree
electronic_and_zpe = electronic_energy + zpe_au # hartree
E_total = electronic_energy+zpe_au+E_corr_au    # hartree
S_e = R*math.log(multiplicity)                  # J/mol/K
S_tot  = S_t + S_r + S_v + S_e                  # cal/mol/K 
S_tot_cal = S_tot/4.184                         # cal/mol/K
S_t_cal = S_t/4.184
S_r_cal = S_r/4.184
S_v_cal = S_v/4.184
S_e_cal = S_e/4.184
S_tot_au = S_tot*J2Eh/N_A                       # hartree/K
H_corr = E_corr + k_B*temperature*N_A/1000      # kJ/mol 
H_corr_kcal = H_corr/4.184                      # kcal/mol 
H_corr_au = E_corr_au + k_B*temperature*J2Eh    # hartree
H_total = E_total + k_B*temperature*J2Eh        # hartree
G_corr_au = zpe_au + H_corr_au - temperature*S_tot_au    # hartree
G_corr_kcal = G_corr_au*Eh2kcal                      # kcal/mol
G_corr = G_corr_kcal*4.184                                # kJ/mol
G_total = H_total - temperature*S_tot_au        # hartree

####################   Main printing section ############################
if number_of_atoms >= 2:
   print(' Principal axes of inertia (atomic units) ')
if number_of_atoms == 1:
   print('Nothing to be printed here')
elif number_of_atoms == 2:
   print(' Ia = ', "%.4f" % Ia)
else:
   print(' Ia = ', "%.4f" % Ia, ' Ib = ', "%.4f" % Ib, ' Ic = ', "%.4f" % Ic, ' \n')
print(' Molecular mass = ', "%.4f" % molecular_mass)
print(' Rotational temperatures (K) ')
if number_of_atoms == 1:
   print('No thetas')
elif linear:
   print(' Theta   = ', "%.4f" % rotational_temperature(moment_of_inertia_SI))
else:
   print(' Theta_a = ', "%.4f" % rotational_temperature(Ia_SI), ' Theta_b = ', "%.4f" % rotational_temperature(Ib_SI), \
         ' Theta_c = ', "%.4f" % rotational_temperature(Ic_SI), ' \n')
print(' Rotational symmetry number = ', sigma, ' \n\n')
print(' Electronic energy (hartree)                        = ', "%.6f" % electronic_energy, '\n')
print(' Zero-point energy (hartree)                        = ', "%.6f" % zpe_au)
print('                   (kcal/mol)                       = ', "%.2f" % zpe_kcal)
print('                   (kJ/mol)                         = ', "%.2f" % zpe_kJ, ' \n')
# Thermal corrections (in SI and in atomic units, e.g., E_corr and E_corr_au). The vibrational contribution includes ZPE.
# Thermal corrections in a.u. (per molecule).
print(' Total internal energy                   (hartree)  = ', "%.6f" % E_total)
print(' Electronic energy + ZPVE                (hartree)  = ', "%.6f" % electronic_and_zpe)
print(' Thermal correction to internal energy   (hartree)  = ', "%.6f" % E_corr_au)
print('                                         (kJ/mol)   = ', "%.2f" % E_corr)
print('                                         (kcal/mol) = ', "%.2f" % E_corr_kcal, '\n')
print(' Contributions to E_corr (kJ/mol):    Translational = ', "%.2f" % E_t)
print('                                      Rotational    = ', "%.2f" % E_r)
print('                                      Vibrational   = ', "%.2f" % E_v, '\n\n')

print(' Total entropy (cal/K/mol) = ', "%.2f" % S_tot_cal, ' ( S_trans = ', "%.2f" % S_t_cal, ' S_rot = ', \
      "%.2f" % S_r_cal, ' S_vib = ', "%.2f" % S_v_cal, ' S_ele = ', "%.2f" % S_e_cal,') \n\n') 

print(' Total enthalpy                          (hartree)  = ', "%.6f" % H_total)
print(' Thermal correction to enthalpy          (kcal/mol) = ', "%.6f" % H_corr_kcal)
print('                                         (kJ/mol)   = ', "%.2f" % H_corr)
print('                                         (hartree)  = ', "%.6f" % H_corr_au, ' \n\n')

print(' Total Gibbs free energy                 (hartree)  = ', "%.6f" % G_total)
print(' Thermal correction to Gibss free energy (kcal/mol) = ', "%.6f" % G_corr_kcal)
print('                                         (kJ/mol)   = ', "%.2f" % G_corr)
print('                                         (hartree)  = ', "%.6f" % G_corr_au, ' \n')
print('######################################################################################  \n')


