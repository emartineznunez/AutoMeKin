#!/usr/bin/env python3
import numpy as np
from sys import argv

'''
Emax from temp
'''
            
#opt_start is the optimized initial structure
temp  = float(argv[1])

E = int(0.064 * temp + 0.002 * temp * np.log(temp))

print(max(E,100))
