---
title: Running the tests
layout: home
nav_order: 2
---


# Running the tests

To run the tests follow these steps:

1. Load the module, unless you use singularity:
```
module load amk/2021
```
2. Run the following script to run all tests:
```
run_test.sh
```

{: .warning }  
Note that each test takes from a few seconds to several minutes. The results of each test will be gathered in a different directory.  

If you rather prefer to run a subset of tests use the following:  
```
run_test.sh --tests=FA, FAthermo
```
which will run FA and FAthermo tests only. These are the tests available in this version: `assoc`, `assoc_qcore`, `rdiels_bias`, `diels_bias`, `FA_biasH2`, `FA_biasH2O`, `FA_bxde`, `FA_singletraj`, `FA`, `FAthermo`, `FA_programopt`, `vdW`, `FA_ck`, `FA_qcore`, `FA_bxde_qcore` and `ttors`.

Some tests can be run using this Notebook in Colab: [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/emartineznunez/AutoMeKin/blob/main/AutoMeKin2.ipynb) 
