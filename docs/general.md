---
title: General section
layout: home
parent: Input files
grand_parent: Tutorial
nav_order: 1
---

# General section

In this section the electronic structure details are provided. The following is an example of the
keywords employed in this section for the FA molecule.
```
--General--  
molecule       FA  
LowLevel       mopac pm7 t=3m  
HighLevel      g16 b3lyp/6-31G(d,p)  
HL_rxn_network complete  
IRCpoints      30  
charge         0  
mult           1  
```
List of <code>Keyword value(s)</code> for this section:

{: .important }  
<code>molecule value</code>   
[<code>value</code> is one string with no blank spaces; _mandatory keyword_]  

<code>value</code> is the name of the system and _it must match the name of the XYZ file without the extension, FA in our example. For association and vdW sampling there is no XYZ file at the beginning and
<code>value</code> is just the name of the system._


{: .important }  
<code>LowLevel values</code>   
[two <code>values</code>: two strings; the second string accepts blank spaces; default: <code>mopac pm7</code>]  

The first <code>value</code> is the program and the second the semiempirical method. So far, <code>qcore</code> and <code>mopac</code> are valid programs. For <code>qcore</code> only <code>xtb</code> method is implemented, and for <code>mopac</code>, any of the semiempirical methods of MOPAC2016 can be employed to run the MD simulations. You can use a combination of MOPAC keywords. In the example above, for instance, the pm7 semiempirical level together with a maximum CPU time, for any type of mopac calculation, of 3 minutes is requested. _The use of the MOPAC keyword t=, followed by an amount of time, is highly recommended to enhance the efficiency of the calculations._

If you do not employ the keyword <code>LowLevel_TSopt</code>, explained below in advanced options, both the low-level TS optimizations and MD simulations are carried out using the semiempirical method specified by the second value. This is in general a good choice both in terms of efficacy and efficiency, and also because all structures will be re-optimized later using ab initio/DFT methods as specified with the keyword HighLevel.

However, if you know that semiempirical methods do not work well for your system, and although they are
going to be employed for the MD sampling, you can still pick one
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
For <code>g09/g16</code>, supported methods are HF, MP2 and DFT for geometry optimizations and HF, MP2, DFT and CCSD$($T$)$ for single point energy calculations.

For <code>qcore</code>, the method is specified in an additional file named qcore_template. An example of such file is given in the FA_qcore example. This option also allows an extra keyword: <code>hessianmethod</code>, which could accept the values <code>analytic</code> or <code>semianalytic</code>.

{: .important }  
<code>HL_rxn_network value(s)</code>  
[one or two <code>values</code>: first is a string, and second, if present, is an integer; default value: <code>reduced</code>]

The first value can be <code>complete</code> or <code>reduced</code>. <code>complete</code> indicates that all the TSs will be reoptimized and in this case no second value is needed.

Alternatively, you may use <code>reduced</code> as the first value, the default, followed by a second <code>value</code>, an integer, which indicates the maximum energy, in kcal/mol and relative to the reference starting structure, of a transition state to be calculated at the high level.

{: .important }  
<code>IRCpoints value</code>  
[<code>value</code> is an integer; default value: <code>100</code> ]

<code>value</code> is the maximum number of IRC points in each direction computed at the high-level. Note that g09/g16 calculations need much fewer points than Entos Qcore.

{: .important }  
<code>charge value</code>  
[<code>value</code> is an integer; default value: <code>0</code> ]  
<code>value</code> is the charge of the system.

{: .important }  
<code>Memory value</code>  
[<code>value</code> is an integer; default value: <code>1</code> ]  
<code>value</code> is the number of GB of memory employed in the gaussian high-level calculations.

{: .important }  
<code>mult value</code>  
[<code>value</code> is an integer; default value: <code>1</code> ]   
<code>value</code> is the multiplicity of the system. Note that this keyword is only employed in the HL calculations. If you want to run the LL calculations with a specific multiplicity, this should be specified in the <code>LowLevel</code> keyword using any of the possibilities that MOPAC offers.
