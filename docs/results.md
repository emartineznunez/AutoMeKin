---
title: Results
layout: home
parent: Tutorial
nav_order: 4
---

# Results

### a) Relevant information

Scripts final.sh and FINAL.sh are employed to collect all relevant information in FINALDIR
(FINAL_LL_FA and FINAL_HL_FA in our example, respectively). These folders contain files as well as a
subdirectory called normal_modes, which includes, for each structure, a file (in MOLDEN format) with
which you can visualize the corresponding normal modes. The files included in these folders are the
following.

**convergence.txt** lists the number of located transition states as a function of the number of trajectories
and iteration (Only in FINAL_LL_FA).

**Energy_profile.pdf** is an energy diagram with the _relevant paths_ , which are those that participate in
the dynamics at the conditions of interest. If you change the value[ImpPaths] in the kinetics section of
the input data (see below), you can incorporate/remove some pathways (the maximum number of TSs in
the profile is 100). In our example, the energy diagram is the following:

**frag_warnings.** contains information on failed ab initio calculations of the fragments. If all calculations
are successful, the file is absent. The file is located **in** FINAL_HL_FA **folder**.

**MINinfo** contains information of the minima:

MIN # DE(kcal/mol)
1 - 8.341


2 0.000
3 5.288
4 6.732
5 15.441
6 82.122
7 110.400
8 188.254
Conformational isomers are listed in the same line:
1 2
3 4 5
**TSinfo** contains information of the TSs:

TS # DE(kcal/mol)
1 - 1.624
2 1.868
3 9.644
4 25.135
5 32.821
6 37.608
7 40.956
8 44.037
9 53.173
10 58.156
11 60.015
12 85.659
13 142.228
14 188.765
15 191.650
Conformational isomers are listed in the same line:
9 11
In the above files, DE is the energy relative to that of the main structure specified in the FA.dat file
(optimized with the semiempirical Hamiltonian). The integers are used to identify, independently, minima
and transition states. Notice that, in this example, MIN 2 corresponds to the structure specified in FA.xyz.

**table.db** with table being min, prod and ts, which refer to the minima (intermediates), product
fragments and transition states, respectively. These are SQLite3 tables containing the geometries, energies
and frequencies of minima, products and TSs, respectively. The different properties can be obtained using
select.sh:

select.sh FINALDIR property table label

where property can be: natom, name, energy, zpe, g, geom, freq, formula (only for prod) or all, and
label is one of the numbers shown in RXNet (see below), which are employed to label each structure. At the
semiempirical level, the energy values correspond to heats of formation. For high-level calculations, the
tables collect the electronic energies. Please note that for the hybrid calculations involved through the use
of keyword LowLevel_TSopt, energies, zpe and frequencies in the tables are those obtained with MOPAC,
while the geometry in ts.db is the one obtained at the g09/g16 level of theory.

As an example, to obtain the geometry of the first low-level transition state of FA, you should use:


select.sh FINAL_LL_FA geom ts 1

**CAVEAT: MOPAC** optimizations of minimum-energy structures ( **min** ) might not be fully optimized and,
consequently, imaginary **frequencies** might arise for minima. Additionally, the frequencies obtained for
fragments ( **prod** ) are meaningless as these structures are not optimized.

**RXNet** contains information of the complete reaction network, that is all the elementary reactions found by
the amk program (the file shown below, and the following ones, were cut and show only up to TS 15 ).

TS # DE(kcal/mol) Reaction path information
==== ============ =========================
1 - 1.6 PR2: CO + H2O <---> PR2: CO + H2O
2 1.9 MIN 1 <---> MIN 2
3 9.6 MIN 3 <---> MIN 4
4 25.1 MIN 1 <---> MIN 1
5 32.8 PR2: CO + H2O <---> PR1: H2 + CO2
6 37.6 MIN 4 ----> PR2: CO + H2O
7 41.0 MIN 1 ----> PR2: CO + H2O
8 44.0 PR1: H2 + CO2 <---> PR1: H2 + CO2
9 53.2 MIN 1 <---> MIN 4
10 58.2 MIN 2 ----> PR1: H2 + CO2
11 60.0 MIN 2 <---> MIN 5
12 85.7 MIN 2 <---> MIN 6
13 142.2 MIN 3 <---> MIN 6
14 188.8 MIN 2 <---> MIN 8
15 191.7 MIN 7 <---> MIN 8
As can be seen, for each transition state, this file specifies the associated minima and/or product fragments
and their corresponding identification numbers. Notice that TS, MIN and PR have independent identification
numbers. If you use the option complete for the keyword HL_rxn_network (in the General section of
the input data), all the TSs will be reoptimized in the high-level calculations. You may reduce significantly the
number of TSs to be reoptimized in the HL calculations, and therefore the reaction network, if you use the
option reduced. If it is employed without an argument, TSs associated to PR <--> PR steps (i.e.,
bimolecular reactions) and to interconversion between optical isomers will not be reoptimized in the HL
calculations. You may include a number as an argument of this option:

HL_rxn_network reduced 55

In this case, besides the above TSs, all TSs having relative energies larger than 55 kcal/mol will not be
considered for HL optimizations, that is, they will not be included in the HL reaction network. We notice that
the last argument must be an integer.

**RXNet.barrless**. Barrierless reactions are included in this file (only when MOPAC and g09/g16 are
employed). The user must be aware that the channels are those consistent with the values of the keyword
neighbors explained above. These channels are not considered in the kinetics, but they are plotted in the
complete graph indicated below.


TS # DE(kcal/mol) Reaction path information
==== ============ =========================
1 152.8 MIN 1 ----> PR6: HO + CHO
2 170.4 MIN 3 ----> PR7: HO + CHO
3 150.6 MIN 6 ----> PR8: HO + CHO
Note that here TS refers to a dynamical TS and no saddle point exists in these paths.

**RXNet.cg**. By default (see below) the KMC calculations are “coarse-grained”, that is, conformational
isomers form a single state, which is taken as the lowest energy isomer. Such reaction network, which also
removes bimolecular channels, is the following:

TS # DE(kcal/mol) Reaction path information
==== ============ =========================
6 37.6 MIN 3 ----> PR2: CO + H2O CONN
7 41.0 MIN 1 ----> PR2: CO + H2O CONN
9 53.2 MIN 1 <---> MIN 3 CONN
10 58.2 MIN 1 ----> PR1: H2 + CO2 CONN
11 60.0 MIN 1 <---> MIN 3 CONN
12 85.7 MIN 1 <---> MIN 6 CONN
13 142.2 MIN 3 <---> MIN 6 CONN
14 188.8 MIN 1 <---> MIN 8 DISCONN
15 191.7 MIN 7 <---> MIN 8 DISCONN
The last column with the flag “CONN” or “DISCONN” indicates whether the given process is connected with
the others (CONN) or whether it is isolated (DISCONN). This flag is useful when you choose a starting
intermediate for the KMC simulations, because that intermediate should be connected. If you want to
include all conformational isomers explicitly in the KMC simulations, you need to construct the reaction
network by using the allstates option, as described in the next section.

**RXNet.rel** is similar to RXNet.cg, but only collects the relevant paths, that is, those included in the
Energy_profile.pdf file. A maximum of 100 TSs are printed in this file. If this number is reached, both
Energy_profile.pdf and RXNet.rel would be incomplete, and the pathways drawn in
Energy_profile.pdf could be less than those that appear in RXNet.rel.

**rxn_x.txt (x = all, kin, stats)** are files with information relevant for the reaction network analysis
made with NetworkX python library.^6 Each line of rxn_all.txt lists the nodes (first two columns) and the
weight (last column), which is the number of paths connecting the two nodes. For rxn_kin.txt the weight
is the total flux in the kinetics simulations. These two files are employed to construct graph_all.pdf and
graph_kin.pdf, respectively. In rxn_stats.txt, some properties of the reaction network are listed, like
the average shortest path length, the average clustering coefficient, the transitivity, etc. The user is
encouraged to read the NetworkX documentation and ref 7.

**To generate a meaningful rxn_stats.txt file use the following script from the amk_tools repository:**

amk_rxn_stats.py FINALDIR


**The file rxn_stats.txt will be created in the working directory (not inside FINALDIR).**

**kineticsFvalue** contains the kinetics results, namely, the final branching ratios and the population of
every species as a function of time. In the name of the file, **F** is either “ **T** ” or “ **E** ” for temperature or energy,
and “ **value** ” is the corresponding value. For instance, the kinetics results for a canonical calculation at 298
K would be printed in a file called kineticsT298. A file called populationFvalue.pdf is also available.
It is a plot with the population of each species as a function of time. A maximum of 20 species (the most
populated ones) are plotted. The following figure shows an example of such a plot obtained for the
decomposition of FA using the PM7 stationary points.

### b) Visualization tools

The Python library amk-tools developed by Diego Garay (Institute of Chemical Research of Catalonia Prof.
Carles Bo Research group) is a useful package to parse, process and transform the reaction networks created
by AutoMeKin (https://github.com/dgarayr/amk_tools ). All the data contained in FINALDIR can be easily
accessed using these tools.

The commandline script amk_gen_view.py allows to generate visualizations directly taking arguments
from STDIN:

amk_gen.py FINALDIR RXNFILE


where RXNFILE is the name of the RXNet files explained above (RXNet, RXNet.cg or RXNet.rel). Additional
arguments that may be passed are:

```
--barrierless. Include the barrierless routes stored in RXNet.barrless.
--vibrations NVIBR. Add only NVIBR normal modes to the visualization. Default is -1, meaning that ALL
modes are included.
--paths [SOURCE] [TARGET] Locate paths in the network connecting SOURCE to TARGET, to include
energy profile visualizations in the dashboards. When both SOURCE and TARGET are specified, a simple
search is performed including only the routes that connect both nodes. If --paths is passed without
further specification, all possible cyclic paths along the network are searched (much slower). If only
SOURCE is specified, all cyclic paths are also searched, and then filtered to only keep these with
connections to SOURCE.
--cutoff_path CUTOFF. Maximum depth for two-ended path search (number of intermediate nodes
between SOURCE and TARGET), default is 4.
--outfile FILENAME. Name of the output HTML file containing the dashboard.
--title TITLE. Title shown in the dashboard.
```
The following example shows how to create interactive plots from RXNet.cg file including all paths found at
low level for Formic Acid (FA):

amk_gen.py FINAL_LL_FA RXNet.cg --b --paths

While this one creates the corresponding plots for the paths that connect MIN1 with the H 2 + CO 2 products:

amk_gen.py FINAL_LL_FA RXNet.cg --paths MIN1 H2+CO2

More details can be found here: https://github.com/dgarayr/amk_tools/blob/master/UserGuide.md

Example of an interactive dashboard (for FA), with the reaction network on the left and a selected edge (TS)
on the right. Clicking on “Show profile” enables visualization of the energy profile as well.


### c) Kinetics simulations at different temperatures

The kinetics calculations can be rerun for a temperature/energy different from that specified in the input file
after the keywords Temperature or Energy. You may also want to use the allstates option (see
below). This can be easily done using the kinetics.sh command line script:

kinetics.sh value calc (allstates)

where value is the new value of the temperature (in K) or energy (in kcal/mol) depending on your initial
choice in the Kinetics section, and calc is either ll (for low-level) or hl (for high-level). Finally, with no
other options, the conformational isomers will form a single state (default for all sampling except vdW).
However, using allstates as the last argument, the calculations will regard every conformational isomer
as a different state (default for vdW). Each calculation will create a new folder named
FINAL_XL_molecule_Fvalue (with X = H,L and F=T,E)

### d) Removing unwanted TS structures

As explained above, the use of very tight criteria in the screening process might lead to redundant TS
structures in the FINAL directories. In those cases, the user can remove those structures as shown in the
following example:

remove_ts.sh 2 4 7

where 2 , 4 and 7 are the labels of the TSs to be removed (for the LL calculations). The corresponding script
for the HL calculations is REMOVE_TS.sh. These two scripts will create a new FINAL_XL_FA (with X = H,L)
directory where the selected TS structures have been removed.