---
title: Input files
layout: home
parent: Tutorial
nav_order: 2
has_children: true
---

# Input files

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
```
keyword value(s)
```
<code>keyword</code> is a case-sensitive string and it must be the first field of the line.

<code>value(s)</code> can be strings, integers or floats and is/are the `value(s)` of the keyword.

_At least one blank space must be kept between_ `keyword` and `value(s)`. A few keywords include some
additional lines right below the keyword line (see _Biased dynamics_).

Example of a `.dat` file:
```
--General--
molecule       FA
LowLevel       mopac pm7
HighLevel      g09 hf/sto-3g
HL_rxn_network complete
IRCpoints      29
charge         0
mult           1

--Method--
sampling    MD
ntraj       10
barrierless yes

--Screening--
imagmin 200
MAPEmax 0.008
BAPEmax 2.5
eigLmax 0.1

--Kinetics--
Energy 150
``` 




Next, you will find a detailed explanation of the keywords grouped together in the different sections. For
each section, only the most important keywords are described. Additional keywords can be found in
[Other capabilities](https://emartineznunez.github.io/AutoMeKin/docs/other.html).
