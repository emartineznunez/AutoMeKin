#!/usr/bin/env python3 
import sys
import numpy as np
from scipy.signal import butter, filtfilt 
from statistics import mean,stdev

def butter_lowpass(cutoff, fs, order=5):
    nyq = 0.5 * fs
    normal_cutoff = cutoff / nyq
    b, a = butter(order, normal_cutoff, btype='low', analog=False)
    return b, a

def butter_lowpass_filter(data, cutoff, fs, order=5):
    b, a = butter_lowpass(cutoff, fs, order=order)
    padlen = 3 * max(len(a), len(b))
    if len(data) > padlen: 
       y = filtfilt(b, a, data)
    else:
       y = data
    return y

natom  = int(sys.argv[1])
cutoff = float(sys.argv[2])
stdf   = float(sys.argv[3])
flag   = str(sys.argv[4])
#natom  = 5
#cutoff = 100
#stdf   = 2 
#number of steps to take the initial and final bonds orders
nsteps = 200
#minimum value that a bond order needs to change to consider it
mindiffbo = 0.1
# Filter requirements.
c = 2.99792458 / 10 ** 5 # cm / fs
order = 6
fs = 1               # fs-1 
cutoff = cutoff * c  # fs-1 
ndista = int(natom * (natom - 1) / 2)
nframe = 0
one  = ' 1 '
zero = ' 0 '
ind = []
jnd = []
for i in range(natom):
   for j in range(i+1,natom):
      ind.append(i+1)
      jnd.append(j+1)

data = []
inp = open('coordir/'+flag+'.bo', 'r')
for line in inp:
   nframe+=1
   darray = []
   for i in range(ndista):
      darray.append( float(line.split()[i]) )
   data.append(darray)
y = []
for i in range(ndista):
    d = []
    for j in range(nframe):
       d.append(data[j][i])
    y.append( butter_lowpass_filter(d,cutoff,fs,order) )

#out  = open('bo','w')
#outd = open('dbo','w')
derivarray = []
for i in range(nframe):
   darray = []
   for j in range(ndista):
      if i == 0: 
         deriv = ( y[j][i+1] - y[j][i] ) 
      elif i == nframe-1:
         deriv = ( y[j][i] - y[j][i-1] ) 
      else:
         deriv = ( y[j][i+1] - y[j][i-1] ) / 2 
      darray.append(deriv)
#      if j < ndista-1:
#         out.write(str(y[j][i])+' ')
#         outd.write(str(deriv)+' ')
#      else:
#         out.write(str(y[j][i])+'\n')
#         outd.write(str(deriv)+'\n')
   derivarray.append(darray) 

av = []
sd = []
diffbo = []
for i in range(ndista):
   deriv = []
   ibo = 0
   fbo = 0
   for j in range(nframe):
      deriv.append(derivarray[j][i])   
      if j < nsteps:
         ibo += y[i][j]
      if j >= (nframe-nsteps):
         fbo += y[i][j]
   av.append(mean(deriv))
   sd.append(stdev(deriv))
   diffbo.append( np.sqrt( (ibo - fbo) ** 2 ) / nsteps)
#sum of all derivatives with peaks greater than stdf * sdtm
#stdfile = open('stds', 'w')
#for i in range(ndista):
#   stdfile.write(str(sd[i])+'\n')
stdm=mean(sd)
#stdfile.write('Mean of the stdevs = '+str(stdm))

derivsold = 0
rxncoord = []
maxval = 0
npath = 0
tsl = []
rxncoordn = []
for i in range(nframe):
   derivs = 0
   if derivsold == 0:
       if len(rxncoord) > 0:
          npath += 1 
          tsl.append(ts)
          rxncoord.sort()
          rxncoordn.append(rxncoord)
       rxncoord = []
       maxval = 0
   for j in range(ndista):
      valued = abs( derivarray[i][j] )
      value = diffbo[j]
      if valued > stdf * sd[j] and valued > stdf * stdm and value > mindiffbo:
         if ind[j] not in rxncoord:
            rxncoord.append(ind[j])
         if jnd[j] not in rxncoord:
            rxncoord.append(jnd[j])
         derivs += valued
         if derivs > maxval:
            maxval = derivs
            ts = i + 1
   derivsold = derivs       
print('  Number of paths ',npath) 
with open ('coordir/'+flag+'.xyz') as f:
   lines = f.readlines()
for i in range(npath):
   part = open('partial_opt/fort.'+str(i+1),'w')
   print('  Path=   ',i+1,' Step=',tsl[i],' Atoms involved=  ',*rxncoordn[i])
   frame = 0
   for n,line in enumerate(lines):
      if len(line.split()) == 1: 
         frame += 1
         if frame == tsl[i]:
            s = [  str(line.split()[0]) for line in lines[n + 2: n + 2 + natom] ]  
            x = [float(line.split()[1]) for line in lines[n + 2: n + 2 + natom] ]   
            y = [float(line.split()[2]) for line in lines[n + 2: n + 2 + natom] ]   
            z = [float(line.split()[3]) for line in lines[n + 2: n + 2 + natom] ]          
   for atom in range(natom):
      atomp1 = atom + 1
      if atomp1 in rxncoordn[i]:
         tag = zero
      else:
         tag = one
      part.write(s[atom]+' '+str(x[atom])+tag+str(y[atom])+tag+str(z[atom])+tag+'\n')

print("  *+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*\n")
