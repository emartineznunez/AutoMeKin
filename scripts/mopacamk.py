"""This module defines an ASE interface to MOPAC.

Set $ASE_MOPAC_COMMAND to something like::

    LD_LIBRARY_PATH=/path/to/lib/ \
    MOPAC_LICENSE=/path/to/license \
    /path/to/MOPAC2012.exe PREFIX.mop 2> /dev/null

"""
import os

import numpy as np
import re
import math

from ase import Atoms
from ase.calculators.calculator import FileIOCalculator, ReadError, Parameters
from ase.units import kcal, mol, Debye


class MOPACamk(FileIOCalculator):
    implemented_properties = ['energy', 'forces', 'dipole', 'magmom']
    _legacy_default_command = 'mopac PREFIX.mop 2> /dev/null'
    command = 'mopac PREFIX.mop 2> /dev/null'
    discard_results_on_any_change = True

    default_parameters = dict(
        method='PM7',
        task='1SCF GRADIENTS',
        freq=False,
        relscf=1)

    methods = ['AM1', 'MNDO', 'MNDOD', 'PM3', 'PM6', 'PM6-D3', 'PM6-DH+',
               'PM6-DH2', 'PM6-DH2X', 'PM6-D3H4', 'PM6-D3H4X', 'PMEP', 'PM7',
               'PM7-TS', 'RM1']

    def __init__(self, restart=None, 
                 ignore_bad_restart_file=FileIOCalculator._deprecated,
                 label='mopac', atoms=None, **kwargs):
        """Construct MOPAC-calculator object.

        Parameters:

        label: str
            Prefix for filenames (label.mop, label.out, ...)

        Examples:

        Use default values to do a single SCF calculation and print
        the forces (task='1SCF GRADIENTS'):

        >>> from ase.build import molecule
        >>> from ase.calculators.mopac import MOPAC
        >>> atoms = molecule('O2')
        >>> atoms.calc = MOPAC(label='O2')
        >>> atoms.get_potential_energy()
        >>> eigs = atoms.calc.get_eigenvalues()
        >>> somos = atoms.calc.get_somo_levels()
        >>> homo, lumo = atoms.calc.get_homo_lumo_levels()

        Use the internal geometry optimization of Mopac:

        >>> atoms = molecule('H2')
        >>> atoms.calc = MOPAC(label='H2', task='GRADIENTS')
        >>> atoms.get_potential_energy()

        Read in and start from output file:

        >>> atoms = MOPAC.read_atoms('H2')
        >>> atoms.calc.get_homo_lumo_levels()

        """
        FileIOCalculator.__init__(self, restart, ignore_bad_restart_file,
                                  label, atoms, **kwargs)

#    def set(self, **kwargs):
#        changed_parameters = FileIOCalculator.set(self, **kwargs)
#        if changed_parameters:
#            self.reset()

    def write_input(self, atoms, properties=None, system_changes=None):
        FileIOCalculator.write_input(self, atoms, properties, system_changes)

        p = self.parameters
        if p.freq:
           end = '\nforce threads=1 oldgeo oldens '+p.method
        else:
           end=''
         
        # Build string to hold .mop input file:
        s = p.method + ' ' + p.task + ' '

        if p.relscf:
            s += 'RELSCF={0} '.format(p.relscf)

        # Write charge:
        charge = atoms.get_initial_charges().sum()
        if charge != 0:
            s += 'CHARGE={0} '.format(int(round(charge)))

        magmom = int(round(abs(atoms.get_initial_magnetic_moments().sum())))
        if magmom:
            s += (['DOUBLET', 'TRIPLET', 'QUARTET', 'QUINTET'][magmom - 1] +
                  ' UHF ')

        s += '\nTitle: ASE calculation\n\n'

        # Write coordinates:
        for xyz, symbol in zip(atoms.positions, atoms.get_chemical_symbols()):
            s += ' {0:2} {1} 1 {2} 1 {3} 1\n'.format(symbol, *xyz)

        for v, p in zip(atoms.cell, atoms.pbc):
            if p:
                s += 'Tv {0} {1} {2}\n'.format(*v)

        s += end
        with open(self.label + '.mop', 'w') as f:
            f.write(s)

    def get_spin_polarized(self):
        return self.nspins == 2

    def get_index(self, lines, pattern):
        for i, line in enumerate(lines):
            if line.find(pattern) != -1:
                return i

    def read(self, label):
        FileIOCalculator.read(self, label)
        if not os.path.isfile(self.label + '.out'):
            raise ReadError

        with open(self.label + '.out') as f:
            lines = f.readlines()

        self.parameters = Parameters(task='', method='')
        p = self.parameters
        parm_line = self.read_parameters_from_file(lines)
        for keyword in parm_line.split():
            if 'RELSCF' in keyword:
                p.relscf = float(keyword.split('=')[-1])
            elif keyword in self.methods:
                p.method = keyword
            else:
                p.task += keyword + ' '

        p.task.rstrip()
        self.atoms = self.read_atoms_from_file(lines)
        self.read_results()

    def read_atoms_from_file(self, lines):
        """Read the Atoms from the output file stored as list of str in lines.
        Parameters:

            lines: list of str
        """
        # first try to read from final point (last image)
        i = self.get_index(lines, 'FINAL  POINT  AND  DERIVATIVES')
        if i is None:  # XXX should we read it from the input file?
            assert 0, 'Not implemented'

        lines1 = lines[i:]
        i = self.get_index(lines1, 'CARTESIAN COORDINATES')
        j = i + 2
        symbols = []
        positions = []
        while not lines1[j].isspace():  # continue until we hit a blank line
            l = lines1[j].split()
            symbols.append(l[1])
            positions.append([float(c) for c in l[2: 2 + 3]])
            j += 1

        return Atoms(symbols=symbols, positions=positions)

    def read_parameters_from_file(self, lines):
        """Find and return the line that defines a Mopac calculation

        Parameters:

            lines: list of str
        """
        for i, line in enumerate(lines):
            if line.find('CALCULATION DONE:') != -1:
                break

        lines1 = lines[i:]
        for i, line in enumerate(lines1):
            if line.find('****') != -1:
                return lines1[i + 1]

    def read_results(self):
        """Read the results, such as energy, forces, eigenvalues, etc.
        """
        natoms  = len(self.atoms) 
        bo = 0
        b_o = np.zeros((natoms,natoms)) 
        self.bond_order = []
        self.calc_ok = True 

        FileIOCalculator.read(self, self.label)
        if not os.path.isfile(self.label + '.out'):
            raise ReadError

        with open(self.label + '.out') as f:
            lines = f.readlines()

        for i, line in enumerate(lines):
            if line.find('FAILED TO ACHIEVE SCF') != -1:
                self.calc_ok = False
                self.results['energy'] = 0
                self.results['forces'] = np.array (
                    np.zeros(3 * len(self.atoms)) ).reshape((-1, 3))
            elif line.find('TOTAL ENERGY') != -1:
                self.results['energy'] = float(line.split()[3])
            elif line.find('NORMAL COORDINATE ANALYSIS') != -1:
                fvf = [line.split() for line in lines[i+7:i+8] ]
                self.freqs = fvf[0]
            elif line.find('FINAL HEAT OF FORMATION') != -1:
                self.final_hof = float(line.split()[5]) * kcal / mol
            elif line.find('FINAL  POINT  AND  DERIVATIVES') != -1:
                nf = [len(line.split()) == 8
                     for line in lines[i + 3:i + 3 + 3 * len(self.atoms)]]
                if not False in nf:
                    forces = [-float(line.split()[6])
                          for line in lines[i + 3:i + 3 + 3 * len(self.atoms)]]
                    self.results['forces'] = np.array(
                        forces).reshape((-1, 3)) * kcal / mol
                else:
                    self.calc_ok = False
                    self.results['energy'] = 0
                    self.results['forces'] = np.array (
                        np.zeros(3 * len(self.atoms)) ).reshape((-1, 3)) 
            elif line.find('(VALENCIES)   BOND ORDERS') != -1: bo = 1
            elif line.find('JOB ENDED') != -1: 
                for i in range(natoms):
                    for j in range(i+1,natoms): 
                        self.bond_order.append(str(b_o[i][j]))
                break
            elif bo == 1 and len(line.split()) > 2:
                if re.search(r'\) ',line): ind0 = int(line.split()[0]) -1
                for k in (x for x in range(len(line.split())) if x%3==0): 
                    ind1 = int(line.split()[k])-1
                    if ind1 != ind0: b_o[ind0][ind1] = line.split()[k+2]

    def get_bond_order(self):
        """Bond orders as reported in the Mopac output file
        """
        return self.bond_order

    def get_forces_permission(self):
        """True or False if forces cannot be read from output file
        """
        return self.forces_permission

    def get_calc_ok(self):
        """True or False if energy cannot be read from output file
        """
        return self.calc_ok

    def get_final_heat_of_formation(self):
        """Final heat of formation as reported in the Mopac output file
        """
        return self.final_hof

    def get_freqs(self):
        """First vibrational frequencies
        """
        return self.freqs

