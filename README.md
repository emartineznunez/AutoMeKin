<p align="center">
  <img src="https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/svg/26a0.svg" alt="Warning" width="110" height="110">
</p>

<h2 align="center">This repository has moved to <a href="https://github.com/ComputationalChem-USC/AutoMeKin-X">AutoMeKin-X</a> and is no longer maintained</h2>

> [!WARNING]
> **This repository has moved and is no longer maintained.**
>
> AutoMeKin development now continues as **[AutoMeKin-X](https://github.com/ComputationalChem-USC/AutoMeKin-X)**, led by [Omar Rodríguez López](https://github.com/OmarRodriguezLopez1398). This repository is kept only for reference and for reproducibility of earlier work. It will not receive new features or bug fixes, and new issues and pull requests should be opened in AutoMeKin-X.
>
> AutoMeKin-X adds, among other things, an [ORCA](https://orcaforum.kofo.mpg.de/) interface and **machine-learning interatomic potentials (MLIPs)** as efficient alternatives to DFT for automated reaction discovery.
>
> - Code: https://github.com/ComputationalChem-USC/AutoMeKin-X
> - Documentation: https://computationalchem-usc.github.io/AutoMeKin-X/
> - Colab notebook: [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/ComputationalChem-USC/AutoMeKin-X/blob/main/notebooks/AutoMeKin.ipynb)

# Automated Mechanisms and Kinetics (AutoMeKin)

[![Status: no longer maintained](https://img.shields.io/badge/status-moved%20to%20AutoMeKin--X-red.svg)](https://github.com/ComputationalChem-USC/AutoMeKin-X) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/emartineznunez/AutoMeKin/blob/main/notebooks/AutoMeKin.ipynb)  [![Sylabs - AutoMeKin](https://img.shields.io/badge/Sylabs-AutoMeKin-2ea44f)](https://cloud.sylabs.io/library/emartineznunez/default/automekin) [![DOI](https://zenodo.org/badge/476189550.svg)](https://zenodo.org/doi/10.5281/zenodo.10674957)  [![AutoMeKin - SOURCEFORGE](https://img.shields.io/badge/AutoMeKin-SOURCEFORGE-2ea44f?logo=%23FF6600)](https://sourceforge.net/projects/automekin-rev1140/)

### This was the official repository of the automated reaction discovery program **AutoMeKin**. The official repository is now [AutoMeKin-X](https://github.com/ComputationalChem-USC/AutoMeKin-X).

<p align="left">
   <img src="logo.png" alt="alt text" width="200" height="100">
</p>

<code>AutoMeKin</code> (formerly <code>tsscds</code>) has been designed to discover reaction mechanisms in an automated fashion. Transition states are located using MD simulations and Graph Theory algorithms. Monte Carlo simulations afford kinetic results. The only input is a starting structure in XYZ format. The method is described in these two publications: [1](https://onlinelibrary.wiley.com/doi/abs/10.1002/jcc.23790) [2](https://pubs.rsc.org/en/content/articlelanding/2015/cp/c5cp02175h#!divAbstract). 

Our custom version of [MOPAC](https://github.com/openmopac/mopac) is built-in, and the following quantum engines are interfaced with <code>AutoMeKin</code>: [Entos Qcore](https://software.entos.ai/qcore/documentation/) and [Gaussian (G09/G16)](https://gaussian.com/). 

## Content
- [Installation and documentation](#inst)
- [Simple examples in Colab](#colab)
- [Web for submitting simple examples](#web)

## Installation and documentation <a name="inst"></a>
Verify if your version is up to date [here](https://github.com/emartineznunez/AutoMeKin/blob/main/ChangeLog.md)    
The installation instructions and much more are [detailed here](https://emartineznunez.github.io/AutoMeKin). For the current version, see the [AutoMeKin-X documentation](https://computationalchem-usc.github.io/AutoMeKin-X/).

## Simple example in Colab<a name="colab"></a>
You can have a look at this [Notebook](https://colab.research.google.com/github/emartineznunez/AutoMeKin/blob/main/notebooks/AutoMeKin.ipynb) to install it, test a simple example and more...

This second [Notebook](https://colab.research.google.com/github/emartineznunez/AutoMeKin/blob/main/notebooks/AutoMeKin2.ipynb) can be used to try some further tests.

## Web site for submitting simple examples<a name="web"></a>
You can also test our [web site](https://rxnkin.usc.es/amk/), where you can submit a simple example.
