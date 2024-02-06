---
title: Run parallel calculations
layout: home
nav_order: 3
---

# Running the code

Unless you donwloaded the singularity container, to start using any of the scripts of the program, load the module:
```
module load amk/2021
```
To run the low-level calculations use:
```
nohup llcalcs.sh molecule.dat ntasks niter runningtasks >llcalcs.log 2>&1 &
```
where:  
<code>molecule</code> is the name of your molecule  
<code>ntasks</code> is the number of tasks  
<code>niter</code> is the number of iterations  
<code>runningtasks</code> is the number of simultaneous tasks  

To run the high-level calculations use:
```
nohup hlcalcs.sh molecule.dat runningtasks >hlcalcs.log 2>&1 &
```
