# Automated Mechanisms and Kinetics (AutoMeKin)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/emartineznunez/AutoMeKin/blob/main/notebooks/AutoMeKin.ipynb)  [![Sylabs - AutoMeKin](https://img.shields.io/badge/Sylabs-AutoMeKin-2ea44f)](https://cloud.sylabs.io/library/emartineznunez/default/automekin) [![DOI](https://zenodo.org/badge/476189550.svg)](https://zenodo.org/doi/10.5281/zenodo.10674957)  [![AutoMeKin - SOURCEFORGE](https://img.shields.io/badge/AutoMeKin-SOURCEFORGE-2ea44f?logo=%23FF6600)](https://sourceforge.net/projects/automekin-rev1140/)





### This is the official repository of the automated reaction discovery program **AutoMeKin**.

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
The installation instructions and much more are [detailed here](https://emartineznunez.github.io/AutoMeKin)

## Simple example in Colab<a name="colab"></a>
You can have a look at this [Notebook](https://colab.research.google.com/github/emartineznunez/AutoMeKin/blob/main/notebooks/AutoMeKin.ipynb) to install it, test a simple example and more...

This second [Notebook](https://colab.research.google.com/github/emartineznunez/AutoMeKin/blob/main/notebooks/AutoMeKin2.ipynb) can be used to try some further tests.

## Web site for submitting simple examples<a name="web"></a>
You can also test our [web site](https://rxnkin.usc.es/amk/), where you can submit a simple example.

