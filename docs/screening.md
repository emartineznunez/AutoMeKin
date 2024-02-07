---
title: Screening section
layout: home
parent: Input files
grand_parent: Tutorial
nav_order: 3
---

# Screening section

Some of the initially located structures might have very low imaginary frequencies, be repeated
or correspond to transition states of van der Waals complexes formed upon fragmentation of the reactant
molecule. To avoid or minimize low-imaginary-frequency structures, redundancies and van der Waals
complexes, amk includes a screening tool, which is based on the following descriptors: energy, [SPRINT
coordinates](https://journals.aps.org/prl/abstract/10.1103/PhysRevLett.107.085504), degrees of each vertex and eigenvalues of the Laplacian matrix. While the lowest eigenvalues of the Laplacian, eigL, are employed to discriminate fragmented structures, comparing the descriptors for any pair of structures, a mean absolute percentage error, MAPE, and a biggest absolute percentage error, BAPE are obtained.

In this section we set a minimum value for the imaginary frequency and maximum values for MAPE, BAPE
and eigL, as explained below:
```
--Screening --
imagmin 200
MAPEmax 0.008
BAPEmax 2.5
eigLmax 0.1
```

List of `Keyword value(s)` for this section:

{: .important }  
`imagmin value`   
[`value` is an integer; default value: `0` ]   
`value` is the minimum value for the imaginary frequency (in absolute value and cm<sup>−1</sup>) of the selected TS structures. Discarded structures will be stored in `tsdirLL_molecule/LOW_IMAG_TSs` to allow the user inspection of the rejected TSs.

{: .important }  
`MAPEmax value`  
[`value` is a float; default value: `0` ]   
`value` is the maximum value for MAPE.

{: .important }  
`BAPEmax value`   
[`value` is a float; default value: `0` ]   
`value` is the maximum value for BAPE.

If both, the MAPE and BAPE values calculated for two structures are below the values of MAPEmax and
BAPEmax, respectively, the structures are considered equivalent, and therefore only one is kept.

As a general advice, `value[MAPEmax]` and `value[BAPEmax]` should be small. A good starting point could
be the values provided in the input files of the examples. Since the HL calculations have much more stringent tests for optimization than those of MOPAC, in the screening of the HL structures, `value[MAPEmax]` and `value[BAPEmax]` are set to MIN$\scriptstyle{(}$MAPEmax, 0.001$\scriptstyle{)}$ and MIN$\scriptstyle{(}$BAPEmax, 1 $\scriptstyle{)}$,
respectively.

{: .important }  
`eigLmax value`   
[`value` is a float; default value: `0`]   
`value` is the maximum value for an eigL to be considered 0. In Spectral Graph Theory, the number of zero
eigLs provides the number of fragments in the system. This criterion is used to identify van der Waals
complexes that are formed by unimolecular fragmentation.


