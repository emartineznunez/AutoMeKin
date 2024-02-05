# Automated Mechanisms and Kinetics (AutoMeKin)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/emartineznunez/AutoMeKin/blob/main/AutoMeKin.ipynb) [![Download AutoMeKin](https://img.shields.io/sourceforge/dm/automekin.svg)](https://sourceforge.net/projects/automekin/files/latest/download) [![Twitter](https://img.shields.io/twitter/url/https/twitter.com/AutoMeKin2021.svg?style=social&label=Follow%20%40AutoMeKin2021)](https://twitter.com/AutoMeKin2021)


### This is the official repository of the automated reaction discovery program **AutoMeKin**[^1].

<p align="left">
   <img src="logo.png" alt="alt text" width="200" height="100">
</p>


AutoMeKin (formerly tsscds) has been designed to discover reaction mechanisms in an automated fashion. Transition states are located using MD simulations and Graph Theory algorithms. Monte Carlo simulations afford kinetic results. The only input is a starting structure in XYZ format. The method is described in these two publications: [1](https://onlinelibrary.wiley.com/doi/abs/10.1002/jcc.23790) [2](https://pubs.rsc.org/en/content/articlelanding/2015/cp/c5cp02175h#!divAbstract). At present [MOPAC2016](https://github.com/openmopac/mopac), [Entos Qcore](https://software.entos.ai/qcore/documentation/) and [Gaussian (G09/G16)](https://gaussian.com/) are interfaced with AutoMeKin. The program has been tested on the following Linux distros: CentOS 7, Red Hat Enterprise Linux and Ubuntu 20.04 LTS.


- The documentation page is under construction: https://emartineznunez.github.io/AutoMeKin/
- In the mean time, the old wiki can be consulted: https://github.com/emartineznunez/AutoMeKin/wiki
- Simple example in Colab: 
[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/emartineznunez/AutoMeKin/blob/main/AutoMeKin.ipynb)
- Simple problems _via_ the following web site:  https://rxnkin.usc.es/amk/

## Installation
The installation instructions are [detailed here](https://emartineznunez.github.io/AutoMeKin/)


[^1]: For enquiries please contact: emilio.nunez@usc.es
