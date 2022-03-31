#!/usr/bin/env python3

"""
This script reduces the list of elementary steps in the LL tslist. 
In particular, it removes PROD <--> PROD reactions and MIN i <---> MIN i reactions.
Also, and this is optional, it removes elementary steps with DE or DG values larger than that specified 
as a second (optional) argument of this script (value, see below).

Execution of this script:
reduce_tslist.py molecule value

The first argument, molecule, is the name of the system (case sensitive).

Procedure:   1. cp tslist tslist_complete
             2. Select from tslist_complete the desired elementary steps and copy them to a new tslist 
"""

import os
import sys

molecule = str(sys.argv[1])

LL_dir = 'tsdirLL_' + molecule + '/'

tslist_file = LL_dir + 'tslist'
tslist_complete_file = tslist_file + '_complete'

if os.path.isfile(tslist_file):
   copiar = 'cp ' + tslist_file + ' ' + tslist_file + '_complete'
   os.system(copiar)
else:
   sys.exit(' In reduce_tslist.py: file tslist does not exist')

arg = False
if sys.argv[2:]:
   arg = float(sys.argv[2])

reaction = {}

# Select elementary steps from RXNet file
RXNet_file = LL_dir + 'KMC/RXNet'
if not os.path.isfile(RXNet_file): sys.exit(' In reduce_tslist.py: file RXNet does not exist')
RXNet = open(RXNet_file, 'r')
for line in RXNet:
    columns = line.split()
    if str(columns[0]) == 'TS':
       name = str(columns[2])[:-5]
       if str(columns[6]) == 'PROD' and str(columns[9]) == 'PROD': reaction[name] = False    
       elif str(columns[6]) == str(columns[9]) and int(columns[7]) == int(columns[10]): reaction[name] = False
       elif arg:
            if arg < float(columns[4]): reaction[name] = False
            else: reaction[name] = True
       else: reaction[name] = True
RXNet.close()

# Copy selected elementary steps from tslist_complete to a new tslist
new = open(tslist_file, 'w')
old = open(tslist_complete_file, 'r')

for line in old:
    columns = line.split()
    name = str(columns[2])
    if name not in reaction: new.write(line)
    else:
        if reaction[name]: new.write(line)

old.close()
new.close()

