---
title: Other capabilities
layout: home
parent: Tutorial
nav_order: 5
---

# Other capabilities

## Contents
- [van der Walls Complexes](#vdw)
- [Scanning dihedral angles](#dihed)
- [Fragmentation](#frag)
- [Advanced options](#adv)
- [Biased dynamics](#bias)


## van der Waals complexes<a name="vdw"></a>

AutoMeKin includes an option to find van der Waals, vdW, complexes. In principle two related sampling
options are available: association and vdW. While association runs a number of structure
optimizations for randomly rotated fragments, vdW is a more powerful option representing a natural
[extension of our bbfs method to study vdW complexes](https://onlinelibrary.wiley.com/doi/abs/10.1002/qua.26008). The input files for these two options slightly differ
from those explained previously, as detailed below.

### association 
Here, a number of full optimizations are performed starting from random orientations of A and B. An example of such input file can be found in `path_to_program/examples/assoc.dat`. Two additional input files are also needed for this example, `Bz.xyz` and `N2.xyz`, which are also available in the same folder. The assoc.dat file contains the following data:
```
--General--
molecule  Bz-N2
fragmentA Bz
fragmentB N2

--Method--
sampling association
rotate   com com 4 .0 1. 5
Nassoc   50

--Screening--
MAPEmax 0.0001
BAPEmax 0.5
eigLmax 0.05
```
This type of sampling only needs three sections: General, Method and Screening. Some further `keyword
value(s)` pairs are needed for this sampling:

{: .important }  
`fragmentA value`  
[`value` is one string with no blank spaces; _mandatory keyword_ ]  
`value` is the name of fragment A (`Bz` in our case). A file with the Cartesian coordinates `Bz.xyz` must be present in `wrkdir`.

{: .important }  
`fragmentB value`   
[`value  is one string with no blank spaces; _mandatory keyword`_ ]   
`value` is the name of fragment B (`N2` in our case). A file with the Cartesian coordinates `N2.xyz` must be present as well.

{: .important }  
`rotate values`   
[four `values`: first two can be strings or integers and last two are floats; default values: `com com 4.0
1.5`]  
The first two values are the pivot positions of the random rotations: the center of mass (`com`) of fragment A and the center of mass of fragment B in our example; these pivots could be labels of atoms and therefore integers. The last two values are the distance, in Å, between both pivots and the minimum intermolecular distance between any two atoms of both fragments, respectively.

{: .important }  
`Nassoc value`  
[`value` is an integer; default value: `100` ]  
`value` is the total number of intermolecular structures considered in the sampling. With this sampling, you cannot perform kinetics. However, you still need to provide the parameters for the screening. 

_To run the calculations, just type_:
```
amk.sh assoc.dat
```
This job will submit `value[Nassoc]` independent optimizations to find the structures. After the jobs finished, the script will automatically remove duplicates and select the best association “complex”.

{: .note }   
You cannot use `amk_parallel.sh` with this option, as this script is only employed to run MD
simulations.

You can check the optimized structures in folder `assoc_Bz_N2`. The program will also select the “best”
structure according to the minimum number of structural changes between the complex and the individual
fragments and its energy. The structure selected will be called `Bz-N2.xyz`. For fragments containing metals, the selection is also based on the valence of the metal center. The file assoclist_sorted (in
`assoc_Bz_N2` folder) collects a summary of the structures and their energies, as well as the MOPAC2016
output files of each of them, which are called _assocN.out_ , where N is a number from 1 to `value[Nassoc]`.

### vdW

For this option, the first part is common to association, and the program runs `value[Nassoc]` independent
optimizations to get an initial structure of the complex. From that point onwards, the program performs
BXDE simulations to find TSs and intermediates for the system. Here is the inputfile vdW.dat that you can
find in the examples folder:
```
--General--
molecule  Bz-N2
fragmentA Bz
fragmentB N2

--Method--
sampling vdW
rotate   com com 4.0 1.5
Nassoc   10
ntraj    1
fs       500

--Screening--
MAPEmax 0.0001
BAPEmax 0.5
eigLmax 0.01

--Kinetics--
Energy 150
```
As with other MD-based sampling methods, `amk_parallel.sh` can be employed here as well.

## Scanning dihedral angles<a name="dihed"></a>

Dihedral angles can be scanned using script tors.sh. You will need the inputfile and the XYZ file in your
`wrkdir` and just type:
```
tors.sh inputfile file
```
The first argument is the name of the inputfile and the second one can be: `all`, the default, or `file`. Using `all`, all the rotatable angles are scanned, while if you use `file`, the four indices that specify the dihedrals you want to scan must be present in file `dihedrals`.

The dihedrals will be scanned and the highest point, or points, along the scan, or scans, will be subjected to TS optimizations.

In general, dihedral scans are automatically performed in all parallel calculations, except with vdW and assoc samplings. For big and/or highly flexible molecules these automated scans can be very CPU intensive, and they can be avoided adding the keyword `torsion` with the value no to your Method section like in the next example:
```
--Method--
sampling MD
ntraj    10
torsion  no
```
The default value for `torsion` is `yes`.

## Fragmentation<a name="frag"></a>

The fragmentation patterns and breakdown curves can be modelled using the script `amk_frag.sh`. This script provides a workflow to iteratively discover fragmentation pathways not only the parent molecule but also for the fragments resulting from the primary fragmentation. Usage:
```
nohup amk_frag.sh > amk_frag.log 2>&1 &
```
The inputfile must have an additional section called “Fragmentation”, as in this example:
```
--Fragmentation--
minsize 4
systems 1
CH3O+   3
```
The new keywords are explained below.

{: .important }   
`minsize value`   
[`value` is an integer; default value: `4` ]  
`value` is the minimum number of atoms for a fragment to be considered in secondary fragmentations. 

{: .important }   
`systems value`   
[`value` is an integer; default value: `0`]  
`value` (or `ns`) is the number of additional fragments, or systems, to be considered in secondary fragmentations, besides those obtained in the fragmentation of the parent molecule. These could be fragments with other spin state, or fragments that are obtained through a barrierless process. 

This line must be followed by `ns` lines with two columns each one: the formula of each system, sys, and its multiplicity, mult. Note that for the formula the chemical symbols of the atoms must sorted following AutoMeKin’s convention: alphabetic order:
```
systems ns
sys(1) mult(1)
sys(2) mult(2)
...
sys(ns) mult(ns)
```
In the example above, only fragments with number of atoms greater than or equal to 4 are further
fragmented and an additional system has been added: CH<sub>3</sub>O<sup>+</sup> in its triplet state.

This workflow creates a new folder: `M3Cinp` containing files that can be read by program M3C to simulate
the breakdown curves of the studied system.

## Advanced options<a name="adv"></a>

The following are keywords that can be useful for experienced users.

### General

Here is a list of additional keywords that can be employed in the General section:

{: .important }  
`iop value`  
[`value` is one string with no blank spaces; no default value]   
`value` is a gaussian IOp string or any other additional keyword you want to add. 

Example:
```
HighLevel g16 mpwb95/6-31+G(d,p)
iop       iop(3/76=0560004400)
```

{: .warning }   
Care must be taken when `LowLevel_TSopt`, see below, is employed with `iop`, as this keyword
will also be activated in `LowLevel_TSopt` calculations. If the iop is only desired for high-level gaussian
calculations, then, the keyword should be removed while running the low-level computations.

{: .important }  
`LowLevel_TSopt values`  
[two `values`: two strings; no blank spaces in each string; default values: `mopac value[LowLevel]`]   
First `value` is the program and second value is the electronic structure level employed to optimize the TSs at the low-level stage. _This keyword is employed if you want to use g09/g16 for the low-level TS
optimizations, as shown in the example below but take into account that it is very CPU-time consuming_.
Besides the TSs, the starting minimum in `name.xyz` is also optimized at this level of theory. 

Example:
```
LowLevel_TSopt g09 hf/3-21g
```

{: .important }   
`recalc value`   
[one `value`: one integer; by default this keyword is not employed; _only with mopac_ ]  
If the last point of the IRC is an intermediate, MOPAC will try to optimize it. 

For difficult cases, the user can employ this keyword like in this example:

```
recalc 10
```
which tells MOPAC to recalculate the Hessian every 10 steps in the EF optimization. For small values, the
calculation is costly but is also very effective in terms of convergence.

### Method

Here is a list of additional keywords that can be employed in the Method section:

{: .important }  
`atoms value(s)`    
[one or two `values`: first is a string with no blank spaces or an integer and second, if present, is a string with no blank spaces; _only with MD_ ; default value: `all`]   
The first `value` can be `all`, in which case no other values are needed, or the number of atoms initially
excited followed by a second value, a string, which is the list of atoms separated by commas, without blank
spaces. It is analogous to modes, explained below. 

This is an example where atoms 1, 2 and 3 are initially excited:
```
atoms 3 1,2,3
```

{: .important }  
`etraj value`   
[`value` is an integer or string with no blank spaces; _only with MD-micro_ ; no default]  
If an integer, `value` is the energy, in kcal/mol, of the MD-micro simulations. 

If value is a range as in the example below, the energy is randomly selected in the given energy range:
```
etraj 200-300
```
If `etraj` is not specified, the program automatically employs the following range of energies: $\scriptstyle{16.25(s−1)−46.25(s−1)}$ kcal/mol, where $\scriptstyle{s}$ is the number of vibrational degrees of freedom of the system. The values $\scriptstyle{16.25}$ and $\scriptstyle{46.25}$ have been determined from the formic acid results and making use of RRK theory.
The program automatically adjusts the range to obtain at least 60% reactivity at the boundaries.

{: .important }   
`factorflipv value`  
[`value` is a float; _only with MD and MD-micro_ ; no default]   
Using the default options, trajectories are halted when the simulation time reaches the `value[fs]`, see below, or when there an interatomic distance, $\scriptstyle{r_{ij}}$, reaches 5 times its initial value $\scriptstyle{r_{ij}^0}$, which is regarded as a fragmentation. 

Using `factorflipv`, fragmentation can be prevented because the atomic velocities change their sign: whenever the following relationship is fulfilled: $\scriptstyle{r_{ij}>=\mathrm{FP}\times r_{ij}^0}$, where $\scriptstyle{mathrm{FP}}$ is `value[factorflipv]`. We recommend this value to be in the range 3.0-5.0.

{: .important }   
`fs value`  
[`value` is an integer; default value: `500` for MD and MD-micro and `5000` for BXDE]  
`value` is the simulation time in fs in MD, MD-micro and BXDE samplings. Notice that this is the maximum
simulation time, because when any interatomic distance reaches 5 times its initial value, the simulation
stops. 

To run 2 ps trajectories the following should be employed:
```
fs 2000
```

{: .important }   
`modes value(s)`    
[one or two `values`: first is a string with no blank spaces or an integer and second, if present, is a string with no blank spaces; _only with MD-micro_ ; default value: `all`]   
The first `value` can be `all`, in which case no other values are needed, or the number of modes initially
excited followed by a second value, string, which is the list of modes separated by commas and without blank spaces. It is analogous to `atoms`, explained above.

{: .important }   
`multiple_minima value`   
[`value` is one string: `yes` or `no`; default value: `yes`]   
`value` can be `yes`, in which case the exploratory simulations start from multiple minima, or `no`, where the all the MD simulations start from the input initial structure.

{: .important }   
`post_proc value(s)`   
[from one to three `values`: first `value` is a string: `bbfs`, `bots` or `no`; the second and third are integers or floats; default values: `bbfs 20 1` for all samplings except association where the default value is `no`]   
The first `value` is the post-processing algorithm employed to detect reaction events and it can be bbfs, the default, `bots` or `no`, if no algorithm is applied; this makes only sense for the purpose of testing the MD module. For `bbfs` two more values can follow: the time window in fs employed by `bbfs` and the number of guess structures selected per candidate. Possible choices for this last number can be 1 or 3. 

Example:
```
post_proc bbfs 20 1
```
If `bots`, for bond order time series, is employed, _only with BXDE, vdW and external_, the algorithm
developed by [Hutchings et al.](https://pubs.acs.org/doi/abs/10.1021/acs.jctc.9b01039) is employed. In this case the two additional values are the cutoff frequency (in cm<sup>−1</sup>) for the low-pass filter
used to smooth bond order time series, and the number of standard deviations considered to identify peaks
associated with reactive events. The default values for this algorithm are:
```
post_proc bots 200 2.5
```

{: .important }  
`temp value`  
[`value` is an integer or string with no blank spaces; _only with MD and BXDE_ ; no default]  
If an integer, `value` is the temperature, in K, of the MD or BXDE simulations. If a range, _only valid for MD_, the temperature is randomly selected in the given range. In the absence of the temp keyword, the program automatically defines the following range of temperatures: $\scriptstyle{5452(s−1)/n−15517(s−1)/n}$ K, which has been optimized for formic acid and $\scriptstyle{n}$ being the number of atoms. However, as for `etraj`, the boundaries are adjusted _on the fly_ to obtain a minimum reactivity of 60%. _For BXDE, temp has only one value and 1000 K is the default)._

{: .important }  
`thmass value`   
[`value` is an integer; _only with MD_ ; default value: `0`]   
`value` is the required minimum mass in a.u. of an atom to be initially excited.

{: .important }  
`Use_LET value`  
[`value` is one string: `yes` or `no`; _only with mopac_ ; default value: `no` for all samplings except `ChemKnow`]   
If `value` is `yes`, then mopac TS optimizations that fail throwing the error: “NUMERICAL PROBLEMS
BRACKETING LAMDA” are rerun using LET keyword, which allows [more of the potential energy surface to be
sampled:](http://openmopac.net/manual/error_messages.html). To help the user judge whether to use this
keyword, the results of the optimizations using LET are collected in the file `stats_let` located in
`tsdirLL_molecule`. This file contains several lines, one per iteration, with two numbers: the first is the
number of optimized TSs, and the second is the number of total attempts using LET.

### Screening

Here is a list of additional keywords that can be employed in the Screening section:

{: .important }  
`tight_ts value`   
[`value` is one string: `yes` or `no`; default value: `yes`]   
`value` can be `yes`, in which case only first order saddles are considered, or `no` if we want to keep also higher order saddles.

### Kinetics

Here is a list of additional keywords that can be employed in the Kinetics section:

{: .important }  
`imin value`  
[`value` is an integer or the string `min0`; default value: `min0`]   
`value` is the starting minimum for the KMC simulations. value can be an integer, which identifies the
desired structure or `min0`, which refers to the input structure. All the minima are listed in `MINinfo` file and the user must examine `RXNet.cg` file to check that the minimum is indeed connected with the other ones.

{: .important }  
`nmol value`   
[`value` is an integer; default value: `1000` ]    
`value` is the number of molecules for the KMC simulations. 

{: .important }  
`Stepsize value`   
[`value` is an integer; default value: `10` ]   
`value` is the number of reactions that have to take place before printing the population in the KMC runs.

{: .important }  
`MaxEn value`   
[`value` is an integer; default value: `100` for thermal kinetics or 3/2 the value of Energy for
microcanonical kinetics]  
`value` is the maximum allowed energy, in kcal/mol and relative to the input structure, for a TS to be included in the reaction network.

{: .important }  
`ImpPaths value`   
[`value` is a float; default value: `0` ]   
`value` is the minimum percentage of processes occurring through a particular pathway that has to be achieved in order to be considered relevant and finally included in `Energy_profile.pdf` and in `RXNet.rel`. The default value means that pathways which are overcome at least once by the KMC simulations are included in these files. To reduce to number of channels drawn in `Energy_profile.pdf` and printed in `RXNet.rel` you can increase the default value. Notice that these pathways may refer to the “coarse-grained” mechanism or to the complete mechanism that includes conformational isomers, obtained by using the `allstates` option as described above. For practical reasons, _a maximum of 100 TSs_ will be drawn in `Energy_profile.pdf` and printed in `RXNet.rel`. If this maximum value is reached (which can be checked in `RXNet.rel`), it means that part of the channels are missing in these files.

## Biased dynamics<a name="bias"></a>

AutoMeKin includes several methods to bias the dynamics towards specific reaction pathways. So far, these
are the available options, _only for MD and MD-micro_:

- The first option uses the [AXD algorithm](https://pubs.acs.org/doi/10.1021/ct060042z), with which selected bond lengths are not allowed to stretch more than 5 0% with respect to their initial values. This can be useful to prevent the breakage of certain bonds. This option can be invoked using the following “ `keyword value` pair:

{: .important }    
`nbondsfrozen value`    
[`value` is an integer; default value: `0` ]  
where `value`, or `nfr`, is the number of constrained bonds. 

The line containing the `bondsfrozen nfr` pair must be followed by `nfr` lines, each one with two values:  
`fr_i(k) fr_j(k)`   
which are integers indicating the indexes of the atoms that form each constrained bond, as in the following example:
```
nbondsfrozen 2
1 13
2 8
```
This would “freeze” two bond distances connecting atoms 1 and 13 and 2 and 8 , respectively. This keyword
has not been tested thoroughly and the more robust Hookean keyword, see above, is suggested.


- The second algorithm biases the dynamics towards a particular reaction channel. An example of this
option is provided in file `path_to_program/examples/FA_biasH2.dat`; you also need `FA.xyz`, which
illustrates a way to search for H<sub>2</sub> elimination transition states from formic acid. For this we use two sets of keywords to apply constant external forces to break or form bonds. For bond breakage we use the following:

{: .important }    
`nbondsbreak value`   
[`value` is an integer; default value: `0` ]   
where `value`, or `nbr`, is the number of bonds we want to break. 

The line containing this `keyword value` pair must be followed by `nbr` lines, each one with three values `(br_i(1,...,nbr) br_j(1,...,nbr) force(1,...,nbr)`   
of which the first two are integers and the last a float. These three numbers indicate the indexes of the atoms that form each bond we want to break, and the magnitude of the applied external force in kcal/mol/Å, respectively.

For bond formation we use the analogous keyword `nbondsform` as in this example (taken from
`FA_biasH2.dat`):
```
nbondsform 1
4 5 30
nbondsbreak 2
3 5 80
1 4 80
```
A similar test can be performed on the same molecule to get the TS for H<sub>2</sub>O elimination. The corresponding input file, `FA_biasH2O.dat`, is also available in directory path_to_program/examples. Additionally, a retro Diels-Alder reaction has also been tested: cyclohexene$\scriptstyle{\rightarrow}$ethylene+1,3-butadiene, using the input files `rdiels_bias.dat` and `rdiels.xyz` provided in the amk distribution.

The above examples can be tested using the `amk.sh` script:
```
amk.sh inputfile
```
