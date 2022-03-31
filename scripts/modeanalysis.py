#!/usr/bin/env python3

#================================#
import cmath
import numpy    as np
import os
import random
import sys
#================================#
CONNECTSCAL    = 1.3
EPS_CCIC       = 6.0 # cm^-1
EPS_FLOAT      = 1e-8
EPS_GEOM       = 1e-5
EPS_GIV        = 1e-10
EPS_IC         = 0.3
EPS_ICF        = 0.3
EPS_INERTIA    = 1e-7
EPS_LINEAR     = 4.5
EPS_NORM       = 1e-7
EPS_SCX        = 1e-7
EPS_SVD        = 1e-9
EPS_SMALLANGLE = 1e-3
#================================#

#==============================================#
alphUC   = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"        #
alphLC   = "abcdefghijklmnopqrstuvwxyz"        #
numbers  = "0123456789"                        #
#==============================================#

#==============================================#
# SOME USEFUL CONSTANTS AND CONVERSION FACTORS #
#==============================================#
#------------- related to radians -------------#
PI       = 3.141592653589793                   # from math module
TWOPI    = 6.283185307179586                   #
#---------- physical constants  (SI) ----------#
H_SI     = 6.62606896E-34                      # Planck constant    [J*s]
NA_SI    = 6.022140857E+023                    # Avogradro's number [mol^-1]
C0_SI    = 2.99792458E8                        # speed of light     [m/s]
KB_SI    = 1.3806504E-23                       # Boltzmann const    [J/K]
QE_SI    = 1.6021766208E-019                   # charge of electron [C]
ME_SI    = 9.10938356E-031                     # mass of electron   [kg]
MC12_SI  = 1.66053904E-027                     # mass of C12        [kg]
CAL_SI   = 4.184                               # 1 cal = 4.184 J
R_SI     = KB_SI *  NA_SI                      # Ideal gas constant [J*K^-1*mol^-1]
HBAR_SI  =  H_SI / TWOPI                       # Planck constant divided by 2pi    
#-------------- conversion to au --------------#
JOULE    = 4.35974465E-018                     #
METER    = 0.52917721067E-10                   #
SECOND   = 1.0 / 4.1341373337e+16              #
ANGSTROM = METER * 1E10                        #
AMU      = ME_SI/MC12_SI                       #
KG       = ME_SI                               #
CAL      = JOULE / CAL_SI                      #
KCAL     = CAL /1000.0                         #
KJMOL    = JOULE * NA_SI / 1000.0              #
KCALMOL  = KJMOL / CAL_SI                      #
CALMOL   = KCALMOL * 1000.0                    #
JMOL     = KJMOL * 1000.0                      #
METER3   = METER**3                            #
CM       = 100 * METER                         #
ML       = CM**3                               #
EV       = JOULE/QE_SI                         #
DEBYE    = 2.541746                            #
#---------- physical constants  (au) ----------#
H        = 2*PI                                #
HBAR     = 1.0                                 #
NA       = NA_SI                               #
C0       = C0_SI / (METER/SECOND)              #
KB       = KB_SI / (JOULE)                     #
ME       = ME_SI / (KG)                        #
R        = KB * NA                             #
H2CM     = 1.0 / (H * C0) / CM                 # hartree to 1/cm
CM2H     = 1.0/H2CM                            # 1/cm to hartree
#==============================================#

#==============================================#
#            References states in au            #
#==============================================#
PRE0 = 1.00E5  / (JOULE / METER3) # reference pressure of 1 bar
VOL0 = 1.00    / ML               # reference volume of 1 mL per molecule
#==============================================#

#=============================================#
# PERIODIC TABLE: symbols, atnums, masses and #
#                 covalent radii              #
# dpt = dict for periodic table               #
#=============================================#

# Z ---> symbol
dpt_z2s = {  0:'XX' ,                                             \
             1:'H ' ,   2:'He' ,   3:'Li' ,   4:'Be' ,   5:'B ' , \
             6:'C ' ,   7:'N ' ,   8:'O ' ,   9:'F ' ,  10:'Ne' , \
            11:'Na' ,  12:'Mg' ,  13:'Al' ,  14:'Si' ,  15:'P ' , \
            16:'S ' ,  17:'Cl' ,  18:'Ar' ,  19:'K ' ,  20:'Ca' , \
            21:'Sc' ,  22:'Ti' ,  23:'V ' ,  24:'Cr' ,  25:'Mn' , \
            26:'Fe' ,  27:'Co' ,  28:'Ni' ,  29:'Cu' ,  30:'Zn' , \
            31:'Ga' ,  32:'Ge' ,  33:'As' ,  34:'Se' ,  35:'Br' , \
            36:'Kr' ,  37:'Rb' ,  38:'Sr' ,  39:'Y ' ,  40:'Zr' , \
            41:'Nb' ,  42:'Mo' ,  43:'Tc' ,  44:'Ru' ,  45:'Rh' , \
            46:'Pd' ,  47:'Ag' ,  48:'Cd' ,  49:'In' ,  50:'Sn' , \
            51:'Sb' ,  52:'Te' ,  53:'I ' ,  54:'Xe' ,  55:'Cs' , \
            56:'Ba' ,  57:'La' ,  58:'Ce' ,  59:'Pr' ,  60:'Nd' , \
            61:'Pm' ,  62:'Sm' ,  63:'Eu' ,  64:'Gd' ,  65:'Tb' , \
            66:'Dy' ,  67:'Ho' ,  68:'Er' ,  69:'Tm' ,  70:'Yb' , \
            71:'Lu' ,  72:'Hf' ,  73:'Ta' ,  74:'W ' ,  75:'Re' , \
            76:'Os' ,  77:'Ir' ,  78:'Pt' ,  79:'Au' ,  80:'Hg' , \
            81:'Tl' ,  82:'Pb' ,  83:'Bi' ,  84:'Po' ,  85:'At' , \
            86:'Rn' ,  87:'Fr' ,  88:'Ra' ,  89:'Ac' ,  90:'Th' , \
            91:'Pa' ,  92:'U ' ,  93:'Np' ,  94:'Pu' ,  95:'Am' , \
            96:'Cm' ,  97:'Bk' ,  98:'Cf' ,  99:'Es' , 100:'Fm' , \
           101:'Md' , 102:'No' , 103:'Lr'                         \
          }

# Z --> mass
dpt_z2m = {  0:  0.000000 ,                                                    \
             1:  1.007825 ,   2:  4.002600 ,   3:  7.016000 ,   4:  9.012180 , \
             5: 11.009310 ,   6: 12.000000 ,   7: 14.003070 ,   8: 15.994910 , \
             9: 18.998400 ,  10: 19.992440 ,  11: 22.989800 ,  12: 23.985040 , \
            13: 26.981530 ,  14: 27.976930 ,  15: 30.973760 ,  16: 31.972070 , \
            17: 34.968850 ,  18: 39.948000 ,  19: 38.963710 ,  20: 39.962590 , \
            21: 44.955920 ,  22: 47.900000 ,  23: 50.944000 ,  24: 51.940500 , \
            25: 54.938100 ,  26: 55.934900 ,  27: 58.933200 ,  28: 57.935300 , \
            29: 62.929800 ,  30: 63.929100 ,  31: 68.925700 ,  32: 73.921900 , \
            33: 74.921600 ,  34: 79.916500 ,  35: 78.918300 ,  36: 83.911500 , \
            37: 84.911700 ,  38: 87.905600 ,  39: 89.905400 ,  40: 89.904300 , \
            41: 92.906000 ,  42: 97.905500 ,  43: 97.000000 ,  44:101.903700 , \
            45:102.904800 ,  46:105.903200 ,  47:106.904100 ,  48:113.903600 , \
            49:114.904100 ,  50:119.902200 ,  51:120.903800 ,  52:129.906700 , \
            53:126.904400 ,  54:131.904200 ,  55:132.905400 ,  56:137.905200 , \
            57:138.906300 ,  58:139.905400 ,  59:140.907600 ,  60:141.907700 , \
            61:144.912700 ,  62:151.919700 ,  63:152.921200 ,  64:157.924100 , \
            65:158.925300 ,  66:163.929200 ,  67:164.930300 ,  68:165.930300 , \
            69:168.934200 ,  70:173.938900 ,  71:174.940800 ,  72:179.946500 , \
            73:180.948000 ,  74:183.950900 ,  75:186.955700 ,  76:191.961500 , \
            77:192.962900 ,  78:194.964800 ,  79:196.966500 ,  80:201.970600 , \
            81:204.974400 ,  82:207.976600 ,  83:208.980400 ,  84:208.982400 , \
            85:209.987100 ,  86:222.017600 ,  87:223.019700 ,  88:226.025400 , \
            89:227.027800 ,  90:232.038100 ,  91:231.035900 ,  92:238.050800 , \
            93:237.048200 ,  94:244.064200 ,  95:243.061400 ,  96:247.070300 , \
            97:247.070300 ,  98:251.079600 ,  99:252.082900 , 100:257.075100 , \
           101:258.098600 , 102:259.100900 , 103:260.105300 }

# Z --> covalent radius
dpt_z2cr = {  0:-10.00 ,                                             \
              1:0.31 ,   2:0.28 ,   3:1.28 ,   4:0.96 ,   5:0.84 , \
              6:0.73 ,   7:0.71 ,   8:0.66 ,   9:0.57 ,  10:0.58 , \
             11:1.66 ,  12:1.41 ,  13:1.21 ,  14:1.11 ,  15:1.07 , \
             16:1.05 ,  17:1.02 ,  18:1.06 ,  19:2.03 ,  20:1.76 , \
             21:1.70 ,  22:1.60 ,  23:1.53 ,  24:1.39 ,  25:1.50 , \
             26:1.42 ,  27:1.38 ,  28:1.24 ,  29:1.32 ,  30:1.22 , \
             31:1.22 ,  32:1.20 ,  33:1.19 ,  34:1.20 ,  35:1.20 , \
             36:1.16 ,  37:2.20 ,  38:1.95 ,  39:1.90 ,  40:1.75 , \
             41:1.64 ,  42:1.54 ,  43:1.47 ,  44:1.46 ,  45:1.42 , \
             46:1.39 ,  47:1.45 ,  48:1.44 ,  49:1.42 ,  50:1.39 , \
             51:1.39 ,  52:1.38 ,  53:1.39 ,  54:1.40 ,  55:2.44 , \
             56:2.15 ,  57:2.07 ,  58:2.04 ,  59:2.03 ,  60:2.01 , \
             61:1.99 ,  62:1.98 ,  63:1.98 ,  64:1.96 ,  65:1.94 , \
             66:1.92 ,  67:1.92 ,  68:1.89 ,  69:1.90 ,  70:1.87 , \
             71:1.87 ,  72:1.75 ,  73:1.70 ,  74:1.62 ,  75:1.51 , \
             76:1.44 ,  77:1.41 ,  78:1.36 ,  79:1.36 ,  80:1.32 , \
             81:1.45 ,  82:1.46 ,  83:1.48 ,  84:1.40 ,  85:1.50 , \
             86:1.50 ,  87:2.60 ,  88:2.21 ,  89:2.15 ,  90:2.06 , \
             91:2.00 ,  92:1.96 ,  93:1.90 ,  94:1.87 ,  95:1.80 , \
             96:1.69 }

# dict for isotopic elements
dpt_im = {'C13 ': 13.00335500 , 'C14 ': 14.00324200 , 'Cl37': 36.96590300 , \
          'D   ':  2.01410178 , 'T   ':  3.01604928 , 'N15 ': 15.00010900 , \
          'O17 ': 16.99913200 , 'O18 ': 17.99916000 }

# symbol --> Z
dpt_s2z  = dict( (s.strip(), z        ) for z,s in dpt_z2s.items())

# symbol --> mass
dpt_s2m  = dict( (dpt_z2s[z].strip(),m) for z,m in dpt_z2m.items() )

# symbol --> covalent radius
dpt_s2cr = dict( (dpt_z2s[z].strip(),r) for z,r in dpt_z2cr.items() )

# add also lower case
symbols = list(dpt_s2z.keys())
for key in symbols:
    if key in dpt_s2z.keys() : dpt_s2z[key.lower()]  = dpt_s2z[key]
    if key in dpt_s2m.keys() : dpt_s2m[key.lower()]  = dpt_s2m[key]
    if key in dpt_s2cr.keys(): dpt_s2cr[key.lower()] = dpt_s2cr[key]

#=====================================#
# Dict of points for 5,6-member rings #
#=====================================#

# 5RING
dicCONF5 = {}

# 6RING; each point = (theta,phi); theta in [0,pi], phi in [0,2pi]
dicCONF6_v2 = {'C1' :(  0.0,  0.0), \
               'C2' :(180.0,  0.0), \

               'B1 ':( 90.0,  0.0), \
               'TB1':( 90.0, 90.0), \
               'B2 ':( 90.0,180.0), \
               'TB2':( 90.0,270.0), \

               'HB1':( 45.0,  0.0), \
               'HC1':( 45.0, 90.0), \
               'HB2':( 45.0,180.0), \
               'HC2':( 45.0,270.0), \

               'HB3':(135.0,  0.0), \
               'HC3':(135.0, 90.0), \
               'HB4':(135.0,180.0), \
               'HC4':(135.0,270.0), \
                }


# 6RING; each point = (theta,phi); theta in [0,pi], phi in [0,2pi]
dicCONF6 = {'B25':( 90.0, 60.0) , 'B36':( 90.0,300.0) , 'B41':( 90.0,180.0) , \
            'E1 ':(125.3,180.0) , 'E2 ':( 54.7, 60.0) , 'E3 ':(125.3,300.0) , \
            'E4 ':( 54.7,180.0) , 'E5 ':(125.3, 60.0) , 'E6 ':( 54.7,300.0) , \
            '1C4':(  0.0,  0.0) , '1E ':( 54.7,  0.0) , '1H2':( 50.8, 30.0) , \
            '1H6':( 50.8,330.0) , '1S2':( 67.5, 30.0) , '1S6':( 67.5,330.0) , \
            '1T3':( 90.0,330.0) , '2E ':(125.3,240.0) , '2H1':(129.2,210.0) , \
            '2H3':(129.2,270.0) , '2S1':(112.5,210.0) , '2S3':(112.5,270.0) , \
            '2T4':( 90.0,210.0) , '2T6':( 90.0,270.0) , '3E ':( 54.7,120.0) , \
            '3H2':( 50.8, 90.0) , '3H4':( 50.8,150.0) , '3S2':( 67.5, 90.0) , \
            '3S4':( 67.5,150.0) , '3T1':( 90.0,150.0) , '4C1':(180.0,  0.0) , \
            '4E ':(125.3,  0.0) , '4H3':(129.2,330.0) , '4H5':(129.2, 30.0) , \
            '4S3':(112.5,330.0) , '4S5':(112.5, 30.0) , '4T2':( 90.0, 30.0) , \
            '5E ':( 54.7,240.0) , '5H4':( 50.8,210.0) , '5H6':( 50.8,270.0) , \
            '5S4':( 67.5,210.0) , '5S6':( 67.5,270.0) , '6E ':(125.3,120.0) , \
            '6H1':(129.2,150.0) , '6H5':(129.2, 90.0) , '6S1':(112.5,150.0) , \
            '6S5':(112.5, 90.0) , '6T2':( 90.0, 90.0) , '14B':( 90.0,  0.0) , \
            '25B':( 90.0,240.0) , '36B':( 90.0,120.0) }

#=============================#
# Preparation of dictionaries #
#=============================#
dpt_im   = {key.strip():value for key,value in dpt_im.items()}
dicCONF6 = {key.strip():value for key,value in dicCONF6.items() }
dicCONF6_v2 = {key.strip():value for key,value in dicCONF6_v2.items() }

#=======================================#
# Unit conversion (to au, radians, etc) #
#=======================================#
dpt_z2m  = {k:v/AMU           for k,v       in dpt_z2m.items() }
dpt_s2m  = {k:v/AMU           for k,v       in dpt_s2m.items() }
dpt_im   = {k:v/AMU           for k,v       in dpt_im.items()  }
dpt_z2cr = {k:v/ANGSTROM      for k,v       in dpt_z2cr.items()}
dpt_s2cr = {k:v/ANGSTROM      for k,v       in dpt_s2cr.items()}
dicCONF6 = {k:(np.deg2rad(v1),np.deg2rad(v2)) for k,(v1,v2) in dicCONF6.items()   }


#===============================================#
def exp128(arg):
    if arg < -700 or arg > 700: return np.exp(np.float128(arg))
    return np.exp(arg)
#---------------------------------------------#
def eformat(value,ndec):
    try:
      # value inside normal limits
      if 1E-300 < abs(value) < 1E+300 or value == 0.0:
         string = "%%.%iE"%ndec%value
      # value outside of normal limits
      else:
         string = str(value).replace("e","E")
         coef, exponent = string.split("E")
         coef = ("%%.%if"%ndec)%float(coef)
         string = "%sE%s"%(coef,exponent)
      return string
    except: return str(value)
#===============================================#

#===============================================#
# Some useful things to make better software    #
#===============================================#
def classify_args(user_args):
    '''
    classify the arguments
    '''
    dargs = {None:[]}
    # in case -h is used instead of --help
    user_args = [arg if arg != "-h" else "--help" for arg in user_args]
    # the first arguments until one with --
    for ii,arg in enumerate(user_args):
        if "--" in arg: break
        dargs[None].append(arg)
    # the rest of arguments
    for jj,arg in enumerate(user_args):
        if jj < ii: continue
        if arg.startswith("--"):
           current = arg[2:]
           dargs[current] = []
           continue
        try   : dargs[current].append(arg)
        except: pass
    return dargs
#-----------------------------------------------#
def do_parallel(parallel=False):
    yes = [True,"yes","Yes","YES","y","Y"]
    if parallel in yes:
       try   : import multiprocessing
       except: return False
       return True
    else: return False
#-----------------------------------------------#
def set_parallel(parallel):
    '''
    use it with these two line:
        >> global PARALLEL, delayed, multiprocessing, Parallel
        >> PARALLEL, delayed, multiprocessing, Parallel = fncs.set_parallel(parallel)
    '''
    global PARALLEL
    global delayed
    global multiprocessing
    global Parallel
    PARALLEL        = False
    delayed         = None
    multiprocessing = None
    Parallel        = None
    # Parallization required
    if parallel in [True,"yes","Yes","YES","y","Y"]:
        try:
            from   joblib import delayed, Parallel
            import multiprocessing
            PARALLEL = True
        except: PARALLEL = False
    # return
    return PARALLEL, delayed, multiprocessing, Parallel
#===============================================#


#=============================================#
# Functions related to (lists of) strings     #
#=============================================#
def add_iblank(string,nib):
    return "".join([" "*nib+line+"\n" for line in string.split("\n")])
#---------------------------------------------#
def fill_string(string,length):
    if len(string) >= length: return string
    while len(string) < length: string = " "+string+" "
    if len(string) > length: string = string[:-1]
    return string
#---------------------------------------------#
def clean_line(line,cs="#",strip=False):
    ''' cs : comment symbol '''
    line = line.split(cs)[0]
    if strip: line = line.strip()
    if not line.endswith("\n"): line += "\n"
    return line
#---------------------------------------------#
def clean_lines(lines,cs="#",strip=False):
    '''
    from a list of lines, it removes the comment part
    - cs stands for comment symbol
    '''
    return [clean_line(line,cs,strip) for line in lines]
#---------------------------------------------#
def extract_lines(lines,key1,key2,fmatch=False,cleanline=True,ignorecase=False):
    '''
    Returns the lines between the one starting with key1 and the one starting with key2
    if fmatch is True, returns the first match
    '''
    if ignorecase:
       key1 = key1.lower()
       key2 = key2.lower()
    record   = False
    selected = []
    for line in lines:
        if cleanline : line = clean_line(line,cs="#",strip=True)
        if ignorecase: line = line.lower()
        if line.startswith(key2):
           record = False
           if fmatch: break
        if record: selected.append(line)
        if line.startswith(key1):
           record   = True
           selected = []
    return selected
#---------------------------------------------#
def extract_string(lines,key1,key2,accumulate=False):
    '''
    Returns a string with lines between key1 and key2 (both included)
    '''
    strings  = []
    # Initialize variables
    record,selected  = False, []
    # Loop along lines
    for line in lines:
        # start-key found!
        if key1 in line: record = True
        # save line?
        if record: selected.append(line)
        # end-key found!
        if key2 in line and record:
           # Save data
           strings.append( "".join(selected) )
           # initialize
           record, selected = False, []
    # return data
    if accumulate: return strings
    else         : return strings[-1]
#---------------------------------------------#
def is_string_valid(string,allowed=alphUC+alphLC+numbers,extra=""):
    allowed = allowed+extra
    for character in string:
        if character not in allowed: return False
    return True
#=============================================#

#=============================================#
# Dealing with float numbers                  #
#=============================================#
def is_smaller(num1,num2,eps):
    ''' check if num1 < num2 (for floats) '''
    return num1-num2 < -abs(eps)
#---------------------------------------------#
def is_greater(num1,num2,eps):
    ''' check if num1 > num2 (for floats) '''
    return num1-num2 > +abs(eps)
#---------------------------------------------#
def is_smallereq(num1,num2,eps):
    ''' check if num1 < num2 (for floats) '''
    return num1-num2 < +abs(eps)
#---------------------------------------------#
def is_greatereq(num1,num2,eps):
    ''' check if num1 >= num2 (for floats) '''
    return num1-num2 > -abs(eps)
#=============================================#


#===============================================#
# Some basic MATHematics                        #
#===============================================#
def sign(number):
    if number >= 0.0: return +1
    else:             return -1
#-----------------------------------------------#
def delta_ij(i,j):
   if i==j: return 1.0
   else:    return 0.0
#-----------------------------------------------#
def float_in_domain(value,domain):
    value = float(value)
    for ival,fval in domain:
        if ival <= value <= fval: return True
    return False
#-----------------------------------------------#
def distance(x1,x2):
    ''' returns distance between two points'''
    diff = [x1_i-x2_i for x1_i,x2_i in zip(x1,x2)]
    return norm(diff)
#-----------------------------------------------#
def angle_vecs(u,v):
    ''' returns angle between two vectors'''
    cos = np.dot(u,v) / norm(u) / norm(v)
    if abs(cos-1.0) <= EPS_SCX: cos = +1.0
    if abs(cos+1.0) <= EPS_SCX: cos = -1.0
    return np.arccos(cos)
#-----------------------------------------------#
def angle(x1,x2,x3):
    '''returns angle between three points (1-2-3)'''
    u = np.array(x1)-np.array(x2)
    v = np.array(x3)-np.array(x2)
    return angle_vecs(u,v)
#-----------------------------------------------#
def dihedral(x1,x2,x3,x4):
    '''returns dihedral angle between 4 points (1-2-3-4)'''
    vec_23 = np.array(x3) - np.array(x2)
    vec_23 = normalize_vec(vec_23)
    # Compute plane vectors
    n1 = get_normal(x1,x2,x3)
    n2 = get_normal(x2,x3,x4)
    # Vector perpendicular to (n1,vec23)
    m1 = np.cross(n1,vec_23)
    # Coordinates of n2 in this frame (n1,vec23,m1)
    x = np.dot(n1,n2)
    y = np.dot(m1,n2)
    # Angle
    return -np.arctan2(y,x)
#-----------------------------------------------#
def dihedral_of_torsion(xcc,torsion_atoms):
    at1,at2,at3,at4 = torsion_atoms
    x1 = xcc[3*at1:3*at1+3]
    x2 = xcc[3*at2:3*at2+3]
    x3 = xcc[3*at3:3*at3+3]
    x4 = xcc[3*at4:3*at4+3]
    return dihedral(x1,x2,x3,x4)
#-----------------------------------------------#
def get_zmatvals_from_xcc(xcc,zmatatoms):
    zmatvals = {}
    for key,atoms in zmatatoms.items():
        # ask for a distance
        if len(atoms) == 2:
            x1 = xcc[3*atoms[0] : 3*atoms[0]+3]
            x2 = xcc[3*atoms[1] : 3*atoms[1]+3]
            value = distance(x1,x2) * ANGSTROM
        # ask for an angle
        elif len(atoms) == 3:
            x1 = xcc[3*atoms[0] : 3*atoms[0]+3]
            x2 = xcc[3*atoms[1] : 3*atoms[1]+3]
            x3 = xcc[3*atoms[2] : 3*atoms[2]+3]
            value = np.rad2deg(angle(x1,x2,x3))
        # ask for a dihedral angle
        elif len(atoms) == 4:
            x1 = xcc[3*atoms[0] : 3*atoms[0]+3]
            x2 = xcc[3*atoms[1] : 3*atoms[1]+3]
            x3 = xcc[3*atoms[2] : 3*atoms[2]+3]
            x4 = xcc[3*atoms[3] : 3*atoms[3]+3]
            value = np.rad2deg(dihedral(x1,x2,x3,x4))
        # none of the previous
        else: value = None
        zmatvals[key] = value
    return zmatvals
#-----------------------------------------------#
def norm(vec):
    return np.linalg.norm(vec)
#-----------------------------------------------#
def normalize_vec(vec):
    return np.array(vec)/norm(vec)
#-----------------------------------------------#
def get_normal(p1,p2,p3):
    '''returns the normal vector to the plane defined by three points'''
    v12 = np.array(p2)-np.array(p1)
    v23 = np.array(p3)-np.array(p2)
    v12 = normalize_vec(v12)
    v23 = normalize_vec(v23)
    normal = np.cross(v12,v23)
    return normalize_vec(normal)
#-----------------------------------------------#
def angle_in_interval(ang,case="0,360"):
    ''' cases = '-180,180', '0,360', '-pi,pi', '0,2pi' '''
    if "pi" in case: ang = ang%TWOPI
    else           : ang = ang%360.0
    if case == "-pi,pi"   and ang > PI  : ang = ang-TWOPI
    if case == "-180,180" and ang > 180.: ang = ang-360.0
    return ang
#-----------------------------------------------#
def angular_dist(ang1,ang2,u="rad",limit=None):
    '''
    if 'limit' is defined, 'u' lacks of sense
    '''
    if limit is None:
       if   u == "rad": limit = TWOPI
       elif u == "deg": limit = 360.0
       else           : return None
    # Get distances
    diff1 = (ang1-ang2)%limit
    diff2 = (ang2-ang1)%limit
    # Return distance
    return min(diff1,diff2)
#-----------------------------------------------#
def angular_dist_with_sign(angle1,angle2):
    '''
    angle1, angle2 in [0,2pi]
    '''
    d1 = angle2-2.0*np.pi-angle1
    d2 = angle2          -angle1
    d3 = angle2+2.0*np.pi-angle1
    if abs(d1) <= abs(d2) and abs(d1) <= abs(d3): return d1
    if abs(d2) <= abs(d1) and abs(d2) <= abs(d3): return d2
    if abs(d3) <= abs(d1) and abs(d3) <= abs(d2): return d3
#-----------------------------------------------#
def sincos2angle(sin,cos):
    # Get angle in first quadrant
    if   cos == 0.0: angle = np.pi/2.0
    elif sin == 0.0: angle = 0.0
    else           : angle = np.arctan( abs(sin/cos) )
    # quadrant 1 and 2
    if sin >= 0.0:
       if cos >= 0.0: angle = angle
       else         : angle = np.pi - angle
    # quadrant 3 and 4
    else:
       if cos >= 0.0: angle = 2*np.pi - angle
       else         : angle = angle + np.pi
    return angle
#-----------------------------------------------#
def angdist_sphere(p1,p2,units="rad"):
  '''
  Angular distance between points p1 and p2 on a sphere
  Each point is a tuple (theta,phi) with
     theta = th in [0, pi]
     phi   = ph in [0,2pi]
  Information:
      * spherical coordinate system (theta,phi definition)
  if units = "rad": input and output angles in radians
  if units = "deg": input and output angles in degrees
  '''
  # Points in sphere
  th1, ph1 = p1
  th2, ph2 = p2
  if units == "deg":
     th1 = np.deg2rad(th1)
     th2 = np.deg2rad(th2)
     ph1 = np.deg2rad(ph1)
     ph2 = np.deg2rad(ph2)
  sth1, cth1 = np.sin(th1), np.cos(th1)
  sth2, cth2 = np.sin(th2), np.cos(th2)
  sph1, cph1 = np.sin(ph1), np.cos(ph1)
  sph2, cph2 = np.sin(ph2), np.cos(ph2)
  v1 = [sth1*cph1,sth1*sph1,cth1]
  v2 = [sth2*cph2,sth2*sph2,cth2]
  angle = angle_vecs( v1,v2 )
  if units == "deg": angle = np.rad2deg(angle)
  return angle
#-----------------------------------------------#
def getPerim_circle(radius):
    return TWOPI*radius
#-----------------------------------------------#
def getArea_triangle(pA,pB,pC):
    '''
    area of triangle by shoelace algorithm
    pA represents the vertex coordinates (xA,yA)
    pB represents the vertex coordinates (xB,yB)
    pC represents the vertex coordinates (xC,yC)
    '''
    Area = + (pB[0]*pC[1] - pC[0]*pB[1]) \
           - (pA[0]*pC[1] - pC[0]*pA[1]) \
           + (pA[0]*pB[1] - pB[0]*pA[1])
    Area = 0.5 * abs(Area)
    return Area
#-----------------------------------------------#
def getArea_circle(radius) :
    return PI*radius**2
#-----------------------------------------------#
def getArea_sphere(radius) :
    return 4.*PI*radius**2
#-----------------------------------------------#
def getVol_sphere(radius)  :
    return 4./3.*PI*radius**3
#===============================================#


#===============================================#
# Symmetry operations                           #
#===============================================#
def getmatrix_inversion():
    return np.diag([-1.,-1.,-1.])
#-----------------------------------------------#
def getmatrix_Cn(n,u):
    ''' n: order; u: vector'''
    t    = TWOPI/n
    cosu = np.cos(t)
    sinu = np.sin(t)
    ux,uy,uz = u
    Cngen = np.zeros( (3,3) )
    Cngen[0,0] = cosu + (ux**2)*(1.-cosu)
    Cngen[1,1] = cosu + (uy**2)*(1.-cosu)
    Cngen[2,2] = cosu + (uz**2)*(1.-cosu)
    Cngen[0,1] = ux*uy*(1.-cosu)-uz*sinu
    Cngen[0,2] = ux*uz*(1.-cosu)+uy*sinu
    Cngen[1,2] = uy*uz*(1.-cosu)-ux*sinu
    Cngen[1,0] = ux*uy*(1.-cosu)+uz*sinu
    Cngen[2,0] = ux*uz*(1.-cosu)-uy*sinu
    Cngen[2,1] = uy*uz*(1.-cosu)+ux*sinu
    return Cngen
#===============================================#


#===============================================#
# Integrating functions                         #
#===============================================#
def intg_trap(function,x0,xf,args=None,n=100,dx=None):
    '''
    function: the function to integrate
    args    : arguments of the function; function(x,args)
    '''
    if dx is None:
       dx = 1.0 * (xf-x0)/(n-1)
    else:
       n = int(round((xf-x0)/dx))+1
    xvalues = [x0+ii*dx for ii in range(n)]
    if args is not None: integrand = [function(x,*args) for x in xvalues]
    else               : integrand = [function(x)       for x in xvalues]
    integral  = sum([y*dx for y in integrand])
    return integral
#-----------------------------------------------#
def intg_gau(function,x0,xf,args=None,n=80):
    points, weights = np.polynomial.legendre.leggauss(n)
    suma     = (xf+x0)/2.0
    resta    = (xf-x0)/2.0
    # Points to evaluate and weights
    points   = [resta*xi+suma for xi in points]
    weights  = [wi*resta for wi in weights]
    # calculate integral
    if args is not None: integral = sum([w*function(x,*args) for x,w in zip(points,weights)])
    else               : integral = sum([w*function(x)       for x,w in zip(points,weights)])
    del points
    del weights
    return integral
#===============================================#





#===============================================#
# Diverse set of useful functions               #
#===============================================#
def frange(start,end,dx,include_end=True):
    '''
    returns a list of floats
    '''
    start = float(start)
    end   = float(end  )
    dx    = float(dx   )
    nsteps = int( round( (end-start)/dx ) )
    if include_end: nsteps = nsteps + 1
    return [ start+i*dx for i in range(nsteps)]
#-----------------------------------------------#
def prod_list(lists):
    '''
    lists is a tuple with lists of floats
    '''
    prod = [1.0 for ii in lists[0]]
    for list_i in lists:
        prod = [v1*v2 for v1,v2 in zip(prod,list_i)]
    return prod
#-----------------------------------------------#
def same_lfloats(list1,list2,eps=EPS_FLOAT):
    if len(list1) != len(list2): return False
    for f1,f2 in zip(list1,list2):
        diff = abs(f1-f2)
        if diff > eps: return False
    return True
#-----------------------------------------------#
def flatten_llist(list_of_lists):
    ''' converts list of lists to list'''
    flattened_list = [y for x in list_of_lists for y in x]
    return flattened_list
#-----------------------------------------------#
def uniquify_flist(list_of_floats,eps=EPS_FLOAT):
    ''' removes duplicates in a list of float numbers'''
    if len(list_of_floats) < 2: return list_of_floats
    # Copy list and sort it
    list2 = list(list_of_floats)
    list2.sort()
    # Get position of duplicates
    repeated = []
    if len(list2) > 1:
       for idx in range(1,len(list2)):
           previous_float = list2[idx-1]
           current_float  = list2[idx]
           if abs(current_float - previous_float) < eps: repeated.append(idx)
    # Change values of positions to Nones
    for idx in repeated: list2[idx] = None
    # Remove Nones from list
    removals = list2.count(None)
    for removal in range(removals): list2.remove(None)
    return list2
#-----------------------------------------------#
def ll2matrix(ll,varcomp=None,pos=0):
    '''
    Converts a list of lists (of different sizes)
    to a list of list with equal sizes.
    Begin N the maximum length:
          N = max([len(alist) for alist in ll])
    all the lists in ll are modified to present
    the same size. To do so, the variable 'varcomp'
    is added to each list until len(alist) = N.
    The variable is added at the beggining (pos=0)
    or at the end (pos=-1) of the list
    '''
    if pos not in [0,-1]: raise Exception("Wrong 'pos' variable given in ll2matrix")
    # empty list?
    if len(ll) == 0: return None
    # maximum size
    N = max([len(alist) for alist in ll])
    if N == 0: return None
    # Initialize matrix
    shape = (len(ll),N)
    matrix = [ [0.0 for col in range(shape[1])] for row in range(shape[0])]
    # Now, complete
    for row in range(shape[0]):
        arow = ll[row]
        while len(arow) < N:
              if pos ==  0: arow = [varcomp]+arow
              if pos == -1: arow = arow+[varcomp]
        for col in range(shape[1]):
            matrix[row][col] = arow[col]
    # return list of list
    return matrix
#-----------------------------------------------#
def remove_float(thefloat,thelist,eps=EPS_FLOAT):
    return [ii for ii in thelist if abs(ii-thefloat)>eps]
#-----------------------------------------------#
def uppt2matrix(upptriangle):
    if upptriangle is None: return None
    l = len(upptriangle)
    N = int( (-1 + (1+8*l)**0.5) / 2)
    index = 0
    matrix = [ [0.0 for ii in range(N)] for jj in range(N) ]
    for i in range(1,N+1):
        for j in range(i,N+1):
            matrix[i-1][j-1] = upptriangle[index]
            matrix[j-1][i-1] = upptriangle[index]
            index += 1
    return matrix
#-----------------------------------------------#
def lowt2matrix(lowtriangle):
    if lowtriangle is None: return None
    l = len(lowtriangle)
    N = int( (-1 + (1+8*l)**0.5) / 2)
    index = 0
    matrix = [ [0.0 for ii in range(N)] for jj in range(N) ]
    for i in range(1,N+1):
        for j in range(1,i+1):
            matrix[i-1][j-1] = lowtriangle[index]
            matrix[j-1][i-1] = lowtriangle[index]
            index += 1
    return matrix
#-----------------------------------------------#
def matrix2lowt(matrix):
    if matrix is None: return None
    nrows = len(matrix)
    ncols = len(matrix[0])
    low   = []
    for row in range(nrows):
        for col in range(0,row+1):
            Fij = matrix[row][col]
            low.append(Fij)
    return low
#-----------------------------------------------#
def time2human(t, units):
    ''' units : ["secs","mins","hours"]'''
    while True:
        if t < 1 and units == "secs":
           t = t * 1000
           units = "msecs"
        elif t > 60 and units == "secs":
           t = t / 60.0
           units = "mins"
        elif t > 60 and units == "mins":
           t = t / 60.0
           units = "hours"
        elif t > 24 and units == "hours":
           t = t / 24.0
           units = "days"
        else: break
    return (t, units)
#===============================================#




#===============================================#
# Functions related to molecules                #
#===============================================#
def vol2pressure(V,T): return KB*T/V
#---------------------------------------------#
def pressure2vol(P,T): return KB*T/P
#---------------------------------------------#
def symbol_and_atonum(symbol_or_atonum):
    try:
        atonum = int(symbol_or_atonum)
        symbol = dpt_z2s[atonum].strip()
    except:
        symbol = correct_symbol(symbol_or_atonum)
        atonum = dpt_s2z[symbol]
    return symbol,atonum
#---------------------------------------------#
def symbols_and_atonums(symbols_or_atonums):
    symbols = []
    atonums = []
    for atsym in symbols_or_atonums:
        symbol, atonum = symbol_and_atonum(atsym)
        symbols.append(symbol)
        atonums.append(atonum)
    return symbols, atonums
#---------------------------------------------#
def correct_symbol(symbol):
    if symbol.upper() in "XX,X,DA": return "XX"
    return symbol[0].upper()+symbol[1:].lower()
#---------------------------------------------#
def clean_dummies(symbols,xcc=None,masses=None,gcc=None,Fcc=None):
    # initialize lists
    symbols_wo = []
    masses_wo  = []
    xcc_wo     = []
    gcc_wo     = []
    # first: clean only symbols
    indices_dummies = []
    for idx,symbol in enumerate(symbols):
        if str(symbol) == "0" or str(symbol).upper() == "XX":
           indices_dummies.append(idx)
           continue
        symbols_wo.append(symbol)
    # clean the rest of lists, if needed
    num0 =   len(symbols_wo)
    num1 = 3*len(symbols_wo)
    num2 = 3*len(symbols_wo)*(3*len(symbols_wo)+1)//2
    if masses is not None and len(masses) == num0: return symbols_wo,masses
    if xcc    is not None and len(xcc)    == num1: return symbols_wo,xcc
    if gcc    is not None and len(gcc)    == num1: return symbols_wo,gcc
    if Fcc    is not None and len(Fcc)    == num2: return symbols_wo,Fcc

    for idx,symbol in enumerate(symbols):
        if idx in indices_dummies: continue
        if   xcc    is not None: xcc_wo += xcc[3*idx:3*idx+3]
        elif gcc    is not None: gcc_wo += gcc[3*idx:3*idx+3]
        elif masses is not None: masses_wo.append(masses[idx])
    if   xcc    is not None: return symbols_wo,xcc_wo
    elif gcc    is not None: return symbols_wo,gcc_wo
    elif masses is not None: return symbols_wo,masses_wo
    # cleaning Fcc
    if Fcc is not None:
        # (a) in matrix format
        Fcc_matrix = lowt2matrix(Fcc)
        # (b) clean Fcc
        Fcc_wo = []
        for row,symbol1 in enumerate(symbols):
            the_row = []
            dummy1 = str(symbol1) == "0" or str(symbol1).upper() == "XX"
            if dummy1: continue
            for col,symbol2 in enumerate(symbols):
                dummy2 = str(symbol2) == "0" or str(symbol2).upper() == "XX"
                if dummy2: continue
                the_row.append( Fcc_matrix[row][col] )
            Fcc_wo.append(the_row)
        # (c) return to triangular list
        Fcc_wo = matrix2lowt(Fcc_wo)
        return symbols_wo,Fcc_wo
    # if nothing more, it just returns symbols_wo
    return symbols_wo
#---------------------------------------------#
def correct_symbols(symbols):
   '''
   for each symbol, first character in upper, the rest in lower
   '''
   return [correct_symbol(symbol) for symbol in symbols]
#---------------------------------------------#
def get_molformula(symbols):
    '''
    Returns the molecular formula of a given molecule
    '''
    formula_dict = {symbol:symbols.count(symbol) for symbol in symbols}
    molform = ""
    for key,value in sorted(formula_dict.items()):
        if value != 1: molform += "%s(%i)"%(key,value)
        if value == 1: molform += "%s"%(key)
    return molform
#---------------------------------------------#
def molformula2mass(mformu):
    digits  = "0123456789"
    symbols = ""
    nc      = len(mformu)
    for idx,character in enumerate(mformu):
        if character == ")":
           number   = int(number)
           current  = symbols.split()[-1]
           symbols += " ".join([current for ii in range(number-1)])
           symbols += " "
           continue
        if   character in digits:
           number += character
           continue
        if character in "(":
           number = ""
           continue
        symbols += character
        if idx+1 < nc:
           next_upper = (mformu[idx+1].upper() == mformu[idx+1])
           if next_upper: symbols += " "
    symbols = symbols.split()
    masses  = symbols2masses(symbols)
    totmass = sum(masses)
    return totmass, symbols
#---------------------------------------------#
def symbols2atonums(symbols):
    return [dpt_s2z[s] for s in symbols]
#---------------------------------------------#
def atonums2symbols(atonums):
    return [dpt_z2s[z].strip() for z in atonums]
#---------------------------------------------#
def get_symbols(atonums):
    return atonums2symbols(atonums)
#---------------------------------------------#
def atonums2masses(atonums):
    return [dpt_z2m[z] for z in atonums]
#---------------------------------------------#
def symbols2masses(symbols):
    return [dpt_s2m[s] for s in symbols]
#---------------------------------------------#
def get_atonums(symbols):
    return [dpt_s2z[s] for s in symbols]
#---------------------------------------------#
def howmanyatoms(xcc): return len(xcc)//3
#---------------------------------------------#
def xyz(xcc,at): return xcc[3*at:3*at+3]
#---------------------------------------------#
def x(xcc,at)  : return xcc[3*at+0]
#---------------------------------------------#
def y(xcc,at)  : return xcc[3*at+1]
#---------------------------------------------#
def z(xcc,at)  : return xcc[3*at+2]
#---------------------------------------------#
def get_centroid(xcc,indices=None):
    if indices is None: indices = range(len(xcc)//3)
    centroid_x = sum([x(xcc,idx) for idx in indices])/len(indices)
    centroid_y = sum([y(xcc,idx) for idx in indices])/len(indices)
    centroid_z = sum([z(xcc,idx) for idx in indices])/len(indices)
    return [centroid_x,centroid_y,centroid_z]
#---------------------------------------------#
def get_com(xcc,masses,indices=None):
    '''
    Returns the centre of mass of the selected atoms (indices)
    If no indices given, all atoms are considered
    '''
    if indices is None: indices = range(len(masses))
    tmass = sum([           masses[idx] for idx in indices])
    com_x = sum([x(xcc,idx)*masses[idx] for idx in indices])/tmass
    com_y = sum([y(xcc,idx)*masses[idx] for idx in indices])/tmass
    com_z = sum([z(xcc,idx)*masses[idx] for idx in indices])/tmass
    return [com_x,com_y,com_z]
#---------------------------------------------#
def get_distmatrix(xcc):
    nat = howmanyatoms(xcc)
    dmatrix = np.zeros( (nat,nat) )
    for ii in range(nat):
        xii = xyz(xcc,ii)
        for jj in range(ii+1,nat):
            xjj = xyz(xcc,jj)
            dmatrix[ii][jj] = distance(xii,xjj)
            dmatrix[jj][ii] = dmatrix[ii][jj]
    return dmatrix
#---------------------------------------------#
def set_origin(xcc,x0):
    '''
    returns xcc with x0 as origin
    '''
    nat = howmanyatoms(xcc)
    return [xi-xj for xi,xj in zip(xcc,nat*x0)]
#---------------------------------------------#
def shift2com(xcc,masses):
    '''
    Function to shift to center of mass
    '''
    com = get_com(xcc,masses)
    xcc = set_origin(xcc,com)
    return xcc
#---------------------------------------------#
def islinear(xcc):
    nats    = howmanyatoms(xcc)
    masses  = [1.0 for at in range(nats)]
    itensor = get_itensor_matrix(xcc,masses)
    linear  = get_itensor_evals(itensor)[3]
    return linear
#---------------------------------------------#
def same_geom(x1,x2,eps=EPS_GEOM):
    diff = [xi-xj for xi,xj in zip(x1,x2)]
    #value = norm(diff) / len(diff)
    value = max(diff)
    if value < eps: return True
    else          : return False
#---------------------------------------------#
def center_and_orient(xcc,gcc,Fcc,masses):
    # number of atoms?
    nats = howmanyatoms(xcc)
    # in center of mass
    xcc = shift2com(xcc,masses)
    if nats == 1: return xcc, gcc, Fcc
    # Is it linear?
    itensor = get_itensor_matrix(xcc,masses)
    evalsI, rotTs, rtype, linear = get_itensor_evals(itensor)
    if not linear: return xcc, gcc, Fcc
    # Get moments and axis of inertia
    itensor = np.matrix(itensor)
    evalsI, evecsI = np.linalg.eigh(itensor)
    evecsI = np.matrix(evecsI)
    # Rotation matrix 3N x 3N
    zeros = np.zeros((3, 3))
    R= []
    for at in range(nats):
        row = []
        count = 0
        while count < at:
              row.append(zeros)
              count += 1
        row.append(evecsI)
        while count < nats-1:
              row.append(zeros)
              count += 1
        R.append(row)
    R = np.matrix(np.block(R))
    # Rotate coordinates
    xcc = np.matrix(xcc) * R
    xcc = xcc.tolist()[0]
    # Rotate gradient
    if gcc is not None and len(gcc) != 0:
       gcc = np.matrix(gcc) * R
       gcc = gcc.tolist()[0]
    # rotate Fcc
    if Fcc is not None and len(Fcc) != 0:
       nr,nc = np.matrix(Fcc).shape
       if nr != nc: Fcc = lowt2matrix(Fcc)
       Fcc = R.transpose() * np.matrix(Fcc) * R
       Fcc = Fcc.tolist()
    return xcc, gcc, Fcc
#---------------------------------------------#
def cc2ms_x(xcc,masses,mu=1.0/AMU):
    ''' cartesian --> mass-scaled; x'''
    if xcc is None or len(xcc) == 0: return xcc
    nat  = len(masses)
    cfs  = [ (masses[idx]/mu)**0.5 for idx in range(nat)]
    xms  = [ [x(xcc,at)*cfs[at],y(xcc,at)*cfs[at],z(xcc,at)*cfs[at]] for at in range(nat)]
    xms  = flatten_llist(xms)
    return xms
#---------------------------------------------#
def cc2ms_g(gcc,masses,mu=1.0/AMU):
    ''' cartesian --> mass-scaled; gradient'''
    if gcc is None or len(gcc) == 0: return gcc
    nat  = len(masses)
    cfs  = [ (masses[idx]/mu)**0.5 for idx in range(nat)]
    gms  = [ [x(gcc,at)/cfs[at],y(gcc,at)/cfs[at],z(gcc,at)/cfs[at]] for at in range(nat)]
    gms  = flatten_llist(gms)
    return gms
#---------------------------------------------#
def cc2ms_F(Fcc,masses,mu=1.0/AMU):
    ''' cartesian --> mass-scaled; force constant matrix'''
    if Fcc is None or len(Fcc) == 0: return Fcc
    nat    = len(masses)
    Fms    = [ [ 0.0 for at1 in range(3*nat) ] for at2 in range(3*nat)]
    for i in range(3*nat):
        mi = masses[int(i/3)]
        for j in range(3*nat):
            mj = masses[int(j/3)]
            f = mu / ((mi*mj)**0.5)
            Fms[i][j] = Fcc[i][j] * f
    return Fms
#---------------------------------------------#
def ms2cc_x(xms,masses,mu=1.0/AMU):
    ''' mass-scaled --> cartesian; x'''
    if xms is None or len(xms) == 0: return xms
    nat  = len(masses)
    cfs  = [ (masses[idx]/mu)**0.5 for idx in range(nat)]
    xcc  = [ [x(xms,at)/cfs[at],y(xms,at)/cfs[at],z(xms,at)/cfs[at]] for at in range(nat)]
    xcc  = flatten_llist(xcc)
    return xcc
#---------------------------------------------#
def ms2cc_g(gms,masses,mu=1.0/AMU):
    ''' mass-scaled --> cartesian; gradient'''
    if gms is None or len(gms) == 0: return gms
    nat  = len(masses)
    cfs  = [ (masses[idx]/mu)**0.5 for idx in range(nat)]
    gcc  = [ [x(gms,at)*cfs[at],y(gms,at)*cfs[at],z(gms,at)*cfs[at]] for at in range(nat)]
    gcc  = flatten_llist(gcc)
    return gcc
#---------------------------------------------#
def ms2cc_F(Fms,masses,mu=1.0/AMU):
    ''' mass-scaled --> cartesian; force constant matrix'''
    if Fms is None or len(Fms) == 0: return Fms
    nat    = len(masses)
    Fcc    = [ [ 0.0 for at1 in range(3*nat) ] for at2 in range(3*nat)]
    for i in range(3*nat):
        mi = masses[int(i/3)]
        for j in range(3*nat):
            mj = masses[int(j/3)]
            f = mu / ((mi*mj)**0.5)
            Fcc[i][j] = Fms[i][j] / f
    return Fcc
#===============================================#



#===============================================#
# Functions related to rotations                #
#===============================================#
def gen_rotmatrix(axis,theta):
    '''
    Generates the rotation matrix around axis.
    Input:
      * axis: the (x,y,z) coordinates of the
              direction vector of the axis
      * theta: the rotation angle (radians)
    Returns:
      * rot_matrix: a 3x3 numpy matrix

    Note: The rotation considers that the axis is
    situated at the origin

    Direction of rotation given by right-hand rule
    '''

    # Theta in [0,2*pi]
    while theta < 0.0:
          theta = theta + 2.0*np.pi
    while theta > 2*np.pi:
          theta = theta - 2.0*np.pi
    # Theta in [-pi,pi]
    if theta > np.pi:
       theta = -(2.0*np.pi - theta)

    # Normalize axis length
    ux, uy, uz = normalize_vec(axis)
    st = np.sin(theta)
    ct = np.cos(theta)

    R11 = ux*ux*(1.- ct) +    ct
    R12 = ux*uy*(1.- ct) - uz*st
    R13 = ux*uz*(1.- ct) + uy*st

    R21 = uy*ux*(1.- ct) + uz*st
    R22 = uy*uy*(1.- ct) +    ct
    R23 = uy*uz*(1.- ct) - ux*st

    R31 = uz*ux*(1.- ct) - uy*st
    R32 = uz*uy*(1.- ct) + ux*st
    R33 = uz*uz*(1.- ct) +    ct

    rot_matrix = np.matrix( [ [R11,R12,R13],[R21,R22,R23],[R31,R32,R33] ] )
    return rot_matrix
#-----------------------------------------------#
def rotate_point(xyz,RotMat):
    # Rotate atoms in fragment
    rotated_xyz = []
    xyz = np.matrix(RotMat) * np.matrix(xyz).transpose()
    xyz = np.array((xyz.transpose()).tolist()[0])
    return xyz
#-----------------------------------------------#
def rotate_molecule(xcc,RotMat):
    natoms = len(xcc)//3
    final_xcc = []
    for atom in range(natoms):
        xyz = xcc[3*atom:3*atom+3]
        xyz = list(rotate_point(xyz,RotMat))
        final_xcc += xyz
    return final_xcc
#-----------------------------------------------#
def rotate_internal(xcc,ugraph,tbond,theta):
    if xcc is None: return None
    natoms = int(round(len(xcc)/3))
    # convert to numpy array
    xvector = np.array(xcc,copy=True)
    # Get two fragments
    idxA, idxB = tbond
    A_frag = set(ugraph.bfsearch1d(idxB,idxA))
    B_frag = set(ugraph.bfsearch1d(idxA,idxB))

    # Compare fragments. They may be equal in case of cyclic systems
    if (B_frag is None) or (A_frag is None) or (B_frag == A_frag):
       return None

    # Choose smaller fragment
    if len(A_frag) > len(B_frag):
       # if B_frag, rotation around A-->B
       x0   = xvector[3*idxA:3*idxA+3]
       axis = xvector[3*idxB:3*idxB+3] - x0
       target_fragment = B_frag.copy()
    else:
       # if A_frag, rotation around B-->A
       x0   = xvector[3*idxB:3*idxB+3]
       axis = xvector[3*idxA:3*idxA+3] - x0
       target_fragment = A_frag.copy()
    axis = axis / np.linalg.norm(axis)

    # Remove indices of the bond
    target_fragment.discard(idxA)
    target_fragment.discard(idxB)

    # Get rotation matrix
    R = gen_rotmatrix(axis,theta)

    # Rotate atoms in fragment
    rotated_xyz = []
    for idx in range(natoms):
        xyz    = xvector[3*idx:3*idx+3]
        if idx in target_fragment:
            xyz = xyz - x0
            xyz = R * np.matrix(xyz).transpose()
            xyz = np.array((xyz.transpose()).tolist()[0])
            xyz = xyz + x0
        rotated_xyz += xyz.tolist()
    return rotated_xyz
#===============================================#



#===============================================#
# Functions related to frequencies              #
#===============================================#
def afreq2wnum(angfreq):
    return angfreq / TWOPI / C0
#-----------------------------------------------#
def wnum2afreq(wavenum):
    return wavenum * TWOPI * C0
#-----------------------------------------------#
def eval2afreq(evalue,mu=1.0/AMU):
    return sign(evalue) * (abs(evalue)/mu)**0.5
#-----------------------------------------------#
def eval2wnum(evalue,mu=1.0/AMU):
    return wnum2afreq(eval2afreq(evalue,mu))
#-----------------------------------------------#
def afreq2zpe(angfreq):
    if angfreq < 0.0: return 0.0
    return HBAR * angfreq / 2.0
#-----------------------------------------------#
def afreq2turnpoint(angfreq,mu):
    if angfreq < 0.0: return 1e10
    return np.sqrt( HBAR / angfreq / mu )
#-----------------------------------------------#
def wnum2zpe(wavenum):
    angfreq = wnum2afreq(wavenum)
    if angfreq < 0.0: return 0.0
    return HBAR * angfreq / 2.0
#-----------------------------------------------#
def eval2cm(evalue,mu=1.0/AMU):
    return eval2wnum(evalue,mu)/CM
#-----------------------------------------------#
def afreq2cm(angfreq):
    return afreq2wnum(angfreq)/CM
#-----------------------------------------------#
def cm2afreq(cm):
    return wnum2afreq(cm * CM)
#-----------------------------------------------#
def afreq2eV(angfreq):
    return afreq2wnum(angfreq)/CM
#-----------------------------------------------#
def same_freqs(ccfreqs,icfreqs):
    # compare lengths
    if len(ccfreqs) != len(icfreqs):
        return False
    # compare freqs
    for ccf, icf in zip(ccfreqs,icfreqs):
        ccf = afreq2cm(ccf)
        icf = afreq2cm(icf)
        if abs(ccf-icf) > EPS_CCIC: return False
    return True
#-----------------------------------------------#
def numimag(freqs):
    return [freq<0.0 for freq in freqs].count(True)
#===============================================#




#===============================================#
# Rotations/Vibrations                          #
#===============================================#
def get_itensor_matrix(xcc,masses):
    ''' returns inertia tensor (au)'''
    nat = howmanyatoms(xcc)
    inertia = [[0.0 for i in range(3)] for j in range(3)]
    for i in range(nat):
        # Diagonal elements
        inertia[0][0] += masses[i] * (y(xcc,i)**2 + z(xcc,i)**2)
        inertia[1][1] += masses[i] * (z(xcc,i)**2 + x(xcc,i)**2)
        inertia[2][2] += masses[i] * (x(xcc,i)**2 + y(xcc,i)**2)
        # Offdiagonal elements
        inertia[0][1] -= masses[i] * x(xcc,i) * y(xcc,i)
        inertia[0][2] -= masses[i] * z(xcc,i) * x(xcc,i)
        inertia[1][2] -= masses[i] * y(xcc,i) * z(xcc,i)
    inertia[1][0] = inertia[0][1]
    inertia[2][0] = inertia[0][2]
    inertia[2][1] = inertia[1][2]
    return inertia
#---------------------------------------------#
def get_itensor_evals(itensor):
    evalsI, evecsI = np.linalg.eigh(itensor)

    Ia, Ib, Ic = evalsI

    bool_a  = abs(Ia)        < EPS_INERTIA # Ia = 0
    bool_ab = abs(Ia/Ib-1.0) < EPS_FLOAT   # Ia = Ib
    bool_bc = abs(Ib/Ic-1.0) < EPS_FLOAT   # Ib = Ic
    bool_abc = bool_ab and bool_bc

    if   bool_abc  : rtype = "spherical top"
    elif bool_ab   : rtype = "oblate symmetric top"
    elif bool_bc   :
         if  bool_a: rtype = "linear rotor"
         else      : rtype = "prolate symmetric top"
    else           : rtype = "asymmetric top"

    if rtype == "linear rotor":
       linear = True
       evalsI = [evalsI[1]]
    else:
       linear = False

    # rotational temperature
    rotTs = [HBAR**2 / (2*Ii*KB) for Ii in evalsI]
    return evalsI, rotTs, rtype, linear
#-----------------------------------------------#
def get_projectionmatrix(xcc,masses,v0=None):
    '''
    Generates matrix to project translation
    and rotation coordinates (mass scaled/weighted)
    Other coordinate can be projected by introducing it
    using v0 (in mass-scaled)
    '''
    nat  = len(masses)
    # translation
    sqrtmasses = [np.sqrt(mass) for mass in masses]
    b1 = [term if ii==0 else 0.0 for term in sqrtmasses for ii in range(3)]
    b2 = [term if ii==1 else 0.0 for term in sqrtmasses for ii in range(3)]
    b3 = [term if ii==2 else 0.0 for term in sqrtmasses for ii in range(3)]
    norm1 = np.linalg.norm(b1)
    norm2 = np.linalg.norm(b2)
    norm3 = np.linalg.norm(b3)
    b1 /= norm1
    b2 /= norm2
    b3 /= norm3
    vecs = [b1,b2,b3]
    # rotation
    b4 = np.zeros(len(xcc))
    b5 = np.zeros(len(xcc))
    b6 = np.zeros(len(xcc))
    for i in range(nat):
        b4[3*i + 1] =   np.sqrt(masses[i]) * z(xcc,i)
        b4[3*i + 2] = - np.sqrt(masses[i]) * y(xcc,i)
        b5[3*i + 0] = - np.sqrt(masses[i]) * z(xcc,i)
        b5[3*i + 2] =   np.sqrt(masses[i]) * x(xcc,i)
        b6[3*i + 0] =   np.sqrt(masses[i]) * y(xcc,i)
        b6[3*i + 1] = - np.sqrt(masses[i]) * x(xcc,i)
    norm4 = np.linalg.norm(b4)
    norm5 = np.linalg.norm(b5)
    norm6 = np.linalg.norm(b6)
    if norm4 > EPS_NORM: b4 /= norm4; vecs.append(b4)
    if norm5 > EPS_NORM: b5 /= norm5; vecs.append(b5)
    if norm6 > EPS_NORM: b6 /= norm6; vecs.append(b6)
    # Gram Schmidt
    X = np.matrix(vecs).transpose()
    X_gs, R = np.linalg.qr(X)
    projmatrix = X_gs * X_gs.H
    if v0 is not None:
       normv0 = np.linalg.norm(v0)
       if normv0 > EPS_NORM:
          v0 = np.matrix( v0 ) / normv0
          projmatrix += v0.transpose() * v0
    return projmatrix
#-----------------------------------------------#
def project_hessian(Fms,natoms,proj_matrix):
    ''' Fms: hessian in mass-scaled '''
    # identity matrix
    I = np.identity(3*natoms)
    # Calculate projected hessian matrix
    Fms_proj = (I - proj_matrix) * Fms * (I - proj_matrix)
    return Fms_proj
#-----------------------------------------------#
def diagonalize_hessian(Fms,mu=1.0/AMU):
    # as Fms is symmetric --> diagonalize with eigh
    evalsF, evecsF = np.linalg.eigh(Fms)
    # Convert evals to angular frequencies
    ccfreqs = [eval2afreq(v,mu) for v  in evalsF]
    # evecsF to list of eigenvectors
    evecsF  = evecsF.transpose().tolist()
    # return data
    return ccfreqs, evalsF, evecsF
#-----------------------------------------------#
def detect_frozen(Fcc,nat):
    '''
    Fcc --> 3Nx3N
    '''
    frozen =  []
    if Fcc is None or len(Fcc) == 0: return frozen
    for at in range(nat):
        # get columns (rows are equivalent; symmetric matrix)
        colx = Fcc[:][3*at+0][0]
        coly = Fcc[:][3*at+1][0]
        colz = Fcc[:][3*at+2][0]
        # Get norm of column
        normx = np.linalg.norm(colx)
        normy = np.linalg.norm(coly)
        normz = np.linalg.norm(colz)
        # are columns made of zeros?
        if normx != 0.0: continue
        if normy != 0.0: continue
        if normz != 0.0: continue
        frozen.append(at)
    return frozen
#-----------------------------------------------#
def calc_ccfreqs(Fcc,masses,xcc,mu=1.0/AMU,v0=None):
    '''
    xcc has to be centered at com
    v0 in case gradient has to be removed
    '''
    # num of atoms and Fcc in matrix format
    nat = len(masses)
    if len(Fcc) != 3*nat: Fcc = lowt2matrix(Fcc)
    # Frozen atoms?
    frozen  = detect_frozen(Fcc,nat)
    boolN   = np.array([at not in frozen for at in range(nat)])
    bool3N  = np.array([at not in frozen for at in range(nat) for ii in range(3)])
    # if FROZEN atoms, then reduce system!!
    if len(frozen) != 0:
       masses = np.array(masses)[boolN]
       xcc    = np.array(xcc)[bool3N]
       if v0 is not None: v0 = np.array(v0)[bool3N]
       # force constant matrix
       Fcc = [[Fcc[idx1][idx2] for idx1 in range(3*nat) if bool3N[idx1]]\
                               for idx2 in range(3*nat) if bool3N[idx2]]
       # num atoms
       nat    = len(masses)
       # re-center system
       xcc = shift2com(xcc,masses)
    # Analyze system
    linear = islinear(xcc)
    if linear: nvdof = 3*nat-5
    else     : nvdof = 3*nat-6
    if v0 is not None: nvdof -= 1
    # mass-scaled hessian
    Fms = cc2ms_F(Fcc,masses,mu=mu)
    Fms = np.matrix(Fms)
    # projection matrix
    pmatrix = get_projectionmatrix(xcc,masses,v0)
    # projected hessian
    Fms = project_hessian(Fms,nat,pmatrix)
    # Diagonalization
    ccfreqs, evalsF, evecsF = diagonalize_hessian(Fms,mu)
    # remove extra frequencies
    idxs = sorted([(abs(fq),fq,idx) for idx,fq in enumerate(ccfreqs)])
    idxs.reverse()
    idxs = idxs[:nvdof]
    idxs = sorted([(fq,idx) for absfq,fq,idx in idxs])
    idxs = [idx for fq,idx in idxs]
    ccfreqs = [ccfreqs[idx] for idx in idxs]
    evalsF  = [ evalsF[idx] for idx in idxs]
    evecsF  = [ evecsF[idx] for idx in idxs]
    # Consider the removed atoms in the eigenvectors
    if len(frozen) != 0:
       for idx,evecF in enumerate(evecsF):
           evecsF[idx] = [evecF.pop(0) if booli else 0.0 for booli in bool3N]
    return ccfreqs, evalsF, evecsF
#-----------------------------------------------#
def scale_freqs(freqs,fscal):
    return [freq*fscal for freq in freqs]
#===============================================#


#=============================================#
#        Functions related to extrema         #
#=============================================#
def minima_in_list(lx,ly):
    '''
    in the list, it find points
    that may be local minima
    Returns the list of x-guesses
    '''
    np = len(lx)
    # initialize guesses
    guesses = []
    # initial point
    if ly[0] <= ly[1]:
       guesses.append(lx[0])
    # mid points
    for idx in range(1,np-1):
        xi, yi = lx[idx-1],ly[idx-1]
        xj, yj = lx[idx  ],ly[idx  ]
        xk, yk = lx[idx+1],ly[idx+1]
        if yj <= yi and yj <= yk: guesses.append(xj)
    # final points
    if ly[-1] <= ly[-2]:
       guesses.append(lx[-1])
    return guesses
#=============================================#


#=======================================================#
# FUNCTIONS FOR READING THE LOG FILE OF GAUSSIAN PROG.  #
#=======================================================#
def split_gaulog_into_gaublocks(filename):
    # Key to split the system into blocks
    str_end='Normal termination'
    # Read log/out file and join lines as string
    with open(filename,'r') as asdf: lines = asdf.readlines()
    text  = "".join(lines)
    # Divide by str_end (last element has to be excluded)
    blocks = text.split(str_end)[:-1]
    # For some reason, sometimes Gaussian prints a block
    # without information. In these cases, the block consists
    # of a few lines. Here, we exclude that cases
    #print [len(block.split("\n")) for block in blocks]
    blocks = [block for block in blocks if len(block.split("\n")) > 300]
    # Remove the lines list and the whole text
    del lines, text
    # No normal termination?
    return blocks
#-------------------------------------------------------#
def get_data_from_maintext(mtext):
    key_geom1 = 'Z-Matrix orientation'
    key_geom2 = 'Input orientation'
    key_geom3 = 'Standard orientation'
    key_force = "     Forces ("
    key_zmat  = 'Final structure in terms of initial Z-matrix:'
    key_end   = "------------------"
    key_1bar  = "\\"
    key_oniom = "ONIOM: extrapolated energy"

    # (a) Find cartesian coordinates
    if   key_geom1 in mtext: geom = mtext.split(key_geom1)[-1]
    elif key_geom2 in mtext: geom = mtext.split(key_geom2)[-1]
    elif key_geom3 in mtext: geom = mtext.split(key_geom3)[-1]
    else                   : geom,xcc = None, None
    if geom is not None:
       # convert to list of lines and get the lines associated to geometry
       geom = "\n".join(geom.split("\n")[5:])
       idx  = geom.find(key_end)
       geom = geom[:idx].strip()
       # convert to list of floats
       geom = [line.split() for line in geom.split("\n") if line.strip() != ""]
       xcc  = [[float(x),float(y),float(z)] for (_,atnum,_,x,y,z) in geom]
       xcc  = flatten_llist(xcc)
    # (b) Find forces --> gradient
    if key_force in mtext:
       force = mtext.split(key_force)[-1]
       # convert to list of lines and get the lines associated to forces
       force = "\n".join(force.split("\n")[3:])
       idx = force.find(key_end)
       force = force[:idx]
       # convert to list of floats
       force = [line.split() for line in force.split("\n") if line.strip() != ""]
       gcc  = [[-float(gx),-float(gy),-float(gz)] for (_,atnum,gx,gy,gz) in force]
       gcc  = flatten_llist(gcc)
    else: gcc = None
    # (c) Find z-matrix
    if  key_zmat in mtext:
        lines_zmat = mtext.split(key_zmat)[-1].strip().split("\n")
        for idx,line in enumerate(lines_zmat):
            line = line.strip()
            if line == "" or key_1bar in line:
               idx1 = idx
               break
        zmat = [line.strip() for line in lines_zmat[:idx1] if "Variables:" not in line]
    else: zmat = None
    # (d) ONIOM energy?
    E_ONIOM = None
    for line in mtext.split("\n")[::-1]:
        if key_oniom in line:
           E_ONIOM = float(line.split()[-1])
           break
    # Convert xcc to bohr
    if xcc is not None: xcc = [xi/ANGSTROM for xi in xcc]
    # Return data
    return xcc, gcc, zmat, E_ONIOM
#-------------------------------------------------------#
def get_data_from_archive(summary):
    # Keywords to look for
    key_hag  = "#"
    key_1bar ='\\'
    key_2bar ='\\\\'
    key_ver  ='Version'
    key_en1  ='State='
    key_en2  ='RMSD='
    key_imag ='NImag='
    # logical variables
    Lzmat = False
    Lxyz  = False
    Lhess = False
    # (a) the command line
    idx1 = summary.find(key_hag,0)+len(key_hag)
    idx2 = summary.find(key_2bar,idx1)
    commands = summary[idx1:idx2]
    # (b) the comment line
    idx3 = summary.find(key_2bar,idx2)+len(key_2bar)
    idx4 = summary.find(key_2bar,idx3)
    comment = summary[idx3:idx4]
    # (c) charge and multiplicity
    idx5 = summary.find(key_2bar,idx4)+len(key_2bar)
    idx6 = summary.find(key_1bar,idx5)
    ch,mtp = [int(value) for value in summary[idx5:idx6].split(",")]
    # (d) z-matrix or Cartesian coordinates
    idx7 = summary.find(key_ver,idx6)
    geom = [string for string in summary[idx6+len(key_1bar):idx7].split(key_1bar) if string != ""]
    if len(geom[0]) <= 4:
       Lzmat   = True
       zmat    = list(geom)
       symbols = [line.split(",")[0] for line in zmat if "=" not in line]
       xcc     = None
    else:
       Lxyz    = True
       zmat    = None
       symbols = [line.split(",")[0]   for line in geom]
       # sometimes, this line has 5 elements instead of 4
       # for this reason, coordinates are extracted with [-3:]
       # instead of [1:]
       xyz = [line.split(",")[-3:] for line in geom]
       xyz = [[float(x),float(y),float(z)] for (x,y,z) in xyz]
       xcc = flatten_llist(xyz)
    # (e) Energy and other info
    idx8a = summary.find(key_ver,idx7)
    idx8b = summary.find(key_en1,idx7)
    idx8  = max(idx8a,idx8b)
    idx9  = summary.find(key_1bar,idx8)+len(key_1bar)
    idx10 = summary.find(key_en2,idx9)
    str_energies = summary[idx9:idx10].replace(key_1bar," ")
    energies = str_energies.split()
    energies = [line.split("=") for line in energies]
    # remove S**2 (for open-shell)
    energies = [(float(energy),level.strip()) for level,energy in energies if not level.strip().startswith("S2")]
    # (f) Hessian matrix
    Lhess = key_imag in summary
    if Lhess:
       idx11=summary.find(key_imag,0)+len(key_imag)
       idx12=summary.find(key_2bar,idx11)
       num_imag = int(summary[idx11:idx12])
       idx12 += len(key_2bar)
       idx13=summary.find(key_2bar,idx12)
       # low-triangle hessian
       Fcc = [float(value) for value in summary[idx12:idx13].split(",")]
    else:
       num_imag = -1
       Fcc  = None
    # (g) Gradient may appera after hessian matrix
    if Lhess:
       idx13 += len(key_2bar)
       idx14=summary.find(key_2bar,idx13)
       gcc = [float(value) for value in summary[idx13:idx14].split(",")]
    else:
       gcc = None
    # Convert xcc to bohr
    if xcc is not None: xcc = [xi/ANGSTROM for xi in xcc]
    return commands,comment,ch,mtp,symbols,xcc,gcc,Fcc,energies,num_imag,zmat
#-------------------------------------------------------#
def get_data_from_gaublock(gaublock):
    '''
    gaublock is a string 
    gaublock contains the info from begining till Normal termination
    '''
    # Divide the block into the summary part and the rest
    key_start='GINC'
    key_end  ='@'
    mtext    = gaublock.split(key_start)[0]
    summary  = gaublock.split(key_start)[1].split(key_end)[0]
    # Remove the initial blank space of each line in summary
    # Also remove the line breaks
    summary  = "".join([line.strip() for line in summary.split("\n")])
    # Data in summary (aka archive)
    commands,comment,ch,mtp,symbols,xcc,gcc,Fcc,energies,num_imag,zmat = get_data_from_archive(summary)
    # Data in main text (excluding archive)
    xcc_mt, gcc_mt, zmat_mt, E_oniom = get_data_from_maintext(mtext)
    # If data not in archive --> get from main text
    if xcc  is None and  xcc_mt is not None: xcc  =  xcc_mt
    if gcc  is None and  gcc_mt is not None: gcc  =  gcc_mt
    if zmat is None and zmat_mt is not None: zmat = zmat_mt
    # Return data
    return commands,comment,ch,mtp,symbols,xcc,gcc,Fcc,energies,E_oniom,num_imag,zmat
#-------------------------------------------------------#
def read_gaussian_log(filename):
    if not os.path.exists(filename): return
    # split lines into blocks (in case of Link1)
    blocks = split_gaulog_into_gaublocks(filename)
    # Get info of each block
    data = [get_data_from_gaublock(block) for block in blocks]
    # There is nothing to return
    if data == []: return [None]*12
    # Localize data with hessian matrix
    IDX = -1
    for idx,data_i in enumerate(data):
        Fcc =  data_i[7]
        if Fcc is not None:
           IDX = idx
           break
    # Return the best set of data (the last with the hessian or the last block)
    commands,comment,ch,mtp,symbols,xcc,gcc,Fcc,energies,E_oniom,num_imag,zmat = data[IDX]
    # If user does not ask for level, send one of lowest energy
    energies.sort()
    energy,level = energies[0]
    # oniom?
    if E_oniom is not None:
       energy = E_oniom
       level  = "ONIOM"
    # Return data
    return commands,comment,ch,mtp,symbols,xcc,gcc,Fcc,energy,num_imag,zmat,level
#-------------------------------------------------------#
def gen_zmatrix_string(lzmat,zmatvals,constants=[]):
    string = ""
    all_keys = []
    for idx,zmatline in enumerate(lzmat):
        symbol, connections, keys = zmatline
        # Dummy atoms
        if symbol.upper() in "XX,X,DA": symbol = "X"
        # generate line
        string += "%2s  "%symbol
        for (at,key) in zip(connections,keys):
            string += "%3i  %-7s"%(at+1,key)
        string += "\n"
        # avoid duplicates
        all_keys += [key for key in keys if key not in all_keys]
    # Exclude that keys that are, indeed, numbers
    the_keys = []
    for key in all_keys:
        try   : key = float(key)
        except: the_keys.append(key)
    # Write variables and constants
    string += "Variables:\n"
    for key in the_keys:
        if key.startswith("-") or key in constants: continue
        try   : string += "%-7s %.5f\n"%(key,zmatvals[key])
        except: pass
    if len(constants) != 0:
       string += "Constants:\n"
       for key in constants:
           try   : string += "%-7s %.5f\n"%(key,zmatvals[key])
           except: pass
    return string
#-------------------------------------------------------#
def convert_zmat(lines):
    '''
    basically, a modification of read_xyz_zmat (common.files)
    '''
    lines_values  = [line.replace("="," ") for line in lines if "="     in line]
    lines_zmatrix = [line.replace(","," ") for line in lines if "=" not in line]
    # symbols from zmat
    symbols = []
    atonums = []
    lzmat   = []
    negkeys = []
    for idx,line in enumerate(lines_zmatrix):
        line = line.split()
        # Expected number of columns in this line
        if   idx == 0: expected_cols = 1
        elif idx == 1: expected_cols = 3
        elif idx == 2: expected_cols = 5
        else         : expected_cols = 7
        # Get symbol
        symbol,atonum = symbol_and_atonum(line[0])
        # Get other data
        connections = tuple([int(at_i)-1 for at_i  in line[1:expected_cols:2]])
        keys        = tuple([  key_i     for key_i in line[2:expected_cols:2]])
        # add keys with negative sign
        negkeys += [key_i for key_i in keys if key_i.startswith("-")]
        # save data
        symbols.append(symbol)
        atonums.append(atonum)
        lzmat.append( (symbol,connections,keys) )
    # Get diccionary with values
    zmatvals = {line.split()[0]:float(line.split()[1]) for line in lines_values}
    # Generate another dict
    zmatatoms = {}
    for at1,(symbol,connections,keys) in enumerate(lzmat):
        at2,at3,at4,k12,k123,k1234 = [None for dummy in range(6)]
        if   len(connections) == 1: at2,k12  = connections[0], keys[0]
        elif len(connections) == 2: at2,at3,k12,k123 = connections[0:2]+keys[0:2]
        elif len(connections) == 3: at2,at3,at4,k12,k123,k1234 = connections[0:3]+keys[0:3]
        else: continue
        if k12   is not None: zmatatoms[k12]   = (at1,at2)
        if k123  is not None: zmatatoms[k123]  = (at1,at2,at3)
        if k1234 is not None: zmatatoms[k1234] = (at1,at2,at3,at4)
    # any keyword with negative value
    for key_i in negkeys:
        key = key_i[1:]
        if key in zmatvals.keys(): zmatvals[key_i] = -zmatvals[key]
    # Return data
    return (lzmat,zmatvals,zmatatoms), symbols
#=======================================================#



#=======================================================#
# reading method for Pilgrim                            #
#-------------------------------------------------------#
def read_gauout(filename):
    # read gaussian file
    data_gaulog = read_gaussian_log(filename)
    # split data
    ch      = data_gaulog[2]
    mtp     = data_gaulog[3]
    symbols = data_gaulog[4]
    xcc     = data_gaulog[5]
    gcc     = data_gaulog[6]
    Fcc     = data_gaulog[7]
    V0      = data_gaulog[8]
    level   = data_gaulog[11]
    # symbols to atomic numbers
    atonums = symbols2atonums(symbols)
    # atomic mass
    atomasses = atonums2masses(atonums)
    # return data
    return xcc, atonums, ch, mtp, V0, gcc, Fcc, atomasses, level
#=======================================================#





#===============================================#
# Internal coordinates / Graph Theory           #
#===============================================#
def ic2string(ic):
    ictype, icatoms = ic
    if ictype == "st": return "-".join(["%i"%(at+1) for at in icatoms])
    if ictype == "ab": return "-".join(["%i"%(at+1) for at in icatoms])
    if ictype == "pt": return "-".join(["%i"%(at+1) for at in icatoms])
    if ictype == "lb": return "=".join(["%i"%(at+1) for at in icatoms])
    if ictype == "it": return "_".join(["%i"%(at+1) for at in icatoms])
#---------------------------------------------#
def string2ic(icstring):
    if "-" in icstring:
        atoms = [int(at)-1 for at in icstring.split("-")]
        if   len(atoms) == 2: case = "st"
        elif len(atoms) == 3: case = "ab"
        elif len(atoms) == 4: case = "pt"
        else: exit("Problems with internal coordinate!")
        if atoms[0] > atoms[-1]: atoms = atoms[::-1]
    if "=" in icstring:
        atoms = [int(at)-1 for at in icstring.split("=")]
        case  = "lb"
        if len(atoms) != 3: exit("Problems with internal coordinate!")
        if atoms[0] > atoms[-1]: atoms = atoms[::-1]
    if "_" in icstring:
        atoms = [int(at)-1 for at in icstring.split("_")]
        case  = "it"
        if len(atoms) != 4: exit("Problems with internal coordinate!")
        atoms = tuple(sorted(atoms[0:3])+atoms[3:4])
    return (case,atoms)
#-----------------------------------------------#
def merge_ics(ics_st,ics_ab,ics_lb,ics_it,ics_pt):
    all_ics  = [ ("st",ic) for ic in sorted(ics_st)] # stretching
    all_ics += [ ("ab",ic) for ic in sorted(ics_ab)] # angular bending
    all_ics += [ ("lb",ic) for ic in sorted(ics_lb)] # linear  bending
    all_ics += [ ("it",ic) for ic in sorted(ics_it)] # improper torsion
    all_ics += [ ("pt",ic) for ic in        ics_pt ] # proper   torsion (DO NOT SORT)
    return all_ics
#-----------------------------------------------#
def unmerge_ics(all_ics):
    ics_st = [ ic for ic_type,ic in all_ics if ic_type=="st"]
    ics_ab = [ ic for ic_type,ic in all_ics if ic_type=="ab"]
    ics_lb = [ ic for ic_type,ic in all_ics if ic_type=="lb"]
    ics_it = [ ic for ic_type,ic in all_ics if ic_type=="it"]
    ics_pt = [ ic for ic_type,ic in all_ics if ic_type=="pt"]
    return ics_st,ics_ab,ics_lb,ics_it,ics_pt
#-----------------------------------------------#
def count_ics(all_ics):
    ics_st,ics_ab,ics_lb,ics_it,ics_pt = unmerge_ics(all_ics)
    nICs = len(ics_st)+len(ics_ab)+2*len(ics_lb)+len(ics_it)+len(ics_pt)
    return nICs
#-----------------------------------------------#
def get_adjmatrix(xcc,symbols,scale=CONNECTSCAL,mode="bool"):
    '''
    returns adjacency matrix (connection matrix);
    also distance matrix and number of bonds
    * mode = bool, int
    '''
    nbonds  = 0
    nat     = howmanyatoms(xcc)
    dmatrix = get_distmatrix(xcc)
    if   mode == "int" : no, yes = 0    , 1
    elif mode == "bool": no, yes = False, True
    else               : no, yes = False, True
    cmatrix = [ [no for ii in range(nat)] for jj in range(nat)]
    for ii in range(nat):
        cr_ii = dpt_s2cr[symbols[ii]] # covalent radius
        for jj in range(ii+1,nat):
            cr_jj = dpt_s2cr[symbols[jj]]
            dref  = (cr_ii+cr_jj)*scale
            if dmatrix[ii][jj] < dref:
               nbonds += 1
               cmatrix[ii][jj] = yes
               cmatrix[jj][ii] = yes
    return cmatrix, dmatrix, nbonds
#-----------------------------------------------#
def get_bonds(amatrix):
    bonds = []
    nnodes = len(amatrix)
    for node1 in range(nnodes):
        for node2 in range(node1+1,nnodes):
            if amatrix[node1][node2] in [True,1]: bonds += [(node1,node2)]
    return bonds
#-----------------------------------------------#
def get_numbonds(amatrix):
    nbonds = 0
    nnodes = len(amatrix)
    for node1 in range(nnodes):
        for node2 in range(node1+1,nnodes):
            if amatrix[node1][node2] in [True,1]: nbonds += 1
    return nbonds
#-----------------------------------------------#
def adjacency_matrix2list(amatrix):
    alist = {}
    for node1,row in enumerate(amatrix):
       alist[node1]= [node2 for node2, bonded in enumerate(row) if bonded in [True,1]]
    return alist
#-----------------------------------------------#
def get_fragments_from_adjmatrix(amatrix):
    nnodes   = len(amatrix)
    visited  = set([])
    for node in range(nnodes):
        if node in visited: continue
        tovisit  = [node]
        fragment = set([])
        while len(tovisit) != 0:
            nodeA = tovisit.pop(0)
            # neighbors of nodeA
            neighbors = [nodeB for nodeB in range(nnodes) if amatrix[nodeA][nodeB] == 1]
            # Add them to the list to visit
            tovisit += [nodeB for nodeB in neighbors if nodeB not in fragment]
            # Update sets
            fragment.add(nodeA)
            visited.add(nodeA)
        yield fragment
#-----------------------------------------------#
def get_subgraph(node,alist,fragment=[]):
    fragment += [node]
    neighbors = alist[node]
    for neighbor in neighbors:
        if neighbor not in fragment:
            fragment = get_subgraph(neighbor,alist,fragment)
    return fragment
#-----------------------------------------------#
def get_fragments(alist):
    fragments = []
    visited   = set([])
    for node in alist.keys():
        if node in visited: continue
        fragment = set(get_subgraph(node,alist,[]))
        if fragment not in fragments: fragments.append(fragment)
        visited = visited.union(fragment)
    return fragments
#-----------------------------------------------#
def distance_2fragments(frg1,frg2,xcc):
    min_dist = float("inf")
    pair     = (None,None)
    for at1 in frg1:
        x1 = xyz(xcc,at1)
        for at2 in frg2:
            x2 = xyz(xcc,at2)
            dist = distance(x1,x2)
            if dist < min_dist:
               min_dist = dist
               pair     = (at1,at2)
    return min_dist, pair
#-----------------------------------------------#
def distance_allfragments(fragments,xcc):
    nfrags = len(fragments)
    the_list = []
    for idx1 in range(nfrags):
        frg1 = fragments[idx1]
        for idx2 in range(idx1+1,nfrags):
            frg2 = fragments[idx2]
            dist, (at1,at2) = distance_2fragments(frg1,frg2,xcc)
            the_list.append( (dist,idx1,idx2,at1,at2) )
    return sorted(the_list)
#-----------------------------------------------#
def frags_distances(fragments):
    ''' use distance_allfragments -  this one returns distance
        of 1 and just first atom in each fragment'''
    fdists = []
    nfrags = len(fragments)
    for idx1 in range(nfrags):
        for idx2 in range(idx1+1,nfrags):
            dist = 1.0
            atf1 = list(fragments[idx1])[0]
            atf2 = list(fragments[idx2])[0]
            fdists.append( (1.0,idx1,idx2,atf1,atf2) )
    fdists.sort()
    return fdists
#-----------------------------------------------#
def link_fragments(xcc,amatrix,nfrags=1):
    if   amatrix[0][0] is False: bonded = True
    elif amatrix[0][0] == 0    : bonded = 1
    else: exit("sth wrong in adjacency matrix!")
    alist     = adjacency_matrix2list(amatrix)
    fragments = get_fragments(alist)
   #fdists    = frags_distances(fragments)
    fdists    = distance_allfragments(fragments,xcc)
    inumfrags = len(fragments)
    fnumfrags = len(fragments)
    for dist,idx1,idx2,atf1,atf2 in fdists:
        fragments[idx1] = fragments[idx1].union(fragments[idx2])
        fragments[idx2] = set([])
        amatrix[atf1][atf2] = bonded
        amatrix[atf2][atf1] = bonded
        fnumfrags = sum([1 for frag in fragments if len(frag)!=0])
        if fnumfrags == nfrags: break
    fragments = [frag for frag in fragments if len(frag) != 0]
    return amatrix, fragments, inumfrags, fnumfrags
#-----------------------------------------------#
def ics_value(xcc,ic):
    ''' ic = (ic_type,ic_atoms)'''
    if type(ic) == type("string"):
        ic_type,ic_atoms = string2ic(ic)
    else:
        ic_type,ic_atoms = ic
    if ic_type == "st": return distance( *(xyz(xcc,at) for at in ic_atoms) )
    if ic_type == "ab": return angle(    *(xyz(xcc,at) for at in ic_atoms) )
    if ic_type == "lb": return angle(    *(xyz(xcc,at) for at in ic_atoms) )
    if ic_type == "it": return dihedral( *(xyz(xcc,at) for at in ic_atoms) )
    if ic_type == "pt": return dihedral( *(xyz(xcc,at) for at in ic_atoms) )
#-----------------------------------------------#
def ics_get_stretchings(cmatrix,natoms):
   ics_st = [(at1,at2) for at1 in range(natoms) for at2 in range(at1,natoms) if cmatrix[at1][at2] in [True,1]]
   return ics_st
#-----------------------------------------------#
def ics_get_iccentral(adj_list):
    ic_3ats = []
    ic_4ats = []
    for at2 in adj_list.keys():
        bonded  = adj_list[at2]
        nbonded = len(bonded)
        if nbonded < 2: continue
        for idx1 in range(nbonded):
            for idx3 in range(idx1+1,nbonded):
                bending = (bonded[idx1],at2,bonded[idx3])
                ic_3ats.append(bending)
                if nbonded < 3: continue
                for idx4 in range(idx3+1,nbonded):
                    improper_torsion = (bonded[idx1],bonded[idx3],bonded[idx4],at2)
                    ic_4ats.append(improper_torsion)
    return ic_3ats, ic_4ats
#-----------------------------------------------#
def ics_classify_bends(xcc,ic_3ats):
    ics_lb = []
    ics_ab = []
    thetas     = {}
    for at1,at2,at3 in ic_3ats:
       x1 = xyz(xcc,at1)
       x2 = xyz(xcc,at2)
       x3 = xyz(xcc,at3)
       theta = abs(np.rad2deg(angle(x1,x2,x3)))
       if theta < EPS_LINEAR or theta > 180-EPS_LINEAR:
          ics_lb.append( (at1,at2,at3) )
       else:
          ics_ab.append( (at1,at2,at3) )
       thetas[(at1,at2,at3)] = theta
    return ics_lb, ics_ab, thetas
#-----------------------------------------------#
def ics_get_ptorsions(ics_st,adj_list,xcc):
    ics_pt = []
    for at2,at3 in ics_st:
        x2 = xyz(xcc,at2)
        x3 = xyz(xcc,at3)
        bondedto2 = list(adj_list[at2])
        bondedto3 = list(adj_list[at3])
        bondedto2.remove(at3)
        bondedto3.remove(at2)
        if len(bondedto2) == 0: continue
        if len(bondedto3) == 0: continue
        for at1 in bondedto2:
            x1 = xyz(xcc,at1)
            for at4 in bondedto3:
                if at1 == at4: continue
                x4 = xyz(xcc,at4)
                # the two angles
                angA  = np.rad2deg(angle(x1,x2,x3))
                angB  = np.rad2deg(angle(x2,x3,x4))
                # linear?
                booleanA = angA < EPS_LINEAR or angA > 180-EPS_LINEAR
                booleanB = angB < EPS_LINEAR or angB > 180-EPS_LINEAR
                if booleanA or booleanB: continue
                ptorsion = (at1,at2,at3,at4)
                ics_pt.append(ptorsion)
    return ics_pt
#-----------------------------------------------#
def ics_get_ltorsions(ics_lb,adj_list):
    ic_ltors = []
    for at1,at2,at3 in ics_lb:
        bondedto1 = list(adj_list[at1])
        bondedto3 = list(adj_list[at3])
        if at1 in bondedto3: bondedto3.remove(at1)
        if at2 in bondedto3: bondedto3.remove(at2)
        if at2 in bondedto1: bondedto1.remove(at2)
        if at3 in bondedto1: bondedto1.remove(at3)
        for at0 in bondedto1:
            for at4 in bondedto3:
                if at0 == at4: continue
                ltorsion = (at0,at1,at3,at4)
                ic_ltors.append(ltorsion)
    return ic_ltors
#-----------------------------------------------#
def ics_from_geom(xcc,symbols,scale=CONNECTSCAL,nfrags=1,verbose=False):
    natoms = len(symbols)
    amatrix, dmatrix, nbonds = get_adjmatrix(xcc,symbols,scale=scale,mode="bool")
    amatrix, fragments, inumfrags, fnumfrags = link_fragments(xcc,amatrix,nfrags=nfrags)
    if inumfrags != fnumfrags: nbonds = get_numbonds(amatrix)
    alist = adjacency_matrix2list(amatrix)
    ics_st = ics_get_stretchings(amatrix,natoms)
    ic_3ats, ics_it = ics_get_iccentral(alist)
    ics_lb, ics_ab, angles = ics_classify_bends(xcc,ic_3ats)
    ics_pt  = ics_get_ptorsions(ics_st,alist,xcc)
    ics_pt += ics_get_ltorsions(ics_lb,alist)
    # return data
    ics = merge_ics(ics_st,ics_ab,ics_lb,ics_it,ics_pt)
    if not verbose: return ics
    else: return ics, amatrix
#-----------------------------------------------#
def ics_depure_bendings(ic_3ats,keep=[]):
    ''' up to 3 bendings per central atom'''
    centers = [at2 for at1,at2,at3 in keep]
    random.shuffle(ic_3ats)
    for at1,at2,at3 in ic_3ats:
        if centers.count(at2) >= 3: continue
        #if at2 in centers: continue
        keep = [(at1,at2,at3)]+keep
        centers.append(at2)
    return keep
#-----------------------------------------------#
def ics_depure_itorsions(ic_4ats,keep=[]):
    ''' up to two improper torsions per atom'''
    centers = [at4 for at1,at2,at3,at4 in keep]
    random.shuffle(ic_4ats)
    for at1,at2,at3,at4 in ic_4ats:
        if centers.count(at4) >= 2: continue
        #if at4 in centers: continue
        keep = [(at1,at2,at3,at4)]+keep
        centers.append(at4)
    return keep
#-----------------------------------------------#
def ics_depure_ptorsions(ic_4ats,keep=[]):
    ''' one torsion per bond'''
    centers = [(at2,at3) for at1,at2,at3,at4 in keep]
    random.shuffle(ic_4ats)
    for at1,at2,at3,at4 in ic_4ats:
        if (at2,at3) in centers: continue
        if (at3,at2) in centers: continue
        keep = [(at1,at2,at3,at4)]+keep
        centers.append((at2,at3))
    return keep
#-----------------------------------------------#
def ics_depure(ics,keep=[]):
    ''' keep: those that cannot be removed '''
    ics_st ,ics_ab ,ics_lb ,ics_it ,ics_pt  = unmerge_ics(ics)
    keep_st,keep_ab,keep_lb,keep_it,keep_pt = unmerge_ics(keep)
    # depure angular bendings
    ics_ab = ics_depure_bendings(ics_ab,keep_ab)
    # depure torsions
    ics_it = ics_depure_itorsions(ics_it,keep_it)
    ics_pt = ics_depure_ptorsions(ics_pt,keep_pt)
    # merge again
    ics = merge_ics(ics_st,ics_ab,ics_lb,ics_it,ics_pt)
    return ics
#-----------------------------------------------#
def look_for_torsion(ics,torsion):
    ics_st ,ics_ab ,ics_lb ,ics_it ,ics_pt  = unmerge_ics(ics)
    # convert int tuple
    torsion = tuple(torsion)
    # partial torsion
    p2_torsion  = sorted(torsion[1:3])
    p3a_torsion = torsion[0:3]
    p3b_torsion = torsion[1:4][::-1]
    # Equivalent with 2 or 3 atoms in common
    equivalent2 = None
    equivalent3 = None
    # check torsions
    for torsion2 in ics_pt:
        torsion2 = tuple(torsion2)
        # torsion in set
        if torsion2       == torsion: return torsion
        if torsion2[::-1] == torsion: return torsion
        # torsion about same bond
        p2_torsion2  = sorted(torsion2[1:3])
        p3a_torsion2 = torsion2[0:3]
        p3b_torsion2 = torsion2[1:4][::-1]
        if   p3a_torsion == p3a_torsion2: equivalent3 = torsion2
        elif p3a_torsion == p3b_torsion2: equivalent3 = torsion2
        elif p3b_torsion == p3a_torsion2: equivalent3 = torsion2
        elif p3b_torsion == p3b_torsion2: equivalent3 = torsion2
        elif p2_torsion  == p2_torsion2 : equivalent2 = torsion2
    if equivalent3 is not None: return equivalent3
    return equivalent2
#-----------------------------------------------#
def ics_correctdir(x1,evec,ic,sign,masses=None,mu=None):
    '''
    x1 and evec NOT in mass-scaled
    '''
    x2 = [xi+ei for xi,ei in zip(x1,evec)]
    if masses is not None:
       x1 = ms2cc_x(x1,masses,mu)
       x2 = ms2cc_x(x2,masses,mu)
    val1 = ics_value(x1,ic)
    val2 = ics_value(x2,ic)
    diff = val2-val1
    if   diff > 0.0:
        if sign == "++": return True
        if sign == "--": return False
    elif diff < 0.0:
        if sign == "++": return False
        if sign == "--": return True
#-----------------------------------------------#
def ics_idir(xcc,symbols,masses,freqs,ms_evecs,ics=[],mu=1.0/AMU):
    '''
    returns the IC which varies the most due to the imaginary frequency
    '''
    if len(ics) == 0: ics = ics_from_geom(xcc,symbols)
    for freq,Lms in zip(freqs,ms_evecs):
        # only imaginary frequency
        if freq >= 0.0: continue
        Lcc = ms2cc_x(Lms,masses,mu)
        xfin = [xi+ei for xi,ei in zip(xcc,Lcc)]
        target_ic   = None
        target_sign = None
        maxdiff     = -float("inf")
        for ic in ics:
            ival = ics_value(xcc ,ic)
            fval = ics_value(xfin,ic)
            # the sign
            if fval >= ival: sign = "++"
            else           : sign = "--"
            # reference for bonds or angles
            if len(ic[1]) == 2: reference = 1.0       # 1.0 bohr
            else              : reference = np.pi/2.0 # 90 degrees
            # get absolute diff
            if len(ic[1]) == 4: adiff = abs(angular_dist(fval,ival,'rad'))
            else              : adiff = abs(fval - ival)
            # get relative difference with regards to reference
            reldiff = abs(adiff/reference)
            # get the one that changes the most
            if reldiff > maxdiff:
                target_ic   = ic
                target_sign = sign
                maxdiff     = reldiff
        return target_ic,target_sign
#-----------------------------------------------#
def zmat_nextpoint(x1,x2,x3,r,theta,phi):
    '''
    Point connectivity: 1-2-3-4
    Input info:
       * x1: coordinates of point 1
       * x2: coordinates of point 2
       * x3: coordinates of point 3
       * r: distance 3-4
       * theta: angle 2-3-4
       * phi: dihedral 1-2-3-4
    Output:
       * x4: coordinates of point 4
    '''
    # spherical --> cartesian
    sinTheta = np.sin(theta)
    cosTheta = np.cos(theta)
    sinPhi = np.sin(phi)
    cosPhi = np.cos(phi)
    x = r * cosTheta
    y = r * cosPhi * sinTheta
    z = r * sinPhi * sinTheta
    # Now, get vectors from points 1 to 3
    ab = np.array(x2) - np.array(x1)
    bc = np.array(x3) - np.array(x2)
    bc = bc / np.linalg.norm(bc)
    nv = np.cross(ab, bc)
    nv = nv / np.linalg.norm(nv)
    ncbc = np.cross(nv, bc)
    # Relocate x4 with regards to 1-2-3
    new_x = x3[0] - bc[0] * x + ncbc[0] * y + nv[0] * z
    new_y = x3[1] - bc[1] * x + ncbc[1] * y + nv[1] * z
    new_z = x3[2] - bc[2] * x + ncbc[2] * y + nv[2] * z
    x4    = [new_x,new_y,new_z]
    # Return point
    return x4
#-----------------------------------------------#
def zmat2xcc(zmat,zmatvals):
    '''
    distances in zmatvals are in angstrom
    angles    in zmatvals are in degrees
    xcc --> in bohr
    '''
    natoms = len(zmat)
    # (a) first atom to origin
    xcc    = [0.0 for ii in range(3) for at in range(natoms)]
    if len(zmat) == 1: return xcc
    # (b) second atom in z axis
    symbol, (at1,), (dist,) = zmat[1]
    dist  = zmatvals[dist]/ANGSTROM
    x2 = np.array([0.0,0.0,dist])
    xcc[3:6] = x2.tolist()
    if len(zmat) == 2: return xcc
    # (c) third atom in XZ axis
    symbol, (at2,at1), (dist,angle) = zmat[2]
    dist  = zmatvals[dist]/ANGSTROM
    angle = np.deg2rad(zmatvals[angle])
    x1 = np.array(xyz(xcc,at1))
    x2 = np.array(xyz(xcc,at2))
    # get vector 2 --> 1
    vec21 = x1-x2
    # put x2 as origin
    x1 = x1-x2
    x2 = x2-x2
    # rotate vec21 about Y axis
    rotmatrix = gen_rotmatrix(np.array([0,-1,0]),angle)
    vec23 = rotate_point(vec21,rotmatrix)
    # correct size of vec23
    vec23 = dist * vec23 / np.linalg.norm(vec23)
    # Get old x2 and apply vec23
    x2 = np.array(xyz(xcc,at2))
    x3 = x2 + vec23
    xcc[6:9] = x3.tolist()
    if len(zmat) == 3: return xcc
    # The rest of atoms
    current = 4-1
    for line in zmat[3:]:
        symbol, (at3,at2,at1), (dist,angle,dihedral) = line
        # Get values of distances and angles
        # notice that data can be in the own line!
        # deal with distance
        try   : dist     = float(dist)
        except: dist     = zmatvals[dist]
        # deal with angle
        try   : angle    = float(angle)
        except: angle    = zmatvals[angle]
        # deal with dihedral
        try   : dihedral = float(dihedral)
        except:
            if dihedral not in zmatvals.keys() and dihedral.startswith("-"):
                dihedral = - zmatvals[dihedral[1:]]
            else: dihedral = zmatvals[dihedral]
        # in correct unis
        dist     = dist/ANGSTROM
        angle    = np.deg2rad(angle)
        dihedral = np.deg2rad(dihedral)
        # Get coordinates of the connected atoms
        x1 = np.array(xyz(xcc,at1))
        x2 = np.array(xyz(xcc,at2))
        x3 = np.array(xyz(xcc,at3))
        # get x4
        x4 = zmat_nextpoint(x1,x2,x3,dist,angle,dihedral)
        # update xcc
        xcc[3*current:3*current+3] = x4
        # update atom index
        current += 1
    return xcc
#===============================================#


#===============================================#
# WILSON method for freqs in internal coords    #
#===============================================#
def wilson_bvecs(xcc):
    '''
    This functions calculates the distance
    between each pair of atoms (dij) and also
    the unit bond vector eij = (rj - ri)/dij
    '''
    nat = howmanyatoms(xcc)
    bond_vectors = {}
    for ii in range(nat):
        ri = np.array(xyz(xcc,ii))
        for jj in range(ii+1,nat):
            rj = np.array(xyz(xcc,jj))
            eij = rj-ri
            dij = np.linalg.norm(eij)
            eij = eij / dij
            bond_vectors[(ii,jj)] = ( eij, dij)
            bond_vectors[(jj,ii)] = (-eij, dij)
    return bond_vectors
#-----------------------------------------------#
def wilson_stretch(bond_vectors,ij,natoms):
    '''
    Returns the row of the B matrix associated to
    the bond length between atom i and atom j and
    also the corresponding C matrix.
    Check ref [1] and [5].
    '''
    # Using nomenclature of reference [5]
    n = min(ij)
    m = max(ij)
    u, r = bond_vectors[(n,m)]
    # Calculating 1st derivatives: row of B matrix
    B_row = [0.0 for idx in range(3*natoms)]
    for a in [m,n]:
        if a == m: zeta_amn = +1.0
        if a == n: zeta_amn = -1.0
        for i in [0,1,2]:
            dr_dai = zeta_amn * u[i]
            B_row[3*a+i] = dr_dai
    # Calculating 2nd derivatives: 2D matrix of C tensor
    C_matrix = [ [0.0 for idx1 in range(3*natoms)] for idx2 in range(3*natoms)]
    #C_matrix = np.zeros( (3*natoms,3*natoms) )
    for a in [m,n]:
      for i in [0,1,2]:
          for b in [m,n]:
            for j in [0,1,2]:
               if C_matrix[3*a+i][3*b+j] != 0.0: continue
               # Get delta values
               if a == b: delta_ab = 1.0
               else:      delta_ab = 0.0
               if i == j: delta_ij = 1.0
               else:      delta_ij = 0.0
               # Get C element
               dr_daidbj = ((-1.0) ** delta_ab) * (u[i]*u[j] - delta_ij) / r
               # Save data in both positions
               C_matrix[3*a+i][3*b+j] = dr_daidbj
               C_matrix[3*b+j][3*a+i] = dr_daidbj
    return [B_row], [C_matrix]
#-----------------------------------------------#
def wilson_abend(bond_vectors,ijk,natoms):
    '''
    Returns the row of the B matrix associated to the
    i-j-k angle bend and the corresponding C matrix.
    Check ref [1] and [5].
    '''
    # Using nomenclature of reference [5]
    m, o, n = ijk
    u, lambda_u = bond_vectors[(o,m)]
    v, lambda_v = bond_vectors[(o,n)]
    # Get internal coordinate: bond angle
    q = angle_vecs(u,v)
    sinq = np.sin(q)
    cosq = np.cos(q)
    # Generation of w
    w = np.cross(u,v)
    w = w / np.linalg.norm(w)
    uxw = np.cross(u,w)
    wxv = np.cross(w,v)
    # Calculating 1st derivatives: row of B matrix
    B_row = [0.0 for idx in range(3*natoms)]
    for a in [m,o,n]:
        # Get zeta values
        if a == m: zeta_amo = +1.0; zeta_ano =  0.0
        if a == o: zeta_amo = -1.0; zeta_ano = -1.0
        if a == n: zeta_amo =  0.0; zeta_ano = +1.0
        for i in [0,1,2]:
            # Get B element
            dq_dai =  zeta_amo * uxw[i] / lambda_u + zeta_ano * wxv[i] / lambda_v
            B_row[3*a+i] = dq_dai
    # Calculating 2nd derivatives: 2D matrix of C tensor
    #C_matrix = np.zeros( (3*natoms,3*natoms) )
    C_matrix = [ [0.0 for idx1 in range(3*natoms)] for idx2 in range(3*natoms)]
    if abs(sinq) < EPS_SCX: return [B_row], [C_matrix]
    for a in [m,o,n]:
      for i in [0,1,2]:
        for b in [m,o,n]:
          for j in [0,1,2]:
            if C_matrix[3*a+i][3*b+j] != 0.0: continue
            # Define all delta and zeta values
            if a == m: zeta_amo = +1.0; zeta_ano =  0.0
            if a == o: zeta_amo = -1.0; zeta_ano = -1.0
            if a == n: zeta_amo =  0.0; zeta_ano = +1.0
            if b == m: zeta_bmo = +1.0; zeta_bno =  0.0
            if b == o: zeta_bmo = -1.0; zeta_bno = -1.0
            if b == n: zeta_bmo =  0.0; zeta_bno = +1.0
            if i == j: delta_ij = 1.0
            else:      delta_ij = 0.0
            # Get second derivative
            t1 = zeta_amo*zeta_bmo*(u[i]*v[j]+u[j]*v[i]-3*u[i]*u[j]*cosq+delta_ij*cosq)/(lambda_u**2 * sinq)
            t2 = zeta_ano*zeta_bno*(v[i]*u[j]+v[j]*u[i]-3*v[i]*v[j]*cosq+delta_ij*cosq)/(lambda_v**2 * sinq)
            t3 = zeta_amo*zeta_bno*(u[i]*u[j]+v[j]*v[i]-u[i]*v[j]*cosq-delta_ij)/(lambda_u*lambda_v*sinq)
            t4 = zeta_ano*zeta_bmo*(v[i]*v[j]+u[j]*u[i]-v[i]*u[j]*cosq-delta_ij)/(lambda_u*lambda_v*sinq)
            t5 = cosq / sinq * B_row[3*a+i] * B_row[3*b+j]
            dr_daidbj = t1 + t2 + t3 + t4 - t5
            C_matrix[3*a+i][3*b+j] = dr_daidbj
            C_matrix[3*b+j][3*a+i] = dr_daidbj
    return [B_row], [C_matrix]
#-----------------------------------------------#
def wilson_auxlinB(m,o,n,k):
        om = m - o
        on = n - o
        dom = np.linalg.norm(om)
        don = np.linalg.norm(on)
        qk = ((n[2]-o[2])*(m[k]-o[k]) - (n[k]-o[k])*(m[2]-o[2])) / dom / don
        Bk = []
        Dk = []
        for a in ["m","o","n"]:
            for i in [0,1,2]:
                if a == "m": dam, dao, dan = 1.0, 0.0, 0.0
                if a == "o": dam, dao, dan = 0.0, 1.0, 0.0
                if a == "n": dam, dao, dan = 0.0, 0.0, 1.0
                if i ==  2 : di2 = 1.0
                else       : di2 = 0.0
                if i == k  : dik = 1.0
                else       : dik = 0.0
                # Numerator
                N_ai = dik*(dao-dan)*m[2] + di2*(dan-dao)*m[k] +\
                       dik*(dan-dam)*o[2] + di2*(dam-dan)*o[k] +\
                       dik*(dam-dao)*n[2] + di2*(dao-dam)*n[k]
                # Denominator
                D_ai = (dam-dao)*(m[i]-o[i]) * don / dom + \
                       (dan-dao)*(n[i]-o[i]) * dom / don
                Dk.append(D_ai)
                # Whole derivative
                B_ai = (N_ai - qk*D_ai) / (dom*don)
                Bk.append(B_ai)
        return np.array(Bk), np.array(Dk)
#-----------------------------------------------#
def wilson_auxlinC(m,o,n,k,Bk=None,Dk=None):
        om = m - o
        on = n - o
        dom = np.linalg.norm(om)
        don = np.linalg.norm(on)
        if (Bk is None) or (Dk is None): Bk, Dk = get_B(m,o,n,k,True)
        Ck = np.zeros( (9,9) )
        for a in ["m","o","n"]:
            for i in [0,1,2]:
                if a == "m": dam, dao, dan = 1.0, 0.0, 0.0; A=0
                if a == "o": dam, dao, dan = 0.0, 1.0, 0.0; A=1
                if a == "n": dam, dao, dan = 0.0, 0.0, 1.0; A=2
                if i ==  2 : di2 = 1.0
                else       : di2 = 0.0
                if i == k  : dik = 1.0
                else       : dik = 0.0
                for b in ["m","o","n"]:
                    for j in [0,1,2]:
                        if b == "m": dbm, dbo, dbn = 1.0, 0.0, 0.0; B=0
                        if b == "o": dbm, dbo, dbn = 0.0, 1.0, 0.0; B=1
                        if b == "n": dbm, dbo, dbn = 0.0, 0.0, 1.0; B=2
                        if j ==  2 : dj2 = 1.0
                        else       : dj2 = 0.0
                        if j == k  : djk = 1.0
                        else       : djk = 0.0
                        # Term 1
                        term1 = (djk*di2-dik*dj2)*( (dan-dao)*dbm + (dam-dan)*dbo + (dao-dam)*dbn )
                        # Term 2
                        term2 = Bk[3*B+j] * Dk[3*A+i]
                        # Term 3
                        term3 = Bk[3*A+i] * Dk[3*B+j]
                        #
                        Ck[3*A+i,3*B+j] = (term1 - term2 - term3) / dom / don
        return np.matrix(Ck)
#-----------------------------------------------#
def wilson_lbend(m,o,n,MON,natoms):
    M,O,N = MON
    #------------------------------------------#
    # Redefine new Cartesian coordinate system #
    #------------------------------------------#
    # Define new z axis
    new_z = n - m
    new_z = new_z / np.linalg.norm(new_z)

    # Define new y axis
    ref  = np.array([+1.0,+1.0,+1.0])
    prod = np.dot(new_z,ref) / np.linalg.norm(new_z) / np.linalg.norm(ref)
    if abs(prod) == 0.0:
       ref = np.array([+1.0,-1.0,0.0])
    new_y = np.cross(ref,new_z)
    new_y = new_y / np.linalg.norm(new_y)

    # Define new x axis
    new_x = np.cross(new_y,new_z)
    new_x = new_x / np.linalg.norm(new_x)

    # Define rotation matrix such as new_r = R * old_r,
    # considering new_r and old_r as column vectors
    R = np.matrix([new_x,new_y,new_z])
    Tbar = np.zeros( (9,9)  )
    Tbar[0:3,0:3] = R
    Tbar[3:6,3:6] = R
    Tbar[6:9,6:9] = R

    # Define position vectors with this new matrix
    m = R * np.matrix(m).transpose(); m = np.array( m.transpose().tolist()[0] )
    o = R * np.matrix(o).transpose(); o = np.array( o.transpose().tolist()[0] )
    n = R * np.matrix(n).transpose(); n = np.array( n.transpose().tolist()[0] )

    #-----------------------------------------------#
    # Get row of B matrix and 2D matrix of C tensor #
    #-----------------------------------------------#
    B_rows , C_matrices = [] , []
    for k in [0,1]:
        Bk, Dk = wilson_auxlinB(m,o,n,k)
        Ck = wilson_auxlinC(m,o,n,k,Bk,Dk)
        # In old Cartesian coord. systems
        Bk = np.matrix(Bk) * Tbar.transpose()
        Ck = Tbar * Ck * Tbar.transpose()
        # Append data
        B_rows.append(np.array(Bk.tolist()[0]))
        C_matrices.append(Ck)

    #------------------------------------------#
    # Consider all the atoms to create B and C #
    #------------------------------------------#
    final_B = []
    for Bk in B_rows:
        fBk = [0.0 for idx in range(3*natoms)]
        for a in [M,O,N]:
            for i in [0,1,2]:
                if a == M: fBk[3*M+i] = Bk[0+i]
                if a == O: fBk[3*O+i] = Bk[3+i]
                if a == N: fBk[3*N+i] = Bk[6+i]
        final_B.append(fBk)

    final_C = []
    for Ck in C_matrices:
        #fCk = np.zeros( (3*natoms,3*natoms) )
        fCk = [ [0.0 for idx1 in range(3*natoms)] for idx2 in range(3*natoms)]
        for a in [M,O,N]:
            for i in [0,1,2]:
                # Select row in C
                if a == M: row = 0+i
                if a == O: row = 3+i
                if a == N: row = 6+i
                for b in [M,O,N]:
                    for j in [0,1,2]:
                        # Select col in C
                        if b == M: col = 0+j
                        if b == O: col = 3+j
                        if b == N: col = 6+j
                        fCk[3*a+i][3*b+j] = Ck[row,col]
        final_C.append(fCk)

    return final_B, final_C
#-----------------------------------------------#
def wilson_torsion(bond_vectors,ijkl,natoms):
    '''
    Returns the row of the B matrix associated to the
    i-j-k-l torsion and the corresponding C matrix.
    Check ref [1] and [5].
    '''

    # Using nomenclature of reference [5]
    m, o, p, n = ijkl
    u, lambda_u = bond_vectors[(o,m)]
    v, lambda_v = bond_vectors[(p,n)]
    w, lambda_w = bond_vectors[(o,p)]

    uxw = np.cross(u,w)
    vxw = np.cross(v,w)

    cosPhi_u = np.dot(u,w) / np.linalg.norm(u) / np.linalg.norm(w)
    sinPhi_u = np.sqrt(1.0 - cosPhi_u**2)
    cosPhi_v = -np.dot(v,w) / np.linalg.norm(v) / np.linalg.norm(w)
    sinPhi_v = np.sqrt(1.0 - cosPhi_v**2)

    # Get internal coordinate: dihedral angle
    cosq = np.dot(uxw,vxw) / sinPhi_u / sinPhi_v
    if   abs(cosq - 1.0) < EPS_SCX:
       cosq = +1.0; q = 0.0
    elif abs(cosq + 1.0) < EPS_SCX:
       cosq = -1.0; q = np.pi
    else: q = np.arccos(cosq)

    # Calculating 1st derivatives: row of B matrix #
    B_row = [0.0 for idx in range(3*natoms)]
    for a in [m,o,p,n]:
        # Get zeta values
        if a == m: zeta_amo = +1.0; zeta_apn =  0.0; zeta_aop =  0.0
        if a == o: zeta_amo = -1.0; zeta_apn =  0.0; zeta_aop = +1.0
        if a == p: zeta_amo =  0.0; zeta_apn = +1.0; zeta_aop = -1.0
        if a == n: zeta_amo =  0.0; zeta_apn = -1.0; zeta_aop =  0.0
        for i in [0,1,2]:
            # Get B element
            dq_dai =  zeta_amo * uxw[i] / lambda_u / sinPhi_u / sinPhi_u + \
                      zeta_apn * vxw[i] / lambda_v / sinPhi_v / sinPhi_v + \
                      zeta_aop * uxw[i] * cosPhi_u / lambda_w / sinPhi_u / sinPhi_u + \
                      zeta_aop * vxw[i] * cosPhi_v / lambda_w / sinPhi_v / sinPhi_v
            B_row[3*a+i] = dq_dai
    # Calculating 2nd derivatives: 2D matrix of C tensor #
    #C_matrix = np.zeros( (3*natoms,3*natoms) )
    C_matrix = [ [0.0 for idx1 in range(3*natoms)] for idx2 in range(3*natoms)]
    for a in [m,o,p,n]:
      for i in [0,1,2]:
        for b in [m,o,p,n]:
          for j in [0,1,2]:
            if C_matrix[3*a+i][3*b+j] != 0.0: continue
            # Define all delta and zeta values
            if a == m: zeta_amo = +1.0; zeta_anp =  0.0; zeta_apo =  0.0; zeta_aop =  0.0; zeta_ano =  0.0
            if a == o: zeta_amo = -1.0; zeta_anp =  0.0; zeta_apo = -1.0; zeta_aop = +1.0; zeta_ano = -1.0
            if a == p: zeta_amo =  0.0; zeta_anp = -1.0; zeta_apo = +1.0; zeta_aop = -1.0; zeta_ano =  0.0
            if a == n: zeta_amo =  0.0; zeta_anp = +1.0; zeta_apo =  0.0; zeta_aop =  0.0; zeta_ano = +1.0

            if b == m: zeta_bom = -1.0; zeta_bmo = +1.0; zeta_bnp =  0.0; zeta_bop =  0.0; zeta_bpo =  0.0
            if b == o: zeta_bom = +1.0; zeta_bmo = -1.0; zeta_bnp =  0.0; zeta_bop = +1.0; zeta_bpo = -1.0
            if b == p: zeta_bom =  0.0; zeta_bmo =  0.0; zeta_bnp = -1.0; zeta_bop = -1.0; zeta_bpo = +1.0
            if b == n: zeta_bom =  0.0; zeta_bmo =  0.0; zeta_bnp = +1.0; zeta_bop =  0.0; zeta_bpo =  0.0
            zeta_bpn = - zeta_bnp

            if a == b: delta_ab = 1.0
            else:      delta_ab = 0.0
            # Get second derivative
            t01 = uxw[i]*(w[j]*cosPhi_u-u[j])/(lambda_u**2)/(sinPhi_u**4)
            t02 = uxw[j]*(w[i]*cosPhi_u-u[i])/(lambda_u**2)/(sinPhi_u**4)
            t03 = vxw[i]*(w[j]*cosPhi_v+v[j])/(lambda_v**2)/(sinPhi_v**4)
            t04 = vxw[j]*(w[i]*cosPhi_v+v[i])/(lambda_v**2)/(sinPhi_v**4)
            t05 = uxw[i]*(w[j]-2*u[j]*cosPhi_u+w[j]*cosPhi_u**2)/(2*lambda_u*lambda_w*sinPhi_u**4)
            t06 = uxw[j]*(w[i]-2*u[i]*cosPhi_u+w[i]*cosPhi_u**2)/(2*lambda_u*lambda_w*sinPhi_u**4)
            t07 = vxw[i]*(w[j]+2*v[j]*cosPhi_v+w[j]*cosPhi_v**2)/(2*lambda_v*lambda_w*sinPhi_v**4)
            t08 = vxw[j]*(w[i]+2*v[i]*cosPhi_v+w[i]*cosPhi_v**2)/(2*lambda_v*lambda_w*sinPhi_v**4)
            t09 = uxw[i]*(u[j]+u[j]*cosPhi_u**2-3*w[j]*cosPhi_u+w[j]*cosPhi_u**3) / (2*lambda_w**2*sinPhi_u**4)
            t10 = uxw[j]*(u[i]+u[i]*cosPhi_u**2-3*w[i]*cosPhi_u+w[i]*cosPhi_u**3) / (2*lambda_w**2*sinPhi_u**4)
            t11 = vxw[i]*(v[j]+v[j]*cosPhi_v**2+3*w[j]*cosPhi_v-w[j]*cosPhi_v**3) / (2*lambda_w**2*sinPhi_v**4)
            t12 = vxw[j]*(v[i]+v[i]*cosPhi_v**2+3*w[i]*cosPhi_v-w[i]*cosPhi_v**3) / (2*lambda_w**2*sinPhi_v**4)
            if i != j and a != b:
               k = [0,1,2]; k.remove(i); k.remove(j); k = k[0]
               t13 = (w[k]*cosPhi_u-u[k]) / lambda_u / lambda_w / sinPhi_u**2
               t14 = (w[k]*cosPhi_v+v[k]) / lambda_v / lambda_w / sinPhi_v**2
            else:
               t13 = 0.0
               t14 = 0.0
            dr_daidbj = zeta_amo*zeta_bmo*(t01 + t02) + \
                        zeta_anp*zeta_bnp*(t03 + t04) + \
                       (zeta_amo*zeta_bop+zeta_apo*zeta_bom)*(t05 + t06) + \
                       (zeta_anp*zeta_bpo+zeta_aop*zeta_bpn)*(t07 + t08) +\
                        zeta_aop*zeta_bpo*(t09 + t10) + \
                        zeta_aop*zeta_bop*(t11 + t12) + \
                       (zeta_amo*zeta_bop+zeta_apo*zeta_bom)*(1-delta_ab)*(j-i) / (-2.)**(abs(j-i))*t13 +\
                       (zeta_anp*zeta_bpo+zeta_aop*zeta_bpn)*(1-delta_ab)*(j-i) / (-2.)**(abs(j-i))*t14
            # Save data in both positions
            C_matrix[3*a+i][3*b+j] = dr_daidbj
            C_matrix[3*b+j][3*a+i] = dr_daidbj
    return [B_row], [C_matrix]
#-----------------------------------------------#
def wilson_getBC(xcc,all_ics):
    numics = count_ics(all_ics)
    ics_st,ics_ab,ics_lb,ics_it,ics_pt = unmerge_ics(all_ics)
    # unit bond vectors
    natoms = howmanyatoms(xcc)
    bvecs  = wilson_bvecs(xcc)
    # initialize matrices
    wilsonB = [[0.0 for row in range(numics)] for col in range(3*natoms)]
    wilsonB, wilsonC = [], []
    # B and C: stretchings
    for atoms in ics_st:
        row_B, matrix_C = wilson_stretch(bvecs,atoms,natoms)
        wilsonB += row_B
        wilsonC += matrix_C
    # B and C: angular bendings
    for atoms in ics_ab:
        row_B, matrix_C = wilson_abend(bvecs,atoms,natoms)
        wilsonB += row_B
        wilsonC += matrix_C
    # B and C: linear  bendings
    for atoms in ics_lb:
        i,j,k = atoms
        r_m = np.array(xyz(xcc,i))
        r_o = np.array(xyz(xcc,j))
        r_n = np.array(xyz(xcc,k))
        row_B, matrix_C = wilson_lbend(r_m,r_o,r_n,atoms,natoms)
        wilsonB += row_B
        wilsonC += matrix_C
    # B and C: torsions (proper and improper)
    for atoms in ics_it+ics_pt:
        row_B, matrix_C = wilson_torsion(bvecs,atoms,natoms)
        wilsonB += row_B
        wilsonC += matrix_C
    return np.matrix(wilsonB), [np.matrix(ll) for ll in wilsonC]
#-----------------------------------------------#
def numericB(xcc,function,idxs):
    ''' requirement function: function(xcc,idxs) --> value '''
    epsilon = 1E-5
    B = []
    for idx in range(len(xcc)):
        xcc1   = list(xcc); xcc1[idx] -= epsilon
        value1 = function(xcc1,idxs)
        xcc2   = list(xcc); xcc2[idx] += epsilon
        value2 = function(xcc2,idxs)
        derivative = (value2-value1)/(2*epsilon)
        B.append(derivative)
    return B
#-----------------------------------------------#
def numericC(xcc,function,idxs):
    ''' requirement function: function(xcc,idxs) --> value '''
    epsilon = 1E-5
    value0 = function(xcc,idxs)
    C = [[0.0 for idx1 in range(len(xcc))] for idx2 in range(len(xcc))]
    for idxA in range(len(xcc)):
        # d2/dx2
        xcc1 = list(xcc); xcc1[idxA] += epsilon
        xcc2 = list(xcc); xcc2[idxA] -= epsilon
        value1 = function(xcc1,idxs)
        value2 = function(xcc2,idxs)
        derivative2 = (value1+value2-2*value0)/(epsilon**2)
        C[idxA][idxA] = derivative2
        # d2/dxdy
        for idxB in range(idxA+1,len(xcc)):
            xcc1   = list(xcc); xcc1[idxA] += epsilon; xcc1[idxB] += epsilon
            xcc2   = list(xcc); xcc2[idxA] += epsilon
            xcc3   = list(xcc);                        xcc3[idxB] += epsilon
            xcc4   = list(xcc); xcc4[idxA] -= epsilon
            xcc5   = list(xcc);                        xcc5[idxB] -= epsilon
            xcc6   = list(xcc); xcc6[idxA] -= epsilon; xcc6[idxB] -= epsilon

            value1 = function(xcc1,idxs)
            value2 = function(xcc2,idxs)
            value3 = function(xcc3,idxs)
            value4 = function(xcc4,idxs)
            value5 = function(xcc5,idxs)
            value6 = function(xcc6,idxs)
            
            derivative2 = (value1+2*value0+value6)-(value2+value3+value4+value5)
            derivative2 /= (2*epsilon*epsilon)
            C[idxA][idxB] = derivative2
            C[idxB][idxA] = derivative2

    return C
#-----------------------------------------------#
def wilson_getu(masses):
    '''
       masses: N
       u     : 3Nx3N
    '''
    natoms = len(masses)
    u = np.matrix(np.zeros((3*natoms,3*natoms)))
    for at in range(natoms):
        tt = 1.0/masses[at]
        ii,jj,kk = 3*at+0,3*at+1, 3*at+2
        u[ii,ii] = tt
        u[jj,jj] = tt
        u[kk,kk] = tt
    return u
#-----------------------------------------------#
def wilson_getG(u,B):
    '''
    B     : Fx3N
    G     : FxF
    -------------
    G L  = L Lambda
    G    = L Lambda L^T
    G^-1 = L^T^-1 Lambda^-1 L^-1 = L Lambda^-1 L^T
    -------------
    notice that
       L L^T = L^T L = I
    '''
    # Get G
    G = B*u*B.transpose()
    # Get also inverse
    #Ginv = np.linalg.inv(G) # not valid if singular
    # a) eigenvalues, eigenvectors
    Lambda, L = np.linalg.eigh(G)
    # b) reorder
    idxs = sorted([(abs(li),idx) for idx, li in enumerate(Lambda)])
    idxs = [idx for li,idx in idxs]
    Lambda = [Lambda[idx] for idx in idxs]
    L      = L[:,idxs]
    # Generalized inverse (not inverse of zero eigenvalues)
    G    = L * np.diag(Lambda) * L.transpose()
    Lambda_inv = [1.0/li if li > EPS_GIV else li for li in Lambda]
    Ginv = L * np.diag(Lambda_inv) * L.transpose()
    # return
    return G, Ginv
#-----------------------------------------------#
def wilson_gf_internal(u,B,C,Ginv,gcc,Fcc):
    nIC, n3N = B.shape
    if gcc.shape != (n3N,  1): exit("Wrong shape for gcc")
    if Fcc.shape != (n3N,n3N): exit("Wrong shape for Fcc")
    A = u * B.transpose() * Ginv
    g = A.transpose() * gcc
    f = A.transpose() * Fcc * A
    for i in range(nIC):
        f -=  float(g[i]) * A.transpose() * np.matrix(C[i]) * A
    return g, f, A
#-----------------------------------------------#
def wilson_gf_nonred(G,Ginv,g,f):
    nIC, nIC = G.shape
    if g.shape != (nIC,  1): exit("Wrong shape for g")
    if f.shape != (nIC,nIC): exit("Wrong shape for f")
    P   = G * Ginv
    gnr = P * g
    fnr = P * f * P
    return gnr, fnr
#-----------------------------------------------#
def wilson_prj_rc(gnr,fnr,G,nics):
    ''' project out the reaction coordinate'''
    I   = np.identity(nics)
    p   = gnr * gnr.transpose() / (gnr.transpose() * G * gnr)
    fnr = (I - p*G) * fnr * (I-G*p)
    return fnr
#-----------------------------------------------#
def wilson_evecsincart(L,G,A,masses):
    ''' evectors in cartesian (mass-scaled)'''
    nat = len(masses)
    n3N, nIC = A.shape
    # masses 3N
    m3N = [masses[at] for at in range(nat) for i in range(3)]
    # single value decomposition for L^-1
    u, s, v = np.linalg.svd(L,full_matrices=True,compute_uv=True)
    s_inv = np.diag([1.0/s_i if s_i > EPS_SVD else s_i for s_i in s])
    L_inv = v.transpose() * s_inv.transpose() * u.transpose()
    # Get C matrix
    C = L_inv * G * L_inv.transpose()
    # Get W
    W = np.zeros( C.shape,dtype=complex )
    for i in range(len(C)): W[i,i] = cmath.sqrt(C[i,i])
   #for i in range(len(C)): W[i,i] = np.sqrt(C[i,i])
    # Get chi
    chi = A * L * W
    # Get normal-mode eigenvectors in mass-scaled cartesian
    Lcc  = np.zeros( (3*nat,nIC) )
    for j in range(nIC):
        cocient = sum([m3N[k]*chi[k,j]**2 for k in range(n3N)])
        for i in range(n3N):
            Lcc[i,j] = (np.sqrt(m3N[i])*chi[i,j]/cocient).real
    return Lcc
#-----------------------------------------------#
def calc_icfreqs(Fcc,masses,xcc,gcc,all_ics,bool_prc=False):
    '''
    As described in J. Phys. Chem. A 1998, 102, 242-247
    bool_prc: project reaction coordinate?
    '''
    # some dimensions
    nat = len(masses)
    n3N = 3 * nat
    nIC = count_ics(all_ics)
    # number of vibrational degrees of freedom
    linear = islinear(xcc)
    if linear: nvdof = n3N - 5
    else     : nvdof = n3N - 6
    if bool_prc: nvdof -= 1
    # the reduced mass (1 amu)
    mu = 1.0/AMU
    # correct shapes:  gcc (3Nx1), Fcc (3Nx3N)
    if bool_prc: gcc = np.matrix(gcc).transpose()
    else       : gcc = np.matrix(np.zeros(n3N)).transpose()
    if len(Fcc) != 3*nat: Fcc = lowt2matrix(Fcc)
    Fcc = np.matrix(Fcc)
    # 1. Calculate B matrix and C^i tensor
    B, C = wilson_getBC(xcc,all_ics)
    # 2. Calculate G (of h in other paper) and Ginv
    u       = wilson_getu(masses)
    G, Ginv = wilson_getG(u,B)
    # 3. Calculate gradient and Hessian in rics
    g,f,A = wilson_gf_internal(u,B,C,Ginv,gcc,Fcc)
    # 4.1 Project to nrics
    gnr, fnr = wilson_gf_nonred(G,Ginv,g,f)
    # 4.2 Project reaction coordinate
    if bool_prc: fnr = wilson_prj_rc(gnr,fnr,G,nIC)
    # 5.1 Eigenvalues and eigenvectors
    Lambda, L = np.linalg.eig(G*fnr)
    # 5.2 Remove imaginary part and reorder
    Lambda  = [mu*li.real for li in Lambda]
    icfreqs = [eval2afreq(li,mu) for li in Lambda]
    # 6.1 Transform eigenvecs to mass-scaled Cartesians
    L = wilson_evecsincart(L,G,A,masses)
    # 6.2 save as a list of eigenvectors
    nr,nc = L.shape
    evecs = [L[:,idx].tolist() for idx in range(nc)]
    # 7.1 indices by abs value
    idxs    = sorted([(abs(fq),fq,idx) for idx, fq in enumerate(icfreqs)])
    idxs.reverse()
    # 7.2 keep only the biggest ones (up to the number of degrees of freedom)
    idxs = idxs[:nvdof]
    # 7.3 sort again, imaginary first, then from small to big
    idxs = sorted([(fq,idx) for fqabs,fq,idx in idxs])
    # 7.4 Remove the zero eigenvalues (freqs < 0.1 cm^-1)
    idxs = [(fq,idx) for fq,idx in idxs if abs(afreq2cm(fq)) > EPS_ICF ]
    # 7.5 Prepare lists
    idxs    = [idx for fq,idx in idxs]
    Lambda  = [Lambda[idx]                   for idx in idxs]
    icfreqs = [icfreqs[idx]                  for idx in idxs]
    evecs   = [evecs[idx]                    for idx in idxs]
    # return data
    return icfreqs, Lambda, evecs
#-----------------------------------------------#
def get_icmodes(Fcc,masses,xcc,gcc,all_ics,bool_prc=False):
    '''
    As described in J. Phys. Chem. A 1998, 102, 242-247
    bool_prc: project reaction coordinate?
    '''
    # some dimensions
    nat = len(masses)
    n3N = 3 * nat
    nIC = count_ics(all_ics)
    # number of vibrational degrees of freedom
    linear = islinear(xcc)
    if linear: nvdof = n3N - 5
    else     : nvdof = n3N - 6
    if bool_prc: nvdof -= 1
    # the reduced mass (1 amu)
    mu = 1.0/AMU
    # correct shapes:  gcc (3Nx1), Fcc (3Nx3N)
    if bool_prc: gcc = np.matrix(gcc).transpose()
    else       : gcc = np.matrix(np.zeros(n3N)).transpose()
    if len(Fcc) != 3*nat: Fcc = lowt2matrix(Fcc)
    Fcc = np.matrix(Fcc)
    # 1. Calculate B matrix and C^i tensor
    B, C = wilson_getBC(xcc,all_ics)
    # 2. Calculate G (of h in other paper) and Ginv
    u       = wilson_getu(masses)
    G, Ginv = wilson_getG(u,B)
    # 3. Calculate gradient and Hessian in rics
    g,f,A = wilson_gf_internal(u,B,C,Ginv,gcc,Fcc)
    # 4.1 Project to nrics
    gnr, fnr = wilson_gf_nonred(G,Ginv,g,f)
    # 4.2 Project reaction coordinate
    if bool_prc: fnr = wilson_prj_rc(gnr,fnr,G,nIC)
    # 5.1 Eigenvalues and eigenvectors
    Lambda, L = np.linalg.eig(G*fnr)
    # 5.2 Remove imaginary part and reorder
    Lambda  = [mu*li.real for li in Lambda]
    icfreqs = [eval2afreq(li,mu) for li in Lambda]
    return icfreqs, Lambda, L
#-----------------------------------------------#
def nonredundant(xcc,masses,gcc,Fcc,all_ics,ccfreqs,unremov=[],ncycles=None,extra=0):
    '''
    unremov: a list with those that cannot be removed
    '''
    mu  = 1.0 / AMU
    nvdof = len(ccfreqs)+extra
    # check number of ics
    nics  = count_ics(all_ics)
    # not enough internal
    if nics < nvdof: raise Exception
    # check they are valid
    try:
      icfreqs = calc_icfreqs(Fcc,masses,xcc,gcc,all_ics)[0]
      same = same_freqs(ccfreqs,icfreqs)
    except: same = False
    # a non-redundant set!
    if nics == nvdof or not same: return all_ics, same

    # depure
    count = -1
    original = list(all_ics)
    while True:
          count += 1
          # stop?
          if ncycles is not None and count == ncycles: break
          # select one ic
          target = random.choice(all_ics)
          if target in unremov: continue
          # remove it
          all_ics.remove(target)
          # calculate
          try:
             icfreqs = calc_icfreqs(Fcc,masses,xcc,gcc,all_ics)[0]
             # compare
             same = same_freqs(ccfreqs,icfreqs)
          except:
             same = False
          # not equal?
          if not same:
              all_ics += [target]
              unremov += [target]
              continue
          # update
          if count_ics(all_ics) <= nvdof : break
    # keep old order
    all_ics = [ic for ic in original if ic in all_ics]
    return all_ics, same
#-----------------------------------------------#
def get_dmatrix(xcc,masslist,nricoords,ntors=2):
    '''
    Get the D matrix for two torsions
    Last two torsions are the selected torsions
    '''

    natoms = round(len(xcc)/3 , 0)
    B_wilson, C_wilson = wilson_getBC(xcc,nricoords)
    mass_array = []
    for m in masslist: mass_array += [m,m,m]
    u = [ 1.0/mass for mass in mass_array]
    u = np.diag(u)

    # Calculate h matrix (h* in [3], cursive G in [4])
    h = B_wilson * u * B_wilson.transpose()

    # Calculate D matrix
    Dmatrix = np.linalg.inv(h)

    # Units of each element of Dmatrix is [distance]^2*[mass] (in a.u.)
    Dmatrix = Dmatrix[-ntors:,-ntors:]

    return Dmatrix
#-----------------------------------------------#

class Molecule():

      # Initialization method
      def __init__(self,label=None):

          self._label    = label

          # Unidimensional
          self._mform    = "-"
          self._mu       = None
          self._ch       = None
          self._mtp      = None
          self._V0       = None
          self._pgroup   = None
          self._rotsigma = None
          self._natoms   = None
          self._nel      = None # number of electrons
          self._rtype    = None
          self._linear   = None

          # Multi-dimensional
          self._atnums   = None
          self._symbols  = None
          self._masses   = None
          self._les      = None # list of electronic states
          self._itensor  = None
          self._imoms    = None
          self._rotTs    = None

          # Arrays of importance
          self._xcc      = None
          self._gcc      = None
          self._Fcc      = None
          self._xms      = None
          self._gms      = None
          self._Fms      = None

          # related to frequencies
          self._fscal    = 1.0
          self._nvdof    = None
          self._cczpe    = None
          self._ccfreqs  = None
          self._ccFevals = None
          self._ccFevecs = None
          self._iczpe    = None
          self._icfreqs  = None
          self._icFevals = None
          self._icFevecs = None

          # other stuff for very particular occasion
          self._gts      = None

      def __str__(self): return self._mform

      def setvar(self,xcc=None,gcc=None,Fcc=None,\
                      atonums=None,symbols=None,masses=None,\
                      ch=None,mtp=None, V0=None,\
                      pgroup=None,rotsigma=None,\
                      fscal=None,les=None):

          if xcc      is not None: self._xcc      = xcc
          if gcc      is not None: self._gcc      = gcc
          if Fcc      is not None: self._Fcc      = Fcc

          if atonums  is not None: self._atnums   = atonums
          if symbols  is not None: self._symbols  = symbols
          if masses   is not None: self._masses   = masses

          if ch       is not None: self._ch       = int(ch)
          if mtp      is not None: self._mtp      = int(mtp)
          if V0       is not None: self._V0       = V0

          if pgroup   is not None: self._pgroup   = pgroup
          if rotsigma is not None: self._rotsigma = rotsigma

          if fscal    is not None: self._fscal    = fscal
          if les      is not None: self._les      = les

      def genderivates(self):
          self._mform   = get_molformula(self._symbols)
          self._natoms  = len(self._atnums)
          self._mass    = sum(self._masses)
          self._nel     = sum(self._atnums)-self._ch
          if self._les is None: self._les = [ (self._mtp,0.0) ]

      def prepare(self):
          # check atnums
          if self._atnums is not None and type(self._atnums[0]) == str:
             self._symbols = list(self._atnums)
          # check symbols
          if self._symbols is not None and type(self._symbols[0]) == int:
             self._atnums  = list(self._symbols)
          # Get both atnums and symbols if None
          if self._atnums  is None: self._atnums  = symbols2atonums(self._symbols)
          if self._symbols is None: self._symbols = atonums2symbols(self._atnums)
          # check masses
          if self._masses is None:
             self._masses = atonums2masses(self._atnums)
          # derivated magnitudes
          self.genderivates()
          # check Fcc
          if self._Fcc not in (None,[]) and len(self._Fcc) != 3*self._natoms:
             self._Fcc = lowt2matrix(self._Fcc)

      def remove_frozen(self):
          frozen = detect_frozen(self._Fcc,self._natoms)
          if len(frozen) == 0: return [],[]
          # coordinates and symbols of frozen moiety
          bN   = [at in frozen for at in range(self._natoms)]
          b3N  = [at in frozen for at in range(self._natoms) for ii in range(3)]
          frozen_xcc     = np.array(self._xcc)[b3N]
          frozen_symbols = np.array(self._symbols)[bN]
          # now system is just the flexible moiety
          bN   = [at not in frozen for at in range(self._natoms)]
          b3N  = [at not in frozen for at in range(self._natoms) for ii in range(3)]
          self._xcc      = np.array(self._xcc)[b3N].tolist()
          self._symbols  = np.array(self._symbols)[bN].tolist()
          self._atnums   = np.array(self._atnums)[bN].tolist()
          self._masses   = np.array(self._masses)[bN].tolist()
          self._pgroup   = None
          self._rotsigma = None
          # Gradient and hessian
          if self._gcc is not None and len(self._gcc) != 0:
             self._gcc     = np.array(self._gcc)[b3N].tolist()
          if self._Fcc is not None and len(self._Fcc) != 0:
             n3 = self._natoms*3
             self._Fcc = [[self._Fcc[idx1][idx2] for idx1 in range(n3) if b3N[idx1]]\
                                                 for idx2 in range(n3) if b3N[idx2]]
          # set origin for frozen moiety
          com = get_com(self._xcc,self._masses)
          frozen_xcc = set_origin(frozen_xcc,com)
          # prepare system
          self.prepare()
          return frozen_xcc, frozen_symbols

      def mod_masses(self,masses):
          self._masses = list(masses)
          self._mass   = sum(self._masses)

      def setup(self,mu=1.0/AMU,projgrad=False):
          self._mu = mu
          # derivated magnitudes (again, in case sth was modified)
          # for example, when set from gts and masses are added latter
          self.genderivates()
          # shift to center of mass and reorientate molecule
          idata = (self._xcc,self._gcc,self._Fcc,self._masses)
          self._xcc, self._gcc, self._Fcc = center_and_orient(*idata)
          # Generate mass-scaled arrays
          self._xms = cc2ms_x(self._xcc,self._masses,self._mu)
          self._gms = cc2ms_g(self._gcc,self._masses,self._mu)
          self._Fms = cc2ms_F(self._Fcc,self._masses,self._mu)
          #-------------#
          # Atomic case #
          #-------------#
          if self._natoms == 1:
              self._nvdof    = 0
              self._linear   = False
             #self._xms      = list(self._xcc)
             #self._gms      = list(self._gcc)
             #self._Fms      = list(self._Fcc)
              self._ccfreqs  = []
              self._ccFevals = []
              self._ccFevecs = []
          #----------------#
          # Molecular case #
          #----------------#
          else:
             # Calculate inertia
             self._itensor = get_itensor_matrix(self._xcc,self._masses)
             self._imoms, self._rotTs, self._rtype, self._linear = \
                     get_itensor_evals(self._itensor)
             # Vibrational degrees of freedom
             if self._linear: self._nvdof = 3*self._natoms - 5
             else           : self._nvdof = 3*self._natoms - 6
             # calculate frequencies
             if self._Fcc is None        : return
             if len(self._Fcc) == 0      : return
             if self._ccfreqs is not None: return

             v0   = self._gms if projgrad else None
             data = calc_ccfreqs(self._Fcc,self._masses,self._xcc,self._mu,v0=v0)
             self._ccfreqs, self._ccFevals, self._ccFevecs = data
             # Scale frequencies
             self._ccfreqs = scale_freqs(self._ccfreqs,self._fscal)

      def get_imag_main_dir(self):
          ic, fwsign = ics_idir(self._xcc,self._symbols,\
                       self._masses,self._ccfreqs,self._ccFevecs)
          return ic, fwsign

      def icfreqs(self,ics,bool_pg=False):
          #----------------#
          # Molecular case #
          #----------------#
          if self._natoms != 1:
             ituple = (self._Fcc,self._masses,self._xcc,self._gcc,ics,bool_pg)
             self._icfreqs, self._icFevals, self._icFevecs = calc_icfreqs(*ituple)
          #-------------#
          # Atomic case #
          #-------------#
          else:
             self._icfreqs  = []
             self._icFevals = []
             self._icFevecs = []
          # scale frequencies
          self._icfreqs = [freq*self._fscal for freq in self._icfreqs]

      def ana_freqs(self,case="cc"):
          if case == "cc":
             # Keep record of imaginary frequencies
             if self._ccFevecs is not None:
                self._ccimag = [ (frq,self._ccFevecs[idx]) for idx,frq in enumerate(self._ccfreqs)\
                                 if frq < 0.0]
             else:
                self._ccimag = [ (frq,None)                for idx,frq in enumerate(self._ccfreqs)\
                                if frq < 0.0]
             # Calculate zpe
             self._cczpes = [afreq2zpe(frq) for frq in self._ccfreqs]
             self._cczpe  = sum(self._cczpes)
             self._ccV1   = self._V0 + self._cczpe
          if case == "ic":
             # Keep record of imaginary frequencies
             if self._icFevecs is not None:
                self._icimag = [ (frq,self._icFevecs[idx]) for idx,frq in enumerate(self._icfreqs)\
                                 if frq < 0.0]
             else:
                self._icimag = [ (frq,None)                for idx,frq in enumerate(self._icfreqs)\
                                if frq < 0.0]
             # Calculate zpe
             self._iczpes = [afreq2zpe(frq) for frq in self._icfreqs]
             self._iczpe  = sum(self._iczpes)
             self._icV1   = self._V0 + self._iczpe

      def clean_freqs(self,case="cc"):
          # select case
          if case == "cc": freqs = self._ccfreqs
          else           : freqs = self._icfreqs
          # keep track of those to save
          keep = []
          for idx,freq in enumerate(freqs):
              if abs(afreq2cm(freq)) < EPS_IC: continue
              keep.append(idx)
          # keep only those > EPS_IC
          if case == "cc":
             self._ccfreqs  = [self._ccfreqs[idx]  for idx in keep]
             if self._ccFevals is not None:
                self._ccFevals = [self._ccFevals[idx] for idx in keep]
             if self._ccFevecs is not None:
                self._ccFevecs = [self._ccFevecs[idx] for idx in keep]
          if case == "ic":
             self._icfreqs  = [self._icfreqs[idx]  for idx in keep]
             if self._icFevals is not None:
                self._icFevals = [self._icFevals[idx] for idx in keep]
             if self._icFevecs is not None:
                self._icFevecs = [self._icFevecs[idx] for idx in keep]

      def deal_lowfq(self,lowfq={},case="cc"):
          # for Cartesian Coordinates
          if   case == "cc":
             # frequencies were not projected along MEP
             if   self._nvdof - len(self._ccfreqs) == 0:
                for idx,newfreq in lowfq.items():
                    self._ccfreqs[idx] = max(self._ccfreqs[idx],newfreq)
             # frequencies were projected along MEP
             elif self._nvdof - len(self._ccfreqs) == 1:
                for idx,newfreq in lowfq.items():
                    self._ccfreqs[idx-1] = max(self._ccfreqs[idx-1],newfreq)
          # for Internal Coordinates
          elif case == "ic":
             # frequencies were not projected along MEP
             if   self._nvdof - len(self._icfreqs) == 0:
                for idx,newfreq in lowfq.items():
                    self._icfreqs[idx] = max(self._icfreqs[idx],newfreq)
             # frequencies were projected along MEP
             elif self._nvdof - len(self._icfreqs) == 1:
                for idx,newfreq in lowfq.items():
                    self._icfreqs[idx-1] = max(self._icfreqs[idx-1],newfreq)


      def info_string(self,ib=0):
          root_mass = sum(symbols2masses(self._symbols))
          string  = "Molecular formula     : %s\n"%self._mform
          string += "Number of atoms       : %i\n"%self._natoms
          string += "Number of electrons   : %i\n"%self._nel
          string += "Vibrational DOFs      : %i\n"%self._nvdof
          string += "Charge                : %i\n"%self._ch
          string += "Multiplicity          : %i\n"%self._mtp
          string += "Electronic energy (V0): %.8f hartree\n"%self._V0
          string += "Total mass [root]     : %.4f amu\n"%(root_mass *AMU)
          string += "Total mass            : %.4f amu\n"%(self._mass*AMU)
          if self._pgroup   is not None: string += "Point group symmetry  : %s\n"%(self._pgroup)
          if self._rotsigma is not None: string += "Rotational sym num    : %i\n"%(self._rotsigma)
          string += "Cartesian coordinates (Angstrom):\n"
          for at,symbol in enumerate(self._symbols):
              mass   = self._masses[at]*AMU
              x,y,z  = xyz(self._xcc,at)
              x *= ANGSTROM
              y *= ANGSTROM
              z *= ANGSTROM
              string += "  %2s   %+10.6f  %+10.6f  %+10.6f  [%7.3f amu]\n"%(symbol,x,y,z,mass)

          try:
              str2  = "Moments and product of inertia (au):\n"
              if len(self._imoms) == 1:
                 str2 += "        %+10.3E\n"%self._imoms[0]
              if len(self._imoms) == 3:
                 prodinert = self._imoms[0]*self._imoms[1]*self._imoms[2]
                 dataline = (self._imoms[0],self._imoms[1],self._imoms[2],prodinert)
                 str2 += "        %+10.3E  %+10.3E  %+10.3E  [%10.3E]\n"%dataline
              string += str2
          except: pass

          try:
              str2  = "Vibrational frequencies [1/cm] (scaled by %.3f):\n"%self._fscal
              for idx in range(0,len(self._ccfreqs),6):
                  str2 += "  %s\n"%("  ".join("%8.2f"%afreq2cm(freq) \
                                      for freq in self._ccfreqs[idx:idx+6]))
              if len(self._ccfreqs) != 0: string += str2
          except: pass

          try:
              str2  = "Vibrational zero-point energies [kcal/mol]:\n"
              for idx in range(0,len(self._cczpes),6):
                  str2 += "  %s\n"%("  ".join("%8.2f"%(zpe*KCALMOL) \
                                      for zpe in self._cczpes[idx:idx+6]))
              zpe_au   = self._cczpe
              zpe_kcal = self._cczpe * KCALMOL
              zpe_eV   = self._cczpe * EV
              zpe_cm   = self._cczpe * H2CM
              str2 += "Vibrational zero-point energy: %+14.8f hartree  = \n"%zpe_au
              str2 += "                               %+14.2f kcal/mol = \n"%zpe_kcal
              str2 += "                               %+14.2f eV       = \n"%zpe_eV
              str2 += "                               %+14.2f cm^-1 \n"%zpe_cm
              str2 += "V0 + zero-point energy (V1)  : %+14.8f hartree\n"%self._ccV1
              if self._cczpe != 0.0: string += str2
          except: pass

          # add blank spaces
          string = "\n".join([" "*ib+line for line in string.split("\n")])
          return string

      #=======================================#
      # Calculation of geometric parameters   #
      #=======================================#
      def dihedral(self,at1,at2,at3,at4):
          x1 = self._xcc[3*at1:3*at1+3]
          x2 = self._xcc[3*at2:3*at2+3]
          x3 = self._xcc[3*at3:3*at3+3]
          x4 = self._xcc[3*at4:3*at4+3]
          return dihedral(x1,x2,x3,x4)
      #=======================================#



############################################################
############################################################
############################################################
############################################################
############################################################


#================================#
def print_ics(ics):
    print("     num ics: %i"%len(ics))
    ics_st,ics_ab,ics_lb,ics_it,ics_pt = unmerge_ics(ics)
    for ics_i in (ics_st,ics_ab,ics_lb,ics_it,ics_pt):
        for idx in range(0,len(ics_i),6):
            line = ""
            for icatoms in ics_i[idx:idx+6]:
                sic = "-".join([str(atom+1) for atom in icatoms])
                line += sic+"  "
            print("     "+line)
#--------------------------------#
def print_freqs(ccfreqs,icfreqs):
    count = 0
    for ccf,icf in zip(ccfreqs,icfreqs):
        count += 1
        ccf = get_sfreq(ccf)
        icf = get_sfreq(icf)
        print("    (%2i) %s   %s   (cm^-1)"%(count,ccf,icf))
    print()
#--------------------------------#
def print_row(dd):
    print(" ".join(["%7.4f"%di for di in dd]))
#--------------------------------#
def print_analysis(icfreqs,ics,L2,nvdof_ps):
    NEPL = 6
    for idx0 in range(0,len(icfreqs),NEPL):
        line0 = " %10s "%"int.coord."
        for icfreq in icfreqs[idx0:idx0+NEPL]:
            line0 += "| %8.2f "%afreq2cm(icfreq)
        print("-"*len(line0))
        print(line0)
        print("-"*len(line0))
        nn = len(icfreqs[idx0:idx0+NEPL])
        weights = [0.0 for ii in range(nn)]
        for idx1,(ictype,icatoms) in enumerate(ics):
            if icatoms is not None: sic = "-".join(["%i"%(at+1) for at in icatoms])
            else: sic = ictype
            line = " %10s "%sic
            count = 0
            for idx2 in range(idx0,idx0+NEPL):
                if idx2+1 > len(L2[idx1]): continue
                line += "| %8.3f "%L2[idx1][idx2]
                if idx1 >= nvdof_ps: weights[count] += L2[idx1][idx2]
                count += 1
            print(line)
        print("-"*len(line0))
        lineN = " %10s "%"weight:"
        for weight in weights: lineN += "| %8.3f "%weight
        print(lineN)
        print("-"*len(line0))
        print("")
        print("")
#================================#


#================================#
def read_input(fname):
    frst, fts = None, None
    fp1 , fp2 = None, None
    dp1 , dp2 = None, None
    # read lines
    with open(fname,'r') as asdf: lines = asdf.readlines()
    # get data
    lines = [line.split("#")[0].strip() for line in lines]
    bool_dr  = False
    bool_dp1 = False
    bool_dp2 = False
    for line in lines:
        if line == "": continue
        if line.startswith("file_rst")     : frst = line.split()[1]; continue
        if line.startswith("file_product1"): fp1  = line.split()[1]; continue
        if line.startswith("file_product2"): fp2  = line.split()[1]; continue
        if line.startswith("file_saddle"  ): fts  = line.split()[1]; continue
        if line.startswith("startnum_product1"): bool_dp1 = True ; continue
        if line.startswith("endnum_product1"  ): bool_dp1 = False; continue
        if line.startswith("startnum_product2"): bool_dp2 = True ; continue
        if line.startswith("endnum_product2"  ): bool_dp2 = False; continue
        # correlation between atoms
        if bool_dp1:
           if dp1 is None: dp1 = {}
           atA, atB = line.split()
           dp1[int(atA)-1] = int(atB)-1
        if bool_dp2:
           if dp2 is None: dp2 = {}
           atA, atB = line.split();
           dp2[int(atA)-1] = int(atB)-1
    return fp1,fp2,fts,frst,dp1,dp2
#--------------------------------#
def get_sfreq(freq):
    return "%8.1f"%(afreq2cm(freq))
#--------------------------------#
def ics2tsnum(ics,dp):
    ics_renum = []
    for ictype,icatoms in ics:
        icatoms = [dp[atom] for atom in icatoms]
        ics_renum.append( (ictype,tuple(icatoms)) )
    return ics_renum
#--------------------------------#
def get_molecule(log):
    print("==> %s\n"%log)
    xcc, atonums, ch, mtp, V0, gcc, Fcc, atomasses, level = read_gauout(log)
    mol = Molecule()
    mol.setvar(xcc=xcc)
    mol.setvar(gcc=gcc)
    mol.setvar(Fcc=Fcc)
    mol.setvar(atonums=atonums)
    mol.setvar(ch=ch)
    mol.setvar(mtp=mtp)
    mol.setvar(V0=V0)
    mol.prepare()
    mol.setup()
    return mol
#--------------------------------#
def get_ics(mol,dp=None):
    # Get internal coordinates
    ics = ics_from_geom(mol._xcc,mol._symbols,scale=1.3)
    # assert they are valid
    mol.icfreqs(ics)
    same = same_freqs(mol._ccfreqs,mol._icfreqs)
    if not same:
       print("FAIL! Unable to find valid set of internal coordinates...")
       raise Exception
    # Depure them if possible
    ics2 = ics_depure(ics)
    mol.icfreqs(ics2)
    same = same_freqs(mol._ccfreqs,mol._icfreqs)
    if same: ics = ics2
    # non-redundant
    args = (mol._xcc,mol._masses,mol._gcc,mol._Fcc,ics,mol._ccfreqs)
    ics2, same = nonredundant(*args)
    if same:
       print("    * Non-redundant set FOUND")
       ics = ics2
    else:
       print("    * Non-redundant set NOT FOUND")
    # all with TS numeration
    if dp is not None:
       final_ics = []
       for ictype,icatoms in ics:
           icatoms = tuple([dp[at] for at in icatoms])
           final_ics.append( (ictype,icatoms) )
    else:
       final_ics = ics
    # print
    print_ics(final_ics)
    print("")
    # return data
    return final_ics
#--------------------------------#
def center_and_orient_fragment(xcc_all,fragment):
    xcc = []
    for at in fragment: xcc += xcc_all[3*at:3*at+3]
    # number of atoms?
    nats = len(xcc) // 3
    if nats == 1: return xcc, None
    # in center
    centroid = get_centroid(xcc)
    xcc      = set_origin(xcc,centroid)
    # Is it linear?
    itensor = get_itensor_matrix(xcc,[1.0 for at in range(nats)])
    evalsI, rotTs, rtype, linear = get_itensor_evals(itensor)
    if not linear: return xcc, None
    # Get moments and axis of inertia
    itensor = np.matrix(itensor)
    evalsI, evecsI = np.linalg.eigh(itensor)
    evecsI = np.matrix(evecsI)
    # Rotation matrix 3N x 3N
    zeros = np.zeros((3, 3))
    R= []
    for at in range(nats):
        row = []
        count = 0
        while count < at:
              row.append(zeros)
              count += 1
        row.append(evecsI)
        while count < nats-1:
              row.append(zeros)
              count += 1
        R.append(row)
    R = np.matrix(np.block(R))
    # Rotate coordinates
    xcc = np.matrix(xcc) * R
    xcc = xcc.tolist()[0]
    # Rotate gradient
    return xcc, R
#--------------------------------#
def trans_rot_vectors(xcc,fragment):
    nat  = len(xcc) // 3
    # translation
    b1 = np.zeros(len(xcc))
    b2 = np.zeros(len(xcc))
    b3 = np.zeros(len(xcc))
    for atom in fragment:
        b1[3*atom+0] = 1
        b2[3*atom+1] = 1
        b3[3*atom+2] = 1
    b1 /= np.linalg.norm(b1)
    b2 /= np.linalg.norm(b2)
    b3 /= np.linalg.norm(b3)
    vecs = [list(b1),list(b2),list(b3)]
    # rotation
    if len(fragment) != 1:
       xcc2, R = center_and_orient_fragment(xcc,fragment)
       nat2 = len(xcc2)//3
       b4 = np.zeros(len(xcc2))
       b5 = np.zeros(len(xcc2))
       b6 = np.zeros(len(xcc2))
       for atom in range(nat2):
           b4[3*atom + 1] =   z(xcc2,atom)
           b4[3*atom + 2] = - y(xcc2,atom)
           b5[3*atom + 0] = - z(xcc2,atom)
           b5[3*atom + 2] =   x(xcc2,atom)
           b6[3*atom + 0] =   y(xcc2,atom)
           b6[3*atom + 1] = - x(xcc2,atom)
       # save them
       for bi in (b4,b5,b6):
           norm_i = np.linalg.norm(bi)
           if norm_i < 1e-7: continue
           bi = bi / norm_i
           # in original frame
           if R is not None: bi = (bi*R.transpose()).tolist()[0]
           # complete with all atoms
           bj = [0.0 for at in range(nat) for coord in range(3)]
           for idx1,idx2 in zip(range(nat2),fragment):
               bj[3*idx2+0] = bi[3*idx1+0]
               bj[3*idx2+1] = bi[3*idx1+1]
               bj[3*idx2+2] = bi[3*idx1+2]
           vecs.append(bj)
    return np.matrix(vecs)
#--------------------------------#
def aux_distx(xcc,idxs):
    dxx = sum( [xcc[3*idx+0] for idx in idxs] )
    return dxx
#--------------------------------#
def aux_disty(xcc,idxs):
    dxx = sum( [xcc[3*idx+1] for idx in idxs] )
    return dxx
#--------------------------------#
def aux_distz(xcc,idxs):
    dxx = sum( [xcc[3*idx+2] for idx in idxs] )
    return dxx
#--------------------------------#
def aux_minertiax(xcc,idxs):
    # center of mass
    xcc2 = []
    for at in idxs: xcc2 += xcc[3*at:3*at+3]
    # number of atoms?
    centroid = get_centroid(xcc2)
    xcc2     = set_origin(xcc2,centroid)
    # Get moment of inertia for x-axis
    inertia = 0.0
    for idx in range(len(idxs)):
        xi,yi,zi = xcc2[3*idx:3*idx+3]
        inertia += yi**2 + zi**2
    return inertia
#--------------------------------#
def numC_rotx(natoms):
    C = [[0.0 for idx1 in range(3*natoms)] for idx2 in range(3*natoms)]
    for at in range(natoms):
        for idx in range(3):
            if idx == 1: C[idx*at][3*at+2] = -1
            if idx == 2: C[idx*at][3*at+1] = +1
#--------------------------------#
def get_wilson(xcc,all_ics):
    # some dimensions
    n3N = len(xcc)
    nIC = count_ics(all_ics)
    # number of vibrational degrees of freedom
    linear = islinear(xcc)
    if linear: nvdof = n3N - 5
    else     : nvdof = n3N - 6
    # prepare ics
    # Calculate B matrix and C^i tensor
    B, C = wilson_getBC(xcc,all_ics)
    ictype,icatoms = all_ics[0]
    return B,C, all_ics
#--------------------------------#
def get_icmodes(xcc,gcc,Fcc,B,C,masses,sval=0.0):
    n3N = len(xcc)
    nIC = len(C[0])
    # the reduced mass (1 amu)
    mu = 1.0/AMU
    # gradient
#   gcc = np.matrix(np.zeros(n3N)).transpose()
    gcc = np.matrix(gcc).transpose()
    # hessian
    if len(Fcc) != n3N: Fcc = lowt2matrix(Fcc)
    Fcc = np.matrix(Fcc)
    # 2. Calculate G (of h in other paper) and Ginv
    u       = wilson_getu(masses)
    G, Ginv = wilson_getG(u,B)
    # 3. Calculate gradient and Hessian in rics
    A = u * B.transpose() * Ginv
    g = A.transpose() * gcc
    f = A.transpose() * Fcc * A
    for i in range(nIC):
        f -=  float(g[i]) * A.transpose() * np.matrix(C[i]) * A
    # 4.1 Project to nrics
    gnr, fnr = wilson_gf_nonred(G,Ginv,g,f)
    # 4.2 Project reaction coordinate
    #if sval != 0.0: fnr = wilson_prj_rc(gnr,fnr,G,nIC)
    # 5.1 Eigenvalues and eigenvectors
    Lambda, L = np.linalg.eig(G*fnr)
    # 5.2 Remove imaginary part and reorder
    Lambda  = [mu*li.real for li in Lambda]
    icfreqs = [eval2afreq(li,mu) for li in Lambda]
    return icfreqs, Lambda, L
#--------------------------------#
def exclude(ts,ics1,ics2,atoms_p1,atoms_p2,nvdof,sval=0.0):
    print("    * Initial set of internal coordinates for TS:")
    print("")
    ics_st,ics_ab,ics_lb,ics_it,ics_pt = unmerge_ics(ics1+ics2)
    ics = merge_ics(ics_st,ics_ab,ics_lb,ics_it,ics_pt)
    B,C,ics = get_wilson(ts._xcc,ics)
    print_ics(ics)
    print("")

    # Get B matrix considering translations and rotations of fragments
    trarot1  = trans_rot_vectors(ts._xcc,atoms_p1)
    ntrarot1 = len(trarot1)
    ics  += [("trx1",None),("try1",None),("try1",None)]
    if len(atoms_p1) != 1:
       ics  += [("rotA1",None),("rotB1",None)]
       if ntrarot1 == 6: ics  += [("rotC1",None)]

    trarot2  = trans_rot_vectors(ts._xcc,atoms_p2)
    ntrarot2 = len(trarot2)
    ics  += [("trx2",None),("try2",None),("try2",None)]
    if len(atoms_p2) != 1:
       ics  += [("rotA2",None),("rotB2",None)]
       if ntrarot2 == 6: ics  += [("rotC2",None)]

    ntrarot  = ntrarot1+ntrarot2
    print("    * Adding translations and rotations of individual fragments:")
    print("      num(tra-rot,P1) = %i"%ntrarot1)
    print("      num(tra-rot,P2) = %i"%ntrarot2)
    print("")

    # Final B matrix
    Bfinal  = np.matrix(B.tolist()+trarot1.tolist()+trarot2.tolist())
    # Final C matrix
    nrows,ncols = C[0].shape
    for i in range(ntrarot): C.append( np.matrix(np.zeros((nrows,ncols))) )

    # Get frequencies in internal coordinates
    icfreqs, Lambda, L = get_icmodes(ts._xcc,ts._gcc,ts._Fcc,Bfinal,C,ts._masses,sval)
    # Exclude overall rotations and translations
    L = L.transpose().tolist()
    data_ic = []
    for idx in range(len(icfreqs)):
        icfreq   = icfreqs[idx]
        evalue   = Lambda[idx]
        Li       = L[idx]
        icsquare = icfreq ** 2
        data_ic.append( (icsquare,icfreq,evalue,Li) )
    data_ic.sort()
    data_ic = data_ic[-nvdof:]
    return ics, data_ic, ntrarot
#--------------------------------#
def get_freqs(fp1,fp2,fts,frst,dp1,dp2):

    # Check set for each case
    atoms_p1 = list(dp1.values())
    atoms_p2 = list(dp2.values())
    N1 = len(atoms_p1)
    N2 = len(atoms_p2)
    N  = N1+N2

    # Get Molecule instances
    p1   = get_molecule(fp1)
    if p1._natoms != 1: ics1 = get_ics(p1,dp1)
    else              : ics1 = []
    p2   = get_molecule(fp2)
    if p2._natoms != 1: ics2 = get_ics(p2,dp2)
    else              : ics2 = []

    ts   = get_molecule(fts)

    nvdof_ps = p1._nvdof + p2._nvdof
    nvdof_ts = ts._nvdof
    nexcluded = nvdof_ts-nvdof_ps
    print("      N.V.D.O.F.(products) = %i"%nvdof_ps)
    print("      N.V.D.O.F.( saddle ) = %i"%nvdof_ts)
    print("")

    # Prepare internal coordinates
    nvdof   = len(ts._ccfreqs)
    ics, data_ic, ntrarot = exclude(ts,ics1,ics2,atoms_p1,atoms_p2,nvdof)

    # Sort again so imaginary is the firt one
    data_ic.sort(key = lambda asdf:asdf[1])
    icfreqs = [icfreq for icfreq2,icfreq,evalue,Lm in data_ic]
    same = same_freqs(ts._ccfreqs,icfreqs)
    print_freqs(ts._ccfreqs,icfreqs)
    if same: print("    * SET IS VALID!!!\n")
    else   : print("    * SET IS NOT VALID!!!\n"); raise Exception

    print("    * Analyzing modes...")
    L2 = [[Lm_i**2 for Lm_i in Lm]  for icfreq2,icfreq,evalue,Lm in data_ic]
    L2 = np.matrix(L2).transpose().tolist()

    # print table with analysis of each mode
    print_analysis(icfreqs,ics,L2,nvdof_ps)

    excluded = []
    imag = None
    for icfreq2,icfreq,evalue,Lm in data_ic:
        weight = sum([Lm_i**2 for Lm_i in Lm[-ntrarot:]])
        if icfreq >= 0.0: excluded.append( (weight,icfreq) )
        else            : imag = (weight,icfreq)
    print("TRA-ROT IN PRODS:")
    excluded.sort(reverse = True)
    excluded = [imag] + excluded
    count = 0
    for idx,(weight,icfreq) in enumerate(excluded):
        count += 1
        print("   %8s  -- prob = %.3f"%(get_sfreq(icfreq),weight))
        if count == nexcluded:
           print("")
           print("VIBR IN PRODS:")
    print("")
    return excluded[:nexcluded]
#================================#

if __name__ == '__main__':

    args = sys.argv[1:]
    if len(args) == 0:
       print("no filename given!")
       exit()
    elif len(args) == 1: fname = sys.argv[1]
    elif len(args) == 2: fname = sys.argv[1]; EPS_CCIC = float(sys.argv[2])
    else: exit()
    print("Filename: %s"%fname)
    if not os.path.exists(fname):
       print("   - file not found!")
       exit()
    print("Comparison threshold for freqs: %.3f 1/cm"%EPS_CCIC)
    print()
    try:
      fp1,fp2,fts,frst,dp1,dp2 = read_input(fname)
      excluded = get_freqs(fp1,fp2,fts,frst,dp1,dp2)
    except:
      print("Something went wrong...")

