---
title: Method section
layout: home
parent: Input files
grand_parent: Tutorial
nav_order: 2
---

# Method section

Here the user provides details of the method employed for sampling the reaction space. In our FA
example, we have the following:
```
--Method--
sampling MD
ntraj 10
```

List of <code>Keyword value(s)</code> for this section:

{: .important }  
<code>sampling value</code>    
[<code>value</code> is one string with no blank spaces; default value: <code>MD</code>]  
<code>value</code> can be: <code>MD</code>, <code>MD-micro</code>, <code>BXDE</code>, <code>external</code>, <code>ChemKnow</code>, <code>association</code> and <code>vdW</code>

<code>MD</code> and <code>MD-micro</code> refer to the type of initial conditions used to run the MD simulations. <code>MD-micro</code> _has not been implemented yet for qcore. With <code>BXDE</code> the rare-event [acceleration method named BXDE](https://chemistry-europe.onlinelibrary.wiley.com/doi/abs/10.1002/syst.201900024) is invoked. 

<code>MD</code> allows the user to include partial constraints in the trajectories, which may be useful for large systems (see the “advanced users” section for more details).

<code>external</code> allows trajectory data to be read from the results of an external (MD) program. The trajectory data (in XYZ format) must be stored in a directory named coordir using one file per trajectory which should be called <code>name_dynX.xyz</code>, where name is <code>value[molecule]</code>, and X is the number of each trajectory (X = 1 - ntraj). The keyword <code>ntraj</code> must be set accordingly.

<code>ChemKnow</code> makes all possible combinations of bond breakages/formations which are consistent with preset
valencies of the atoms and with products lying below the maximum energy of the system. Once the
combinations are known, the starting and ending points are obtained after a constrained MD simulation with
external forces applied to break/form the selected bonds. Then, a NEB calculation tries to obtain a path
connecting both states, and the highest point of the NEB is subjected to TS optimization. This sampling does not need to include the number of trajectories and _has not been implemented yet for qcore_.

{: .warning }  
To use <code>MD-micro</code> the initial structure needs to be fully optimized and a frequency calculation can not afford imaginary frequencies. Otherwise choose <code>MD</code>

<code>association</code> and <code>vdW</code> are employed to sample van der Waals structures, present some peculiarities and therefore are explained in detail in van der Waals complexes.

<code>MD</code>, <code>MD-micro</code>, <code>external</code> and <code>BXDE</code> samplings accept the following keywords (<code>BXDE</code> and <code>ChemKnow</code> also accept additional keywords as seen below):

{: .important }  
<code>barrierless value</code>   
[<code>value</code> is one string: <code>yes</code> or <code>no</code>; default value: <code>no</code>]   
<code>value</code> can be <code>yes</code>, in which case barrierless processes are searched. The keyword neighbors explained below is related to this one.

{: .important }   
<code>neighbors values</code>   
[three <code>values</code>: first is a string and last two are floats; default values (see table below)]   
The first <code>value</code> is an atomic symbol and the two numbers are the minimum and maximum number of
neighbors of the corresponding atoms. This keyword is needed if atoms other than those in the table below
are present in your system and/or if you want to change the default values. The number of neighbors is
employed to locate _barrierless processes_ and are also employed by <code>ChemKnow</code>. 

For instance, if you want to consider dissociations leading to atomic hydrogen, you must add the following line:
```
neighbors H 0 1
```
The default values are listed in this table:

|Atom|Min # of neighbors|Max # of neighbors|Atom|Min # of neighbors|Max # of neighbors|
|---|:---:|:---:|---|:---:|:---:|
|H|1|1|  Mg | 0  | 2  |
|Li|0|1| Al  | 1  | 3  |
|Be|0|2| Si  | 1  | 4  |
|B|1|3| P  | 1  | 5  |
|C|1|4| S  | 1  | 6  |
|N|1|3| Cl  | 0  | 1  |
|O|1|2| Br  | 0  | 1  |
|F|0|1| I  | 0  |  1 |
|Na|0|1|   |   |   |


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
