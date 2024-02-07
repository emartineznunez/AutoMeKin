---
title: Tutorial
layout: home
nav_order: 4
has_children: true
---

# Tutorial

The first step in our strategy for finding reaction mechanisms involves Heuristics- or MD-based methods, for which MOPAC 2016 or Entos Qcore are used. The algorithm samples the potential energy surface to locate
transition states by using the original [BBFS algorithm](https://onlinelibrary.wiley.com/doi/abs/10.1002/jcc.23790), or a [bond-order-based search algorithm](https://pubs.acs.org/doi/abs/10.1021/acs.jctc.9b01039). Then, reactants and products are obtained by intrinsic reaction coordinate, IRC, calculations. Finally, a reaction network is
constructed with all the elementary reactions predicted by the program. To increase the efficacy of
AutoMeKin, this process may be carried out in an iterative fashion as described in [PCCP-2015](https://pubs.rsc.org/en/content/articlelanding/2015/cp/c5cp02175h). Once the
reaction network has been predicted at the semiempirical level, the user can calculate rate constants for all the elementary reactions and run Kinetic Monte Carlo, KMC, calculations to predict the time evolution of all the chemical species involved in the global reaction mechanism and to calculate product ratios.

In a subsequent step, the collection of TSs located at the semiempirical level are reoptimized using a higher level of electronic structure theory. Notice that, depending on the selected level of theory, the total number of reoptimized TSs may differ from that obtained with the semiempirical Hamiltonian. For each reoptimized
TS, IRC calculations are performed to obtain the associated reactant and products. The reaction
network is then constructed for the high level of theory. As for the low-level computations, the last step
involves the calculation of rate constants and product ratios. At present, the high-level electronic structure calculations can be performed with G09/G16 or with Entos Qcore.

{: .highlight }
To follow the guidelines of this tutorial, you can try the formic acid (`FA`) test case that comes with the
distribution. Make a working directory (<code>wrkdir</code>) and copy files <code>FA.dat</code> and <code>FA.xyz</code> from <code>path_to_program/examples</code> to your <code>wrkdir</code>. All scripts must be run from your <code>wrkdir</code>.

{: .note }
As a general advise, use short names for the <code>wrkdir</code> and the input files. Good choices are short acronyms using capital letters like FA for formic acid. 
