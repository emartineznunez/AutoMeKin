#set up max val for atoms in a dict
max_val = {'H' : 1, 'Li' : 1, 'Be' : 2, 'B' : 3, 'C' : 4 , 'N' : 3, 'O' : 2, 'F' : 1, 'Na' : 1, 'Mg' : 2, 'Al' : 3, 'Si' : 4, 'P' : 5, 'S' : 6, 'Cl' : 1, 'Br' : 1, 'I' : 1 }
min_val = {'H' : 1, 'Li' : 0, 'Be' : 0, 'B' : 1, 'C' : 1 , 'N' : 1, 'O' : 1, 'F' : 0, 'Na' : 0, 'Mg' : 0, 'Al' : 1, 'Si' : 1, 'P' : 1, 'S' : 1, 'Cl' : 0, 'Br' : 0, 'I' : 0 }
cov_rad = {'Ac' : 1.88 ,'Er' : 1.73 ,'Na' : 0.97 ,'Sb' : 1.46 ,'Ag' : 1.59 ,'Eu' : 1.99 ,'Nb' : 1.48 ,'Sc' : 1.44 ,'Al' : 1.35 ,'F' : 0.64 ,'Nd' : 1.81 ,'Se' : 1.22 ,'Am' : 1.51 ,'Fe' : 1.34 ,'Ni' : 1.50 ,'Si' : 1.20 ,'As' : 1.21 ,'Ga' : 1.22 ,'Np' : 1.55 ,'Sm' : 1.80 ,'Au' : 1.50 ,'Gd' : 1.79 ,'O' : 0.68 ,'Sn' : 1.46 ,'B' : 0.83 ,'Ge' : 1.17 ,'Os' : 1.37 ,'Sr' : 1.12 ,'Ba' : 1.34 ,'H' : 0.35 ,'P' : 1.05 ,'Ta' : 1.43 ,'Be' : 0.35 ,'Hf' : 1.57 ,'Pa' : 1.61 ,'Tb' : 1.76 ,'Bi' : 1.54 ,'Hg' : 1.70 ,'Pb' : 1.54 ,'Tc' : 1.35 ,'Br' : 1.21 ,'Ho' : 1.74 ,'Pd' : 1.50 ,'Te' : 1.47 ,'C' : 0.68 ,'I' : 1.40 ,'Pm' : 1.80 ,'Th' : 1.79 ,'Ca' : 0.99 ,'In' : 1.63 ,'Po' : 1.68 ,'Ti' : 1.47 ,'Cd' : 1.69 ,'Ir' : 1.32 ,'Pr' : 1.82 ,'Tl' : 1.55 ,'Ce' : 1.83 ,'K' : 1.33 ,'Pt' : 1.50 ,'Tm' : 1.72 ,'Cl' : 0.99 ,'La' : 1.87 ,'Pu' : 1.53 ,'U' : 1.58 ,'Co' : 1.33 ,'Li' : 0.68 ,'Ra' : 1.90 ,'V' : 1.33 ,'Cr' : 1.35 ,'Lu' : 1.72 ,'Rr' : 1.47 ,'W' : 1.37 ,'Cs' : 1.67 ,'Mg' : 1.10 ,'Re' : 1.35 ,'Y' : 1.78 ,'Cu' : 1.52 ,'Mn' : 1.35 ,'Rh' : 1.45 ,'Yb' : 1.94 ,'D' : 0.23 ,'Mo' : 1.47 ,'Ru' : 1.40 ,'Zn' : 1.45 ,'Dy' : 1.75 ,'N' : 0.68 ,'S' : 1.02 ,'Zr' : 1.56 }
vdw_rad = {'H' :  1.10, 'He' :  1.40, 'Li' :  1.81, 'Be' :  1.53, 'B' :  1.92, 'C' :  1.70, 'N' :  1.55, 'O' :  1.52, 'F' :  1.47, 'Ne' :  1.54, 'Na' :  2.27, 'Mg' :  1.73, 'Al' :  1.84, 'Si' :  2.10, 'P' :  1.80, 'S' :  1.80, 'Cl' :  1.75, 'Ar' :  1.88, 'K' :  2.75, 'Ca' :  2.31, 'Ga' :  1.87, 'Ge' :  2.11, 'As' :  1.85, 'Se' :  1.90, 'Br' :  1.83, 'Kr' :  2.02, 'Rb' :  3.03, 'Sr' :  2.49, 'In' :  1.93, 'Sn' :  2.17, 'Sb' :  2.06, 'Te' :  2.06, 'I' :  1.98, 'Xe' :  2.16, 'Cs' :  3.43, 'Ba' :  2.68, 'Tl' :  1.96, 'Pb' :  2.02, 'Bi' :  2.07, 'Po' :  1.97, 'At' :  2.02, 'Rn' :  2.20, 'Fr' :  3.48, 'Ra' :  3.83 }
#number of bonds that change in a given process-->nbonds
nbonds   = 3
emax     = 150
prog     = 'mopac'
method   = 'PM7'
task     = '1SCF GRADIENTS BONDS'
relscf   = '0.01'
active   = []
startd   = 2.75
label    = 'none'
comb22   = False
Crossb   = False
brrng    = False
charge   = '0'
MaxBoB   = 2
MaxBoF   = 2
MaxBO    = 1.5
gto3d    = 'POpt'
