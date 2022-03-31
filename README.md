# AutoMeKin

<p align="center">
   <img src="logo.png" alt="alt text" width="400" height="200">
</p>

AutoMeKin (formerly known as tsscds) is a computer program that has been designed to discover reaction mechanisms and solve the kinetics in an automated fashion. AutoMeKin obtains transition state guess structures from trajectory simulations of the highly vibrationally excited species. From the obtained TS structures, minima and product fragments are determined following the intrinsic reaction coordinate. Finally, having determined the stationary points, the reaction network is constructed and the kinetics is solved. The program is interfaced with MOPAC2016 and Gaussian 09 (G09).

A computer program for finding reaction mechanisms and solving the kinetics.

## AUTHORS

* George L. Barnes
* David R. Glowacki
* Sabine Kopec
* Emilio Martinez-Nunez
* Daniel Pelaez-Ruiz
* Aurelio Rodriguez
* Roberto Rodriguez-Fernandez
* Robin J. Shannon
* James J. P. Stewart
* Pablo G. Tahoces
* Saulo A. Vazquez

## LICENSE

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


## INSTALLATION INSTRUCTIONS

Once you have downloaded the source code, untar and unzip the file:

```
tar xvfz Amk-SOURCE-2020.tar.gz
```

or clone the code from github:

```
git clone https://github.com/emartineznunez/AutoMeKin2020.git AutoMeKin
```

## DEPENDENCIES

Before installing amk for the first time, be aware that the following packages are needed:

- **[GNU Bash](https://www.gnu.org/software/bash/)**
- **[GNU bc](https://www.gnu.org/software/bc/)**
- **[environment-modules](https://github.com/cea-hpc/modules)**
- **[GNU Awk (gawk)](https://www.gnu.org/software/gawk/)**
- **[GNU C Compiler (gcc)](https://gcc.gnu.org/)**
- **[Gnuplot](http://www.gnuplot.info/)**
- **[GNU Fortran Compiler (gfortran)](https://gcc.gnu.org/wiki/GFortran)**
- **[GNU Parallel](https://www.gnu.org/software/bash/manual/html_node/GNU-Parallel.html)**
- **[SQLite](https://www.sqlite.org/index.html)** (version >= 3)
- **[Zenity](https://wiki.gnome.org/Projects/Zenity)**

You can install the missing ones manually, or you can use the scripts located in amk-SOURCE-2020 and called install-required-packages-distro.sh (where distro=ubuntu-16.4lts, centos7 or sl7), which will do the work for you. The ubuntu-16.4lts script installs all dependencies, but for the RHEL derivatives (centos7 and sl7) you have to install parallel separately, and you have two choices:

1. **install-gnu-parallel-from-source.sh**. This script installs parallel latest version from source thanks 
to Ole Tange (the author). Also it can fallback to a user private installation into $HOME/bin 
if you have not administrator permisions to install it globally.

2. **install-gnu-parallel-from-epel.sh**. Enables the EPEL repository and installs parallel from it.

The program employs python3 and the following python3 libraries are needed:

- **[ASE](https://wiki.fysik.dtu.dk/ase/)**
- **[Matplotlib](https://matplotlib.org/)**
- **[NetworkX](https://networkx.github.io/)**
- **[NumPy](https://www.numpy.org/)**
- **[SciPy](https://www.scipy.org/)**

The program runs using two levels of theory: semiempirical (or Low-Level LL) and ab initio/DFT (or High-Level HL). So far, the only program interfaced with amk to perform the ab initio/DFT calculations is G09. Therefore, if you want to perform the HL calculations G09 should be installed and should run like in this example:

```
g09<inputfile>outputfile.
```

These packages might also be useful to analyze the results:

1. **[molden](http://cheminf.cmbi.ru.nl/molden/)**
2. **[sqlitebrowser](https://github.com/sqlitebrowser/sqlitebrowser)**

## INSTALLATION

Once the above packages are installed, either:

Go to AutoMeKin if you cloned it from github

```
cd AutoMeKin
```

or go to the amk-SOURCE-2020 folder, if you downloaded the tarball.

```
cd amk-SOURCE-2020
```

In both cases, the process continues the same way. Now type:

```
./configure
```

This will install amk in $HOME/amk-2020 by default. If you want to install it in a different directory, type:

```
./configure --prefix=path_to_program
```

Finally, complete the installation:

```
make
make install
make clean
```

The last command (make clean) is only necessary if you want to remove from the src directory the object files and executables created in the compilation process.

For convenience, and once “Environment Modules” has been installed, you should add the following line to your .bashrc file:

```
module use path_to_program/modules
```

where path_to_program is the path where you installed amk (e.g., $HOME/amk-2020).


## PROGRAM EXECUTION

To start using any of the scripts of the program, you have to load amk/2020 module:


```
module load amk/2020
```

To run the low-level calculations use:

```
nohup llcalcs.sh molecule.dat ntasks niter runningtasks >llcalcs.log 2>&1 &
```

where:
molecule is the name of your molecule
ntasks is the number of tasks
niter is the number of iterations
runningtasks is the number of simultaneous tasks

To run the high-level calculations use:
	
```
nohup hlcalcs.sh molecule.dat runningtasks >hlcalcs.log 2>&1 &
```

For more details, follow the instructions given in the tutorial.

