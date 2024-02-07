---
title: Get everything with a single script
layout: home
nav_order: 3
---

# Get everything with a single script

Unless you donwloaded the singularity container, to start using any of the scripts of the program, load the module:
```bash
module load amk/2021
```
To run the low-level calculations use:
```bash
nohup llcalcs.sh molecule.dat ntasks niter runningtasks >llcalcs.log 2>&1 &
```
where:  
<code>molecule</code> is the name of your molecule  
<code>ntasks</code> is the number of tasks  
<code>niter</code> is the number of iterations  
<code>runningtasks</code> is the number of simultaneous tasks  

To run the high-level calculations use:
```bash
nohup hlcalcs.sh molecule.dat runningtasks >hlcalcs.log 2>&1 &
```
