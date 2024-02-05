---
title: Tutorial
layout: home
nav_order: 4
has_children: true
---

# Tutorial

AutoMeKin (_amk_ for short), which stands for Automated Mechanisms and Kinetics, is an automated protocol to
discover chemical reaction mechanisms and simulate the kinetics at the conditions of interest. Although the
method was originally designed to find transition states (TSs) from reactive molecular dynamics (MD)
simulations, several new tools have been incorporated throughout the past few years. The current pipeline
consists of three steps:

1. Exploration of reaction mechanisms through MD simulations or chemical knowledge-based
algorithms.
2. Use of Graph Theory algorithms to build the reaction network (RXNet).
3. Kinetics simulations.

The program is interfaced with [MOPAC2016](https://github.com/openmopac/mopac), [Qcore](https://software.entos.ai/qcore/documentation/) and [Gaussian (G09/G16)](https://gaussian.com/), but work is in progress to
incorporate more electronic structure programs. This tutorial is thought to guide you through the various
steps needed to predict reaction mechanisms and kinetics of unimolecular decompositions. To facilitate the
presentation, we consider, as an example, the decomposition of formic acid (FA). Users are encouraged to
read references [JCC-2015](https://onlinelibrary.wiley.com/doi/abs/10.1002/jcc.23790) [PCCP-2015](https://pubs.rsc.org/en/content/articlelanding/2015/cp/c5cp02175h) [JCC-2021](https://onlinelibrary.wiley.com/doi/full/10.1002/jcc.26734) before using AutoMeKin package.

The present version has been tested on CentOS 7, Red Hat Enterprise Linux and Ubuntu 16.04.3 LTS. If you
find a bug, please report it to the main developer (<emilio.nunez@usc.es>). Comments and suggestions are
also welcome.








  
3. Shannon, R. J.; Amabilino, S.; O’Connor, M.; Shalishilin, D. V.; Glowacki, D. R., Adaptively Accelerating Reactive
Molecular Dynamics Using Boxed Molecular Dynamics in Energy Space. _Journal of Chemical Theory and Computation_
**2018,** _14_ (9), 4541-4552.
4. Hjorth Larsen, A.; Jørgen Mortensen, J.; Blomqvist, J.; Castelli, I. E.; Christensen, R.; Dułak, M.; Friis, J.; Groves,
M. N.; Hammer, B.; Hargus, C.; Hermes, E. D.; Jennings, P. C.; Bjerre Jensen, P.; Kermode, J.; Kitchin, J. R.; Leonhard
Kolsbjerg, E.; Kubal, J.; Kaasbjerg, K.; Lysgaard, S.; Bergmann Maronsson, J.; Maxson, T.; Olsen, T.; Pastewka, L.;
Peterson, A.; Rostgaard, C.; Schiøtz, J.; Schütt, O.; Strange, M.; Thygesen, K. S.; Vegge, T.; Vilhelmsen, L.; Walter, M.; Zeng, Z.; Jacobsen, K. W., The atomic simulation environment—a Python library for working with atoms. _Journal of Physics: Condensed Matter_ **2017,** _29_ (27), 273002.
5. Pietrucci, F.; Andreoni, W., _Phys. Rev. Lett._ **2011,** _107_ , 085504.
6. Hagberg, A. A.; Shult, D. A.; Swart, P. J. In _Exploring network structure, dynamics, and function using NetworkX_ ,
7th Python in Science Conference (SciPy2008), Pasadena, CA USA, Varoquaux, G.; Vaught, T.; Millman, J., Eds.
Pasadena, CA USA, 2008; pp 11-15.
7. Jara-Toro, R. A.; Pino, G. A.; Glowacki, D. R.; Shannon, R. J.; Martínez-Núñez, E., Enhancing Automated Reaction
Discovery with Boxed Molecular Dynamics in Energy Space. _ChemSystemsChem_ **2020,** _2_ , e1900024.
8. Kopec, S.; Martínez-Núñez, E.; Soto, J.; Peláez, D., vdW-TSSCDS—An automated and global procedure for the
computation of stationary points on intermolecular potential energy surfaces. _International Journal of Quantum
Chemistry_ **2019,** _119_ (21), e26008.
9. Hutchings, M.; Liu, J.; Qiu, Y.; Song, C.; Wang, L.-P., Bond order time series analysis for detecting reaction
events in ab initio molecular dynamics simulations. _J. Chem. Theor. Comput._ **2020**.
10. Martinez-Nunez, E.; Shalashilin, D. V., Acceleration of classical mechanics by phase space constraints. _Journal
of Chemical Theory and Computation_ **2006,** _2_ (4), 912-919.
