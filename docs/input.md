---
title: Input files
layout: home
parent: Tutorial
nav_order: 2
---

# Input files

The first step in our strategy for finding reaction mechanisms involves Heuristics- or MD-based methods, for which MOPAC 2016 or Entos Qcore are used. The algorithm samples the potential energy surface to locate
transition states by using the original [BBFS algorithm](https://onlinelibrary.wiley.com/doi/abs/10.1002/jcc.23790), or a [bond-order-based search algorithm](https://pubs.acs.org/doi/abs/10.1021/acs.jctc.9b01039). Then, reactants and products are obtained by intrinsic reaction coordinate (IRC) calculations. Finally, a reaction network is
constructed with all the elementary reactions predicted by the program. To increase the efficacy of
AutoMeKin, this process may be carried out in an iterative fashion as described in [PCCP-2015](https://pubs.rsc.org/en/content/articlelanding/2015/cp/c5cp02175h). Once the
reaction network has been predicted at the semiempirical level, the user can calculate rate constants for all the elementary reactions and run Kinetic Monte Carlo (KMC) calculations to predict the time evolution of all the chemical species involved in the global reaction mechanism and to calculate product ratios.

In a subsequent step, the collection of TSs located at the semiempirical level are reoptimized using a higher level of electronic structure theory. Notice that, depending on the selected level of theory, the total number of reoptimized TSs may differ from that obtained with the semiempirical Hamiltonian. For each reoptimized
TS, IRC calculations are performed to obtain the associated minima (reactant and products). The reaction
network is then constructed for the high level of theory. As for the low-level computations, the last step
involves the calculation of rate constants and product ratios. At present, the high-level electronic structure calculations can be performed with G 09 /G16 or with Entos Qcore.

**To follow the guidelines of this tutorial, you can try the formic acid (FA) test case that comes with the
distribution**. Make a working directory (<code>wrkdir</code>) and copy files <code>FA.dat</code> and <code>FA.xyz</code> from <code>path_to_program/examples</code> to your <code>wrkdir</code>. All scripts (described below) must be run from your <code>wrkdir</code>.

{: .warning }
Use short names for the <code>wrkdir</code> and the input files. Good choices are short acronyms (using capital letters) like FA for formic acid. 


The following are files read by amk, and therefore, they must be present in <code>wrkdir</code>.

**name.xyz** (<code>FA.xyz</code> in our example), where name refers to the name for our system; the recommendation
is to use acronyms like FA for Formic Acid or short names. This file contains an initial input structure of our
system in XYZ format:
```
5  
  
C  0.000000 0.000000  0.000000    
O  0.000000 0.000000  1.220000    
O  1.212436 0.000000 -0.700000    
H -0.943102 0.000000 -0.544500     
H  1.038843 0.000000 -1.634005     
```
Please provide here a stable conformer of the reactant molecule. A general recommendation is to use a
structure previously optimized with the method selected with the keyword LowLevel (or eventually
LowLevel_TSopt). _If your input structure is fragmented, then, kinetics results (if available) are
meaningless. In this case you should use biased MD to smash together the fragments and obtain a TS for
the bimolecular process, like in the diels_alder example._

_This file is mandatory except for association and vdW samplings_ where two XYZ files are needed instead
(see below).

{: .warning }
Avoid using integers for any of the XYZ coordinates, as this will cause problems with the high-level
calculations.

**name.dat** (where name can be anything, from just the name of the system to something that identifies the
type of calculation you are carrying out; in our case FA.dat). This file contains all parameters of the
calculation and has different sections, which are explained as follows. _This file is mandatory in all cases._

The file name.dat is organized in four sections: General, Method, Screening and Kinetics, which are
explained in detail below. Each section contains lines with several <code>keyword value(s)</code> pairs with the following syntax:

<code>keyword value(s)</code>

<code>keyword</code> is a case-sensitive string and it must be the first field of the line.

<code>value(s)</code> can be strings, integers or floats and is/are the value(s) of the keyword.

_At least one blank space must be kept between keywork and value(s)_. A few keywords include some
additional lines right below the keyword line (see _Biased dynamics_).

Below you will find a detailed explanation of the keywords grouped together in the different sections. For
each section, only the most important keywords are described. Additional keywords can be found in
_Advanced options_.


**General.** In this section the electronic structure details are provided. The following is an example of the
keywords employed in this section for the FA.
```
--General--  
molecule FA  
LowLevel mopac pm7 t=3m  
HighLevel g16 b3lyp/6-31G(d,p)  
HL_rxn_network complete  
IRCpoints 30  
charge 0  
mult 1  
```
List of <code>Keyword value(s)</code> for this section:

{: .important }  
<code>molecule value</code>   
[<code>value</code> is one string with no blank spaces; _mandatory keyword_]  

<code>value</code> is the name of the system and _it must match the name of the XYZ file without the extension (FA in
our example). For association and vdW sampling there is no XYZ file at the beginning and
<code>value</code> is just the name of the system._


{: .important }  
<code>LowLevel values</code>   
[two <code>values</code>: two strings; the second string accepts blank spaces; default: <code>mopac pm7</code>]  

The first <code>value</code> is the program and the second the semiempirical method. So far, <code>qcore</code> and <code>mopac</code> are valid programs. For <code>qcore</code> only <code>xtb</code> method is implemented, and for <code>mopac</code>, any of the semiempirical methods of MOPAC2016 can be employed to run the MD simulations. You can use a combination of MOPAC keywords. In the example above, for instance, the pm7 semiempirical level together with a maximum CPU time (for any type of mopac calculation) of 3 minutes is requested. _The use of the MOPAC keyword t= (followed by an amount of time) is highly recommended to enhance the efficiency of the calculations._

If you do not employ the keyword <code>LowLevel_TSopt</code>, explained below in advanced options, both the low-level TS optimizations and MD simulations are carried out using the semiempirical method specified by the second value. This is in general a good choice both in terms of efficacy and efficiency, and also because all structures will be re-optimized later using ab initio/DFT methods as specified with the keyword HighLevel.

However, if you know that semiempirical methods do not work well for your system, and although they are
going to be employed for the MD sampling (there is no other choice at the moment), you can still pick one
of the _ab initio_/DFT methods already at this stage for the TS optimizations using the keyword
<code>LowLevel_TSopt</code> explained below in advanced options. However, note that this will be much more demanding.

{: .important }  
<code>HighLevel values</code>  
[two <code>values</code>: two strings; no blank spaces in each string; _mandatory keyword except for
association_]

The first <code>value</code> is the program (<code>g09</code>, <code>g16</code> or <code>qcore</code> are the possible choices) and the second indicates the level of theory employed in the high-level calculations. For gaussian, you can employ a dual-level approach, which includes a higher level to refine the energy, as shown in the following example:
```
HighLevel g16 ccsd(t)/6-311+G(2d,2p)//b3lyp/6-31G(d,p)
```
For <code>g09/g16</code>, supported methods are HF, MP2 and DFT for geometry optimizations and HF, MP2, DFT and CCSD(T) for single point energy calculations.

For <code>qcore</code>, the method is specified in an additional file named qcore_template. An example of such file is given in the FA_qcore example. This option also allows an extra keyword: <code>hessianmethod</code>, which could accept the values <code>analytic</code> or <code>semianalytic</code>.

{: .important }  
<code>HL_rxn_network value(s)</code>  
[one or two <code>values</code>: first is a string, and second (if present) is an integer; default value: <code>reduced</code>]

The first value can be <code>complete</code> or <code>reduced</code>. <code>complete</code> indicates that all the TSs will be reoptimized and in this case no second value is needed.

Alternatively, you may use <code>reduced</code> as the first value (the default), followed by a second <code>value</code> (an integer) which indicates the maximum energy (in kcal/mol and relative to the reference starting structure) of a transition state to be calculated at the high level.

{: .important }  
<code>IRCpoints value</code>  
[<code>value</code> is an integer; default value: <code>100</code> ]

<code>value</code> is the maximum number of IRC points (in each direction) computed at the high-level. Note that g09/g16 calculations need much fewer points than Entos Qcore.

**charge** value

[value is an integer; default value: 0 ]

value is the charge of the system.

**Memory** value

[value is an integer; default value: 1 ]

value is the number of GB of memory employed in the gaussian high-level calculations.

**mult** value


[value is an integer; default value: 1 ]

value is the multiplicity of the system. Note that this keyword is only employed in the HL calculations. If
you want to run the LL calculations with a specific multiplicity, this should be specified in the **LowLevel**
keyword using any of the possibilities that MOPAC offers.

**Method.** Here the user provides details of the method employed for sampling the reaction space. In our FA
example, we have the following:

--Method--
sampling MD
ntraj 10
List of “ **Keyword** value(s)” for this section:

**sampling** value

[value is one string with no blank spaces; default value: MD]

value can be: **MD** , **MD-micro** , **BXDE** _,_ **external** , **ChemKnow** , **association** and **vdW**

**MD** and **MD-micro** refer to the type of initial conditions used to run the MD simulations. **MD-micro has not
been implemented yet for qcore** With **BXDE** the rare-event acceleration method named BXDE is invoked.^3
The BXDE module employs the “Atomistic Simulation Environment” (ASE) library of Python,^4 which must be
referenced whenever **BXDE** is employed.

**MD** allows the user to include partial constraints in the trajectories, which may be useful for large systems
(see the “advanced users” section for more details).

**external** allows trajectory data to be read from the results of an external (MD) program. The trajectory
data (in XYZ format) must be stored in a directory named coordir using one file per trajectory which should
be called name_dynX.xyz, where name is value[molecule], and X is the number of each trajectory (X =
1 - ntraj). The keyword ntraj must be set accordingly.
**ChemKnow** makes all possible combinations of bond breakages/formations which are consistent with preset
valencies of the atoms and with products lying below the maximum energy of the system. Once the
combinations are known, the starting and ending points are obtained after a constrained MD simulation with
external forces applied to break/form the selected bonds. Then, a NEB calculation tries to obtain a path
connecting both states, and the highest point of the NEB is subjected to TS optimization. This sampling does
not need to include the number of trajectories and **has not been implemented yet for qcore**.

**CAVEAT:** To use **MD-micro** the initial structure needs to be fully optimized and a frequency calculation can
not afford imaginary frequencies. Otherwise choose **MD**


**association** and **vdW** are employed to sample van der Waals structures, present some peculiarities and
therefore are explained in detail in van der Waals complexes.

MD _,_ MD-micro, external and BXDE samplings accept the following keywords (BXDE and ChemKnow also
accept other keywords as seen below):

**barrierless** value

[value is one string: yes or no; default value: no]
value can be yes, in which case barrierless processes are searched. The keyword neighbors explained
below is related to this one.

**neighbors** values

[three values: first is a string and last two are floats; default values (see table below)]

The first value is an atomic symbol and the two numbers are the minimum and maximum number of
neighbors of the corresponding atoms. This keyword is needed if atoms other than those in the table below
are present in your system and/or if you want to change the default values. The number of neighbors is
employed to locate **barrierless processes** and are also employed by **ChemKnow**. For instance, if you want to
consider dissociations leading to atomic hydrogen, you must add the following line:

neighbors H 0 1

The default values are listed in this table:

**Atom Min # of neighbors Max # of neighbors Atom Min # of neighbors Max # of neighbors**
H 1 1 Mg 0 2
Li 0 1 Al 1 3
Be 0 2 Si 1 4
B 1 3 P 1 5
C 1 4 S 1 6
N 1 3 Cl 0 1
O 1 2 Br 0 1
F 0 1 I 0 1
Na 0 1
**ntraj** value

[value is an integer; default value: 1 ]

value is the number of trajectories. We strongly recommend here to avoid using big numbers of
trajectories. Instead, the user should try to run different batches of trajectories as indicated below with a
small number of trajectories each one. One trajectory is recommended for BXDE and about 10 for MD-based
sampling.

**seed** value


[value is an integer; **only valid for MD and MD-micro** ; default value: 0 ]

value is the seed of the random number generator. It can be employed to run a test trajectory. See the
FA_singletraj.dat file in the examples. **Only use this keyword for testing.**

**BXDE specific keywords.** This sampling (and the other BXDE-based sampling based: vdW) has a number
of specific keywords as shown in this example:

sampling BXDE
Friction 0.
AdaptiveLimit 100
Window 500
Hookean 1 2 2.5 10.
**Friction** value

[value is a float; default value: 0.5]

value is the friction coefficient (in a.u.) employed in the Langevin dynamics of a BXDE simulation.

**AdaptiveLimit** value

[value is an integer; default value: 100 ]

value determines how many MD steps are performed in a new box before the BXDE algorithm adaptively
places a new box based upon the sampled energies.

**Window** value

[value is an integer; default value: 500 ]

value determines the number of consecutive MD steps before considering a reaction to have occurred.

**Hookean** values

[four values: first (i) and second (j) are integers, third (rt) and fourth (k) are floats]

Hookean keyword can be employed with any BXDE-based dynamics sampling. It employs ASE’s Hookean
class to conserve molecular identity (https://wiki.fysik.dtu.dk/ase/ase/constraints.html#the-hookean-class).
A Hookean restorative force with spring constant given by the fourth value (in eV/Å^2 ) is applied between two
atoms of indices given by the first and second values if the distance between them exceeds a threshold (third
value). For instance, the following example tethers atoms at indices 1 and 2 together:

**ChemKnow specific keywords.** This sampling has a number of specific keywords as shown in this
example:

sampling ChemKnow
Graphto3D POpt


active 1 2 3 4
startd 2.
MaxBoF 2
MaxBoB 2
comb22 no
crossb no
BreakRing no
CK_minima all
**Graphto3D** value

[value is a string: POpt or Traj; default value: POpt]

value is the method employed to transform the product Graph into a 3D geometry. POpt performs a series
of partial optimizations (with the bonds involved in the reaction coordinate frozen) where the geometry is
smootly changed from reactant to product. In Traj, an external force is applied for the same purpose.

**active** values

[values are integers]

values are the labels of the atoms that participate in the reactions we are interested in. By default, all
atoms in the system are active.

**startd** value

[value is a float; default value: 2.75]

value is the maximum distance between active atoms to be considered in a bond formation.

**MaxBoF/MaxBoB** value

[value is an integer; default value: 2]

value is the maximum number of bonds formed ( _nF_ )/broken ( _nB_ ) to make all possible ( _nF_ , _nB_ ) combinations
for Graph transformations.

**comb22** value

[value is a string: yes or no; default value: no]

By default, the (2,2) combination is not considered.

**crossb** value

[value is a string: yes or no; default value: no]

A check can be done to see if the closest distance between the paths followed by the atoms in their
rearrangements is lower that a threshold value (a potential problem in planar molecules or planar regions
of a molecule). By default, this check is not done.


**BreakRing** value

[value is a string: yes or no; default value: no]

By default, a bond that belongs to a ring is not broken in (0,1) transformations. However, there might be ring
opening reactions of our interest.

**CK_minima** value

[value is a string: all or cg; default value: all]

By default, all minima are used for graph transformations (including conformers). With the value cg, only
the lowest energy member of each family of conformers is utilized.

**Screening**. Some of the initially located structures might have very low imaginary frequencies, be repeated
or correspond to transition states of van der Waals complexes formed upon fragmentation of the reactant
molecule. To avoid or minimize low-(imaginary)frequency structures, redundancies and van der Waals
complexes, amk includes a screening tool, which is based on the following descriptors: energy, SPRINT
coordinates,^5 degrees of each vertex and eigenvalues of the Laplacian matrix.^1 While the lowest eigenvalues
of the Laplacian (eigL) are employed to discriminate fragmented structures, comparing the descriptors for
any pair of structures, a mean absolute percentage error (MAPE) and a biggest absolute percentage error
(BAPE) are obtained.

In this section we set a minimum value for the imaginary frequency and maximum values for MAPE, BAPE
and eigL, as explained below:

--Screening --
imagmin 200
MAPEmax 0.
BAPEmax 2.
eigLmax 0.
List of “ **Keyword** value(s)” for this section:

**imagmin** value

[value is an integer; default value: 0 ]

value is the minimum value for the imaginary frequency (in absolute value and cm−^1 ) of the selected TS
structures. Discarded structures will be stored in tsdirLL_molecule/LOW_IMAG_TSs to allow the user
inspection of the rejected TSs.

**MAPEmax** value

[value is a float; default value: 0 ]

value is the maximum value for MAPE.


**BAPEmax** value

[value is a float; default value: 0 ]

value is the maximum value for BAPE.

If both, the MAPE and BAPE values calculated for two structures are below the values of MAPEmax and
BAPEmax, respectively, the structures are considered equivalent, and therefore only one is kept.

As a general advice, value[MAPEmax] and value[BAPEmax] should be small. A good starting point could
be the values provided in the input files of the examples. Since the HL calculations (performed with G09/G16)
have much more stringent tests for optimization than those of MOPAC, in the screening of the HL structures,
value[MAPEmax] and value[BAPEmax] are set to MIN(MAPEmax, 0.001) and MIN(BAPEmax, 1 ),
respectively.

**eigLmax** value

[value is a float; default value: 0 ]

value is the maximum value for an eigL to be considered 0. In Spectral Graph Theory, the number of zero
eigLs provides the number of fragments in the system. This criterion is used to identify van der Waals
complexes that are formed by unimolecular fragmentation.

**Kinetics.** This part is employed to provide details for the kinetics calculations at the (experimental)
conditions you want to simulate. **This section is compulsory except for association.**

An example is given as follows.

--Kinetics--
Energy 150
The kinetics simulations will be carried out for a canonical (fixed temperature) or microcanonical (fixed
energy) ensemble, which have their associated keywords:

List of “ **Keyword** value(s)” for this section:

**Energy** value

[value is an integer; default value: 0 ]

value is the energy (in kcal/mol) for which microcanonical rate coefficients will be calculated.

**Temperature** value

[value is an integer; default value: 298 ]

value is the temperature (in K) for which thermal rate coefficients will be calculated. At present, only
temperatures in the range 100 - 9999 K are allowed.
