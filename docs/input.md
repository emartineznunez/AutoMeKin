---
title: Input files
layout: home
parent: Tutorial
nav_order: 2
has_children: true
---

# Input files

The first step in our strategy for finding reaction mechanisms involves Heuristics- or MD-based methods, for which MOPAC 2016 or Entos Qcore are used. The algorithm samples the potential energy surface to locate
transition states by using the original [BBFS algorithm](https://onlinelibrary.wiley.com/doi/abs/10.1002/jcc.23790), or a [bond-order-based search algorithm](https://pubs.acs.org/doi/abs/10.1021/acs.jctc.9b01039). Then, reactants and products are obtained by intrinsic reaction coordinate, IRC, calculations. Finally, a reaction network is
constructed with all the elementary reactions predicted by the program. To increase the efficacy of
AutoMeKin, this process may be carried out in an iterative fashion as described in [PCCP-2015](https://pubs.rsc.org/en/content/articlelanding/2015/cp/c5cp02175h). Once the
reaction network has been predicted at the semiempirical level, the user can calculate rate constants for all the elementary reactions and run Kinetic Monte Carlo, KMC, calculations to predict the time evolution of all the chemical species involved in the global reaction mechanism and to calculate product ratios.

In a subsequent step, the collection of TSs located at the semiempirical level are reoptimized using a higher level of electronic structure theory. Notice that, depending on the selected level of theory, the total number of reoptimized TSs may differ from that obtained with the semiempirical Hamiltonian. For each reoptimized
TS, IRC calculations are performed to obtain the associated reactant and products. The reaction
network is then constructed for the high level of theory. As for the low-level computations, the last step
involves the calculation of rate constants and product ratios. At present, the high-level electronic structure calculations can be performed with G 09 /G16 or with Entos Qcore.

_To follow the guidelines of this tutorial, you can try the formic acid, FA, test case that comes with the
distribution_. Make a working directory (<code>wrkdir</code>) and copy files <code>FA.dat</code> and <code>FA.xyz</code> from <code>path_to_program/examples</code> to your <code>wrkdir</code>. All scripts must be run from your <code>wrkdir</code>.

{: .warning }
Use short names for the <code>wrkdir</code> and the input files. Good choices are short acronyms using capital letters like FA for formic acid. 

The following are files read by amk, and therefore, they must be present in <code>wrkdir</code>.

## name.xyz

Where name refers to the name for our system (<code>FA.xyz</code> in our example). The recommendation
is to use acronyms like FA for Formic Acid or short names. This file contains an initial input structure of our system in XYZ format:
```
5  
  
C  0.000000 0.000000  0.000000    
O  0.000000 0.000000  1.220000    
O  1.212436 0.000000 -0.700000    
H -0.943102 0.000000 -0.544500     
H  1.038843 0.000000 -1.634005     
```
Please provide here a stable conformer of the reactant molecule. A general recommendation is to use a
structure previously optimized with the method selected with the keyword LowLevel or eventually
`LowLevel_TSopt`. _If your input structure is fragmented, then, kinetics results, if available, are
meaningless. In this case you should use biased MD to smash together the fragments and obtain a TS for
the bimolecular process, like in the diels_alder example._

_This file is mandatory except for association and vdW samplings_ where two XYZ files are needed instead.

{: .warning }
Avoid using integers for any of the XYZ coordinates, as this will cause problems with the high-level
calculations.

## name.dat

Where name can be any name, from just the name of the system to something that identifies the
type of calculation you are carrying out; in our case FA.dat. This file contains all parameters of the
calculation and has different sections, which are explained as follows. _This file is mandatory in all cases._

The file name.dat is organized in four sections: General, Method, Screening and Kinetics, which are
explained in detail below. Each section contains lines with several <code>keyword value(s)</code> pairs with the following syntax:

<code>keyword value(s)</code>

<code>keyword</code> is a case-sensitive string and it must be the first field of the line.

<code>value(s)</code> can be strings, integers or floats and is/are the `value(s)` of the keyword.

_At least one blank space must be kept between_ `keyword` and `value(s)`. A few keywords include some
additional lines right below the keyword line (see _Biased dynamics_).

Next, you will find a detailed explanation of the keywords grouped together in the different sections. For
each section, only the most important keywords are described. Additional keywords can be found in
[Other capabilities](https://emartineznunez.github.io/AutoMeKin/docs/other.html).
