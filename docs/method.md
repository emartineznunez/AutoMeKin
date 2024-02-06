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
ntraj    10
```

List of <code>Keyword value(s)</code> for this section:

{: .important }  
<code>sampling value</code>    
[<code>value</code> is one string with no blank spaces; default value: <code>MD</code>]  
<code>value</code> can be: <code>MD</code>, <code>MD-micro</code>, <code>BXDE</code>, <code>external</code>, <code>ChemKnow</code>, <code>association</code> and <code>vdW</code>

<code>MD</code> and <code>MD-micro</code> refer to the type of initial conditions used to run the MD simulations. <code>MD-micro</code> _has not been implemented yet for qcore. With <code>BXDE</code> the rare-event [acceleration method named BXDE](https://chemistry-europe.onlinelibrary.wiley.com/doi/abs/10.1002/syst.201900024) is invoked. 

<code>MD</code> allows the user to include partial constraints in the trajectories, which may be useful for large systems.

<code>external</code> allows trajectory data to be read from the results of an external MD program. The trajectory data in XYZ format must be stored in a directory named coordir using one file per trajectory which should be called <code>name_dynX.xyz</code>, where name is <code>value[molecule]</code>, and X is the number of each trajectory, with X = 1 - ntraj. The keyword <code>ntraj</code> must be set accordingly.

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
[three <code>values</code>: first is a string and last two are floats; default values, see table below]   
The first <code>value</code> is an atomic symbol and the two numbers are the minimum and maximum number of
neighbors of the corresponding atoms. This keyword is needed if atoms other than those in the table below
are present in your system and/or if you want to change the default values. The number of neighbors is
employed to locate _barrierless processes_ and are also employed by <code>ChemKnow</code>. 

For instance, if you want to consider dissociations leading to atomic hydrogen, you must add the following line:
```
neighbors H 0 1
```
You can add as many lines as needed, one per atom. The default values are listed in this table:

|Atom|Min # of neighbors|Max # of neighbors|Atom|Min # of neighbors|Max # of neighbors|
|:---:|:---:|:---:|:---:|:---:|:---:|
|H|1|1|  Mg | 0  | 2  |
|Li|0|1| Al  | 1  | 3  |
|Be|0|2| Si  | 1  | 4  |
|B|1|3| P  | 1  | 5  |
|C|1|4| S  | 1  | 6  |
|N|1|3| Cl  | 0  | 1  |
|O|1|2| Br  | 0  | 1  |
|F|0|1| I  | 0  |  1 |
|Na|0|1|   |   |   |

{: .important }  
<code>ntraj value</code>   
[<code>value</code> is an integer; default value: <code>1</code> ]  
<code>value</code> is the number of trajectories. We strongly recommend here to avoid using big numbers of
trajectories. Instead, the user should try to run different batches of trajectories as indicated below with a small number of trajectories each one. One trajectory is recommended for BXDE and about 10 for MD-based sampling.

{: .important }  
<code>seed value</code>  
[<code>value</code> is an integer; _only valid for <code>MD</code> and <code>MD-micro</code>_ ; default value: <code>0</code> ]   
<code>value</code> is the seed of the random number generator. It can be employed to run a test trajectory. See the <code>FA_singletraj.dat</code> file in the examples. _Only use this keyword for testing_.

## BXDE specific keywords 

This sampling (and the other BXDE-based sampling based: <code>vdW</code>) has a number of specific keywords as shown in this example:
```
sampling      BXDE
Friction      0.5
AdaptiveLimit 100
Window        500
Hookean       1 2 2.5 10.
```

{: .important }  
<code>Friction value</code>  
[<code>value</code> is a float; default value: <code>0.5</code>]   
<code>value</code> is the friction coefficient in a.u. employed in the Langevin dynamics of a BXDE simulation.

{: .important }  
<code>AdaptiveLimit value</code>  
[<code>value</code> is an integer; default value: <code>100</code> ]   
<code>value</code> determines how many MD steps are performed in a new box before the BXDE algorithm adaptively places a new box based upon the sampled energies.

{: .important }  
<code>Window value</code>   
[<code>value</code> is an integer; default value: <code>500</code> ]   
<code>value</code> determines the number of consecutive MD steps before considering a reaction to have occurred.

{: .important }   
<code>Hookean values</code>   
[four <code>values</code>: first (`i`) and second (`j`) are integers, third (`rt`) and fourth (`k`) are floats]   
<code>Hookean</code> keyword can be employed with any BXDE-based dynamics sampling. It employs ASE’s [Hookean class](https://wiki.fysik.dtu.dk/ase/ase/constraints.html#the-hookean-class) to conserve molecular identity. A Hookean restorative force with spring constant given by the fourth value (in eV/Å<sup>2</sup>) is applied between two atoms of indices given by the first and second values if the distance between them exceeds a threshold, `rt`. 

## ChemKnow specific keywords 

This sampling has a number of specific keywords as shown in this example:
```
sampling  ChemKnow
Graphto3D POpt
active    1 2 3 4
startd    2.75
MaxBoF    2
MaxBoB    2
comb22    no
crossb    no
BreakRing no
CK_minima all
```

{: .important}  
<code>Graphto3D value</code>   
[<code>value</code> is a string: <code>POpt</code> or <code>Traj</code>; default value: <code>POpt</code>]   
<code>value</code> is the method employed to transform the product Graph into a 3D geometry. <code>POpt</code> performs a series of partial optimizations, with the bonds involved in the reaction coordinate frozen, where the geometry is smootly changed from reactant to product. In <code>Traj</code>, an external force is applied for the same purpose.

{: .important }  
<code>active values</code>   
[<code>values</code> are integers]   
<code>values</code> are the labels of the atoms that participate in the reactions we are interested in. By default, all atoms in the system are active.

{: .important }   
<code>startd value</code>  
[<code>value</code> is a float; default value: <code>2.75</code>]   
<code>value</code> is the maximum distance between active atoms to be considered in a bond formation.

{: .important }   
<code>MaxBoF/MaxBoB value</code>   
[<code>value</code> is an integer; default value: <code>2</code>]   
<code>value</code> is the maximum number of bonds formed (n<sub>F</sub>)/broken (<sub>nB</sub>) to make all possible (n<sub>F</sub>,n<sub>B</sub>) combinations for Graph transformations.

{: .important }   
<code>comb22 value</code>   
[<code>value</code> is a string: <code>yes</code> or <code>no</code>; default value: <code>no</code>]   
By default, the $\scriptstyle{(}$2,2$\scriptstyle{)}$ combination is not considered.

{: .important }   
<code>crossb value</code>
[<code>value</code> is a string: <code>yes</code> or <code>no</code>; default value: <code>no</code>]   
A check can be done to see if the closest distance between the paths followed by the atoms in their
rearrangements is lower that a threshold value, a potential problem in planar molecules or planar regions
of a molecule. By default, this check is not done.

{: .important }   
<code>BreakRing value</code>   
[<code>value</code> is a string: <code>yes</code> or <code>no</code>; default value: <code>no</code>]  
By default, a bond that belongs to a ring is not broken in $\scriptstyle{(}$0,1$\scriptstyle{)}$ transformations. However, there might be ring opening reactions of our interest.

{: .important }  
<code>CK_minima value</code>   
[<code>value</code> is a string: <code>all</code> or <code>cg</code>; default value: <code>all</code>]   
By default, all minima are used for graph transformations including conformers. With the value <code>cg</code>, only the lowest energy member of each family of conformers is utilized.
