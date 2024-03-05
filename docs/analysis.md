---
title: Analysis
layout: home
parent: Tutorial
nav_order: 5
---

# Analysis

## Contents
- [Visualization tools](#amktools)
- [Properties of the reaction network](#amktools2)
- [Kinetics simulations at different temperatures](#kint)
- [Removing unwanted TS structures](#rmts)

## Visualization tools<a name="amktools"></a>

The Python library [![GitHub - amk_tools](https://img.shields.io/badge/GitHub-amk_tools-blue?logo=github)](https://github.com/dgarayr/amk_tools/) developed by Diego Garay at  the Institute of Chemical Research of Catalonia, is a useful package to parse, process and transform the reaction networks created by AutoMeKin. All the data contained in `FINALDIR` can be easily accessed using these tools.

The commandline script `amk_gen_view.py` allows to generate visualizations directly taking arguments
from STDIN:
```bash
amk_gen.py FINALDIR RXNFILE
```` 
where `RXNFILE` is the name of the `RXNet` files explained above (`RXNet`, `RXNet.cg` or `RXNet.rel`). Additional arguments that may be passed are [detailed here](https://github.com/dgarayr/amk_tools/blob/master/UserGuide.md).

The following example shows how to create interactive plots from `RXNet.cg` file including all paths found at low level for Formic Acid:
```bash
amk_gen.py FINAL_LL_FA RXNet.cg --b --paths
```
While this one creates the corresponding plots for the paths that connect MIN1 with the H<sub>2</sub>+CO<sub>2</sub> products:
```bash
amk_gen.py FINAL_LL_FA RXNet.cg --paths MIN1 H2+CO2
```
More details can be found in the [user guide](https://github.com/dgarayr/amk_tools/blob/master/UserGuide.md)

Example of an interactive dashboard for FA, with the reaction network on the left and a selected edge, _i.e._, TS, on the right. Clicking on “Show profile” enables visualization of the energy profile as well.
<p align="center">
   <img src="https://raw.githubusercontent.com/emartineznunez/AutoMeKin/gh-pages/assets/images/amk.jpg" alt="alt text" width="800" height="400">
</p>

## Properties of the reaction network<a name="amktools2"></a>

Another commandline script from the same Python library [![GitHub - amk_tools](https://img.shields.io/badge/GitHub-amk_tools-blue?logo=github)](https://github.com/dgarayr/amk_tools/) can be used to obtain the properties of the reaction network: 
```bash
amk_rxn_stats.py FINALDIR
```

Properties like the average shortest path length, the average clustering coefficient or the transitivity will be printed in a file called `rxn_stats.txt`.



## Kinetics simulations at different temperatures<a name="kint"></a>

The kinetics calculations can be rerun for a temperature/energy different from that specified in the input file after the keywords Temperature or Energy. You may also want to use the allstates option as seen below. This can be easily done using the `kinetics.sh` command line script:
```bash
kinetics.sh value calc (allstates)
```
where `value` is the new value of the temperature in K or energy in kcal/mol, depending on your initial
choice in the Kinetics section, and `calc` is either `ll`, for low-level, or `hl`, for high-level. Finally, with no other options, the conformational isomers will form a single state, which is the default for all sampling except vdW. However, using `allstates` as the last argument, the calculations will regard every conformational isomer as a different state, which is the default for vdW. Each calculation will create a new folder named `FINAL_XL_molecule_Fvalue`, with X = H,L and F=T,E.

## Removing unwanted TS structures<a name="rmts"></a>

As explained above, the use of very tight criteria in the screening process might lead to redundant TS
structures in the `FINAL` directories. In those cases, the user can remove those structures as shown in the
following example:
```bash
remove_ts.sh 2 4 7
```
where 2 , 4 and 7 are the labels of the TSs to be removed for the LL calculations. The corresponding script for the HL calculations is `REMOVE_TS.sh`. These two scripts will create a new `FINAL_XL_FA` $\scriptstyle{(}$X = H,L$\scriptstyle{)}$ directory where the selected TS structures have been removed.
