#!/usr/bin/env python3
from subprocess import run,PIPE
from sys import argv
import numpy as np
import json

def Qcore_calc(CalcType):
    p = run(['qcore','-n','1','-f','json',CalcType],stdout=PIPE, stderr=PIPE, universal_newlines=True)
    properties = ['energy','gradient','frequencies','normal_modes','gibbs_free_energy','zero_point_energy','charges']
    values = []
    if len(p.stdout) > 0:
        if 'pop' in json.loads(p.stdout): z = {**json.loads(p.stdout)['my_result'] , **json.loads(p.stdout)['pop']}
        else: z = json.loads(p.stdout)['my_result']
        for x in properties: 
            if x in z:
                if x == 'normal_modes':
                    imag = np.array(z[x][0])
                    values.append( imag / np.linalg.norm(imag) )
                else:
                    values.append( np.array(z[x]) )
            else:
                values.append(np.zeros(1))
    else:
        print(p.stderr)
        exit()
    return values 

if __name__ == '__main__':
    e, grad, freq, imag_nm, gibbs, zpe, charges = Qcore_calc(argv[1])
    print("Energy=",e)
    if len(grad) >1: 
        print("Gradient:")
        for atom in grad:
            for x in atom: print(x)
    if len(freq) >0: 
        print("Freq:")
        for x in freq: print(x * 219474.6552)
    if len(imag_nm) > 1:
        print("Lowest normal mode:")
        for x in imag_nm: print(x)
    print("Gibbs free energy:",gibbs)
    print("ZPE:",zpe)
    if len(charges) > 1:
        print("Charges:")
        for x in charges: print(x)
    if 'thermo' in argv[1]: print("== QCORE DONE ==")
