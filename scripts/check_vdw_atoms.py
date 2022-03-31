#!/usr/bin/env python3
import sys
from ase.io import read
from AMK_parameters import vdw_rad

rmol  = read(str(sys.argv[1])+'.xyz')

for lab in rmol.get_chemical_symbols():
   if lab in vdw_rad.keys(): ok = 1
   else: ok = 0
print(ok)
