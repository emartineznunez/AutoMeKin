---
title: Tutorial
layout: home
nav_order: 4
has_children: true
---

# Tutorial

**AutoMeKin** (_amk_ for short), which stands for Automated Mechanisms and Kinetics, is an automated protocol to
discover chemical reaction mechanisms and simulate the kinetics at the conditions of interest. Although the
method was originally designed to find transition states, TSs, from reactive molecular dynamics, MD,
simulations, several new tools have been incorporated throughout the past few years. The current pipeline
consists of three steps:

1. Exploration of reaction mechanisms through MD simulations or chemical knowledge-based
algorithms.
2. Use of Graph Theory algorithms to build the reaction network, RXNet.
3. Kinetics simulations.

The program is interfaced with [MOPAC2016](https://github.com/openmopac/mopac), [Qcore](https://software.entos.ai/qcore/documentation/) and [Gaussian, G09 or G16](https://gaussian.com/), but work is in progress to
incorporate more electronic structure programs. This tutorial is thought to guide you through the various
steps needed to predict reaction mechanisms and kinetics of unimolecular decompositions. To facilitate the
presentation, we consider, as an example, the decomposition of formic acid, FA. Users are encouraged to
read references [JCC-2015](https://onlinelibrary.wiley.com/doi/abs/10.1002/jcc.23790) [PCCP-2015](https://pubs.rsc.org/en/content/articlelanding/2015/cp/c5cp02175h) [JCC-2021](https://onlinelibrary.wiley.com/doi/full/10.1002/jcc.26734) before using AutoMeKin package.

The present version has been tested on CentOS 7, Red Hat Enterprise Linux and Ubuntu 16.04.3 LTS. If you
find a bug, please report it to the main developer (<emilio.nunez@usc.gal>). Comments and suggestions are
also welcome.
